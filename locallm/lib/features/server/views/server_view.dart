import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/ui.dart';
import '../providers/server_provider.dart';
import '../../local_inference/services/local_inference_service.dart';

class ServerView extends ConsumerStatefulWidget {
  const ServerView({super.key});

  @override
  ConsumerState<ServerView> createState() => _ServerViewState();
}

class _ServerViewState extends ConsumerState<ServerView> {
  final TextEditingController _apiKeyCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final serverState = ref.read(serverProvider);
    _apiKeyCtrl.text = serverState.apiKey;
  }

  @override
  void dispose() {
    _apiKeyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final serverState = ref.watch(serverProvider);
    final localState = ref.watch(localInferenceProvider);
    final t = AppTokens.of(context);

    final isRunning = serverState.isRunning;
    final isStarting = serverState.isStarting;
    final allowNetwork = serverState.allowNetwork;
    final hasLocalModel = localState.isModelLoaded;
    final modelName = hasLocalModel ? localState.loadedModelName! : 'No model loaded';

    return Scaffold(
      backgroundColor: t.bg,
      appBar: AppBar(
        backgroundColor: t.bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 20,
        title: Text(
          'Server',
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.6,
            color: t.text,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          // ── Top Hero Card (Screenshot 6) ──
          AppCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isRunning ? t.green : t.faint,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Local API server',
                      style: t.caption.copyWith(color: t.muted),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  isRunning ? 'Running' : 'Stopped',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                    color: t.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Expose a local model as an OpenAI-compatible API',
                  style: t.caption,
                ),
                const SizedBox(height: 18),
                PrimaryButton(
                  label: isRunning ? 'Stop server' : 'Start server',
                  icon: isRunning ? Icons.stop_rounded : Icons.play_arrow_rounded,
                  busy: isStarting,
                  onPressed: () {
                    Haptics.lightImpact();
                    ref.read(serverProvider.notifier).toggleServer();
                  },
                ),
              ],
            ),
          ),

          if (serverState.error != null) ...[
            const SizedBox(height: 12),
            AppNotice(serverState.error!, icon: Icons.error_outline_rounded, color: t.red),
          ],

          // ── Model Section ──
          const SectionHeader('Model'),
          AppGroup(
            children: [
              AppRow(
                icon: Icons.memory_rounded,
                title: modelName,
                subtitle: hasLocalModel
                    ? 'Loaded on this device'
                    : 'Load a GGUF or LiteRT-LM model to serve it',
                trailing: hasLocalModel
                    ? AppTag('Ready', color: t.green)
                    : AppTag('Not loaded', color: t.orange),
              ),
            ],
          ),

          // ── Access Section ──
          const SectionHeader('Access'),
          AppGroup(
            children: [
              AppRow(
                icon: Icons.lan_outlined,
                title: 'Allow network access',
                subtitle: allowNetwork
                    ? 'Reachable from other devices on your network'
                    : 'Only apps on this device can connect',
                trailing: Switch(
                  activeThumbColor: t.green,
                  value: allowNetwork,
                  onChanged: isStarting
                      ? null
                      : (val) {
                          Haptics.selectionClick();
                          ref.read(serverProvider.notifier).setAllowNetwork(val);
                        },
                ),
              ),
              AppRow(
                icon: Icons.key_outlined,
                title: 'Require API key',
                subtitle: allowNetwork
                    ? 'Always on while network access is enabled'
                    : 'Clients send Authorization: Bearer <key>',
                trailing: Switch(
                  activeThumbColor: t.green,
                  value: serverState.requiresApiKey,
                  onChanged: allowNetwork
                      ? null
                      : (val) {
                          Haptics.selectionClick();
                          ref.read(serverProvider.notifier).setRequiresApiKey(val);
                        },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── API Key Section ──
          AppField(
            label: 'API key',
            helper: serverState.requiresApiKey
                ? 'Required for every request.'
                : 'Optional. Only checked when "Require API key" is on.',
            child: TextField(
              controller: _apiKeyCtrl,
              onChanged: (val) => ref.read(serverProvider.notifier).setApiKey(val),
              style: t.mono.copyWith(fontSize: 13.5),
              autocorrect: false,
              enableSuggestions: false,
              decoration: appInputDecoration(
                context,
                hint: 'aichat_...',
                suffix: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Generate key',
                      visualDensity: VisualDensity.compact,
                      onPressed: () {
                        Haptics.lightImpact();
                        ref.read(serverProvider.notifier).generateApiKey();
                        _apiKeyCtrl.text = ref.read(serverProvider).apiKey;
                      },
                      icon: Icon(Icons.refresh_rounded, size: 19, color: t.muted),
                    ),
                    IconButton(
                      tooltip: 'Copy key',
                      visualDensity: VisualDensity.compact,
                      onPressed: () {
                        Haptics.selectionClick();
                        Clipboard.setData(ClipboardData(text: serverState.apiKey));
                        showToast(context, 'Copied', 'API key copied to clipboard', tone: ToastTone.success);
                      },
                      icon: Icon(Icons.copy_rounded, size: 19, color: t.muted),
                    ),
                    const SizedBox(width: 4),
                  ],
                ),
              ),
            ),
          ),

          // ── Endpoints Section (when running) ──
          if (isRunning && serverState.url != null) ...[
            const SectionHeader('Endpoints'),
            AppGroup(
              children: [
                AppRow(
                  icon: Icons.link_rounded,
                  title: 'Base URL',
                  subtitle: serverState.url,
                  trailing: Icon(Icons.copy_rounded, size: 18, color: t.muted),
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: serverState.url!));
                    showToast(context, 'Copied', 'Base URL copied to clipboard');
                  },
                ),
                AppRow(
                  icon: Icons.api_rounded,
                  title: 'OpenAI Base URL',
                  subtitle: '${serverState.url}/v1',
                  trailing: Icon(Icons.copy_rounded, size: 18, color: t.muted),
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: '${serverState.url}/v1'));
                    showToast(context, 'Copied', 'OpenAI Base URL copied to clipboard');
                  },
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
