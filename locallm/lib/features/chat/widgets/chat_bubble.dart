import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';

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
                color: const Color(0xFF20242D),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                  width: 0.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.description_outlined, size: 16, color: Color(0xFF8B84FF)),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      message.attachmentName!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: Colors.white70,
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
                color: const Color(0xFF232733),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(5),
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.09),
                  width: 0.5,
                ),
              ),
              child: SelectableText(
                message.content,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  height: 1.45,
                  letterSpacing: -0.1,
                  color: Colors.white,
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
                        const Icon(Icons.copy_rounded, size: 14, color: Colors.white38),
                        const SizedBox(width: 4),
                        Text(
                          'Copy',
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            color: Colors.white38,
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
                    color: Colors.white38,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
              const SizedBox(width: 10),
              Text(
                _formatTime(message.timestamp),
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: Colors.white24,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static MarkdownStyleSheet _markdownStyle(BuildContext context) {
    final base = GoogleFonts.inter(
      fontSize: 15,
      height: 1.55,
      letterSpacing: -0.1,
      color: const Color(0xFFE5E7EB),
    );
    const codeBg = Color(0xFF16181D);

    return MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
      p: base,
      strong: base.copyWith(fontWeight: FontWeight.w600, color: Colors.white),
      em: base.copyWith(fontStyle: FontStyle.italic),
      listBullet: base,
      code: GoogleFonts.firaCode(
        fontSize: 13,
        color: const Color(0xFF9D97FF),
        backgroundColor: codeBg,
      ),
      codeblockDecoration: BoxDecoration(
        color: codeBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 0.5,
        ),
      ),
      h1: base.copyWith(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white, height: 1.3),
      h2: base.copyWith(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white, height: 1.3),
      h3: base.copyWith(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white, height: 1.35),
      codeblockPadding: const EdgeInsets.all(12),
      pPadding: const EdgeInsets.only(bottom: 4),
      blockquote: base.copyWith(color: Colors.white60),
      blockquoteDecoration: const BoxDecoration(
        border: Border(left: BorderSide(color: Color(0xFF6C63FF), width: 3)),
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
