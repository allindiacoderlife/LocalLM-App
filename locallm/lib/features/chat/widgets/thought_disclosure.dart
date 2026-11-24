import 'package:flutter/material.dart';

class ThoughtDisclosure extends StatefulWidget {
  final String thought;
  final bool isThinking;

  const ThoughtDisclosure({
    super.key,
    required this.thought,
    this.isThinking = false,
  });

  @override
  State<ThoughtDisclosure> createState() => _ThoughtDisclosureState();
}

class _ThoughtDisclosureState extends State<ThoughtDisclosure> {
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    // Default to open while thinking, collapsed when done
    _isExpanded = widget.isThinking;
  }

  @override
  void didUpdateWidget(covariant ThoughtDisclosure oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isThinking && !widget.isThinking) {
      // Auto-collapse when thinking finishes
      setState(() {
        _isExpanded = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1F24),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2C323C)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Icon(
                    widget.isThinking
                        ? Icons.psychology_outlined
                        : Icons.lightbulb_outline,
                    size: 18,
                    color: widget.isThinking
                        ? const Color(0xFF8B84FF)
                        : Colors.white70,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.isThinking ? 'Thinking...' : 'Reasoning Process',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: widget.isThinking
                          ? const Color(0xFF8B84FF)
                          : Colors.white70,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                    color: Colors.white54,
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded) ...[
            const Divider(height: 1, color: Color(0xFF2C323C)),
            Padding(
              padding: const EdgeInsets.all(14),
              child: SelectableText(
                widget.thought,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.white60,
                  fontStyle: FontStyle.italic,
                  height: 1.45,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
