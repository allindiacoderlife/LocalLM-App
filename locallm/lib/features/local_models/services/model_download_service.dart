import 'dart:async';
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
  final bool isImporting;
  final List<String> importQueue;

  ModelDownloadState({
    this.progress = const {},
    this.downloadedFiles = const [],
    this.activeDownloadingFilename,
    this.downloadSpeed = '',
    this.eta = '',
    this.downloadedMb = 0,
    this.totalMb = 0,
    this.isImporting = false,
    this.importQueue = const [],
  });

  ModelDownloadState copyWith({
    Map<String, double>? progress,
    List<String>? downloadedFiles,
    String? activeDownloadingFilename,
    String? downloadSpeed,
    String? eta,
    int? downloadedMb,
    int? totalMb,
    bool? isImporting,
    List<String>? importQueue,
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
      isImporting: clearActive ? false : (isImporting ?? this.isImporting),
      importQueue: clearActive ? const [] : (importQueue ?? this.importQueue),
    );
  }
}

class ModelDownloadNotifier extends StateNotifier<ModelDownloadState> {
  final Dio _dio = Dio();
  final DownloadNotificationService _notifService =
      DownloadNotificationService();
  CancelToken? _cancelToken;
  int? _activeNotificationId;
  bool _importCancelled = false;

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
    if (state.activeDownloadingFilename != null) {
      return;
    }

    final modelsDir = await getModelsDirectory();
    final savePath = '$modelsDir/${preset.filename}';
    final tempPath = '$savePath.download';
    final tempFile = File(tempPath);

    _cancelToken = CancelToken();
    final int notificationId = 1000 + (preset.filename.hashCode & 0x7FFF);
    _activeNotificationId = notificationId;

    final initialBytes = tempFile.existsSync() ? tempFile.lengthSync() : 0;
    final estimatedTotalBytes = (preset.sizeMb * 1024 * 1024).round();
    final initialProgress = (initialBytes > 0 && estimatedTotalBytes > 0)
        ? (initialBytes / estimatedTotalBytes).clamp(0.0, 0.99)
        : 0.0;

    state = state.copyWith(
      activeDownloadingFilename: preset.filename,
      progress: {...state.progress, preset.filename: initialProgress},
      downloadedMb: initialBytes ~/ (1024 * 1024),
      totalMb: preset.sizeMb.round(),
    );

    const int maxAttempts = 5;
    int attempt = 0;

