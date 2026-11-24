import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

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
      backgroundColor: isDark ? Colors.black : Colors.white,
      body: IndexedStack(
        index: currentTab,
        children: _views,
      ),
      bottomNavigationBar: _buildBottomNav(context, ref, currentTab, isDark),
    );
  }

  Widget _buildBottomNav(
      BuildContext context, WidgetRef ref, int current, bool isDark) {
    final accent = isDark ? const Color(0xFF0A84FF) : const Color(0xFF007AFF);
    final muted = isDark ? const Color(0xFF7C7C80) : const Color(0xFF8E8E93);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.black : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.08),
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 54,
          child: Row(
            children: [
              for (var i = 0; i < _tabs.length; i++)
                Expanded(
                  child: Semantics(
                    selected: current == i,
                    button: true,
                    label: _tabs[i].label,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        if (current != i) {
                          Haptics.selectionClick();
                          ref.read(homeTabProvider.notifier).state = i;
                        }
                      },
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 160),
                            child: Icon(
                              current == i
                                  ? _tabs[i].activeIcon
                                  : _tabs[i].icon,
                              key: ValueKey(current == i),
                              size: 23,
                              color: current == i ? accent : muted,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _tabs[i].label,
                            style: GoogleFonts.inter(
                              fontSize: 10.5,
                              letterSpacing: 0.1,
                              fontWeight: current == i
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: current == i ? accent : muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
