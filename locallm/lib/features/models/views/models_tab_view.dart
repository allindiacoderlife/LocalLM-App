import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/constants.dart';
import '../../../core/ui.dart';
import '../../local_models/models/local_model_info.dart';
import '../../local_models/services/model_download_service.dart';
import '../../local_inference/services/local_inference_service.dart';
import '../../cloud/services/cloud_inference_service.dart';
import '../../chat/providers/chat_provider.dart';

class ModelsTabView extends ConsumerStatefulWidget {
  const ModelsTabView({super.key});

  @override
  ConsumerState<ModelsTabView> createState() => _ModelsTabViewState();
}

class _ModelsTabViewState extends ConsumerState<ModelsTabView> {
  String _selectedScope = 'browse'; // 'local', 'browse', 'online'
  String _selectedCategory = 'chat'; // 'chat', 'image', 'uncensored', 'vision'
  bool? _sortBySizeAsc; // null = default order, true = asc, false = desc

  List<LocalModelPreset> get _filteredPresets {
    var list = LocalModelPresets.all
        .where((m) => m.category == _selectedCategory)
        .toList();
    if (list.isEmpty) {
      list = LocalModelPresets.all;
    }
    if (_sortBySizeAsc != null) {
      list.sort((a, b) => _sortBySizeAsc!
          ? a.sizeMb.compareTo(b.sizeMb)
          : b.sizeMb.compareTo(a.sizeMb));
    }
    return list;
  }

  Future<void> _importLocalFile() async {
    final result = await FilePicker.pickFiles(type: FileType.any);

    if (result != null && result.files.single.path != null) {
      final pickedPath = result.files.single.path!;
      final name = result.files.single.name;
      if (!name.toLowerCase().endsWith('.gguf')) {
        if (mounted) {
          showToast(context, 'Invalid format',
              'Please select a valid .gguf model file.',
              tone: ToastTone.warning);
        }
        return;
      }

      final modelsDir =
          await ref.read(modelDownloadProvider.notifier).getModelsDirectory();
      final destinationPath = '$modelsDir/$name';
      await File(pickedPath).copy(destinationPath);
      await ref.read(modelDownloadProvider.notifier).refreshDownloadedModels();

      if (mounted) {
        showToast(context, 'Imported', 'Imported $name successfully!',
            tone: ToastTone.success);
      }
    }
  }

