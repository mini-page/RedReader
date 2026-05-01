import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../reader/presentation/reader_controller.dart';
import '../../settings/presentation/settings_controller.dart';
import '../../../core/services/ai_service.dart';

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
  bool _isLoadingAI = false;

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

  Future<void> _handleTransform(Future<String> Function(AIProvider p) action) async {
    final aiService = ref.read(aiServiceProvider);
    final provider = await aiService.getProvider();
    if (provider == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please configure Gemini API Key in Settings.')));
      return;
    }

    setState(() => _isLoadingAI = true);
    try {
      final result = await action(provider);
      if (result.isNotEmpty && mounted) {
        setState(() {
          _contentController.text = result;
          _isLoadingAI = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingAI = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('AI Error: $e')));
      }
    }
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
              color: onSurface, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: _buildCircleButton(context, LucideIcons.sparkles,
                () => _showAiMenu(context), isDark, color: const Color(0xFFFF3B3B)),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: _buildCircleButton(context, Icons.check_rounded,
                () => _saveSession(false), isDark),
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('TITLE',
                      style: TextStyle(
                          color: onSurface.withValues(alpha: 0.5),
                          fontSize: 10,
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
                          fontSize: 10,
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
            if (_isLoadingAI)
             Container(
               color: Colors.black.withValues(alpha: 0.7),
               child: const Center(
                 child: CircularProgressIndicator(
                   color: Color(0xFFFF3B3B),
                   strokeWidth: 4,
                 ),
               ),
             ),          ],
        ),
      ),
    );
  }

  void _showAiMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFF1C1C1E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            const Text('AI REFINEMENT', style: TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            const SizedBox(height: 16),
            _AiActionTile(
              icon: LucideIcons.fileText,
              title: 'Summarize',
              subtitle: 'Condense before reading',
              onTap: () {
                Navigator.pop(context);
                _handleTransform((p) => p.summarize(_contentController.text));
              },
            ),
            _AiActionTile(
              icon: LucideIcons.wand2,
              title: 'Simplify',
              subtitle: 'Easy mode reading',
              onTap: () {
                Navigator.pop(context);
                _handleTransform((p) => p.simplify(_contentController.text));
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildCircleButton(
      BuildContext context, IconData icon, VoidCallback onTap, bool isDark, {Color? color}) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.1)
            : Colors.black.withValues(alpha: 0.05),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: color ?? (isDark ? Colors.white : Colors.black), size: 20),
        onPressed: onTap,
      ),
    );
  }
}

class _AiActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _AiActionTile({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: const Color(0xFFFF3B3B), size: 20),
      ),
      title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.white60, fontSize: 12)),
      trailing: const Icon(Icons.chevron_right, color: Colors.white24),
    );
  }
}
