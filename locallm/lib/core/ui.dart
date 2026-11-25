import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart' as lg;

import '../widgets/tonal_button.dart';
import 'haptics.dart';

export '../widgets/tonal_button.dart';
export 'haptics.dart';
export 'package:liquid_glass_widgets/liquid_glass_widgets.dart'
    hide GlassContainer, GlassCard, GlassDivider;

/// Apple Glass Design System for iOS 26 — LocalLM:
/// Translucent frosted glass substrates, specular light-catching borders,
/// spatial ambient depth, smooth squircle continuous corners, and vibrant
/// Apple blue/cyan luminous accents.
class AppTokens {
  final bool isDark;
  final Color bg;
  final Color text;
  final Color muted;
  final Color faint;
  final Color accent;
  final Color accentLight;
  final Color accentGlow;
  final Color surface;
  final Color surfacePressed;
  final Color glass;
  final Color glassElevated;
  final Color glassBorder;
  final Color glassSpecular;
  final Color fill;
  final Color outline;
  final Color hairline;
  final Color green;
  final Color orange;
  final Color red;

  const AppTokens._({
    required this.isDark,
    required this.bg,
    required this.text,
    required this.muted,
    required this.faint,
    required this.accent,
    required this.accentLight,
    required this.accentGlow,
    required this.surface,
    required this.surfacePressed,
    required this.glass,
    required this.glassElevated,
    required this.glassBorder,
    required this.glassSpecular,
    required this.fill,
    required this.outline,
    required this.hairline,
    required this.green,
    required this.orange,
    required this.red,
  });

  factory AppTokens.of(BuildContext context) {
    final d = Theme.of(context).brightness == Brightness.dark;
    return AppTokens._(
      isDark: d,
      bg: d ? const Color(0xFF07080A) : const Color(0xFFF3F5F8),
      text: d ? Colors.white : const Color(0xFF0A0B0E),
      muted: d ? const Color(0xFF98989F) : const Color(0xFF6E6E73),
      faint: d ? const Color(0xFF5A5A62) : const Color(0xFFAEAEB2),
      accent: d ? const Color(0xFF0A84FF) : const Color(0xFF0071E3),
      accentLight: d ? const Color(0xFF409CFF) : const Color(0xFF389BFF),
      accentGlow: const Color(0xFF00F2FE),
      surface: d ? const Color(0xFF101217) : const Color(0xFFFFFFFF),
      surfacePressed: d ? const Color(0xFF1E2129) : const Color(0xFFE5E9EF),
      glass: d
          ? const Color(0x24161A22) // Frosted dark glass
          : const Color(0x90FFFFFF), // Frosted crystal light glass
      glassElevated: d
          ? const Color(0x381E2430)
          : const Color(0xB8FFFFFF),
      glassBorder: d
          ? Colors.white.withValues(alpha: 0.16) // Specular rim
          : Colors.black.withValues(alpha: 0.08),
      glassSpecular: d
          ? Colors.white.withValues(alpha: 0.28)
          : Colors.white.withValues(alpha: 0.85),
      fill: d
          ? Colors.white.withValues(alpha: 0.08)
          : Colors.black.withValues(alpha: 0.05),
      outline: d
          ? Colors.white.withValues(alpha: 0.16)
          : Colors.black.withValues(alpha: 0.12),
      hairline: d
          ? Colors.white.withValues(alpha: 0.08)
          : Colors.black.withValues(alpha: 0.06),
      green: d ? const Color(0xFF30D158) : const Color(0xFF28A745),
      orange: d ? const Color(0xFFFF9F0A) : const Color(0xFFE08600),
      red: d ? const Color(0xFFFF453A) : const Color(0xFFE5342B),
    );
  }

  List<BoxShadow> get glassShadows => [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.32 : 0.05),
          blurRadius: 20,
          offset: const Offset(0, 6),
          spreadRadius: -2,
        ),
      ];

  List<BoxShadow> get elevatedShadows => [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.08),
          blurRadius: 28,
          offset: const Offset(0, 10),
          spreadRadius: -2,
        ),
        if (isDark)
          BoxShadow(
            color: accent.withValues(alpha: 0.08),
            blurRadius: 18,
            spreadRadius: -6,
          ),
      ];

  // ── Type scale ──
  TextStyle get title => GoogleFonts.inter(
      fontSize: 17,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.3,
      color: text);
  TextStyle get body =>
      GoogleFonts.inter(fontSize: 15, letterSpacing: -0.15, color: text);
  TextStyle get bodyStrong => GoogleFonts.inter(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.2,
      color: text);
  TextStyle get caption =>
      GoogleFonts.inter(fontSize: 13, height: 1.35, color: muted);
  TextStyle get small => GoogleFonts.inter(fontSize: 12, color: muted);
  TextStyle get label => GoogleFonts.inter(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.08,
      color: muted);
  TextStyle get mono => TextStyle(fontFamily: 'monospace', fontSize: 12.5, color: text);
}

