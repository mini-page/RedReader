import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../reader/presentation/reader_controller.dart';
import '../../settings/presentation/settings_controller.dart';

class PreviewScreen extends ConsumerStatefulWidget {
  final String? sessionId;
  final String initialTitle;
  final String initialContent;

  const PreviewScreen({
    super.key,
    this.sessionId,
    required this.initialTitle,
    required this.initialContent,
  });

  @override
  ConsumerState<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends ConsumerState<PreviewScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
    _contentController = TextEditingController(text: widget.initialContent);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _saveSession(bool startReading) async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    final settings = ref.read(settingsProvider);

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide a title.')),
      );
      return;
    }

    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Content cannot be empty.')),
      );
      return;
    }

    if (widget.sessionId != null) {
      await ref
          .read(sessionRepositoryProvider)
          .update(widget.sessionId!, title: title, content: content);
    }

    if (startReading) {
      await ref
          .read(readerProvider.notifier)
          .loadText(title, content, wpm: settings.defaultWpm);
      if (mounted) context.pushReplacement('/reader');
    } else {
      if (widget.sessionId == null) {
        await ref
            .read(sessionRepositoryProvider)
            .create(title: title, content: content, wpm: settings.defaultWpm);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session saved to library.')),
        );
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final isDark = settings.themeMode == ThemeMode.dark;
    final onSurface = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: isDark
          ? (settings.showOledBlack ? Colors.black : const Color(0xFF121212))
          : const Color(0xFFF6F6F6),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: _buildCircleButton(
              context, Icons.arrow_back_rounded, () => context.pop(), isDark),
        ),
        title: Text(
          widget.sessionId != null ? 'Edit Document' : 'Preview Extraction',
          style: TextStyle(
              color: onSurface, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: _buildCircleButton(context, Icons.check_rounded,
                () => _saveSession(false), isDark),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('TITLE',
                  style: TextStyle(
                      color: onSurface.withValues(alpha: 0.5),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2)),
              const SizedBox(height: 8),
              TextField(
                controller: _titleController,
                style: TextStyle(
                    color: onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: onSurface.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
              const SizedBox(height: 24),
              Text('CONTENT',
                  style: TextStyle(
                      color: onSurface.withValues(alpha: 0.5),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2)),
              const SizedBox(height: 8),
              Expanded(
                child: TextField(
                  controller: _contentController,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  style: TextStyle(color: onSurface, fontSize: 16, height: 1.5),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: onSurface.withValues(alpha: 0.05),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFFF3B3B),
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                ),
                onPressed: () => _saveSession(true),
                child: const Text('Start Reading',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCircleButton(
      BuildContext context, IconData icon, VoidCallback onTap, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.1)
            : Colors.black.withValues(alpha: 0.05),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: isDark ? Colors.white : Colors.black, size: 20),
        onPressed: onTap,
      ),
    );
  }
}
