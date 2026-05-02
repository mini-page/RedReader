import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../home/presentation/home_screen.dart';
import '../../settings/presentation/settings_screen.dart';
import '../../stats/presentation/stats_screen.dart';
import '../../library/presentation/library_screen.dart';
import '../../settings/presentation/settings_controller.dart';

class MainNavigationNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void set(int index) => state = index;
}

final mainNavigationProvider = NotifierProvider<MainNavigationNotifier, int>(MainNavigationNotifier.new);

class NavBarVisibilityNotifier extends Notifier<bool> {
  @override
  bool build() => true;
  set show(bool value) => state = value;
}

final navBarVisibilityProvider = NotifierProvider<NavBarVisibilityNotifier, bool>(NavBarVisibilityNotifier.new);

class MainScaffold extends ConsumerStatefulWidget {
  const MainScaffold({super.key});

  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold> {
  double _scrollOffset = 0;
  static const double _hideThreshold = 300.0; // Approx 3 cards height

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(mainNavigationProvider);
    final settings = ref.watch(settingsProvider);
    final isVisible = ref.watch(navBarVisibilityProvider);

    final screens = [
      const HomeScreen(),
      const LibraryScreen(),
      const StatsScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollUpdateNotification) {
            _handleScrollManual(notification.metrics.pixels, notification.scrollDelta ?? 0);
          }
          return false;
        },
        child: IndexedStack(
          index: currentIndex,
          children: screens,
        ),
      ),
      bottomNavigationBar: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        height: isVisible ? kBottomNavigationBarHeight + MediaQuery.of(context).padding.bottom : 0,
        child: Wrap(
          children: [
            BottomNavigationBar(
              currentIndex: currentIndex,
              onTap: (index) => ref.read(mainNavigationProvider.notifier).set(index),
              type: BottomNavigationBarType.fixed,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              selectedItemColor: const Color(0xFFFF3B3B),
              unselectedItemColor: Colors.grey,
              showSelectedLabels: settings.showNavLabels,
              showUnselectedLabels: settings.showNavLabels,
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
          ],
        ),
      ),
    );
  }

  void _handleScrollManual(double pixels, double delta) {
    final isVisible = ref.read(navBarVisibilityProvider);
    
    if (delta > 0) { // Scrolling down
      _scrollOffset += delta;
      if (_scrollOffset > _hideThreshold && isVisible) {
        ref.read(navBarVisibilityProvider.notifier).show = false;
      }
    } else if (delta < 0) { // Scrolling up
      if (!isVisible) {
        ref.read(navBarVisibilityProvider.notifier).show = true;
      }
      _scrollOffset = 0;
    }
  }
}
