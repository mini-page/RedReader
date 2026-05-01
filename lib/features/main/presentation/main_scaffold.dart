import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../home/presentation/home_screen.dart';
import '../../settings/presentation/settings_screen.dart';
import '../../stats/presentation/stats_screen.dart';
import '../../library/presentation/library_screen.dart';

class MainNavigationNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void set(int index) => state = index;
}

final mainNavigationProvider = NotifierProvider<MainNavigationNotifier, int>(MainNavigationNotifier.new);

class MainScaffold extends ConsumerWidget {
  const MainScaffold({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(mainNavigationProvider);

    final screens = [
      const HomeScreen(),
      const LibraryScreen(),
      const StatsScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) => ref.read(mainNavigationProvider.notifier).set(index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        selectedItemColor: const Color(0xFFFF3B3B),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.bookOpen),
            label: 'Library',
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.barChart2),
            label: 'Stats',
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
