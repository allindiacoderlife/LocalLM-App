import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:llama_flutter_android/llama_flutter_android.dart';

class LocalInferenceState {
  final bool isModelLoaded;
  final bool isLoadingModel;
  final bool isGenerating;
  final String? loadedModelName;
  final String? loadedModelPath;
  final double tokensPerSecond;
  final int totalTokensGenerated;
  final String? error;

  LocalInferenceState({
    this.isModelLoaded = false,
    this.isLoadingModel = false,
    this.isGenerating = false,
    this.loadedModelName,
    this.loadedModelPath,
    this.tokensPerSecond = 0.0,
    this.totalTokensGenerated = 0,
    this.error,
  });

  LocalInferenceState copyWith({
    bool? isModelLoaded,
    bool? isLoadingModel,
    bool? isGenerating,
    String? loadedModelName,
    String? loadedModelPath,
    double? tokensPerSecond,
    int? totalTokensGenerated,
    String? error,
    bool clearError = false,
    bool clearModel = false,
  }) {
    return LocalInferenceState(
      isModelLoaded: clearModel ? false : (isModelLoaded ?? this.isModelLoaded),
      isLoadingModel: isLoadingModel ?? this.isLoadingModel,
      isGenerating: isGenerating ?? this.isGenerating,
      loadedModelName: clearModel ? null : (loadedModelName ?? this.loadedModelName),
      loadedModelPath: clearModel ? null : (loadedModelPath ?? this.loadedModelPath),
      tokensPerSecond: tokensPerSecond ?? this.tokensPerSecond,
      totalTokensGenerated: totalTokensGenerated ?? this.totalTokensGenerated,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class LocalInferenceNotifier extends StateNotifier<LocalInferenceState> {
  LlamaController? _controller;
  StreamSubscription<String>? _generationSub;

  LocalInferenceNotifier() : super(LocalInferenceState());

  bool get isSupported => Platform.isAndroid;

  Future<void> loadModel({
    required String modelPath,
    required String modelName,
    int contextSize = 512,
    int threads = 4,
    List<ClusterWorker>? clusterWorkers,
  }) async {
    if (!isSupported) {
      state = state.copyWith(error: 'Local GGUF inference is supported on Android.');
      return;
    }

    state = state.copyWith(isLoadingModel: true, clearError: true);

    try {
      if (_controller != null) {
        await _controller!.dispose();
      }

      _controller = LlamaController();

      // Configure generation & loading
      await _controller!.loadModel(
        modelPath: modelPath,
        contextSize: contextSize,
        threads: threads,
      );

      state = state.copyWith(
        isModelLoaded: true,
        isLoadingModel: false,
        loadedModelName: modelName,
        loadedModelPath: modelPath,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingModel: false,
        error: 'Failed to load model: $e',
      );
    }
  }

  Stream<String> streamGenerate({
    required String prompt,
    String? systemPrompt,
    double temperature = 0.7,
    int maxTokens = 1024,
  }) async* {
    if (_controller == null || !state.isModelLoaded) {
      throw Exception('No local model loaded. Please load a GGUF model first.');
    }

    state = state.copyWith(isGenerating: true, clearError: true);
    final startTime = DateTime.now();
    int tokenCount = 0;

    final controller = StreamController<String>();

    String formattedPrompt = prompt;
    if (systemPrompt != null && systemPrompt.isNotEmpty) {
      formattedPrompt = '<|im_start|>system\n$systemPrompt<|im_end|>\n<|im_start|>user\n$prompt<|im_end|>\n<|im_start|>assistant\n';
    }

    try {
      _generationSub = _controller!
          .generate(
            prompt: formattedPrompt,
            temperature: temperature,
            maxTokens: maxTokens,
          )
          .listen(
        (token) {
          tokenCount++;
          final elapsed = DateTime.now().difference(startTime).inMilliseconds / 1000.0;
          if (elapsed > 0) {
            state = state.copyWith(
              tokensPerSecond: tokenCount / elapsed,
              totalTokensGenerated: tokenCount,
            );
          }
          controller.add(token);
        },
        onError: (err) {
          controller.addError(err);
          state = state.copyWith(isGenerating: false, error: err.toString());
        },
        onDone: () {
          controller.close();
          state = state.copyWith(isGenerating: false);
        },
      );

      yield* controller.stream;
    } catch (e) {
      state = state.copyWith(isGenerating: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> stopGeneration() async {
    await _generationSub?.cancel();
    _generationSub = null;
    if (_controller != null) {
      await _controller!.stop();
    }
    state = state.copyWith(isGenerating: false);
  }

  Future<void> unloadModel() async {
    await stopGeneration();
    if (_controller != null) {
      await _controller!.dispose();
      _controller = null;
    }
    state = state.copyWith(clearModel: true);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}

final localInferenceProvider =
    StateNotifierProvider<LocalInferenceNotifier, LocalInferenceState>((ref) {
  return LocalInferenceNotifier();
});