// ── Glass Core Component ───────────────────────────────────────────────

/// Spatial frosted glass container with blur, specular hairline rim,
/// and ambient soft shadow.
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blur;
  final Color? color;
  final Border? border;
  final List<BoxShadow>? shadows;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;

  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius = 20,
    this.blur = 20,
    this.color,
    this.border,
    this.shadows,
    this.padding,
    this.margin,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final bg = color ?? t.glass;
    final r = BorderRadius.circular(borderRadius);

    Widget content = lg.AdaptiveGlass(
      shape: lg.LiquidRoundedSuperellipse(borderRadius: borderRadius),
      settings: lg.LiquidGlassSettings(
        blur: blur,
        glassColor: bg,
        thickness: 24,
        chromaticAberration: 0.012,
        specularSharpness: lg.GlassSpecularSharpness.medium,
        lightIntensity: t.isDark ? 0.45 : 0.65,
      ),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          borderRadius: r,
          border: border ??
              Border.all(
                color: t.glassBorder,
                width: 0.65,
              ),
        ),
        child: child,
      ),
    );

    if (onTap != null) {
      content = Material(
        color: Colors.transparent,
        borderRadius: r,
        child: InkWell(
          borderRadius: r,
          splashFactory: NoSplash.splashFactory,
          highlightColor: t.surfacePressed.withValues(alpha: 0.4),
          onTap: () {
            Haptics.selectionClick();
            onTap!();
          },
          child: content,
        ),
      );
    }

    if (shadows != null && shadows!.isNotEmpty) {
      content = DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: r,
          boxShadow: shadows,
        ),
        child: content,
      );
    }

    if (margin != null) {
      content = Padding(padding: margin!, child: content);
    }

    return content;
  }
}

// ── Page chrome ─────────────────────────────────────────────────────────

/// Translucent frosted glass app bar: scrolling content blurs beneath it.
PreferredSizeWidget appScreenBar(
  BuildContext context, {
  required String title,
  List<Widget>? actions,
  Widget? leading,
  bool showBack = false,
  Widget? titleWidget,
}) {
  final t = AppTokens.of(context);
  return PreferredSize(
    preferredSize: const Size.fromHeight(kToolbarHeight),
    child: ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          decoration: BoxDecoration(
            color: t.bg.withValues(alpha: t.isDark ? 0.68 : 0.82),
            border: Border(
              bottom: BorderSide(
                color: t.glassBorder,
                width: 0.5,
              ),
            ),
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            automaticallyImplyLeading: showBack,
            leading: leading,
            iconTheme: IconThemeData(color: t.text),
            titleSpacing: leading == null && !showBack ? 20 : 0,
            title: titleWidget ??
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.6,
                    color: t.text,
                  ),
                ),
            actions: [...?actions, const SizedBox(width: 8)],
          ),
        ),
      ),
    ),
  );
}

/// Neutral icon button for app bars with subtle glass circle.
class AppBarIcon extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  const AppBarIcon(
      {super.key, required this.icon, required this.tooltip, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor: t.fill,
          shape: const CircleBorder(),
          padding: const EdgeInsets.all(8),
        ),
        icon: Icon(icon, size: 20, color: onPressed == null ? t.faint : t.text),
      ),
    );
  }
}

/// Standard horizontal page padding with extra bottom padding for floating dock.
const kPagePadding = EdgeInsets.fromLTRB(16, 8, 16, 96);

// ── Sections & groups ───────────────────────────────────────────────────

/// Sentence-case section label with optional trailing widget.
class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;
  const SectionHeader(this.title,
      {super.key,
      this.trailing,
      this.padding = const EdgeInsets.fromLTRB(6, 24, 6, 8)});

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    return Padding(
      padding: padding,
      child: Row(children: [
        Expanded(child: Text(title, style: t.label)),
        if (trailing != null) trailing!,
      ]),
    );
  }
}

