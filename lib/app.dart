import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'features/home/presentation/home_screen.dart';
import 'features/reader/presentation/reader_screen.dart';
import 'features/settings/presentation/settings_controller.dart';
import 'features/settings/presentation/settings_screen.dart';

class RedReaderApp extends ConsumerWidget {
  const RedReaderApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
      GoRoute(path: '/reader', builder: (_, __) => const ReaderScreen()),
      GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
    ]);

    return MaterialApp.router(
      title: 'Red Reader',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: settings.themeMode,
    );
  }
}
