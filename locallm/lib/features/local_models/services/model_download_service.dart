import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../models/local_model_info.dart';
import '../../../core/services/download_notification_service.dart';

class ModelDownloadState {
  final Map<String, double> progress; // filename -> 0.0 .. 1.0
  final List<String> downloadedFiles;
  final String? activeDownloadingFilename;
  final String downloadSpeed; // e.g. "8.4 MB/s"
  final String eta; // e.g. "45s"
  final int downloadedMb;
  final int totalMb;

  ModelDownloadState({
    this.progress = const {},
    this.downloadedFiles = const [],
    this.activeDownloadingFilename,
    this.downloadSpeed = '',
    this.eta = '',
    this.downloadedMb = 0,
    this.totalMb = 0,
  });

  ModelDownloadState copyWith({
    Map<String, double>? progress,
    List<String>? downloadedFiles,
    String? activeDownloadingFilename,
    String? downloadSpeed,
    String? eta,
    int? downloadedMb,
    int? totalMb,
    bool clearActive = false,
  }) {
    return ModelDownloadState(
      progress: progress ?? this.progress,
      downloadedFiles: downloadedFiles ?? this.downloadedFiles,
      activeDownloadingFilename: clearActive
          ? null
          : (activeDownloadingFilename ?? this.activeDownloadingFilename),
      downloadSpeed: clearActive ? '' : (downloadSpeed ?? this.downloadSpeed),
      eta: clearActive ? '' : (eta ?? this.eta),
      downloadedMb: clearActive ? 0 : (downloadedMb ?? this.downloadedMb),
      totalMb: clearActive ? 0 : (totalMb ?? this.totalMb),
    );
  }
}

class ModelDownloadNotifier extends StateNotifier<ModelDownloadState> {
  final Dio _dio = Dio();
  final DownloadNotificationService _notifService = DownloadNotificationService();
  CancelToken? _cancelToken;

  ModelDownloadNotifier() : super(ModelDownloadState()) {
    refreshDownloadedModels();
    _notifService.init();
  }

  Future<String> getModelsDirectory() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/models');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir.path;
  }

  Future<void> refreshDownloadedModels() async {
    final modelsDir = await getModelsDirectory();
    final dir = Directory(modelsDir);
    if (!await dir.exists()) {
      state = state.copyWith(downloadedFiles: []);
      return;
    }

    final files = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.toLowerCase().endsWith('.gguf'))
        .map((f) => f.uri.pathSegments.last)
        .toList();

    state = state.copyWith(downloadedFiles: files);
  }

  Future<String> getModelPath(String filename) async {
    final dir = await getModelsDirectory();
    return '$dir/$filename';
  }

  Future<bool> isModelDownloaded(String filename) async {
    final path = await getModelPath(filename);
    return File(path).existsSync();
  }

  Future<void> downloadModel(LocalModelPreset preset) async {
    final modelsDir = await getModelsDirectory();
    final savePath = '$modelsDir/${preset.filename}';
    final tempPath = '$savePath.download';

    _cancelToken = CancelToken();
    state = state.copyWith(
      activeDownloadingFilename: preset.filename,
      progress: {...state.progress, preset.filename: 0.0},
    );

    int lastBytes = 0;
    DateTime lastTime = DateTime.now();
    DateTime lastNotifUpdate = DateTime.now();
    String currentSpeed = '0 MB/s';
    String currentEta = '';

    const int notificationId = 1001;

    try {
      await _dio.download(
        preset.downloadUrl,
        tempPath,
        cancelToken: _cancelToken,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            final now = DateTime.now();
            final timeDelta = now.difference(lastTime).inMilliseconds / 1000.0;

            if (timeDelta >= 0.8) {
              final bytesDelta = received - lastBytes;
              final bytesPerSec = bytesDelta / timeDelta;

              // Format speed
              if (bytesPerSec >= 1024 * 1024) {
                currentSpeed = '${(bytesPerSec / (1024 * 1024)).toStringAsFixed(1)} MB/s';
              } else {
                currentSpeed = '${(bytesPerSec / 1024).toStringAsFixed(0)} KB/s';
              }

              // Format ETA
              final remainingBytes = total - received;
              if (bytesPerSec > 0) {
                final remainingSec = (remainingBytes / bytesPerSec).round();
                if (remainingSec >= 60) {
                  currentEta = '${remainingSec ~/ 60}m ${remainingSec % 60}s';
                } else {
                  currentEta = '${remainingSec}s';
                }
              }

              lastBytes = received;
              lastTime = now;
            }

            final p = received / total;
            final dMb = received ~/ (1024 * 1024);
            final tMb = total ~/ (1024 * 1024);

            state = state.copyWith(
              progress: {...state.progress, preset.filename: p},
              downloadSpeed: currentSpeed,
              eta: currentEta,
              downloadedMb: dMb,
              totalMb: tMb,
            );

            // Throttle notifications to once every 1.5 seconds to avoid spamming Android notification manager
            if (now.difference(lastNotifUpdate).inMilliseconds >= 1500) {
              lastNotifUpdate = now;
              _notifService.showProgress(
                id: notificationId,
                modelName: preset.name,
                progressPercent: (p * 100).toInt(),
                speed: currentSpeed,
                eta: currentEta,
                downloadedMb: dMb,
                totalMb: tMb,
              );
            }
          }
        },
      );

      // Rename from .download to .gguf
      final tempFile = File(tempPath);
      if (await tempFile.exists()) {
        await tempFile.rename(savePath);
      }

      await refreshDownloadedModels();
      await _notifService.showComplete(id: notificationId, modelName: preset.name);
      state = state.copyWith(clearActive: true);
    } catch (e) {
      final tempFile = File(tempPath);
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
      final updatedProgress = Map<String, double>.from(state.progress);
      updatedProgress.remove(preset.filename);
      await _notifService.cancel(notificationId);
      state = state.copyWith(
        progress: updatedProgress,
        clearActive: true,
      );
      rethrow;
    }
  }

  void cancelDownload() {
    _cancelToken?.cancel('Cancelled by user');
    _cancelToken = null;
    _notifService.cancel(1001);
    state = state.copyWith(clearActive: true);
  }

  Future<void> deleteModel(String filename) async {
    final path = await getModelPath(filename);
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
    await refreshDownloadedModels();
  }
}

final modelDownloadProvider =
    StateNotifierProvider<ModelDownloadNotifier, ModelDownloadState>((ref) {
  return ModelDownloadNotifier();
});
