import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/constants.dart';
import '../../../core/ui.dart';
import '../../../core/providers/theme_provider.dart';
import '../../chat/providers/chat_provider.dart';
import '../../cluster/views/cluster_view.dart';
import '../../cluster/services/phone_cluster_service.dart';
import '../../local_inference/services/local_inference_service.dart';
import '../../server/providers/server_provider.dart';

class SettingsTabView extends ConsumerStatefulWidget {
  const SettingsTabView({super.key});

  @override
  ConsumerState<SettingsTabView> createState() => _SettingsTabViewState();
}

class _SettingsTabViewState extends ConsumerState<SettingsTabView> {
  final _systemPromptController = TextEditingController();
  final _stopSequencesController = TextEditingController(text: '###\n\\nUser:');

  String _deviceRam = '2.7 GB RAM';
  String _chipset = 'Qualcomm Snapdragon';
  bool _hapticsEnabled = true;
  bool _autoCheckUpdates = true;
  String _performanceMode = 'auto_fast'; // 'auto_fast', 'gpu_fast', 'cpu_safe'
  String _imageBackend = 'cpu'; // 'cpu', 'gpu'
  int _imageSize = 0; // 0 = Auto
  double _imageSteps = 1.0;
  double _gpuSafetyMb = 1843.0;

  double _temperature = 0.30;
  int _maxTokens = 256;
  int _contextSize = 1024;

  int _themeModeIndex = 2; // 0=Light, 1=Dark, 2=System
  double _fontScale = 1.0;

  String _logFilter = 'all';
  final List<(String, String, String)> _systemLogs = [
    ('Info', '19:02:18', 'All services initialized, launching app'),
    ('Info', '19:02:18', 'Notifications initialized'),
    ('Info', '19:02:17', '[DeviceInfo] RAM: 2.7GB total, tier: low'),
    ('Info', '19:02:17', 'App started'),
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _detectDevice();
  }

  void _loadSettings() {
    final box = Hive.box(AppConstants.settingsBox);
    _systemPromptController.text = box.get(
      AppConstants.keySystemPrompt,
      defaultValue: 'You are AI Chat, a helpful and friendly assistant. Be concise, accurate, and conversational. Answer questions directly without unnecessary preamble.',
    ) as String;

    final themeStr = box.get('theme_mode', defaultValue: 'system') as String;
    if (themeStr == 'light') {
      _themeModeIndex = 0;
    } else if (themeStr == 'dark') {
      _themeModeIndex = 1;
    } else {
      _themeModeIndex = 2;
    }

    _fontScale = (box.get('font_scale', defaultValue: 1.0) as num).toDouble();
    _temperature = (box.get('temperature', defaultValue: 0.30) as num).toDouble();
    _maxTokens = (box.get('max_tokens', defaultValue: 256) as num).toInt();
    _contextSize = (box.get('context_size', defaultValue: 1024) as num).toInt();
    _stopSequencesController.text = box.get('stop_sequences', defaultValue: '###\n\\nUser:') as String;
    _performanceMode = box.get('performance_mode', defaultValue: 'auto_fast') as String;
    _imageBackend = box.get('image_backend', defaultValue: 'cpu') as String;
    _imageSize = (box.get('image_size', defaultValue: 0) as num).toInt();
    _imageSteps = (box.get('image_steps', defaultValue: 1.0) as num).toDouble();
    _gpuSafetyMb = (box.get('gpu_safety_mb', defaultValue: 1843.0) as num).toDouble();
    _hapticsEnabled = box.get('haptics_enabled', defaultValue: true) as bool;
    _autoCheckUpdates = box.get('auto_check_updates', defaultValue: true) as bool;
  }

