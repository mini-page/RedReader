import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../settings/presentation/settings_controller.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();

    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    await Future.delayed(const Duration(milliseconds: 2500));
    if (!mounted) return;

    final settings = ref.read(settingsProvider);
    if (settings.hasCompletedOnboarding) {
      context.go('/');
    } else {
      context.go('/onboarding');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final isDark = settings.themeMode == ThemeMode.dark;
    
    return Scaffold(
      backgroundColor: isDark ? (settings.showOledBlack ? Colors.black : const Color(0xFF121212)) : const Color(0xFFF6F6F6),
      body: Center(
        child: FadeTransition(
          opacity: _animation,
          child: ScaleTransition(
            scale: _animation,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  isDark ? 'assets/images/transparent_white_icon.png' : 'assets/images/transparent_black_icon.png',
                  width: 160,
                  height: 160,
                ),
                const SizedBox(height: 24),
                Text(
                  'iReader',
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 8,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'READ FAST, THINK DEEP',
                  style: TextStyle(
                    color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.4),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
