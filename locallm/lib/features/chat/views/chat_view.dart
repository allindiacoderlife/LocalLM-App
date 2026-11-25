import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../../core/ui.dart';
import '../../documents/services/document_extractor_service.dart';
import '../../home/providers/home_tab_provider.dart';
import '../../local_inference/services/local_inference_service.dart';
import '../../local_models/services/model_download_service.dart';
import '../providers/chat_provider.dart';
import '../widgets/chat_bubble.dart';

class ChatView extends ConsumerStatefulWidget {
  const ChatView({super.key});

  @override
  ConsumerState<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends ConsumerState<ChatView> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _hasInputText = false;
  bool _speechInitialized = false;
  bool _isListening = false;
  String _speechBaseText = '';

  @override
  void initState() {
    super.initState();
    _inputController.addListener(() {
      final hasText = _inputController.text.trim().isNotEmpty;
      if (hasText != _hasInputText) {
        setState(() => _hasInputText = hasText);
      }
    });
  }

  @override
  void dispose() {
    _speech.stop();
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _speech.stop();
      if (mounted) setState(() => _isListening = false);
      return;
    }

    if (!_speechInitialized) {
      _speechInitialized = await _speech.initialize(
        onStatus: (status) {
          if (!mounted) return;
          if (status == 'done' || status == 'notListening') {
            setState(() => _isListening = false);
          }
        },
        onError: (err) {
          if (!mounted) return;
          setState(() => _isListening = false);
          showToast(context, 'Voice input', err.errorMsg,
              tone: ToastTone.warning);
        },
      );
    }

    if (!_speechInitialized) {
      if (mounted) {
        showToast(
          context,
          'Microphone unavailable',
          'Please allow microphone permission to use voice input.',
          tone: ToastTone.warning,
        );
      }
      return;
    }

    _speechBaseText = _inputController.text.trim();
    setState(() => _isListening = true);

    await _speech.listen(
      listenOptions: stt.SpeechListenOptions(
        listenMode: stt.ListenMode.dictation,
        partialResults: true,
      ),
      onResult: (result) {
        if (!mounted) return;
        final spoken = result.recognizedWords.trim();
        final combined = _speechBaseText.isEmpty
            ? spoken
            : (spoken.isEmpty ? _speechBaseText : '$_speechBaseText $spoken');
        _inputController.value = TextEditingValue(
          text: combined,
          selection: TextSelection.collapsed(offset: combined.length),
        );
      },
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _pickAttachment() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'txt', 'md', 'json', 'dart', 'py'],
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final content = await DocumentExtractorService.extractText(file);
      final fileName = result.files.single.name;
      final type = fileName.toLowerCase().endsWith('.pdf') ? 'pdf' : 'text';