/// Footnote text under a group.
class SectionFootnote extends StatelessWidget {
  final String text;
  const SectionFootnote(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 8, 6, 0),
      child: Text(text, style: AppTokens.of(context).small),
    );
  }
}

/// Rounded frosted glass card.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final bool outlined;
  final double borderRadius;
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.outlined = false,
    this.borderRadius = 20,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    return GlassContainer(
      borderRadius: borderRadius,
      blur: 20,
      color: outlined ? Colors.transparent : t.glass,
      border: Border.all(
        color: outlined ? t.outline : t.glassBorder,
        width: outlined ? 1 : 0.65,
      ),
      shadows: t.glassShadows,
      padding: padding,
      onTap: onTap,
      child: child,
    );
  }
}

/// Grouped list surface with inset hairline dividers rendered as a frosted glass pod.
class AppGroup extends StatelessWidget {
  final List<Widget> children;
  final double dividerIndent;
  final bool flat;
  final double borderRadius;
  const AppGroup({
    super.key,
    required this.children,
    this.dividerIndent = 16,
    this.flat = false,
    this.borderRadius = 22,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final items = children.where((w) => w is! SizedBox || w.height != 0);
    final list = items.toList();

    Widget body = Column(mainAxisSize: MainAxisSize.min, children: [
      for (var i = 0; i < list.length; i++) ...[
        if (i > 0)
          Padding(
            padding: EdgeInsets.only(left: dividerIndent),
            child: Container(height: 0.5, color: t.hairline),
          ),
        list[i],
      ],
    ]);

    if (flat) return body;

    return GlassContainer(
      borderRadius: borderRadius,
      blur: 20,
      color: t.glass,
      border: Border.all(color: t.glassBorder, width: 0.65),
      shadows: t.glassShadows,
      child: body,
    );
  }
}

/// Standard row inside an [AppGroup].
class AppRow extends StatelessWidget {
  final IconData? icon;
  final Widget? leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool destructive;
  final bool chevron;
  final bool selected;

  const AppRow({
    super.key,
    this.icon,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.destructive = false,
    this.chevron = false,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final color = destructive ? t.red : t.text;
    final lead = leading ??
        (icon != null
            ? IconBadge(icon!, color: destructive ? t.red : null)
            : null);
    return InkWell(
      onTap: onTap == null
          ? null
          : () {
              Haptics.selectionClick();
              onTap!();
            },
      splashFactory: NoSplash.splashFactory,
      highlightColor: t.surfacePressed.withValues(alpha: 0.4),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 52),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(children: [
            if (lead != null) ...[lead, const SizedBox(width: 12)],
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title,
                        style: t.body.copyWith(
                            color: color,
                            fontWeight:
                                selected ? FontWeight.w600 : FontWeight.w400)),
                    if (subtitle != null && subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(subtitle!, style: t.caption),
                    ],
                  ]),
            ),
            if (trailing != null) ...[const SizedBox(width: 10), trailing!],
            if (selected && trailing == null)
              Icon(Icons.check_rounded, size: 20, color: t.accent),
            if (chevron) ...[
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded, size: 20, color: t.faint),
            ],
          ]),
        ),
      ),
    );
  }
}

/// Neutral circular icon holder with frosted glass texture.
class IconBadge extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color? color;
  const IconBadge(this.icon, {super.key, this.size = 34, this.color});

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: t.fill,
        border: Border.all(
          color: t.glassBorder.withValues(alpha: 0.5),
          width: 0.5,
        ),
      ),
      child: Icon(icon,
          size: size * 0.52, color: color ?? t.text.withValues(alpha: 0.85)),
    );
  }
}

// ── Small pieces ────────────────────────────────────────────────────────

class StatusDot extends StatelessWidget {
  final Color color;
  final double size;
  final bool glow;
  const StatusDot(this.color, {super.key, this.size = 6, this.glow = true});

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: glow
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.6),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
      );
}

