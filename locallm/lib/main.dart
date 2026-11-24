import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/constants.dart';
import 'core/theme.dart';
import 'core/providers/theme_provider.dart';
import 'features/home/views/home_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive local persistence
  await Hive.initFlutter();
  await Hive.openBox(AppConstants.settingsBox);
  await Hive.openBox(AppConstants.chatSessionsBox);

  runApp(
    const ProviderScope(
      child: LocalLMApp(),
    ),
  );
}

class LocalLMApp extends ConsumerWidget {
  const LocalLMApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final fontScale = ref.watch(fontScaleProvider);

    return MaterialApp(
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
    );
  }
}
