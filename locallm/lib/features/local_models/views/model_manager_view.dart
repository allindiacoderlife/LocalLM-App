import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/local_model_info.dart';
import '../services/model_download_service.dart';
import '../../local_inference/services/local_inference_service.dart';
import '../../cluster/services/phone_cluster_service.dart';
import '../../chat/providers/chat_provider.dart';

class ModelManagerView extends ConsumerWidget {
  const ModelManagerView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloadState = ref.watch(modelDownloadProvider);
    final inferenceState = ref.watch(localInferenceProvider);
    final clusterState = ref.watch(phoneClusterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Local Models & Offline AI'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (inferenceState.isModelLoaded) ...[
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E2228),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.greenAccent, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Model Loaded & Ready (100% Offline)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Text(
                          inferenceState.loadedModelName ?? 'Local GGUF',
                          style: const TextStyle(fontSize: 12, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      ref.read(localInferenceProvider.notifier).unloadModel();
                    },
                    child: const Text('Unload', style: TextStyle(color: Colors.redAccent)),
                  ),
                ],
              ),
            ),
          ],
          const Text(
            'Recommended On-Device Models',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF8B84FF)),
          ),
          const SizedBox(height: 6),
          const Text(
            'Download once. Run forever without an internet connection.',
            style: TextStyle(fontSize: 12.5, color: Colors.white54),
          ),
          const SizedBox(height: 16),
          ...LocalModelPresets.all.map((preset) {
            final isDownloaded = downloadState.downloadedFiles.contains(preset.filename);
            final isDownloading = downloadState.activeDownloadingFilename == preset.filename;
            final progress = downloadState.progress[preset.filename] ?? 0.0;
            final isCurrentLoaded = inferenceState.loadedModelName == preset.name;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E2228),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isCurrentLoaded ? const Color(0xFF6C63FF) : const Color(0xFF2C323C),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          preset.name,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF282D35),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          preset.ramRequirement,
                          style: const TextStyle(fontSize: 11, color: Color(0xFF8B84FF)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    preset.description,
                    style: const TextStyle(fontSize: 12.5, color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Size: ${preset.sizeMb.toInt()} MB • ${preset.author}',
                    style: const TextStyle(fontSize: 11.5, color: Colors.white38),
                  ),
                  const SizedBox(height: 12),
                  if (isDownloading) ...[
                    LinearProgressIndicator(
                      value: progress,
                      backgroundColor: const Color(0xFF282D35),
                      valueColor: const AlwaysStoppedAnimation(Color(0xFF6C63FF)),
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${(progress * 100).toStringAsFixed(1)}% • ${downloadState.downloadedMb} / ${downloadState.totalMb} MB',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        if (downloadState.downloadSpeed.isNotEmpty)
                          Text(
                            downloadState.downloadSpeed,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF8B84FF)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.notifications_active_outlined, size: 14, color: Colors.white38),
                            const SizedBox(width: 4),
                            Text(
                              downloadState.eta.isNotEmpty
                                  ? 'ETA: ${downloadState.eta} • Running in background'
                                  : 'Running in background',
                              style: const TextStyle(fontSize: 11, color: Colors.white54),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: () {
                            ref.read(modelDownloadProvider.notifier).cancelDownload();
                          },
                          child: const Text('Cancel', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                        ),
                      ],
                    ),
                  ] else if (isDownloaded) ...[
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: isCurrentLoaded
                                ? null
                                : () async {
                                    final path = await ref
                                        .read(modelDownloadProvider.notifier)
                                        .getModelPath(preset.filename);
                                    await ref
                                        .read(localInferenceProvider.notifier)
                                        .loadModel(
                                          modelPath: path,
                                          modelName: preset.name,
                                          clusterWorkers: clusterState.connectedWorkers,
                                        );
                                    ref.read(chatProvider.notifier).setInferenceMode(InferenceMode.local);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Loaded ${preset.name} offline!')),
                                      );
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isCurrentLoaded ? Colors.grey.shade800 : const Color(0xFF6C63FF),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: Icon(isCurrentLoaded ? Icons.check : Icons.play_arrow),
                            label: Text(isCurrentLoaded ? 'Active Model' : 'Load into Memory'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () {
                            ref.read(modelDownloadProvider.notifier).deleteModel(preset.filename);
                          },
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                        ),
                      ],
                    ),
                  ] else ...[
                    ElevatedButton.icon(
                      onPressed: downloadState.activeDownloadingFilename != null
                          ? null
                          : () {
                              ref.read(modelDownloadProvider.notifier).downloadModel(preset);
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF282D35),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.download, size: 18),
                      label: const Text('Download Model'),
                    ),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
