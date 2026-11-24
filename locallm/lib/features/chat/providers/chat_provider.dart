import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants.dart';
import '../../cloud/services/cloud_inference_service.dart';
import '../../local_inference/services/local_inference_service.dart';
import '../models/chat_message.dart';
import '../models/chat_session.dart';

enum InferenceMode {
  cloud,
  local,
}

class ChatAttachment {
  final String name;
  final String type;
  final String content;

  ChatAttachment({
    required this.name,
    required this.type,
    required this.content,
  });
}

class ChatState {
  final List<ChatSession> sessions;
  final String? currentSessionId;
  final bool isGenerating;
  final InferenceMode inferenceMode;
  final CloudProvider selectedProvider;
  final String selectedModel;
  final ChatAttachment? attachment;
  final String? errorMessage;

  ChatState({
    this.sessions = const [],
    this.currentSessionId,
    this.isGenerating = false,
    this.inferenceMode = InferenceMode.cloud,
    this.selectedProvider = CloudProvider.gemini,
    this.selectedModel = 'gemini-2.5-flash',
    this.attachment,
    this.errorMessage,
  });

  ChatSession? get currentSession {
    if (currentSessionId == null) return null;
    try {
      return sessions.firstWhere((s) => s.id == currentSessionId);
    } catch (_) {
      return null;
    }
  }

