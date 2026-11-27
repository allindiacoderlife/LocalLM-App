import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import 'core/constants.dart';
import 'core/theme.dart';
import 'core/ui.dart' show AppGlassScope;
import 'core/providers/theme_provider.dart';
import 'features/home/views/home_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Apple Liquid Glass engine & pre-warm shaders (with timeout/guard)
  try {
    await LiquidGlassWidgets.initialize().timeout(const Duration(seconds: 3));
  } catch (e) {
    debugPrint('[LocalLM] LiquidGlass init skipped/error: $e');
  }

  // Initialize Hive local persistence
  try {
    await Hive.initFlutter();
    await Hive.openBox(AppConstants.settingsBox);
    await Hive.openBox(AppConstants.chatSessionsBox);
  } catch (e) {
    debugPrint('[LocalLM] Hive init error: $e');
  }

  runApp(
    LiquidGlassWidgets.wrap(
      brightnessResolver: Theme.maybeBrightnessOf,
      child: const ProviderScope(
        child: LocalLMApp(),
      ),
    ),
  );
}

class LocalLMApp extends ConsumerWidget {
  const LocalLMApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final fontScale = ref.watch(fontScaleProvider);
    final glassEnabled =
        !Platform.isAndroid || ref.watch(glassUiEnabledProvider);

    return AppGlassScope(
      enabled: glassEnabled,
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeMode,
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(fontScale),
            ),
            child: child ?? const SizedBox.shrink(),
          );
        },
        home: const HomeView(),
      ),
    );
  }
}
