import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TonalButton extends StatelessWidget {
  final String label;
  final Color color;
  final Color fill;
  final VoidCallback onTap;

  const TonalButton({
    super.key,
    required this.label,
    required this.color,
    required this.fill,
    required this.onTap,
  });

  factory TonalButton.neutral(BuildContext context,
      {required String label, required VoidCallback onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TonalButton(
      label: label,
      onTap: onTap,
      color: isDark ? Colors.white : const Color(0xFF0A0B0E),
      fill: isDark
          ? Colors.white.withValues(alpha: 0.10)
          : const Color(0xFFE8ECEF),
    );
  }

  factory TonalButton.destructive(BuildContext context,
      {required String label, required VoidCallback onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TonalButton(
      label: label,
      onTap: onTap,
      color: isDark ? const Color(0xFFFF453A) : const Color(0xFFE5342B),
      fill: (isDark ? const Color(0xFFFF453A) : const Color(0xFFFF3B30))
          .withValues(alpha: isDark ? 0.16 : 0.12),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.black.withValues(alpha: 0.06),
          width: 0.6,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: SizedBox(
            height: 50,
            child: Center(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                  color: color,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