/// Compact label badge with subtle glass styling.
class AppTag extends StatelessWidget {
  final String label;
  final Color? color;
  final IconData? icon;
  const AppTag(this.label, {super.key, this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final fg = color ?? t.muted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: color == null ? t.fill : color!.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color == null
              ? t.glassBorder
              : color!.withValues(alpha: 0.25),
          width: 0.5,
        ),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[
          Icon(icon, size: 11, color: fg),
          const SizedBox(width: 3.5),
        ],
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
      ]),
    );
  }
}

/// Thin rounded progress bar with luminous gradient.
class AppProgressBar extends StatelessWidget {
  final double? value;
  final Color? color;
  final double height;
  const AppProgressBar({super.key, this.value, this.color, this.height = 4.5});

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: LinearProgressIndicator(
        value: value,
        minHeight: height,
        color: color ?? t.accent,
        backgroundColor: t.fill,
      ),
    );
  }
}

/// Horizontal filter chips. Selected = solid text-colour fill; others are outlined glass.
class AppChips<T> extends StatelessWidget {
  final List<(T, String)> items;
  final T selected;
  final ValueChanged<T> onSelected;
  const AppChips(
      {super.key,
      required this.items,
      required this.selected,
      required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: [
        for (final (value, label) in items) ...[
          Builder(builder: (_) {
            final on = value == selected;
            return Material(
              color: on ? t.text : t.fill,
              shape: StadiumBorder(
                  side: BorderSide(
                      color: on ? t.text : t.glassBorder, width: 0.6)),
              child: InkWell(
                customBorder: const StadiumBorder(),
                splashFactory: NoSplash.splashFactory,
                onTap: () {
                  Haptics.selectionClick();
                  onSelected(value);
                },
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Text(label,
                      style: GoogleFonts.inter(
                          fontSize: 13.5,
                          fontWeight: on ? FontWeight.w600 : FontWeight.w500,
                          color: on ? t.bg : t.text.withValues(alpha: 0.88))),
                ),
              ),
            );
          }),
          const SizedBox(width: 8),
        ],
      ]),
    );
  }
}

/// Apple-style segmented control with smooth animated sliding indicator.
class AppSegmented<T> extends StatelessWidget {
  final List<(T, String)> items;
  final T selected;
  final ValueChanged<T> onChanged;
  final double height;

  const AppSegmented({
    super.key,
    required this.items,
    required this.selected,
    required this.onChanged,
    this.height = 40,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);

    return Container(
      height: height,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: t.isDark ? const Color(0xFF1E222D) : const Color(0xFFE5E7EB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: t.isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04),
          width: 0.75,
        ),
      ),
      child: Row(
        children: items.map((item) {
          final isSelected = item.$1 == selected;
          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                Haptics.selectionClick();
                onChanged(item.$1);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected
                      ? (t.isDark ? const Color(0xFF2C3242) : Colors.white)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: t.isDark ? 0.35 : 0.08),
                            blurRadius: 4,
                            offset: const Offset(0, 1.5),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  item.$2,
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? t.text : t.muted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Apple Glass toggle switch with liquid refraction and spring jump animation (iOS 26).
class AppSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Color? activeColor;

  const AppSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    return lg.GlassSwitch(
      value: value,
      onChanged: onChanged,
      activeColor: activeColor ?? t.green,
      inactiveColor: t.isDark ? const Color(0xFF3A3F4E) : const Color(0xFFD1D5DB),
      thumbColor: Colors.white,
      quality: lg.GlassQuality.standard,
      useOwnLayer: true,
    );
  }
}

/// Apple Glass slider with liquid track and jelly physics thumb (iOS 26).
class AppSlider extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;
  final double min;
  final double max;
  final int? divisions;
  final Color? activeColor;

  const AppSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0.0,
    this.max = 1.0,
    this.divisions,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    return lg.GlassSlider(
      value: value.clamp(min, max),
      onChanged: onChanged,
      min: min,
      max: max,
      divisions: divisions,
      activeColor: activeColor ?? t.accent,
      inactiveColor: t.isDark ? const Color(0xFF3A3F4E) : const Color(0xFFE5E7EB),
      thumbColor: Colors.white,
      quality: lg.GlassQuality.standard,
      useOwnLayer: true,
    );
  }
}