  void _showModelDetails(LocalModelPreset model) {
    final downloadState = ref.watch(modelDownloadProvider);
    final inferenceState = ref.watch(localInferenceProvider);
    final isDownloaded = downloadState.downloadedFiles.contains(model.filename);
    final isLoaded = inferenceState.isModelLoaded &&
        inferenceState.loadedModelName == model.filename;
    final (badge, color) = _getBadgeInfo(model.name);

    showAppSheet(
      context,
      title: model.name,
      builder: (ctx) {
        final t = AppTokens.of(ctx);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                _buildAvatar(badge, color, size: 48),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(model.name,
                          style: t.bodyStrong.copyWith(fontSize: 16)),
                      const SizedBox(height: 3),
                      Text('By ${model.author} · ${model.ramRequirement}',
                          style: t.caption),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(model.description, style: t.body),
            const SizedBox(height: 16),
            AppGroup(
              children: [
                AppRow(
                    title: 'File size',
                    trailing: Text('${model.sizeMb.toStringAsFixed(0)} MB',
                        style: t.caption)),
                AppRow(
                    title: 'RAM required',
                    trailing: Text(model.ramRequirement, style: t.caption)),
                AppRow(
                    title: 'Format',
                    trailing: Text('GGUF (Quantized)', style: t.caption)),
                AppRow(
                    title: 'Filename',
                    trailing:
                        Text(model.filename, style: t.small, maxLines: 1)),
              ],
            ),
            const SizedBox(height: 20),
            if (isDownloaded) ...[
              if (isLoaded)
                PrimaryButton(
                  label: 'Loaded into RAM (Active)',
                  onTap: () => Navigator.pop(ctx),
                )
              else
                PrimaryButton(
                  label: 'Load Model into Memory',
                  onTap: () async {
                    Navigator.pop(ctx);
                    Haptics.lightImpact();
                    final path = await ref
                        .read(modelDownloadProvider.notifier)
                        .getModelPath(model.filename);
                    ref.read(localInferenceProvider.notifier).loadModel(
                          modelPath: path,
                          modelName: model.filename,
                        );
                    if (mounted) {
                      showToast(context, 'Loading',
                          'Loading ${model.name} into RAM...');
                    }
                  },
                ),
            ] else ...[
              PrimaryButton(
                label: 'Download (${model.sizeMb.toStringAsFixed(0)} MB)',
                onTap: () {
                  Navigator.pop(ctx);
                  Haptics.lightImpact();
                  ref.read(modelDownloadProvider.notifier).downloadModel(model);
                  if (mounted) {
                    showToast(
                        context, 'Downloading', 'Downloading ${model.name}...');
                  }
                },
              ),
            ],
          ],
        );
      },
    );
  }

  void _showCloudProviderConfig(String providerName) {
    final box = Hive.box(AppConstants.settingsBox);
    CloudProvider? prov;
    String keySettingName = '';
    String defaultModel = '';

    switch (providerName.toLowerCase()) {
      case 'openrouter':
        prov = CloudProvider.openRouter;
        keySettingName = AppConstants.keyOpenRouterKey;
        defaultModel = 'deepseek/deepseek-r1';
        break;
      case 'openai':
        prov = CloudProvider.openAi;
        keySettingName = AppConstants.keyOpenAiKey;
        defaultModel = 'gpt-4o-mini';
        break;
      case 'deepseek':
        prov = CloudProvider.deepSeek;
        keySettingName = AppConstants.keyDeepSeekKey;
        defaultModel = 'deepseek-chat';
        break;
      case 'google gemini':
        prov = CloudProvider.gemini;
        keySettingName = AppConstants.keyGeminiKey;
        defaultModel = 'gemini-2.5-flash';
        break;
      case 'nvidia nim':
        prov = CloudProvider.openRouter;
        keySettingName = 'nvidia_nim_api_key';
        defaultModel = 'meta/llama-3.1-8b-instruct';
        break;
      case 'custom api':
      default:
        prov = CloudProvider.openAi;
        keySettingName = AppConstants.keyCustomApiKey;
        defaultModel = 'default';
        break;
    }

    final currentKey = box.get(keySettingName, defaultValue: '') as String;
    final currentModel =
        box.get('${prov.name}_model', defaultValue: defaultModel) as String;

    final keyCtrl = TextEditingController(text: currentKey);
    final modelCtrl = TextEditingController(text: currentModel);

    showAppSheet(
      context,
      title: '$providerName Configuration',
      builder: (ctx) {
        final t = AppTokens.of(ctx);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Enter your API key and default model for $providerName. Keys remain private on your device.',
              style: t.caption,
            ),
            const SizedBox(height: 16),
            Text('API Key', style: t.bodyStrong),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: t.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: t.hairline),
              ),
              child: TextField(
                controller: keyCtrl,
                obscureText: true,
                style: t.mono,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Paste API Key here',
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Model ID', style: t.bodyStrong),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: t.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: t.hairline),
              ),
              child: TextField(
                controller: modelCtrl,
                style: t.mono,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: defaultModel,
                ),
              ),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Save & Set as Active Cloud Provider',
              onTap: () {
                final key = keyCtrl.text.trim();
                final model = modelCtrl.text.trim().isNotEmpty
                    ? modelCtrl.text.trim()
                    : defaultModel;
                box.put(keySettingName, key);
                ref.read(chatProvider.notifier).setProvider(prov!, model);
                Navigator.pop(ctx);
                Haptics.selectionClick();
                showToast(
                    context, 'Saved', '$providerName configured successfully',
                    tone: ToastTone.success);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final downloadState = ref.watch(modelDownloadProvider);

    return Scaffold(
      backgroundColor: t.bg,
      appBar: AppBar(
        backgroundColor: t.bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 20,
        title: Text(
          'Models',
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.6,
            color: t.text,
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: _importLocalFile,
            icon: Icon(Icons.add_rounded, size: 18, color: t.accent),
            label: Text(
              'Import',
              style: GoogleFonts.inter(
                  fontSize: 14, fontWeight: FontWeight.w600, color: t.accent),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          4,
          16,
          MediaQuery.of(context).padding.bottom + 100,
        ),
        children: [
          // ── Scope Segmented Control (My models | Browse | Cloud) ──
          AppSegmented<String>(
            items: const [
              ('local', 'My models'),
              ('browse', 'Browse'),
              ('online', 'Cloud'),
            ],
            selected: _selectedScope,
            onChanged: (val) {
              setState(() => _selectedScope = val);
            },
          ),
          const SizedBox(height: 16),

          // ── Active Download Progress Card (Screenshots 1 & 3) ──
          if (downloadState.activeDownloadingFilename != null)
            _buildActiveDownloadCard(t, downloadState),

          if (_selectedScope == 'browse')
            ..._buildBrowseContent(t)
          else if (_selectedScope == 'local')
            ..._buildMyModelsContent(t)
          else
            ..._buildCloudContent(t),
        ],
      ),
    );
  }

  // ── SUBTAB: BROWSE (Screenshot 1) ──
  List<Widget> _buildBrowseContent(AppTokens t) {
    final downloadState = ref.watch(modelDownloadProvider);
    final displayedPresets = _filteredPresets;

    return [
      // Recommended Section
      Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
        child: Text('Recommended', style: t.label),
      ),
      SizedBox(
        height: 172,
        child: ListView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          children: [
            _buildFeaturedCard(
              t,
              name: 'LFM2.5 1.2B',
              badge: 'LF',
              badgeColor: const Color(0xFF14B8A6),
              subtitle: 'Best for chat',
              sizeStr: '731 MB',
              model: LocalModelPresets.byId('lfm2.5-1.2b'),
            ),
            const SizedBox(width: 10),
            _buildFeaturedCard(
              t,
              name: 'Gemma 3 4B',
              badge: 'Ge',
              badgeColor: const Color(0xFF4285F4),
              subtitle: 'Understands photos',
              sizeStr: '2.49 GB',
              model: LocalModelPresets.byId('gemma-3-4b-vision'),
            ),
            const SizedBox(width: 10),
            _buildFeaturedCard(
              t,
              name: 'Qwen 2.5 Coder',
              badge: 'Qw',
              badgeColor: const Color(0xFF6366F1),
              subtitle: 'Offline coding',
              sizeStr: '986 MB',
              model: LocalModelPresets.byId('qwen2.5-coder-1.5b'),
            ),
          ],
        ),
      ),
      const SizedBox(height: 18),

      // Filter Chips: Chat | Coding | Reasoning | Vision | Uncensored | Image
      AppChips<String>(
        items: const [
          ('chat', 'Chat'),
          ('coding', 'Coding'),
          ('reasoning', 'Reasoning'),
          ('vision', 'Vision'),
          ('uncensored', 'Uncensored'),
          ('image', 'Image'),
        ],
        selected: _selectedCategory,
        onSelected: (cat) => setState(() => _selectedCategory = cat),
      ),
      const SizedBox(height: 16),

      // Count & Sort row: "All X" and "⇅ By size"
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Row(
          children: [
            Text('All ${displayedPresets.length}', style: t.label),
            const Spacer(),
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                setState(() {
                  if (_sortBySizeAsc == null) {
                    _sortBySizeAsc = true;
                  } else if (_sortBySizeAsc == true) {
                    _sortBySizeAsc = false;
                  } else {
                    _sortBySizeAsc = null;
                  }
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Row(
                  children: [
                    Icon(
                      _sortBySizeAsc == null
                          ? Icons.swap_vert_rounded
                          : (_sortBySizeAsc!
                              ? Icons.arrow_upward_rounded
                              : Icons.arrow_downward_rounded),
                      size: 16,
                      color: _sortBySizeAsc != null ? t.accent : t.muted,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      _sortBySizeAsc == null
                          ? 'By size'
                          : (_sortBySizeAsc! ? 'Size: Asc' : 'Size: Desc'),
                      style: t.small.copyWith(
                        color: _sortBySizeAsc != null ? t.accent : t.muted,
                        fontWeight: _sortBySizeAsc != null
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // Grouped list of downloadable models
      AppGroup(
        dividerIndent: 62,
        children: [
          for (final model in displayedPresets)
            _buildModelDownloadRow(t, model, downloadState),
        ],
      ),
    ];
  }

  // ── ACTIVE DOWNLOAD PROGRESS CARD (Screenshots 1 & 3) ──
  Widget _buildActiveDownloadCard(
      AppTokens t, ModelDownloadState downloadState) {
    final filename = downloadState.activeDownloadingFilename;
    if (filename == null) return const SizedBox.shrink();

    final preset = LocalModelPresets.all.firstWhere(
      (p) => p.filename == filename,
      orElse: () => LocalModelPreset(
        id: filename,
        name: filename,
        author: '',
        filename: filename,
        downloadUrl: '',
        sizeMb: downloadState.totalMb.toDouble(),
        ramRequirement: '',
        description: '',
      ),
    );

    final prog = downloadState.progress[filename] ?? 0.0;
    final percent = (prog * 100).toInt();
    final speed = downloadState.downloadSpeed.isNotEmpty
        ? downloadState.downloadSpeed
        : '0 MB/s';
    final eta = downloadState.eta.isNotEmpty ? downloadState.eta : '';
    final infoParts = <String>['$percent%'];
    if (speed.isNotEmpty) infoParts.add(speed);
    if (eta.isNotEmpty) infoParts.add('$eta left');
    final infoText = infoParts.join(' · ');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.hairline, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: t.fill,
            ),
            child: Icon(Icons.arrow_downward_rounded, size: 20, color: t.text),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  preset.name,
                  style: t.bodyStrong,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: prog > 0 ? prog : null,
                    backgroundColor: t.fill,
                    valueColor: AlwaysStoppedAnimation<Color>(t.accent),
                    minHeight: 3.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  infoText,
                  style: t.caption.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.close_rounded, size: 20, color: t.muted),
            onPressed: () {
              Haptics.selectionClick();
              ref.read(modelDownloadProvider.notifier).cancelDownload();
            },
            tooltip: 'Cancel download',
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadProgressWidget(AppTokens t, double prog, String filename,
      {double size = 32}) {
    final percent = (prog * 100).toInt();
    return GestureDetector(
      onTap: () {
        Haptics.selectionClick();
        ref.read(modelDownloadProvider.notifier).cancelDownload();
      },
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircularProgressIndicator(
              value: prog > 0 ? prog : null,
              strokeWidth: 2.4,
              color: t.accent,
              backgroundColor: t.fill,
            ),
            Text(
              '$percent%',
              style: GoogleFonts.inter(
                fontSize: size * 0.30,
                fontWeight: FontWeight.w700,
                color: t.text,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedCard(
    AppTokens t, {
    required String name,
    required String badge,
    required Color badgeColor,
    required String subtitle,
    required String sizeStr,
    required LocalModelPreset model,
  }) {
    final downloadState = ref.watch(modelDownloadProvider);
    final isDownloaded = downloadState.downloadedFiles.contains(model.filename);
    final isDownloading =
        downloadState.activeDownloadingFilename == model.filename;
    final prog = downloadState.progress[model.filename] ?? 0.0;

    return SizedBox(
      width: 168,
      child: Material(
        color: t.surface,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          splashFactory: NoSplash.splashFactory,
          onTap: () => _showModelDetails(model),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAvatar(badge, badgeColor, size: 44),
                const Spacer(),
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: t.bodyStrong.copyWith(height: 1.25),
                ),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: t.small,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(sizeStr, style: t.small),
                    ),
                    if (isDownloaded)
                      Icon(Icons.check_circle_rounded, size: 22, color: t.green)
                    else if (isDownloading)
                      _buildDownloadProgressWidget(t, prog, model.filename,
                          size: 30)
                    else
                      GestureDetector(
                        onTap: () {
                          Haptics.lightImpact();
                          ref
                              .read(modelDownloadProvider.notifier)
                              .downloadModel(model);
                        },
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle, color: t.fill),
                          child: Icon(Icons.arrow_downward_rounded,
                              size: 16, color: t.text),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModelDownloadRow(
      AppTokens t, LocalModelPreset model, ModelDownloadState downloadState) {
    final isDownloaded = downloadState.downloadedFiles.contains(model.filename);
    final isDownloading =
        downloadState.activeDownloadingFilename == model.filename;
    final prog = downloadState.progress[model.filename] ?? 0.0;
    final (badge, color) = _getBadgeInfo(model.name);
    final sizeMb = model.sizeMb.toStringAsFixed(0);

    return InkWell(
      onTap: () => _showModelDetails(model),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              _buildAvatar(badge, color, size: 36),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(model.name, style: t.bodyStrong),
                    const SizedBox(height: 2),
                    Text(
                      model.name.contains('360M')
                          ? '★ Recommended · $sizeMb MB · ${model.ramRequirement}'
                          : '$sizeMb MB · ${model.ramRequirement}',
                      style: t.caption,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (isDownloaded)
                Icon(Icons.check_circle_rounded, size: 22, color: t.green)
              else if (isDownloading)
                _buildDownloadProgressWidget(t, prog, model.filename, size: 34)
              else
                GestureDetector(
                  onTap: () {
                    Haptics.lightImpact();
                    ref
                        .read(modelDownloadProvider.notifier)
                        .downloadModel(model);
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration:
                        BoxDecoration(shape: BoxShape.circle, color: t.fill),
                    child: Icon(Icons.arrow_downward_rounded,
                        size: 17, color: t.text.withValues(alpha: 0.8)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ── SUBTAB: MY MODELS (Screenshot 2) ──
  List<Widget> _buildMyModelsContent(AppTokens t) {
    final downloadState = ref.watch(modelDownloadProvider);
    final inferenceState = ref.watch(localInferenceProvider);
    final downloaded = downloadState.downloadedFiles;

    if (downloaded.isEmpty) {
      return [
        const SizedBox(height: 48),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration:
                    BoxDecoration(shape: BoxShape.circle, color: t.fill),
                child: Icon(Icons.arrow_downward_rounded,
                    size: 28, color: t.muted),
              ),
              const SizedBox(height: 16),
              Text(
                'No models on this phone yet',
                style: t.bodyStrong.copyWith(fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                'Download one from Browse, or import a model file.',
                style: t.caption,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  PillButton(
                    label: 'Browse models',
                    primary: true,
                    onTap: () => setState(() => _selectedScope = 'browse'),
                  ),
                  const SizedBox(width: 10),
                  PillButton(
                    label: 'Import file',
                    icon: Icons.file_upload_outlined,
                    onTap: _importLocalFile,
                  ),
                ],
              ),
            ],
          ),
        ),
      ];
    }

    return [
      if (inferenceState.isModelLoaded) ...[
        AppCard(
          child: Row(
            children: [
              IconBadge(Icons.memory_rounded, size: 36, color: t.green),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(inferenceState.loadedModelName ?? 'Model',
                        style: t.bodyStrong),
                    const SizedBox(height: 2),
                    Text('Loaded · CPU · GGUF', style: t.caption),
                  ],
                ),
              ),
              PillButton(
                label: 'Unload',
                destructive: true,
                onTap: () =>
                    ref.read(localInferenceProvider.notifier).unloadModel(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
      SectionHeader('Downloaded models (${downloaded.length})'),
      AppGroup(
        dividerIndent: 62,
        children: [
          for (final fileName in downloaded)
            Builder(builder: (ctx) {
              final isLoaded = inferenceState.isModelLoaded &&
                  inferenceState.loadedModelName == fileName;
              final (badge, color) = _getBadgeInfo(fileName);

              return ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 56),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                  child: Row(
                    children: [
                      _buildAvatar(badge, color, size: 36),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(fileName,
                                style: t.bodyStrong,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 2),
                            Text(isLoaded ? '● Loaded into RAM' : 'Local file',
                                style: t.caption),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (isLoaded)
                        AppTag('Active', color: t.green)
                      else
                        PillButton(
                          label: 'Load',
                          primary: true,
                          onTap: () async {
                            Haptics.lightImpact();
                            final modelPath = await ref
                                .read(modelDownloadProvider.notifier)
                                .getModelPath(fileName);
                            final box = Hive.box(AppConstants.settingsBox);
                            final contextSize = (box.get('context_size',
                                    defaultValue: 1024) as num)
                                .toInt();
                            ref.read(localInferenceProvider.notifier).loadModel(
                                  modelPath: modelPath,
                                  modelName: fileName,
                                  contextSize: contextSize,
                                );
                            if (mounted) {
                              showToast(
                                  context, 'Loading', 'Loading $fileName...');
                            }
                          },
                        ),
                      const SizedBox(width: 6),
                      IconButton(
                        icon: Icon(Icons.delete_outline_rounded,
                            size: 20, color: t.faint),
                        tooltip: 'Delete model',
                        onPressed: () async {
                          final ok = await confirmSheet(
                            context,
                            title: 'Delete $fileName?',
                            message:
                                'This will remove the downloaded .gguf file from device storage to free up space.',
                            confirmLabel: 'Delete File',
                            destructive: true,
                          );
                          if (ok && mounted) {
                            Haptics.selectionClick();
                            if (isLoaded) {
                              await ref
                                  .read(localInferenceProvider.notifier)
                                  .unloadModel();
                            }
                            await ref
                                .read(modelDownloadProvider.notifier)
                                .deleteModel(fileName);
                            if (mounted) {
                              showToast(
                                  context, 'Deleted', '$fileName removed');
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    ];
  }

  // ── SUBTAB: CLOUD (Screenshot 3) ──
  List<Widget> _buildCloudContent(AppTokens t) {
    final chatState = ref.watch(chatProvider);

    return [
      // Top active cloud card
      AppCard(
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(shape: BoxShape.circle, color: t.fill),
              child: Icon(Icons.cloud_outlined, size: 22, color: t.text),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chatState.selectedModel.isNotEmpty
                        ? chatState.selectedModel
                        : 'No online model selected',
                    style: t.bodyStrong,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                              color: t.accent, shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Text(
                          'Cloud · ${chatState.selectedProvider.name.toUpperCase()}',
                          style: t.caption),
                    ],
                  ),
                ],
              ),
            ),
            PillButton(
              label: 'Change',
              onTap: () =>
                  _showCloudProviderConfig(chatState.selectedProvider.name),
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),

      const SectionHeader('Providers'),
      AppGroup(
        dividerIndent: 60,
        children: [
          _buildProviderRow(t, 'OpenRouter', Icons.hub_outlined),
          _buildProviderRow(t, 'OpenAI', Icons.auto_awesome_rounded),
          _buildProviderRow(t, 'DeepSeek', Icons.psychology_outlined),
          _buildProviderRow(t, 'Google Gemini', Icons.diamond_outlined),
          _buildProviderRow(t, 'NVIDIA NIM', Icons.memory_rounded),
          _buildProviderRow(t, 'Custom API', Icons.tune_rounded),
        ],
      ),
      const SectionFootnote(
          'Tap a provider to choose a model. Keys are stored on this device.'),
    ];
  }

  Widget _buildProviderRow(AppTokens t, String name, IconData icon) {
    final box = Hive.box(AppConstants.settingsBox);
    String keySettingName = '';
    switch (name.toLowerCase()) {
      case 'openrouter':
        keySettingName = AppConstants.keyOpenRouterKey;
        break;
      case 'openai':
        keySettingName = AppConstants.keyOpenAiKey;
        break;
      case 'deepseek':
        keySettingName = AppConstants.keyDeepSeekKey;
        break;
      case 'google gemini':
        keySettingName = AppConstants.keyGeminiKey;
        break;
      case 'nvidia nim':
        keySettingName = 'nvidia_nim_api_key';
        break;
      case 'custom api':
      default:
        keySettingName = AppConstants.keyCustomApiKey;
        break;
    }

    final hasKey =
        (box.get(keySettingName, defaultValue: '') as String).isNotEmpty;

    return AppRow(
      icon: icon,
      title: name,
      subtitle: hasKey ? '● Configured' : '● Needs API key',
      trailing: Text('...', style: t.title.copyWith(color: t.faint)),
      onTap: () => _showCloudProviderConfig(name),
    );
  }

  Widget _buildAvatar(String text, Color color, {double size = 38}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(size * 0.35),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: size * 0.38,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  (String, Color) _getBadgeInfo(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('gemma')) return ('Ge', const Color(0xFF4285F4));
    if (lower.contains('qwen')) return ('Qw', const Color(0xFF7C5CFF));
    if (lower.contains('lfm')) return ('LF', const Color(0xFF14B8A6));
    if (lower.contains('llama')) return ('Ll', const Color(0xFFF97316));
    if (lower.contains('smol')) return ('Sm', const Color(0xFF22C55E));
    if (lower.contains('deepseek')) return ('DS', const Color(0xFF0EA5E9));
    return (
      name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase(),
      const Color(0xFF8B5CF6)
    );
  }
}
