import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../services/local_api_server_service.dart';
import '../../local_inference/services/local_inference_service.dart';
import '../../chat/providers/chat_provider.dart';
import '../../cloud/services/cloud_inference_service.dart';
import '../../../core/constants.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ServerState {
  final bool isRunning;
  final bool isStarting;
  final String? url;
  final int port;
  final bool allowNetwork;
  final bool requiresApiKey;
  final String apiKey;
  final List<String> logs;
  final int requestsServed;
  final String? error;

  ServerState({
    this.isRunning = false,
    this.isStarting = false,
    this.url,
    this.port = 8080,
    this.allowNetwork = false,
    this.requiresApiKey = false,
    this.apiKey = '',
    this.logs = const [],
    this.requestsServed = 0,
    this.error,
  });

  ServerState copyWith({
    bool? isRunning,
    bool? isStarting,
    String? url,
    int? port,
    bool? allowNetwork,
    bool? requiresApiKey,
    String? apiKey,
    List<String>? logs,
    int? requestsServed,
    String? error,
    bool clearError = false,
  }) {
    return ServerState(
      isRunning: isRunning ?? this.isRunning,
      isStarting: isStarting ?? this.isStarting,
      url: url ?? this.url,
      port: port ?? this.port,
      allowNetwork: allowNetwork ?? this.allowNetwork,
      requiresApiKey: requiresApiKey ?? this.requiresApiKey,
      apiKey: apiKey ?? this.apiKey,
      logs: logs ?? this.logs,
      requestsServed: requestsServed ?? this.requestsServed,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class ServerNotifier extends StateNotifier<ServerState> {
  final Ref _ref;
  final LocalApiServerService _service = LocalApiServerService();
  final CloudInferenceService _cloudService = CloudInferenceService();
  StreamSubscription<String>? _logSub;

  ServerNotifier(this._ref) : super(ServerState()) {
    _logSub = _service.logStream.listen((log) {
      final updated = [log, ...state.logs];
      if (updated.length > 100) updated.removeLast();
      final isRequest = log.contains('POST /v1/chat/completions');
      state = state.copyWith(
        logs: updated,
        requestsServed: isRequest ? state.requestsServed + 1 : state.requestsServed,
      );
    });
  }

  void generateApiKey() {
    final key = 'sk-local-${const Uuid().v4().substring(0, 16)}';
    state = state.copyWith(apiKey: key);
    if (state.isRunning) {
      _service.updateApiKey(state.requiresApiKey ? key : null);
    }
  }

  void setApiKey(String key) {
    state = state.copyWith(apiKey: key);
    if (state.isRunning) {
      _service.updateApiKey(state.requiresApiKey ? key : null);
    }
  }

  void setAllowNetwork(bool allow) {
    state = state.copyWith(allowNetwork: allow);
    if (allow) {
      // Network access requires an API key for security
      state = state.copyWith(requiresApiKey: true);
      if (state.apiKey.isEmpty) generateApiKey();
    }
  }

  void setRequiresApiKey(bool req) {
    state = state.copyWith(requiresApiKey: req);
    if (req && state.apiKey.isEmpty) {
      generateApiKey();
    }
    if (state.isRunning) {
      _service.updateApiKey(req ? state.apiKey : null);
    }
  }

  Future<void> toggleServer() async {
    if (state.isRunning) {
      await stopServer();
    } else {
      await startServer();
    }
  }

  Future<void> startServer() async {
    state = state.copyWith(isStarting: true, clearError: true);
    try {
      await _service.start(
        port: state.port,
        apiKey: state.requiresApiKey ? state.apiKey : null,
        allowNetwork: state.allowNetwork,
        onGenerateChat: (prompt, systemPrompt) async {
          // If local model is loaded, use local inference
          final localInference = _ref.read(localInferenceProvider);
          if (localInference.isModelLoaded) {
            return _ref.read(localInferenceProvider.notifier).streamGenerate(
                  prompt: prompt,
                  systemPrompt: systemPrompt,
                );
          }

          // Otherwise fall back to configured cloud API provider
          final chatState = _ref.read(chatProvider);
          final box = Hive.box(AppConstants.settingsBox);
          final apiKey = box.get('${chatState.selectedProvider.name}_api_key', defaultValue: '') as String;

          if (apiKey.isEmpty) {
            throw Exception('No local model loaded and no cloud API key configured.');
          }

          return _cloudService.streamChat(
            provider: chatState.selectedProvider,
            apiKey: apiKey,
            model: chatState.selectedModel,
            history: [],
            prompt: prompt,
            systemPrompt: systemPrompt,
          );
        },
        getCurrentModelName: () {
          final local = _ref.read(localInferenceProvider);
          if (local.isModelLoaded) {
            return local.loadedModelName ?? 'Local-GGUF';
          }
          final chatState = _ref.read(chatProvider);
          return chatState.selectedModel;
        },
      );

      state = state.copyWith(
        isRunning: true,
        isStarting: false,
        url: _service.localUrl,
      );
    } catch (e) {
      state = state.copyWith(
        isStarting: false,
        error: 'Failed to start server: $e',
      );
    }
  }

  Future<void> stopServer() async {
    await _service.stop();
    state = state.copyWith(isRunning: false, url: null);
  }

  void clearLogs() {
    state = state.copyWith(logs: []);
  }

  @override
  void dispose() {
    _logSub?.cancel();
    _service.stop();
    super.dispose();
  }
}

final serverProvider = StateNotifierProvider<ServerNotifier, ServerState>((ref) {
  return ServerNotifier(ref);
});
