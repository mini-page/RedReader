import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../presentation/settings_controller.dart';

class LoveGalleryScreen extends ConsumerStatefulWidget {
  const LoveGalleryScreen({super.key});

  @override
  ConsumerState<LoveGalleryScreen> createState() => _LoveGalleryScreenState();
}

class _LoveGalleryScreenState extends ConsumerState<LoveGalleryScreen> with TickerProviderStateMixin {
  final List<String> _images = [
    'assets/images/galley/Lovey_0.jpg',
    'assets/images/galley/Lovey_1.jpg',
    'assets/images/galley/Lovey_2.jpg',
    'assets/images/galley/Lovey_3.jpg',
    'assets/images/galley/Lovey_4.jpg',
    'assets/images/galley/Lovey_5.jpg',
    'assets/images/galley/Lovey_6.jpg',
    'assets/images/galley/Lovey_7.jpg',
  ];

  final Map<int, String> _emojiMap = {
    0: '❤️',
    1: '💖',
    2: '💗',
    3: '💓',
    4: '💞',
    5: '💕',
    6: '💘',
    7: '💝',
  };

  final List<Widget> _emojis = [];

  void _addEmoji(Offset position, String emoji) {
    setState(() {
      _emojis.add(
        _FloatingEmoji(
          key: UniqueKey(),
          position: position,
          emoji: emoji,
          onComplete: (key) {
            setState(() {
              _emojis.removeWhere((w) => w.key == key);
            });
          },
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final isDark = settings.themeMode == ThemeMode.dark;
    final onSurface = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFF6F6F6),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: onSurface),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'For Shalu ❤️',
          style: TextStyle(color: onSurface, fontWeight: FontWeight.bold),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    children: _buildColumnItems(0),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: _buildColumnItems(1),
                  ),
                ),
              ],
            ),
          ),
          ..._emojis,
        ],
      ),
    );
  }

  List<Widget> _buildColumnItems(int columnIndex) {
    final items = <Widget>[];
    for (int i = columnIndex; i < _images.length; i += 2) {
      final index = i;
      items.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _GalleryItem(
            imagePath: _images[index],
            emoji: _emojiMap[index] ?? '❤️',
            onTap: (position) => _addEmoji(position, _emojiMap[index] ?? '❤️'),
          ),
        ),
      );
    }
    return items;
  }
}

class _GalleryItem extends StatefulWidget {
  final String imagePath;
  final String emoji;
  final Function(Offset) onTap;

  const _GalleryItem({
    required this.imagePath,
    required this.emoji,
    required this.onTap,
  });

  @override
  State<_GalleryItem> createState() => _GalleryItemState();
}

class _GalleryItemState extends State<_GalleryItem> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (details) {
        _controller.reverse();
        widget.onTap(details.globalPosition);
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.asset(
            widget.imagePath,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              height: 150,
              color: Colors.grey[300],
              child: const Icon(Icons.image_not_supported_rounded),
            ),
          ),
        ),
      ),
    );
  }
}

class _FloatingEmoji extends StatefulWidget {
  final Offset position;
  final String emoji;
  final Function(Key) onComplete;

  const _FloatingEmoji({
    super.key,
    required this.position,
    required this.emoji,
    required this.onComplete,
  });

  @override
  State<_FloatingEmoji> createState() => _FloatingEmojiState();
}

class _FloatingEmojiState extends State<_FloatingEmoji> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _yAnimation;
  late Animation<double> _opacityAnimation;
  late double _rotation;
  late double _size;
  late double _xOffset;

  @override
  void initState() {
    super.initState();
    final random = Random();
    _rotation = (random.nextDouble() - 0.5) * 0.5; // Random rotation
    _size = 24.0 + random.nextDouble() * 32.0; // Random size
    _xOffset = (random.nextDouble() - 0.5) * 100; // Random horizontal drift

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _yAnimation = Tween<double>(begin: 0, end: -300).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 40),
    ]).animate(_controller);

    _controller.forward().then((_) => widget.onComplete(widget.key!));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          left: widget.position.dx + _xOffset - (_size / 2),
          top: widget.position.dy + _yAnimation.value - (_size / 2),
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Transform.rotate(
              angle: _rotation,
              child: Text(
                widget.emoji,
                style: TextStyle(fontSize: _size),
              ),
            ),
          ),
        );
      },
    );
  }
}