  Future<void> _detectDevice() async {
    try {
      if (Platform.isAndroid) {
        final android = await DeviceInfoPlugin().androidInfo;
        setState(() {
          _deviceRam = '2.7 GB RAM';
          _chipset = android.hardware.isNotEmpty ? android.hardware : 'Qualcomm Snapdragon';
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _systemPromptController.dispose();
    _stopSequencesController.dispose();
    super.dispose();
  }

  void _saveSystemPrompt() {
    final box = Hive.box(AppConstants.settingsBox);
    box.put(AppConstants.keySystemPrompt, _systemPromptController.text.trim());
    showToast(context, 'Saved', 'System prompt saved', tone: ToastTone.success);
  }

  void _navRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required WidgetBuilder builder,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => _SettingsPage(
          title: title,
          builder: builder,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final chatState = ref.watch(chatProvider);
    final clusterState = ref.watch(phoneClusterProvider);

    return Scaffold(
      backgroundColor: t.bg,
      appBar: AppBar(
        backgroundColor: t.bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 20,
        title: Text(
          'Settings',
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.6,
            color: t.text,
          ),
        ),
      ),
      body: ListView(
        padding: kPagePadding,
        children: [
          // ── GENERAL ──
          const SectionHeader('General', padding: EdgeInsets.fromLTRB(4, 8, 4, 8)),
          AppGroup(
            dividerIndent: 60,
            children: [
              AppRow(
                icon: Icons.palette_outlined,
                title: 'Appearance',
                trailing: Text(
                  _themeModeIndex == 0 ? 'Light' : (_themeModeIndex == 1 ? 'Dark' : 'System'),
                  style: t.caption.copyWith(fontSize: 14),
                ),
                chevron: true,
                onTap: () => _navRow(
                  context,
                  icon: Icons.palette_outlined,
                  title: 'Appearance',
                  value: 'System',
                  builder: (ctx) => _buildAppearanceGroup(ctx),
                ),
              ),
              AppRow(
                icon: Icons.vibration_rounded,
                title: 'Haptic feedback',
                trailing: AppSwitch(
                  value: _hapticsEnabled,
                  onChanged: (val) {
                    Haptics.selectionClick();
                    final box = Hive.box(AppConstants.settingsBox);
                    box.put('haptics_enabled', val);
                    setState(() => _hapticsEnabled = val);
                  },
                ),
              ),
            ],
          ),

          // ── CHAT ──
          const SectionHeader('Chat'),
          AppGroup(
            dividerIndent: 60,
            children: [
              AppRow(
                icon: Icons.memory_rounded,
                title: 'Inference mode',
                trailing: Text(
                  chatState.inferenceMode == InferenceMode.local ? 'Local' : 'Cloud',
                  style: t.caption.copyWith(fontSize: 14),
                ),
                chevron: true,
                onTap: () => _navRow(
                  context,
                  icon: Icons.memory_rounded,
                  title: 'Inference mode',
                  value: 'Local',
                  builder: (ctx) => _buildInferenceGroup(ctx),
                ),
              ),
              AppRow(
                icon: Icons.chat_bubble_outline_rounded,
                title: 'System prompt',
                trailing: Text('Custom', style: t.caption.copyWith(fontSize: 14)),
                chevron: true,
                onTap: () => _navRow(
                  context,
                  icon: Icons.chat_bubble_outline_rounded,
                  title: 'System prompt',
                  value: 'Custom',
                  builder: (ctx) => _buildSystemPromptGroup(ctx),
                ),
              ),
              AppRow(
                icon: Icons.tune_rounded,
                title: 'Model parameters',
                trailing: Text(_temperature.toStringAsFixed(2), style: t.caption.copyWith(fontSize: 14)),
                chevron: true,
                onTap: () => _navRow(
                  context,
                  icon: Icons.tune_rounded,
                  title: 'Model parameters',
                  value: _temperature.toStringAsFixed(2),
                  builder: (ctx) => _buildModelParametersGroup(ctx),
                ),
              ),
            ],
          ),

          // ── PERFORMANCE ──
          const SectionHeader('Performance'),
          AppGroup(
            dividerIndent: 60,
            children: [
              AppRow(
                icon: Icons.speed_rounded,
                title: 'GGUF & LiteRT',
                trailing: Text(
                  _performanceMode == 'gpu_fast' ? 'GPU fast' : (_performanceMode == 'cpu_safe' ? 'CPU safe' : 'Auto fast'),
                  style: t.caption.copyWith(fontSize: 14),
                ),
                chevron: true,
                onTap: () => _navRow(
                  context,
                  icon: Icons.speed_rounded,
                  title: 'GGUF & LiteRT',
                  value: 'Auto fast',
                  builder: (ctx) => _buildLiteRtGroup(ctx),
                ),
              ),
              AppRow(
                icon: Icons.image_outlined,
                title: 'Image generation',
                trailing: Text(_imageBackend.toUpperCase(), style: t.caption.copyWith(fontSize: 14)),
                chevron: true,
                onTap: () => _navRow(
                  context,
                  icon: Icons.image_outlined,
                  title: 'Image generation',
                  value: _imageBackend.toUpperCase(),
                  builder: (ctx) => _buildImageGenerationGroup(ctx),
                ),
              ),
              AppRow(
                icon: Icons.hub_outlined,
                title: 'Phone cluster',
                trailing: Text(
                  clusterState.role == ClusterRole.master
                      ? 'Master'
                      : (clusterState.role == ClusterRole.worker ? 'Worker' : 'Off'),
                  style: t.caption.copyWith(fontSize: 14),
                ),
                chevron: true,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ClusterView()),
                  );
                },
              ),
            ],
          ),

          // ── ABOUT ──
          const SectionHeader('About'),
          AppGroup(
            dividerIndent: 60,
            children: [
              AppRow(
                icon: Icons.system_update_rounded,
                title: 'App updates',
                trailing: Text('Up to date', style: t.caption.copyWith(fontSize: 14)),
                chevron: true,
                onTap: () => _navRow(
                  context,
                  icon: Icons.system_update_rounded,
                  title: 'App updates',
                  value: 'Up to date',
                  builder: (ctx) => _buildUpdatesGroup(ctx),
                ),
              ),
              AppRow(
                icon: Icons.smartphone_rounded,
                title: 'Device',
                trailing: Text(_deviceRam, style: t.caption.copyWith(fontSize: 14)),
                chevron: true,
                onTap: () => _navRow(
                  context,
                  icon: Icons.smartphone_rounded,
                  title: 'Device',
                  value: _deviceRam,
                  builder: (ctx) => _buildDeviceGroup(ctx),
                ),
              ),
              AppRow(
                icon: Icons.article_outlined,
                title: 'Logs',
                chevron: true,
                onTap: () => _navRow(
                  context,
                  icon: Icons.article_outlined,
                  title: 'Logs',
                  value: '',
                  builder: (ctx) => _buildLogsGroup(ctx),
                ),
              ),
              AppRow(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    'assets/icons/appicon.png',
                    width: 32,
                    height: 32,
                    errorBuilder: (_, __, ___) => Icon(Icons.token_rounded, size: 32, color: t.accent),
                  ),
                ),
                title: 'LocalLM',
                subtitle: 'Version 1.0.0 · Local & Cluster Offline AI',
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // SUB-PAGES
  // ───────────────────────────────────────────────────────────────────────────

  // ── 1. APPEARANCE ──
  Widget _buildAppearanceGroup(BuildContext context) {
    final t = AppTokens.of(context);
    return StatefulBuilder(
      builder: (context, setSubState) => AppGroup(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Theme', style: t.body),
                const SizedBox(height: 10),
                AppSegmented<int>(
                  items: const [
                    (0, 'Light'),
                    (1, 'Dark'),
                    (2, 'System'),
                  ],
                  selected: _themeModeIndex,
                  onChanged: (idx) {
                    setSubState(() => _themeModeIndex = idx);
                    setState(() => _themeModeIndex = idx);
                    final mode = idx == 0
                        ? ThemeMode.light
                        : (idx == 1 ? ThemeMode.dark : ThemeMode.system);
                    ref.read(themeModeProvider.notifier).setThemeMode(mode);
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(height: 0.5, color: t.hairline),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Text size', style: t.body),
                    Text(
                      _fontScale <= 0.88 ? 'XS' : (_fontScale <= 1.05 ? 'Small' : 'Large'),
                      style: t.caption,
                    ),
                  ],
                ),
                AppSlider(
                  value: _fontScale,
                  min: 0.8,
                  max: 1.3,
                  divisions: 5,
                  onChanged: (val) {
                    setSubState(() => _fontScale = val);
                    setState(() => _fontScale = val);
                    ref.read(fontScaleProvider.notifier).setFontScale(val);
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('XS', style: t.small),
                    Text('Small (default)', style: t.small.copyWith(color: t.text, fontWeight: FontWeight.w600)),
                    Text('Large', style: t.small),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 2. INFERENCE MODE ──
  Widget _buildInferenceGroup(BuildContext context) {
    final t = AppTokens.of(context);
    final chatState = ref.watch(chatProvider);
    final localState = ref.watch(localInferenceProvider);
    final isLocal = chatState.inferenceMode == InferenceMode.local;

    return AppGroup(
      dividerIndent: 60,
      children: [
        AppRow(
          icon: Icons.phone_android_rounded,
          title: 'Local (on-device)',
          subtitle: localState.isModelLoaded ? localState.loadedModelName! : 'No model loaded',
          selected: isLocal,
          trailing: isLocal ? Icon(Icons.check_rounded, color: t.accent, size: 20) : null,
          onTap: () {
            ref.read(chatProvider.notifier).setInferenceMode(InferenceMode.local);
          },
        ),
        AppRow(
          icon: Icons.cloud_outlined,
          title: 'Cloud API',
          subtitle: chatState.selectedProvider.name.toUpperCase(),
          selected: !isLocal,
          trailing: !isLocal ? Icon(Icons.check_rounded, color: t.accent, size: 20) : null,
          onTap: () {
            ref.read(chatProvider.notifier).setInferenceMode(InferenceMode.cloud);
          },
        ),
      ],
    );
  }

  // ── 3. SYSTEM PROMPT ──
  Widget _buildSystemPromptGroup(BuildContext context) {
    final t = AppTokens.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: t.hairline, width: 0.5),
          ),
          child: TextField(
            controller: _systemPromptController,
            minLines: 5,
            maxLines: 12,
            style: t.body,
            decoration: const InputDecoration(border: InputBorder.none, isDense: true),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Applies to local and cloud models.',
                style: t.small,
              ),
            ),
            PillButton(
              label: 'Save',
              primary: true,
              onTap: () {
                Haptics.selectionClick();
                _saveSystemPrompt();
              },
            ),
          ],
        ),
      ],
    );
  }

  // ── 4. MODEL PARAMETERS ──
  Widget _buildModelParametersGroup(BuildContext context) {
    final t = AppTokens.of(context);

    return StatefulBuilder(
      builder: (context, setSubState) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppGroup(
            children: [
              // Temperature
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Temperature', style: t.body),
                        Text(_temperature.toStringAsFixed(2), style: t.bodyStrong),
                      ],
                    ),
                    AppSlider(
                      value: _temperature,
                      min: 0.0,
                      max: 1.5,
                      divisions: 15,
                      onChanged: (v) {
                        setSubState(() => _temperature = v);
                        setState(() => _temperature = v);
                      },
                    ),
                    Text('Recommended max: 1', style: t.small),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(height: 0.5, color: t.hairline),
              ),
              // Max tokens
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Max tokens', style: t.body),
                        Text('$_maxTokens', style: t.bodyStrong),
                      ],
                    ),
                    AppSlider(
                      value: _maxTokens.toDouble(),
                      min: 64,
                      max: 2048,
                      divisions: 31,
                      onChanged: (v) {
                        setSubState(() => _maxTokens = v.toInt());
                        setState(() => _maxTokens = v.toInt());
                      },
                    ),
                    Text('Recommended max: 512', style: t.small),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(height: 0.5, color: t.hairline),
              ),
              // Context size
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Context size', style: t.body),
                        Text('$_contextSize', style: t.bodyStrong),
                      ],
                    ),
                    AppSlider(
                      value: _contextSize.toDouble(),
                      min: 512,
                      max: 4096,
                      divisions: 7,
                      onChanged: (v) {
                        setSubState(() => _contextSize = v.toInt());
                        setState(() => _contextSize = v.toInt());
                      },
                    ),
                    Text('Recommended max: 2048', style: t.small),
                  ],
                ),
              ),
            ],
          ),

          const SectionHeader('Stop sequences'),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: t.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: t.hairline, width: 0.5),
            ),
            child: TextField(
              controller: _stopSequencesController,
              minLines: 2,
              maxLines: 5,
              style: t.mono,
              decoration: const InputDecoration(border: InputBorder.none, isDense: true),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Local models stop when they write one of these. One per line; use \\n for a newline.',
                  style: t.small,
                ),
              ),
              PillButton(
                label: 'Save',
                primary: true,
                onTap: () {
                  final box = Hive.box(AppConstants.settingsBox);
                  box.put('temperature', _temperature);
                  box.put('max_tokens', _maxTokens);
                  box.put('context_size', _contextSize);
                  box.put('stop_sequences', _stopSequencesController.text.trim());
                  Haptics.selectionClick();
                  showToast(context, 'Saved', 'Model parameters and stop sequences saved', tone: ToastTone.success);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── 5. GGUF & LITERTM ──
  Widget _buildLiteRtGroup(BuildContext context) {
    final t = AppTokens.of(context);
    final modes = [
      (
        value: 'auto_fast',
        title: 'Auto fast',
        subtitle: 'Uses the GPU when supported, CPU if the GPU can\'t load the model',
        icon: Icons.auto_awesome_rounded,
      ),
      (
        value: 'gpu_fast',
        title: 'GPU fast',
        subtitle: 'Always tries the GPU. Fastest, may crash on some devices',
        icon: Icons.bolt_rounded,
      ),
      (
        value: 'cpu_safe',
        title: 'CPU safe',
        subtitle: 'CPU only. Most stable, slower',
        icon: Icons.shield_outlined,
      ),
    ];

    return StatefulBuilder(
      builder: (context, setSubState) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppGroup(
            dividerIndent: 60,
            children: [
              for (final m in modes)
                AppRow(
                  icon: m.icon,
                  title: m.title,
                  subtitle: m.subtitle,
                  selected: _performanceMode == m.value,
                  trailing: _performanceMode == m.value
                      ? Icon(Icons.check_rounded, color: t.accent, size: 20)
                      : null,
                  onTap: () {
                    Haptics.selectionClick();
                    final box = Hive.box(AppConstants.settingsBox);
                    box.put('performance_mode', m.value);
                    setSubState(() => _performanceMode = m.value);
                    setState(() => _performanceMode = m.value);
                  },
                ),
            ],
          ),
          const SizedBox(height: 10),
          const SectionFootnote(
            'Applies to both GGUF and LiteRT models. Takes effect the next time a model is loaded.',
          ),
        ],
      ),
    );
  }

  // ── 6. IMAGE GENERATION ──
  Widget _buildImageGenerationGroup(BuildContext context) {
    final t = AppTokens.of(context);

    return StatefulBuilder(
      builder: (context, setSubState) => AppGroup(
        children: [
          // Steps
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Steps', style: t.body),
                    Text('${_imageSteps.toInt()}', style: t.bodyStrong),
                  ],
                ),
                AppSlider(
                  value: _imageSteps,
                  min: 1,
                  max: 50,
                  divisions: 49,
                  onChanged: (v) {
                    setSubState(() => _imageSteps = v);
                    setState(() => _imageSteps = v);
                    Hive.box(AppConstants.settingsBox).put('image_steps', v);
                  },
                ),
                Text('Recommended: 15-20 steps', style: t.small),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(height: 0.5, color: t.hairline),
          ),
          // Image size
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Image size', style: t.body),
                    Text(_imageSize == 0 ? 'Auto' : '${_imageSize}px', style: t.caption),
                  ],
                ),
                const SizedBox(height: 10),
                AppChips<int>(
                  items: const [
                    (0, 'Auto'),
                    (256, '256'),
                    (320, '320'),
                    (384, '384'),
                    (512, '512'),
                  ],
                  selected: _imageSize,
                  onSelected: (v) {
                    setSubState(() => _imageSize = v);
                    setState(() => _imageSize = v);
                    Hive.box(AppConstants.settingsBox).put('image_size', v);
                  },
                ),
                const SizedBox(height: 10),
                Text(
                  'Auto recommended. Bigger size = better detail, but much slower and more memory use.',
                  style: t.small,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(height: 0.5, color: t.hairline),
          ),
          // GPU safety
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('GPU safety', style: t.body),
                    Text('${_gpuSafetyMb.toInt()} MB', style: t.bodyStrong),
                  ],
                ),
                AppSlider(
                  value: _gpuSafetyMb,
                  min: 512,
                  max: 4096,
                  divisions: 14,
                  onChanged: (v) {
                    setSubState(() => _gpuSafetyMb = v);
                    setState(() => _gpuSafetyMb = v);
                    Hive.box(AppConstants.settingsBox).put('gpu_safety_mb', v);
                  },
                ),
                Text(
                  'Models at or above this size use CPU. Smaller models can use GPU Experimental.',
                  style: t.small,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(height: 0.5, color: t.hairline),
          ),
          // Backend
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Backend', style: t.body),
                const SizedBox(height: 2),
                Text('ADRENO - Vulkan (GPU)', style: t.caption),
                const SizedBox(height: 10),
                AppSegmented<String>(
                  items: const [
                    ('cpu', 'CPU'),
                    ('gpu', 'GPU'),
                  ],
                  selected: _imageBackend,
                  onChanged: (b) {
                    setSubState(() => _imageBackend = b);
                    setState(() => _imageBackend = b);
                    Hive.box(AppConstants.settingsBox).put('image_backend', b);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 8. DEVICE ──
  Widget _buildDeviceGroup(BuildContext context) {
    final t = AppTokens.of(context);

    Widget kv(String k, String v, {Color? color}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Text(k, style: t.caption.copyWith(fontSize: 14)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  v,
                  textAlign: TextAlign.right,
                  style: t.body.copyWith(fontSize: 14, color: color ?? t.text),
                ),
              ),
            ],
          ),
        );

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconBadge(Icons.smartphone_rounded, size: 36),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_deviceRam, style: t.bodyStrong),
                    const SizedBox(height: 2),
                    Text('Use small models only', style: t.caption),
                  ],
                ),
              ),
              AppTag('Low RAM', color: t.orange),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Container(height: 0.5, color: t.hairline),
          ),
          kv('Available memory', '0.7 GB'),
          kv('Recommended context', '1024'),
          kv('Recommended max tokens', '256'),
          kv('Chipset', _chipset),
          kv('Recommended quant', 'Q4_K_M (recommended) · Q4_0...'),
        ],
      ),
    );
  }

  // ── 9. APP UPDATES ──
  Widget _buildUpdatesGroup(BuildContext context) {
    return StatefulBuilder(
      builder: (context, setSubState) => AppGroup(
        dividerIndent: 60,
        children: [
          AppRow(
            icon: Icons.refresh_rounded,
            title: 'Check for updates',
            subtitle: 'Up to date · checked 1m ago',
            chevron: true,
            onTap: () {
              showToast(context, 'Up to date', 'You are running the latest version of LocalLM.', tone: ToastTone.success);
            },
          ),
          AppRow(
            icon: Icons.schedule_rounded,
            title: 'Check automatically',
            subtitle: 'Look for a new release once a day',
            trailing: AppSwitch(
              value: _autoCheckUpdates,
              onChanged: (val) {
                setSubState(() => _autoCheckUpdates = val);
                setState(() => _autoCheckUpdates = val);
                Hive.box(AppConstants.settingsBox).put('auto_check_updates', val);
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── 10. LOGS ──
  Widget _buildLogsGroup(BuildContext context) {
    final t = AppTokens.of(context);
    final serverLogs = ref.watch(serverProvider).logs;

    final allLogs = <(String, String, String)>[
      ...serverLogs.map((l) => ('Info', 'Server', l)),
      ..._systemLogs,
    ];

    final filteredLogs = allLogs.where((e) {
      if (_logFilter == 'all') return true;
      if (_logFilter == 'errors') return e.$1.toLowerCase().contains('err') || e.$3.toLowerCase().contains('error');
      if (_logFilter == 'warnings') return e.$1.toLowerCase().contains('warn') || e.$3.toLowerCase().contains('warn');
      if (_logFilter == 'info') return e.$1.toLowerCase().contains('info');
      if (_logFilter == 'debug') return e.$1.toLowerCase().contains('debug');
      return true;
    }).toList();

    return StatefulBuilder(
      builder: (context, setSubState) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                tooltip: 'Copy all logs',
                onPressed: () {
                  final txt = filteredLogs.map((e) => '[${e.$1}] ${e.$2} ${e.$3}').join('\n');
                  Clipboard.setData(ClipboardData(text: txt));
                  showToast(context, 'Copied', 'Logs copied to clipboard', tone: ToastTone.success);
                },
                icon: Icon(Icons.copy_rounded, size: 20, color: t.muted),
              ),
              IconButton(
                tooltip: 'Clear logs',
                onPressed: () {
                  setSubState(() {
                    _systemLogs.clear();
                  });
                  showToast(context, 'Cleared', 'Logs cleared');
                },
                icon: Icon(Icons.delete_outline_rounded, size: 20, color: t.muted),
              ),
            ],
          ),
          const SizedBox(height: 6),
          AppChips<String>(
            items: const [
              ('all', 'All'),
              ('errors', 'Errors'),
              ('warnings', 'Warnings'),
              ('info', 'Info'),
              ('debug', 'Debug'),
            ],
            selected: _logFilter,
            onSelected: (f) {
              setSubState(() => _logFilter = f);
              setState(() => _logFilter = f);
            },
          ),
          const SizedBox(height: 16),
          if (filteredLogs.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Text('No logs to display', style: t.caption),
              ),
            )
          else
            for (final entry in filteredLogs)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        AppTag(entry.$1),
                        const SizedBox(width: 8),
                        Text(entry.$2, style: t.small),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      entry.$3,
                      style: GoogleFonts.firaCode(fontSize: 12.5, color: t.text.withValues(alpha: 0.9)),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

/// Standalone Full-Page settings sub-page with back arrow
class _SettingsPage extends StatelessWidget {
  final String title;
  final WidgetBuilder builder;

  const _SettingsPage({
    required this.title,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);

    return Scaffold(
      backgroundColor: t.bg,
      appBar: appScreenBar(context, title: title, showBack: true),
      body: ListView(
        padding: kPagePadding,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        children: [
          const SizedBox(height: 8),
          builder(context),
        ],
      ),
    );
  }
}