/// Primary spatial filled button with luminous Apple accent gradient.
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool busy;
  final bool expand;
  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.onTap,
    this.icon,
    this.busy = false,
    this.expand = true,
  });

  VoidCallback? get _action => onTap ?? onPressed;

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final enabled = _action != null && !busy;
    final r = BorderRadius.circular(16);

    final child = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (busy)
          const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white))
        else if (icon != null)
          Icon(icon, size: 18, color: Colors.white),
        if (busy || icon != null) const SizedBox(width: 8),
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
                color: Colors.white)),
      ],
    );

    final button = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: r,
        gradient: enabled
            ? LinearGradient(
                colors: [
                  t.accentLight,
                  t.accent,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              )
            : null,
        color: enabled ? null : t.accent.withValues(alpha: 0.35),
        boxShadow: enabled
            ? [
                BoxShadow(
                  color: t.accent.withValues(alpha: 0.32),
                  blurRadius: 16,
                  offset: const Offset(0, 5),
                  spreadRadius: -2,
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: r,
        child: InkWell(
          borderRadius: r,
          onTap: enabled
              ? () {
                  Haptics.lightImpact();
                  _action!();
                }
              : null,
          child: SizedBox(
            height: 50,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Center(child: child),
            ),
          ),
        ),
      ),
    );

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// Small pill action (e.g. "Load", "Browse") styled with glass capsule.
class PillButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final VoidCallback? onTap;
  final bool primary;
  final bool destructive;
  final IconData? icon;
  const PillButton({
    super.key,
    required this.label,
    this.onPressed,
    this.onTap,
    this.primary = false,
    this.destructive = false,
    this.icon,
  });

  VoidCallback? get _action => onTap ?? onPressed;

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final Color bg;
    final Color fg;
    if (primary) {
      bg = t.accent;
      fg = Colors.white;
    } else if (destructive) {
      bg = t.red.withValues(alpha: t.isDark ? 0.16 : 0.10);
      fg = t.red;
    } else {
      bg = t.fill;
      fg = t.text;
    }

    return Opacity(
      opacity: _action == null ? 0.45 : 1,
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: primary
                ? Colors.transparent
                : t.glassBorder.withValues(alpha: 0.5),
            width: 0.6,
          ),
          boxShadow: primary
              ? [
                  BoxShadow(
                    color: t.accent.withValues(alpha: 0.30),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: _action == null
                ? null
                : () {
                    Haptics.selectionClick();
                    _action!();
                  },
            child: Padding(
              padding: EdgeInsets.fromLTRB(icon != null ? 10 : 14, 7, 14, 7),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                if (icon != null) ...[
                  Icon(icon, size: 15, color: fg),
                  const SizedBox(width: 5),
                ],
                Text(label,
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.1,
                        color: fg)),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

/// Centered empty / zero state with spatial glass icon holder.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;
  const EmptyState(
      {super.key,
      required this.icon,
      required this.title,
      this.message,
      this.action});

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      child: Column(children: [
        IconBadge(icon, size: 56),
        const SizedBox(height: 16),
        Text(title, textAlign: TextAlign.center, style: t.bodyStrong),
        if (message != null) ...[
          const SizedBox(height: 6),
          Text(message!, textAlign: TextAlign.center, style: t.caption),
        ],
        if (action != null) ...[const SizedBox(height: 20), action!],
      ]),
    );
  }
}

/// Inline notice with soft glass tinting.
class AppNotice extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color? color;
  const AppNotice(this.text,
      {super.key, this.icon = Icons.info_outline_rounded, this.color});

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final c = color ?? t.muted;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
      decoration: BoxDecoration(
        color: color == null ? t.fill : c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color == null ? t.glassBorder : c.withValues(alpha: 0.22),
          width: 0.6,
        ),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 16, color: c),
        const SizedBox(width: 9),
        Expanded(
            child: Text(text,
                style: t.caption.copyWith(
                    color:
                        color == null ? t.muted : c.withValues(alpha: 0.95)))),
      ]),
    );
  }
}

// ── Inputs ──────────────────────────────────────────────────────────────