  ChatState copyWith({
    List<ChatSession>? sessions,
    String? currentSessionId,
    bool? isGenerating,
    InferenceMode? inferenceMode,
    CloudProvider? selectedProvider,
    String? selectedModel,
    ChatAttachment? attachment,
    bool clearAttachment = false,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ChatState(
      sessions: sessions ?? this.sessions,
      currentSessionId: currentSessionId ?? this.currentSessionId,
      isGenerating: isGenerating ?? this.isGenerating,
      inferenceMode: inferenceMode ?? this.inferenceMode,
      selectedProvider: selectedProvider ?? this.selectedProvider,
      selectedModel: selectedModel ?? this.selectedModel,
      attachment: clearAttachment ? null : (attachment ?? this.attachment),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class ChatNotifier extends StateNotifier<ChatState> {
  final Ref _ref;
  final CloudInferenceService _cloudService = CloudInferenceService();
  final _uuid = const Uuid();
  StreamSubscription<String>? _streamSub;

  ChatNotifier(this._ref) : super(ChatState()) {
    _loadState();
  }

  void _loadState() {
    final settingsBox = Hive.box(AppConstants.settingsBox);
    final sessionsBox = Hive.box(AppConstants.chatSessionsBox);

    final rawSessions = sessionsBox.get('sessions', defaultValue: <dynamic>[]) as List<dynamic>;
    final sessions = rawSessions
        .map((s) => ChatSession.fromJson(Map<String, dynamic>.from(s as Map)))
        .toList();

    final providerName = settingsBox.get(AppConstants.keySelectedProvider, defaultValue: 'gemini');
    final provider = CloudProvider.values.firstWhere(
      (p) => p.name == providerName,
      orElse: () => CloudProvider.gemini,
    );

    final model = settingsBox.get(
      '${provider.name}_model',
      defaultValue: _defaultModelFor(provider),
    );

    state = state.copyWith(
      sessions: sessions,
      currentSessionId: sessions.isNotEmpty ? sessions.first.id : null,
      selectedProvider: provider,
      selectedModel: model,
    );
  }

  void _saveSessions() {
    final sessionsBox = Hive.box(AppConstants.chatSessionsBox);
    sessionsBox.put('sessions', state.sessions.map((s) => s.toJson()).toList());
  }

  void setInferenceMode(InferenceMode mode) {
    state = state.copyWith(inferenceMode: mode, clearError: true);
  }

  void setAttachment(ChatAttachment? attachment) {
    state = state.copyWith(
      attachment: attachment,
      clearAttachment: attachment == null,
    );
  }

  void setProvider(CloudProvider provider, String model) {
    final settingsBox = Hive.box(AppConstants.settingsBox);
    settingsBox.put(AppConstants.keySelectedProvider, provider.name);
    settingsBox.put('${provider.name}_model', model);

    state = state.copyWith(
      selectedProvider: provider,
      selectedModel: model,
    );
  }

  String _defaultModelFor(CloudProvider provider) {
    switch (provider) {
      case CloudProvider.openAi:
        return 'gpt-4o-mini';
      case CloudProvider.gemini:
        return 'gemini-2.5-flash';
      case CloudProvider.deepSeek:
        return 'deepseek-chat';
      case CloudProvider.anthropic:
        return 'claude-3-5-sonnet-20241022';
      case CloudProvider.openRouter:
        return 'deepseek/deepseek-r1';
    }
  }

  void newChat() {
    final newSession = ChatSession(
      id: _uuid.v4(),
      title: 'New Conversation',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      messages: [],
    );

    final updated = [newSession, ...state.sessions];
    state = state.copyWith(
      sessions: updated,
      currentSessionId: newSession.id,
      clearError: true,
      clearAttachment: true,
    );
    _saveSessions();
  }

  void switchSession(String id) {
    state = state.copyWith(currentSessionId: id, clearError: true);
  }

  void deleteSession(String id) {
    final updated = state.sessions.where((s) => s.id != id).toList();
    state = state.copyWith(
      sessions: updated,
      currentSessionId: updated.isNotEmpty ? updated.first.id : null,
    );
    _saveSessions();
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty && state.attachment == null) return;
    if (state.isGenerating) return;

    if (state.currentSessionId == null) {
      newChat();
    }

    String fullPrompt = text;
    String? attachName = state.attachment?.name;
    String? attachType = state.attachment?.type;

    if (state.attachment != null) {
      fullPrompt = 'Document Context (${state.attachment!.name}):\n"""\n${state.attachment!.content}\n"""\n\nQuestion: $text';
    }

    final userMessage = ChatMessage(
      id: _uuid.v4(),
      role: 'user',
      content: text,
      timestamp: DateTime.now(),
      attachmentName: attachName,
      attachmentType: attachType,
    );

    final assistantMsgId = _uuid.v4();
    final assistantPlaceholder = ChatMessage(
      id: assistantMsgId,
      role: 'assistant',
      content: '',
      timestamp: DateTime.now(),
    );

    final current = state.currentSession!;
    final sessionTitle = current.messages.isEmpty
        ? (text.length > 30 ? '${text.substring(0, 30)}...' : text)
        : current.title;

    final updatedMessages = [...current.messages, userMessage, assistantPlaceholder];
    final updatedSession = current.copyWith(
      title: sessionTitle,
      updatedAt: DateTime.now(),
      messages: updatedMessages,
    );

    state = state.copyWith(
      sessions: state.sessions.map((s) => s.id == updatedSession.id ? updatedSession : s).toList(),
      isGenerating: true,
      clearAttachment: true,
      clearError: true,
    );

    final settingsBox = Hive.box(AppConstants.settingsBox);
    final systemPrompt = settingsBox.get(
      AppConstants.keySystemPrompt,
      defaultValue: AppConstants.defaultSystemPrompt,
    );

    StringBuffer streamBuffer = StringBuffer();

    // 1. ROUTE TO LOCAL OFFLINE INFERENCE (0 INTERNET REQUIRED)
    if (state.inferenceMode == InferenceMode.local) {
      final localInference = _ref.read(localInferenceProvider);
      if (!localInference.isModelLoaded) {
        state = state.copyWith(
          isGenerating: false,
          errorMessage: 'No local model is loaded. Open "Local Models" from the menu to load one.',
        );
        return;
      }

      try {
        final temperature = (settingsBox.get('temperature', defaultValue: 0.30) as num).toDouble();
        final maxTokens = (settingsBox.get('max_tokens', defaultValue: 256) as num).toInt();

        final stream = _ref.read(localInferenceProvider.notifier).streamGenerate(
          prompt: fullPrompt,
          systemPrompt: systemPrompt,
          temperature: temperature,
          maxTokens: maxTokens,
        );

        _streamSub = stream.listen(
          (chunk) {
            streamBuffer.write(chunk);
            _updateAssistantMessage(assistantMsgId, streamBuffer.toString());
          },
          onError: (err) {
            state = state.copyWith(
              isGenerating: false,
              errorMessage: err.toString(),
            );
          },
          onDone: () {
            final tps = _ref.read(localInferenceProvider).tokensPerSecond;
            _updateAssistantMessage(
              assistantMsgId,
              streamBuffer.toString(),
              tokensPerSec: tps > 0 ? tps : null,
            );
            state = state.copyWith(isGenerating: false);
            _saveSessions();
          },
        );
      } catch (e) {
        state = state.copyWith(
          isGenerating: false,
          errorMessage: e.toString(),
        );
      }
      return;
    }

    // 2. ROUTE TO CLOUD API PROVIDER
    final apiKey = _getApiKey(state.selectedProvider, settingsBox);
    if (apiKey.isEmpty) {
      state = state.copyWith(
        isGenerating: false,
        errorMessage: 'API Key missing for ${state.selectedProvider.name.toUpperCase()}. Please configure it in Settings or switch to Local Model.',
      );
      return;
    }

    try {
      final stream = _cloudService.streamChat(
        provider: state.selectedProvider,
        apiKey: apiKey,
        model: state.selectedModel,
        history: current.messages,
        prompt: fullPrompt,
        systemPrompt: systemPrompt,
      );

      _streamSub = stream.listen(
        (chunk) {
          streamBuffer.write(chunk);
          _updateAssistantMessage(assistantMsgId, streamBuffer.toString());
        },
        onError: (err) {
          state = state.copyWith(
            isGenerating: false,
            errorMessage: err.toString(),
          );
        },
        onDone: () {
          state = state.copyWith(isGenerating: false);
          _saveSessions();
        },
      );
    } catch (e) {
      state = state.copyWith(
        isGenerating: false,
        errorMessage: e.toString(),
      );
    }
  }

  void _updateAssistantMessage(String messageId, String updatedContent, {double? tokensPerSec}) {
    if (state.currentSessionId == null) return;
    final current = state.currentSession!;
    final updatedMessages = current.messages.map((m) {
      if (m.id == messageId) {
        return m.copyWith(
          content: updatedContent,
          tokensPerSec: tokensPerSec ?? m.tokensPerSec,
        );
      }
      return m;
    }).toList();

    final updatedSession = current.copyWith(messages: updatedMessages);
    state = state.copyWith(
      sessions: state.sessions.map((s) => s.id == updatedSession.id ? updatedSession : s).toList(),
    );
  }

  void stopGeneration() {
    _streamSub?.cancel();
    _streamSub = null;
    if (state.inferenceMode == InferenceMode.local) {
      _ref.read(localInferenceProvider.notifier).stopGeneration();
    }
    state = state.copyWith(isGenerating: false);
    _saveSessions();
  }

  String _getApiKey(CloudProvider provider, Box box) {
    switch (provider) {
      case CloudProvider.openAi:
        return box.get(AppConstants.keyOpenAiKey, defaultValue: '') as String;
      case CloudProvider.gemini:
        return box.get(AppConstants.keyGeminiKey, defaultValue: '') as String;
      case CloudProvider.deepSeek:
        return box.get(AppConstants.keyDeepSeekKey, defaultValue: '') as String;
      case CloudProvider.anthropic:
        return box.get(AppConstants.keyAnthropicKey, defaultValue: '') as String;
      case CloudProvider.openRouter:
        return box.get(AppConstants.keyOpenRouterKey, defaultValue: '') as String;
    }
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  return ChatNotifier(ref);
});
