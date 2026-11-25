import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:markdown/markdown.dart' as md;

import '../../../core/ui.dart';
import '../models/chat_message.dart';
import '../../../core/utils/thought_parser.dart';
import 'thought_disclosure.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final double? currentTokensPerSec;

  const ChatBubble({
    super.key,
    required this.message,
    this.currentTokensPerSec,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';
    if (isUser) {
      return _buildUser(context);
    }
    return _buildAssistant(context);
  }

  // ── User: Compact pill on the right (Apple / PrivateLM style) ──
  Widget _buildUser(BuildContext context) {
    final t = AppTokens.of(context);
    final maxW = MediaQuery.of(context).size.width * 0.82;

    return Padding(
      padding: const EdgeInsets.fromLTRB(48, 8, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (message.attachmentName != null) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 6),
              constraints: BoxConstraints(maxWidth: maxW),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: t.fill,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: t.glassBorder,
                  width: 0.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.description_outlined, size: 16, color: t.accent),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      message.attachmentName!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: t.muted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (message.content.trim().isNotEmpty) ...[
            Container(
              constraints: BoxConstraints(maxWidth: maxW),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: t.isDark
                    ? const Color(0xFF1F2430)
                    : const Color(0xFFE3E8F0),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(5),
                ),
                border: Border.all(
                  color: t.glassBorder,
                  width: 0.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: t.isDark ? 0.2 : 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: SelectableText(
                message.content,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  height: 1.45,
                  letterSpacing: -0.1,
                  color: t.text,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Assistant: Full-width text, unboxed, quiet actions below ──
  Widget _buildAssistant(BuildContext context) {
    final t = AppTokens.of(context);
    final parsed = ThoughtParser.parse(message.content);
    final answerText = parsed.response.trim();

    final speed = message.tokensPerSec ?? currentTokensPerSec;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Collapsible Reasoning Process (for models like DeepSeek / Qwen / SmolLM with thoughts)
          if (parsed.thought != null && parsed.thought!.isNotEmpty) ...[
            ThoughtDisclosure(
              thought: parsed.thought!,
              isThinking: parsed.isThinking,
            ),
          ],

          // Markdown Answer
          if (answerText.isNotEmpty) ...[
            MarkdownBody(
              data: answerText,
              selectable: true,
              styleSheet: _markdownStyle(context),
              builders: {
                'code': _CodeBlockBuilder(),
              },
            ),
          ] else if (parsed.isThinking) ...[
            const SizedBox.shrink(),
          ],

          const SizedBox(height: 6),

          // Action row below message (aligned with text)
          Row(
            children: [
              if (answerText.isNotEmpty) ...[
                InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: answerText));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Copied response to clipboard'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.copy_rounded, size: 14, color: t.muted),
                        const SizedBox(width: 4),
                        Text(
                          'Copy',
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            color: t.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              if (speed != null && speed > 0) ...[
                const SizedBox(width: 10),
                Text(
                  '${speed.toStringAsFixed(1)} tok/s',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    color: t.muted,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
              const SizedBox(width: 10),
              Text(
                _formatTime(message.timestamp),
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: t.faint,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static MarkdownStyleSheet _markdownStyle(BuildContext context) {
    final t = AppTokens.of(context);
    final base = GoogleFonts.inter(
      fontSize: 15,
      height: 1.55,
      letterSpacing: -0.1,
      color: t.text,
    );
    final codeBg = t.isDark ? const Color(0xFF16181D) : const Color(0xFFE5E7EB);

    return MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
      p: base,
      strong: base.copyWith(fontWeight: FontWeight.w600, color: t.text),
      em: base.copyWith(fontStyle: FontStyle.italic),
      listBullet: base,
      code: TextStyle(
        fontFamily: 'monospace',
        fontSize: 13,
        color: t.isDark ? const Color(0xFF9D97FF) : const Color(0xFF4F46E5),
        backgroundColor: codeBg,
      ),
      codeblockDecoration: const BoxDecoration(),
      h1: base.copyWith(fontSize: 20, fontWeight: FontWeight.w700, color: t.text, height: 1.3),
      h2: base.copyWith(fontSize: 18, fontWeight: FontWeight.w700, color: t.text, height: 1.3),
      h3: base.copyWith(fontSize: 16, fontWeight: FontWeight.w600, color: t.text, height: 1.35),
      codeblockPadding: EdgeInsets.zero,
      pPadding: const EdgeInsets.only(bottom: 4),
      blockquote: base.copyWith(color: t.muted),
      blockquoteDecoration: BoxDecoration(
        border: Border(left: BorderSide(color: t.accent, width: 3)),
      ),
      blockquotePadding: const EdgeInsets.only(left: 12, top: 2, bottom: 2),
    );
  }

  static String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _CodeBlockBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final cls = element.attributes['class'] ?? '';
    final isCodeBlock =
        cls.startsWith('language-') || element.textContent.contains('\n');
    if (!isCodeBlock) {
      return null;
    }

    String language = 'code';
    if (cls.startsWith('language-')) {
      final lang = cls.substring('language-'.length).trim();
      if (lang.isNotEmpty) language = lang;
    }

    final code = element.textContent.trimRight();
    return _CodeBlockCard(language: language, code: code);
  }
}

class _CodeBlockCard extends StatefulWidget {
  final String language;
  final String code;

  const _CodeBlockCard({
    required this.language,
    required this.code,
  });

  @override
  State<_CodeBlockCard> createState() => _CodeBlockCardState();
}

class _CodeBlockCardState extends State<_CodeBlockCard> {
  bool _copied = false;

  void _copyCode() {
    Haptics.selectionClick();
    Clipboard.setData(ClipboardData(text: widget.code));
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final headerBg = t.isDark ? const Color(0xFF20242E) : const Color(0xFFDDE1E8);
    final bodyBg = t.isDark ? const Color(0xFF14171E) : const Color(0xFFECEFF4);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: bodyBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: t.glassBorder,
          width: 0.7,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: headerBg,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.language,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: t.muted,
                  ),
                ),
                InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: _copyCode,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _copied ? Icons.check_rounded : Icons.copy_rounded,
                          size: 14,
                          color: _copied ? t.green : t.muted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _copied ? 'Copied' : 'Copy code',
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: _copied ? t.green : t.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(12),
            child: SelectableText(
              widget.code,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12.5,
                height: 1.45,
                color: t.isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
