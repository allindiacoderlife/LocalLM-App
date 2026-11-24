import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../../core/haptics.dart';
import '../../chat/views/chat_view.dart';
import '../../models/views/models_tab_view.dart';
import '../../server/views/server_view.dart';
import '../../settings/views/settings_tab_view.dart';
import '../providers/home_tab_provider.dart';

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

class HomeView extends ConsumerWidget {
  const HomeView({super.key});

  static const _tabs = [
    _NavItem(
      icon: Icons.chat_bubble_outline_rounded,
      activeIcon: Icons.chat_bubble_rounded,
      label: 'Chat',
    ),
    _NavItem(
      icon: Icons.layers_outlined,
      activeIcon: Icons.layers_rounded,
      label: 'Models',
    ),
    _NavItem(
      icon: Icons.lan_outlined,
      activeIcon: Icons.lan_rounded,
      label: 'Server',
    ),
    _NavItem(
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings,
      label: 'Settings',
    ),
  ];

  static const _views = [
    ChatView(),
    ModelsTabView(),
    ServerView(),
    SettingsTabView(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentTab = ref.watch(homeTabProvider);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF07080A) : const Color(0xFFF3F5F8),
      extendBody: true,
      body: Stack(
        children: [
          // Ambient Spatial Glass Canvas (Soft chromatic light pools)
          Positioned(
            top: -120,
            left: -80,
            child: IgnorePointer(
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      (isDark ? const Color(0xFF0A84FF) : const Color(0xFF4FACFE))
                          .withValues(alpha: isDark ? 0.14 : 0.18),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 60,
            right: -90,
            child: IgnorePointer(
              child: Container(
                width: 340,
                height: 340,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      (isDark ? const Color(0xFF5E5CE6) : const Color(0xFFB388FF))
                          .withValues(alpha: isDark ? 0.10 : 0.14),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Views
          IndexedStack(
            index: currentTab,
            children: _views,
          ),
        ],
      ),
      bottomNavigationBar: _buildGlassDock(context, ref, currentTab, isDark),
    );
  }

  /// Floating Apple Glass Dock with liquid refraction and jelly physics (iOS 26)
  Widget _buildGlassDock(
      BuildContext context, WidgetRef ref, int current, bool isDark) {
    final accent = isDark ? const Color(0xFF0A84FF) : const Color(0xFF0071E3);
    final muted = isDark ? const Color(0xFF8E8E93) : const Color(0xFF6E6E73);

    return GlassTabBar.bottom(
      tabs: [
        for (final item in _tabs)
          GlassTab(
            icon: Icon(item.icon),
            activeIcon: Icon(item.activeIcon),
            label: item.label,
            glowColor: accent,
          ),
      ],
      selectedIndex: current,
      onTabSelected: (i) {
        Haptics.selectionClick();
        ref.read(homeTabProvider.notifier).state = i;
      },
      selectedIconColor: accent,
      selectedLabelColor: accent,
      unselectedIconColor: muted,
      unselectedLabelColor: muted,
      barHeight: 64,
      horizontalPadding: 16,
      verticalPadding: 10,
    );
  }
}