      ref.read(chatProvider.notifier).setAttachment(
            ChatAttachment(name: fileName, type: type, content: content),
          );
    }
  }

  void _handleSend([String? customPrompt]) {
    if (_isListening) {
      _speech.stop();
      setState(() => _isListening = false);
    }
    final text = (customPrompt ?? _inputController.text).trim();
    if (text.isEmpty && ref.read(chatProvider).attachment == null) return;
    if (customPrompt == null) {
      _inputController.clear();
      setState(() => _hasInputText = false);
    }
    ref.read(chatProvider.notifier).sendMessage(text);
    _scrollToBottom();
  }

  String get _greetingText {
    final h = DateTime.now().hour;
    if (h < 5) return 'Up late?';
    if (h < 12) return 'Good morning,';
    if (h < 17) return 'Good afternoon,';
    return 'Good evening,';
  }

  void _showModelSelectorSheet(BuildContext context) {
    final chatState = ref.read(chatProvider);
    final localState = ref.read(localInferenceProvider);
    final isLocal = chatState.inferenceMode == InferenceMode.local;
    final t = AppTokens.of(context);

    showAppSheet<void>(
      context,
      title: 'Active Model',
      subtitle: 'Choose between 100% offline local model or cloud model.',
      builder: (ctx) => Column(
        children: [
          AppGroup(
            children: [
              AppRow(
                icon: Icons.memory_rounded,
                title: 'Local Model (Offline)',
                subtitle: localState.isModelLoaded
                    ? localState.loadedModelName
                    : 'No model loaded on this device',
                selected: isLocal,
                trailing: isLocal ? AppTag('Active', color: t.green) : null,
                onTap: () {
                  ref
                      .read(chatProvider.notifier)
                      .setInferenceMode(InferenceMode.local);
                  Navigator.pop(ctx);
                },
              ),
              AppRow(
                icon: Icons.cloud_outlined,
                title: 'Cloud Model',
                subtitle:
                    '${chatState.selectedProvider.name.toUpperCase()} · ${chatState.selectedModel}',
                selected: !isLocal,
                trailing: !isLocal ? AppTag('Active', color: t.accent) : null,
                onTap: () {
                  ref
                      .read(chatProvider.notifier)
                      .setInferenceMode(InferenceMode.cloud);
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TonalButton.neutral(
                  ctx,
                  label: 'Manage models',
                  onTap: () {
                    Navigator.pop(ctx);
                    ref.read(homeTabProvider.notifier).state = 1;
                  },
                ),
              ),
              if (localState.isModelLoaded) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: TonalButton.destructive(
                    ctx,
                    label: 'Unload',
                    onTap: () {
                      Navigator.pop(ctx);
                      ref.read(localInferenceProvider.notifier).unloadModel();
                    },
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final localState = ref.watch(localInferenceProvider);
    final downloadState = ref.watch(modelDownloadProvider);
    final currentSession = chatState.currentSession;
    final messages = currentSession?.messages ?? [];
    final isLocalMode = chatState.inferenceMode == InferenceMode.local;
    final t = AppTokens.of(context);

    ref.listen(chatProvider, (previous, next) {
      if (previous?.currentSession?.messages.length !=
              next.currentSession?.messages.length ||
          next.isGenerating) {
        _scrollToBottom();
      }
    });

    final modelDisplayName = isLocalMode
        ? (localState.isModelLoaded
            ? localState.loadedModelName!
            : 'No Local Model')
        : '${chatState.selectedProvider.name.toUpperCase()} · ${chatState.selectedModel}';

    return Scaffold(
      backgroundColor: t.bg,
      drawer: _buildDrawer(chatState, localState),
      appBar: AppBar(
        backgroundColor: t.bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 0,
        leadingWidth: 52,
        leading: Builder(
          builder: (ctx) => IconButton(
            tooltip: 'Chats',
            onPressed: () => Scaffold.of(ctx).openDrawer(),
            icon: Icon(Icons.menu_rounded, color: t.text, size: 24),
          ),
        ),
        title: messages.isEmpty
            ? Text(
                'LocalLM',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  letterSpacing: -0.5,
                  color: t.text,
                ),
              )
            : GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _showModelSelectorSheet(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      currentSession?.title ?? 'Chat',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        letterSpacing: -0.3,
                        color: t.text,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isLocalMode
                                ? (localState.isModelLoaded
                                    ? t.green
                                    : t.orange)
                                : t.accent,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            modelDisplayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                GoogleFonts.inter(fontSize: 12, color: t.muted),
                          ),
                        ),
                        Icon(Icons.expand_more_rounded,
                            size: 16, color: t.muted),
                      ],
                    ),
                  ],
                ),
              ),
        actions: [
          IconButton(
            tooltip: 'New chat',
            onPressed: () {
              Haptics.selectionClick();
              ref.read(chatProvider.notifier).newChat();
            },
            icon: Icon(Icons.edit_square, color: t.text, size: 20),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: messages.isEmpty
                ? _buildEmptyState(context, isLocalMode, localState,
                    downloadState.downloadedFiles.length)
                : ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.only(
                      top: 8,
                      bottom: MediaQuery.of(context).padding.bottom + 92,
                    ),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      final isLast = index == messages.length - 1;
                      return ChatBubble(
                        message: msg,
                        currentTokensPerSec: (isLast && chatState.isGenerating)
                            ? localState.tokensPerSecond
                            : null,
                      );
                    },
                  ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildInputBar(chatState, isLocalMode, localState),
          ),
        ],
      ),
    );
  }

  // ── PrivateLM-Faithful Empty State (Matches Screenshot 7 & 8) ──
  Widget _buildEmptyState(
    BuildContext context,
    bool isLocal,
    LocalInferenceState localState,
    int downloadedCount,
  ) {
    final t = AppTokens.of(context);
    final typing = MediaQuery.of(context).viewInsets.bottom > 0;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        16,
        8,
        16,
        MediaQuery.of(context).padding.bottom + 92,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Top Model Card (Screenshot 7 & 8) ──
          _buildTopModelBanner(t, isLocal, localState, downloadedCount),

          if (!typing) ...[
            const SizedBox(height: 36),
            // ── Centered Prism Logo & Greeting ──
            Center(
              child: Column(
                children: [
                  Image.asset(
                    'assets/icons/appicon.png',
                    width: 44,
                    height: 44,
                    errorBuilder: (_, __, ___) =>
                        Icon(Icons.token_rounded, size: 44, color: t.accent),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    '$_greetingText\nwhat\'s on your mind?',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      height: 1.25,
                      fontWeight: FontWeight.w400,
                      letterSpacing: -0.7,
                      color: t.text.withValues(alpha: 0.88),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 36),

            // ── How It Works or Starters ──
            if (isLocal && !localState.isModelLoaded && downloadedCount == 0)
              _buildHowItWorks(t)
            else
              _buildStarters(t, isLocal, localState),
          ],
        ],
      ),
    );
  }

  Widget _buildTopModelBanner(
    AppTokens t,
    bool isLocal,
    LocalInferenceState localState,
    int downloadedCount,
  ) {
    final String title;
    final String subtitle;
    final Color dotColor;
    final Widget actionButton;

    if (!isLocal) {
      title = 'Cloud AI Assistant';
      subtitle = 'Online · Frontier APIs';
      dotColor = t.accent;
      actionButton = PillButton(
        label: 'Change',
        primary: false,
        onTap: () => ref.read(homeTabProvider.notifier).state = 1,
      );
    } else if (localState.isModelLoaded) {
      title = localState.loadedModelName ?? 'Local model';
      subtitle = 'Ready · CPU · GGUF';
      dotColor = t.green;
      actionButton = PillButton(
        label: 'Switch',
        primary: false,
        onTap: () => ref.read(homeTabProvider.notifier).state = 1,
      );
    } else if (downloadedCount == 0) {
      title = 'No model on this device';
      subtitle = 'Download one to chat offline';
      dotColor = t.orange;
      actionButton = PillButton(
        label: 'Browse',
        primary: true,
        onTap: () {
          Haptics.selectionClick();
          ref.read(homeTabProvider.notifier).state = 1;
        },
      );
    } else {
      title = 'No model loaded';
      subtitle = '$downloadedCount downloaded';
      dotColor = t.faint;
      actionButton = PillButton(
        label: 'Choose',
        primary: true,
        onTap: () => ref.read(homeTabProvider.notifier).state = 1,
      );
    }

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onTap: () => ref.read(homeTabProvider.notifier).state = 1,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: t.fill,
            ),
            child: Icon(
              (downloadedCount == 0 && isLocal && !localState.isModelLoaded)
                  ? Icons.download_rounded
                  : Icons.memory_rounded,
              size: 20,
              color: t.text.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                    color: t.text,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle, color: dotColor),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            GoogleFonts.inter(fontSize: 12.5, color: t.muted),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actionButton,
        ],
      ),
    );
  }

  Widget _buildHowItWorks(AppTokens t) {
    const steps = [
      ('Pick a model', 'Smaller models are faster; larger ones are smarter.'),
      ('Download it once', 'Usually 0.5–3 GB. Wi-Fi recommended.'),
      ('Chat offline', 'Runs on this device. No account, no server.'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 14),
          child: Text('How it works', style: t.label),
        ),
        for (var i = 0; i < steps.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: t.faint, width: 1),
                  ),
                  child: Text(
                    '${i + 1}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: t.muted,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 2),
                      Text(
                        steps[i].$1,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: t.text,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        steps[i].$2,
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          height: 1.35,
                          color: t.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildStarters(
      AppTokens t, bool isLocal, LocalInferenceState localState) {
    final ready = !isLocal || localState.isModelLoaded;
    final starters = [
      (
        Icons.lightbulb_outline_rounded,
        'Explain quantum computing simply',
        'Explain quantum computing simply, like I\'m new to it.'
      ),
      (
        Icons.mail_outline_rounded,
        'Write a polite follow-up email',
        'Write a short, polite follow-up email to someone who hasn\'t replied in a week.'
      ),
      (
        Icons.flight_takeoff_rounded,
        'Plan a 3-day trip to Tokyo',
        'Plan a relaxed 3-day trip to Tokyo with food and sightseeing.'
      ),
    ];

    return Column(
      children: [
        for (final s in starters)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: Colors.transparent,
              shape: StadiumBorder(side: BorderSide(color: t.outline)),
              child: InkWell(
                customBorder: const StadiumBorder(),
                onTap: () {
                  Haptics.selectionClick();
                  if (!ready) {
                    ref.read(homeTabProvider.notifier).state = 1;
                    return;
                  }
                  _handleSend(s.$3);
                },
                splashFactory: NoSplash.splashFactory,
                highlightColor: t.surfacePressed,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 18, 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(s.$1, size: 18, color: t.muted),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          s.$2,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            letterSpacing: -0.15,
                            color: t.text.withValues(alpha: 0.9),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ── Composer Capsule matching Apple Glass Design ──
  Widget _buildInputBar(
      ChatState state, bool isLocal, LocalInferenceState localState) {
    final hasAttachment = state.attachment != null;
    final isGenerating = state.isGenerating;
    final t = AppTokens.of(context);
    final canType = !isLocal || localState.isModelLoaded;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
      color: Colors.transparent,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasAttachment) ...[
              GlassContainer(
                borderRadius: 12,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                margin: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.description, size: 16, color: t.accent),
                    const SizedBox(width: 6),
                    Text(
                      state.attachment!.name,
                      style: GoogleFonts.inter(fontSize: 12, color: t.text),
                    ),
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: () =>
                          ref.read(chatProvider.notifier).setAttachment(null),
                      child: Icon(Icons.close, size: 14, color: t.muted),
                    ),
                  ],
                ),
              ),
            ],

            // iOS 26 Floating Liquid Glass Message Bar + Separate Circle Liquid Action Button
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: GlassContainer(
                    borderRadius: 28,
                    blur: 14,
                    quality: GlassQuality.premium,
                    color: t.isDark
                        ? const Color(0x38161A22)
                        : const Color(0x66FFFFFF),
                    shadows: t.glassShadows,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        IconButton(
                          tooltip: 'Attach file',
                          onPressed: _pickAttachment,
                          icon: Icon(Icons.attach_file_rounded,
                              color: t.muted, size: 22),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _inputController,
                            minLines: 1,
                            maxLines: 4,
                            textInputAction: TextInputAction.send,
                            style:
                                GoogleFonts.inter(fontSize: 15, color: t.text),
                            decoration: InputDecoration(
                              hintText: _isListening
                                  ? 'Listening…'
                                  : (canType
                                      ? 'Message local offline model…'
                                      : 'Load a model to start chatting'),
                              hintStyle: GoogleFonts.inter(
                                fontSize: 15,
                                color: _isListening ? t.accent : t.faint,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 10),
                              isDense: true,
                            ),
                            onSubmitted: (_) => _handleSend(),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                if (isGenerating)
                  GlassContainer(
                    borderRadius: 26,
                    blur: 24,
                    color: t.isDark
                        ? const Color(0xCCFFFFFF)
                        : const Color(0xFF1A1D24),
                    shadows: t.glassShadows,
                    onTap: () {
                      ref.read(chatProvider.notifier).stopGeneration();
                    },
                    child: SizedBox(
                      width: 50,
                      height: 50,
                      child: Icon(
                        Icons.stop_rounded,
                        size: 24,
                        color: t.isDark ? Colors.black : Colors.white,
                      ),
                    ),
                  )
                else if (_isListening)
                  GlassContainer(
                    borderRadius: 26,
                    blur: 24,
                    color: t.red.withValues(alpha: 0.85),
                    shadows: t.glassShadows,
                    onTap: _toggleListening,
                    child: const SizedBox(
                      width: 50,
                      height: 50,
                      child: Icon(
                        Icons.mic_rounded,
                        size: 24,
                        color: Colors.white,
                      ),
                    ),
                  )
                else if (_hasInputText || hasAttachment)
                  GlassContainer(
                    borderRadius: 26,
                    blur: 24,
                    color: t.accent.withValues(alpha: 0.90),
                    shadows: t.glassShadows,
                    onTap: () {
                      Haptics.lightImpact();
                      _handleSend();
                    },
                    child: const SizedBox(
                      width: 50,
                      height: 50,
                      child: Icon(
                        Icons.arrow_upward_rounded,
                        size: 24,
                        color: Colors.white,
                      ),
                    ),
                  )
                else
                  GlassContainer(
                    borderRadius: 26,
                    blur: 14,
                    quality: GlassQuality.premium,
                    color: t.isDark
                        ? const Color(0x38161A22)
                        : const Color(0x66FFFFFF),
                    shadows: t.glassShadows,
                    onTap: _toggleListening,
                    child: SizedBox(
                      width: 50,
                      height: 50,
                      child: Icon(
                        Icons.mic_none_rounded,
                        size: 24,
                        color: t.text,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Drawer ──
  Widget _buildDrawer(ChatState state, LocalInferenceState localState) {
    final t = AppTokens.of(context);

    return Drawer(
      backgroundColor: t.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Image.asset(
                    'assets/icons/appicon.png',
                    width: 28,
                    height: 28,
                    errorBuilder: (_, __, ___) =>
                        Icon(Icons.token_rounded, size: 28, color: t.accent),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'LocalLM',
                    style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: t.text),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () {
                      ref.read(chatProvider.notifier).newChat();
                      Navigator.of(context).pop();
                    },
                    icon: Icon(Icons.add_rounded, color: t.text),
                  ),
                ],
              ),
            ),
            Container(height: 0.5, color: t.hairline),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text('Chat History', style: t.label),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: state.sessions.length,
                itemBuilder: (context, index) {
                  final session = state.sessions[index];
                  final isSelected = session.id == state.currentSessionId;
                  return ListTile(
                    selected: isSelected,
                    selectedTileColor: t.surfacePressed,
                    title: Text(
                      session.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected ? t.accent : t.text,
                      ),
                    ),
                    trailing: state.sessions.length > 1
                        ? IconButton(
                            icon: Icon(Icons.delete_outline_rounded,
                                size: 18, color: t.muted),
                            onPressed: () => ref
                                .read(chatProvider.notifier)
                                .deleteSession(session.id),
                          )
                        : null,
                    onTap: () {
                      ref.read(chatProvider.notifier).switchSession(session.id);
                      Navigator.of(context).pop();
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