    try {
      while (true) {
        attempt++;
        final existingBytes = tempFile.existsSync() ? tempFile.lengthSync() : 0;

        try {
          final response = await _dio.get<ResponseBody>(
            preset.downloadUrl,
            cancelToken: _cancelToken,
            options: Options(
              responseType: ResponseType.stream,
              headers:
                  existingBytes > 0 ? {'Range': 'bytes=$existingBytes-'} : null,
              followRedirects: true,
              receiveTimeout: const Duration(minutes: 10),
              validateStatus: (status) =>
                  status != null &&
                  (status == 200 || status == 206 || status == 416),
            ),
          );

          final statusCode = response.statusCode ?? 200;
          if (statusCode == 416) {
            // File is already completely downloaded on disk
            break;
          }

          final isResume = statusCode == 206 && existingBytes > 0;
          int baseBytes = isResume ? existingBytes : 0;
          int totalBytes = _resolveTotalBytes(
            response.headers,
            baseBytes: baseBytes,
            fallbackMb: preset.sizeMb,
          );

          final sink = tempFile.openWrite(
            mode: isResume ? FileMode.append : FileMode.write,
          );

          int received = baseBytes;
          int lastBytes = received;
          DateTime lastTime = DateTime.now();
          DateTime lastNotifUpdate = DateTime.now();
          String currentSpeed = '0 MB/s';
          String currentEta = '';

          final completer = Completer<void>();
          late final StreamSubscription<List<int>> sub;

          sub = response.data!.stream.listen(
            (chunk) {
              sink.add(chunk);
              received += chunk.length;

              final now = DateTime.now();
              final timeDelta =
                  now.difference(lastTime).inMilliseconds / 1000.0;

              if (timeDelta >= 0.8) {
                final bytesDelta = received - lastBytes;
                final bytesPerSec = bytesDelta / timeDelta;

                if (bytesPerSec >= 1024 * 1024) {
                  currentSpeed =
                      '${(bytesPerSec / (1024 * 1024)).toStringAsFixed(1)} MB/s';
                } else if (bytesPerSec > 0) {
                  currentSpeed =
                      '${(bytesPerSec / 1024).toStringAsFixed(0)} KB/s';
                }

                final remainingBytes = totalBytes - received;
                if (bytesPerSec > 0 && remainingBytes > 0) {
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

              final p = totalBytes > 0
                  ? (received / totalBytes).clamp(0.0, 1.0)
                  : 0.0;
              final dMb = received ~/ (1024 * 1024);
              final tMb = totalBytes ~/ (1024 * 1024);

              state = state.copyWith(
                progress: {...state.progress, preset.filename: p},
                downloadSpeed: currentSpeed,
                eta: currentEta,
                downloadedMb: dMb,
                totalMb: tMb,
              );

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
            },
            onDone: () async {
              await sink.flush();
              await sink.close();
              if (!completer.isCompleted) completer.complete();
            },
            onError: (Object err, StackTrace st) async {
              await sink.flush();
              await sink.close();
              if (!completer.isCompleted) completer.completeError(err, st);
            },
            cancelOnError: true,
          );

          // Ensure user cancellation immediately aborts the stream
          _cancelToken?.whenCancel.then((_) async {
            await sub.cancel();
            await sink.flush();
            await sink.close();
            if (!completer.isCompleted) {
              completer.completeError(
                DioException.requestCancelled(
                  requestOptions: response.requestOptions,
                  reason: 'Cancelled by user',
                ),
              );
            }
          });

          await completer.future;
          break; // Download finished cleanly
        } catch (e) {
          final isCancelled = _cancelToken?.isCancelled == true ||
              (e is DioException && CancelToken.isCancel(e));
          if (isCancelled || attempt >= maxAttempts) {
            rethrow;
          }
          // Network switched (e.g. Wi-Fi <-> Mobile Data): pause briefly and resume from disk
          state = state.copyWith(
            downloadSpeed: 'Reconnecting…',
            eta: '',
          );
          await Future.delayed(const Duration(milliseconds: 2500));
        }
      }

      // Rename from .download to final file
      if (await tempFile.exists()) {
        await tempFile.rename(savePath);
      }

      await refreshDownloadedModels();
      await _notifService.showComplete(
        id: notificationId,
        modelName: preset.name,
      );
      _activeNotificationId = null;
      state = state.copyWith(clearActive: true);
    } catch (e) {
      // Keep partial .download file on disk so next tap resumes from saved bytes!
      final savedBytes = tempFile.existsSync() ? tempFile.lengthSync() : 0;
      final updatedProgress = Map<String, double>.from(state.progress);
      if (savedBytes > 0 && estimatedTotalBytes > 0) {
        updatedProgress[preset.filename] =
            (savedBytes / estimatedTotalBytes).clamp(0.0, 0.99);
      } else {
        updatedProgress.remove(preset.filename);
      }
      await _notifService.cancel(notificationId);
      _activeNotificationId = null;
      state = state.copyWith(
        progress: updatedProgress,
        clearActive: true,
      );
      if (!(_cancelToken?.isCancelled == true ||
          (e is DioException && CancelToken.isCancel(e)))) {
        rethrow;
      }
    }
  }

  int _resolveTotalBytes(
    Headers headers, {
    required int baseBytes,
    required double fallbackMb,
  }) {
    final contentRange = headers.value('content-range');
    if (contentRange != null) {
      final slashIdx = contentRange.lastIndexOf('/');
      if (slashIdx != -1) {
        final total = int.tryParse(contentRange.substring(slashIdx + 1).trim());
        if (total != null && total > 0) return total;
      }
    }
    final contentLen = int.tryParse(headers.value('content-length') ?? '');
    if (contentLen != null && contentLen > 0) {
      return baseBytes + contentLen;
    }
    return (fallbackMb * 1024 * 1024).round();
  }

  void cancelDownload() {
    _importCancelled = true;
    _cancelToken?.cancel('Cancelled by user');
    _cancelToken = null;
    if (_activeNotificationId != null) {
      _notifService.cancel(_activeNotificationId!);
      _activeNotificationId = null;
    }
    state = state.copyWith(clearActive: true);
  }

  Future<int> importModelQueue(List<({String path, String name})> items) async {
    if (state.activeDownloadingFilename != null) {
      throw Exception('Another download or import is currently in progress.');
    }
    if (items.isEmpty) return 0;

    _importCancelled = false;
    int importedCount = 0;
    final remaining = items.map((e) => e.name).toList();

    for (final item in items) {
      if (_importCancelled) break;
      remaining.removeAt(0);
      state = state.copyWith(
        isImporting: true,
        importQueue: List<String>.from(remaining),
      );

      final ok = await _importSingleFile(item.path, item.name);
      if (ok) {
        importedCount++;
        await refreshDownloadedModels();
      }
    }

    state = state.copyWith(clearActive: true);
    return importedCount;
  }

  Future<bool> _importSingleFile(String pickedPath, String name) async {
    final srcFile = File(pickedPath);
    if (!await srcFile.exists() || await srcFile.length() < 4) {
      return false;
    }

    final raf = await srcFile.open();
    final magic = await raf.read(4);
    await raf.close();
    if (String.fromCharCodes(magic) != 'GGUF') {
      return false;
    }

    final totalBytes = await srcFile.length();
    final totalMb = totalBytes ~/ (1024 * 1024);

    state = state.copyWith(
      isImporting: true,
      activeDownloadingFilename: name,
      progress: {...state.progress, name: 0.0},
      downloadSpeed: 'Preparing…',
      eta: '',
      downloadedMb: 0,
      totalMb: totalMb,
    );

    final modelsDir = await getModelsDirectory();
    final destinationPath = '$modelsDir/$name';
    final destFile = File(destinationPath);

    try {
      if (await destFile.exists()) {
        await destFile.delete();
      }

      try {
        await srcFile.rename(destinationPath);
        state = state.copyWith(
          progress: {...state.progress, name: 1.0},
          downloadSpeed: 'Moved',
          downloadedMb: totalMb,
        );
      } catch (_) {
        // Cross-filesystem copy with live speed, memory & ETA tracking
        final sink = destFile.openWrite();
        int copiedBytes = 0;
        int lastBytes = 0;
        DateTime lastSpeedTime = DateTime.now();
        DateTime lastUiUpdate = DateTime.now();
        String currentSpeed = 'Copying…';
        String currentEta = '';

        await for (final chunk in srcFile.openRead()) {
          if (_importCancelled) {
            await sink.close();
            if (await destFile.exists()) await destFile.delete();
            return false;
          }

          sink.add(chunk);
          copiedBytes += chunk.length;

          final now = DateTime.now();
          final speedDelta =
              now.difference(lastSpeedTime).inMilliseconds / 1000.0;
          if (speedDelta >= 0.5) {
            final bytesDelta = copiedBytes - lastBytes;
            final bytesPerSec = bytesDelta / speedDelta;
            if (bytesPerSec >= 1024 * 1024) {
              currentSpeed =
                  '${(bytesPerSec / (1024 * 1024)).toStringAsFixed(1)} MB/s';
            } else if (bytesPerSec > 0) {
              currentSpeed = '${(bytesPerSec / 1024).toStringAsFixed(0)} KB/s';
            }

            final remainingBytes = totalBytes - copiedBytes;
            if (bytesPerSec > 0 && remainingBytes > 0) {
              final sec = (remainingBytes / bytesPerSec).round();
              currentEta = sec >= 60 ? '${sec ~/ 60}m ${sec % 60}s' : '${sec}s';
            }

            lastBytes = copiedBytes;
            lastSpeedTime = now;
          }

          if (now.difference(lastUiUpdate).inMilliseconds >= 200 ||
              copiedBytes >= totalBytes) {
            lastUiUpdate = now;
            final p = totalBytes > 0
                ? (copiedBytes / totalBytes).clamp(0.0, 1.0)
                : 0.0;
            state = state.copyWith(
              progress: {...state.progress, name: p},
              downloadSpeed: currentSpeed,
              eta: currentEta,
              downloadedMb: copiedBytes ~/ (1024 * 1024),
              totalMb: totalMb,
            );
          }
        }
        await sink.flush();
        await sink.close();

        if (pickedPath.contains('file_picker')) {
          try {
            await srcFile.delete();
          } catch (_) {}
        }
      }
      return true;
    } catch (_) {
      if (await destFile.exists()) {
        try {
          await destFile.delete();
        } catch (_) {}
      }
      final updatedProgress = Map<String, double>.from(state.progress);
      updatedProgress.remove(name);
      state = state.copyWith(progress: updatedProgress);
      return false;
    }
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