/// Filled text-field decoration matching the glass aesthetic.
InputDecoration appInputDecoration(BuildContext context,
    {String? hint, String? label, Widget? suffix, Widget? prefix}) {
  final t = AppTokens.of(context);
  OutlineInputBorder b(Color c, [double w = 0]) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: w == 0 ? BorderSide.none : BorderSide(color: c, width: w));
  return InputDecoration(
    hintText: hint,
    labelText: label,
    suffixIcon: suffix,
    prefixIcon: prefix,
    filled: true,
    fillColor: t.isDark
        ? Colors.white.withValues(alpha: 0.07)
        : const Color(0xFFEBEBED),
    hintStyle: GoogleFonts.inter(fontSize: 15, color: t.faint),
    labelStyle: GoogleFonts.inter(fontSize: 14, color: t.muted),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    isDense: true,
    border: b(Colors.transparent),
    enabledBorder: b(t.glassBorder.withValues(alpha: 0.4), 0.5),
    focusedBorder: b(t.accent, 1.2),
    errorBorder: b(t.red, 1),
    focusedErrorBorder: b(t.red, 1.2),
  );
}

/// Labelled form field block: label above, field, optional helper below.
class AppField extends StatelessWidget {
  final String label;
  final Widget child;
  final String? helper;
  const AppField(
      {super.key, required this.label, required this.child, this.helper});

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 6),
        child: Text(label, style: t.label),
      ),
      child,
      if (helper != null)
        Padding(
          padding: const EdgeInsets.only(left: 4, top: 6),
          child: Text(helper!, style: t.small),
        ),
    ]);
  }
}

// ── Sheets & dialogs ────────────────────────────────────────────────────

/// Apple Glass bottom sheet with frosted backdrop blur and crystalline handle.
Future<T?> showAppSheet<T>(
  BuildContext context, {
  String? title,
  String? subtitle,
  required WidgetBuilder builder,
  bool scrollable = true,
}) {
  final t = AppTokens.of(context);
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: t.isDark ? 0.65 : 0.35),
    builder: (ctx) {
      final tt = AppTokens.of(ctx);
      final content = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null) ...[
            Text(title,
                style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                    color: tt.text)),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(subtitle, style: tt.caption),
            ],
            const SizedBox(height: 18),
          ],
          builder(ctx),
        ],
      );

      return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(
              decoration: BoxDecoration(
                color: tt.isDark
                    ? const Color(0xE8141720)
                    : Colors.white.withValues(alpha: 0.88),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border(
                  top: BorderSide(color: tt.glassSpecular, width: 0.8),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 10, bottom: 14),
                    child: Container(
                      width: 40,
                      height: 4.5,
                      decoration: BoxDecoration(
                          color: tt.outline,
                          borderRadius: BorderRadius.circular(2.5)),
                    ),
                  ),
                  Flexible(
                    child: scrollable
                        ? SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                            child: content)
                        : Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                            child: content),
                  ),
                ]),
              ),
            ),
          ),
        ),
      );
    },
  );
}

/// Two-button confirmation sheet (Cancel + confirm). Returns true on confirm.
Future<bool> confirmSheet(
  BuildContext context, {
  required String title,
  String? message,
  required String confirmLabel,
  bool destructive = false,
}) async {
  final ok = await showAppSheet<bool>(
    context,
    title: title,
    subtitle: message,
    builder: (ctx) => Row(children: [
      Expanded(
        child: TonalButton.neutral(ctx,
            label: 'Cancel', onTap: () => Navigator.pop(ctx, false)),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: destructive
            ? TonalButton.destructive(ctx,
                label: confirmLabel, onTap: () => Navigator.pop(ctx, true))
            : PrimaryButton(
                label: confirmLabel, onPressed: () => Navigator.pop(ctx, true)),
      ),
    ]),
  );
  return ok == true;
}

enum ToastTone { info, success, warning, error }

/// App-wide floating glass toast.
void showToast(
  BuildContext context,
  String title,
  String message, {
  ToastTone tone = ToastTone.info,
  Duration duration = const Duration(seconds: 3),
}) {
  final (IconData icon, Color color) = switch (tone) {
    ToastTone.success => (Icons.check_circle_rounded, const Color(0xFF30D158)),
    ToastTone.warning => (Icons.warning_amber_rounded, const Color(0xFFFF9F0A)),
    ToastTone.error => (Icons.error_rounded, const Color(0xFFFF453A)),
    ToastTone.info => (Icons.info_rounded, const Color(0xFF8E8E93)),
  };

  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      duration: duration,
      backgroundColor: Colors.transparent,
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(18, 0, 18, 20),
      padding: EdgeInsets.zero,
      content: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              color: const Color(0xE0181A22),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.18),
                width: 0.65,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white)),
                      if (message.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(message,
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                                fontSize: 13,
                                height: 1.35,
                                color: const Color(0xFFC7C7CC))),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
