import 'dart:io';
import 'dart:async';
import 'dart:math' as math;

import 'package:docx_to_text/docx_to_text.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:red_reader/core/constants/demo_text.dart';
import 'package:red_reader/features/reader/presentation/reader_controller.dart';
import 'package:red_reader/features/settings/presentation/settings_controller.dart';
import 'package:red_reader/shared/models/session.dart';
import 'package:red_reader/core/services/ai_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  List<Session> sessions = const [];
  bool _isProcessing = false;
  String _processingLabel = 'EXTRACTING KNOWLEDGE';

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    sessions = await ref.read(sessionRepositoryProvider).all();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final latestSession = sessions.isNotEmpty ? sessions.first : null;
    final settings = ref.watch(settingsProvider);
    final isDark = settings.themeMode == ThemeMode.dark;
    final onSurface = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: isDark
          ? (settings.showOledBlack ? Colors.black : const Color(0xFF121212))
          : const Color(0xFFF6F6F6),
      body: SafeArea(
        child: Stack(
          children: [
            CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: _buildHeader(context, onSurface, isDark),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _buildActionSlider(onSurface, isDark),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      if (latestSession != null) ...[
                        _buildContinueReading(latestSession, onSurface, isDark),
                        const SizedBox(height: 32),
                      ],
                      if (!settings.hasRunDemo) ...[
                        _buildDemoBar(onSurface, isDark),
                        const SizedBox(height: 40),
                      ],
                      const SizedBox(height: 100),
                    ]),
                  ),
                ),
              ],
            ),
            if (_isProcessing) _buildProcessingOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Color onSurface, bool isDark) {
    final controller = ref.read(settingsProvider.notifier);
    final settings = ref.read(settingsProvider);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Image.asset(
              isDark ? 'assets/images/transparent_white_icon.png' : 'assets/images/transparent_black_icon.png',
              width: 40,
              height: 40,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('i', style: GoogleFonts.lexend(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFFFF3B3B), letterSpacing: 0.5)),
                    Text('Reader', style: GoogleFonts.lexend(fontSize: 24, fontWeight: FontWeight.bold, color: onSurface, letterSpacing: 0.5)),
                  ],
                ),
                Text('READ FAST, THINK DEEP', style: GoogleFonts.lexend(fontSize: 9, fontWeight: FontWeight.w600, color: onSurface.withValues(alpha: 0.4), letterSpacing: 1.2)),
              ],
            ),
          ],
        ),
        _buildCircleIconButton(
          isDark ? Icons.wb_sunny_outlined : Icons.nightlight_round_outlined,
          onSurface,
          () => controller.update(settings.copyWith(themeMode: isDark ? ThemeMode.light : ThemeMode.dark)),
        ),
      ],
    );
  }

  Widget _buildCircleIconButton(IconData icon, Color onSurface, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(color: onSurface.withValues(alpha: 0.05), shape: BoxShape.circle),
      child: IconButton(icon: Icon(icon, color: onSurface.withValues(alpha: 0.8), size: 24), onPressed: onPressed),
    );
  }

  Widget _buildActionSlider(Color onSurface, bool isDark) {
    return SizedBox(
      height: 180,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          _buildActionCard('Paste text', 'Direct edit', LucideIcons.clipboardSignature, const Color(0xFFFF3B3B), onSurface, isDark, () => context.push('/preview', extra: {'title': '', 'content': '', 'id': null})),
          const SizedBox(width: 16),
          _buildActionCard('Upload file', 'PDF, DOCX, TXT', LucideIcons.fileUp, onSurface.withValues(alpha: 0.1), onSurface, isDark, _pickFiles),
          const SizedBox(width: 16),
          _buildActionCard('AI Topic', 'Generate article', LucideIcons.sparkles, const Color(0xFFFF3B3B), onSurface, isDark, _showTopicDialog),
          const SizedBox(width: 16),
          _buildActionCard('Wikipedia', 'Fetch article', LucideIcons.globe, onSurface.withValues(alpha: 0.1), onSurface, isDark, _showWikiDialog),
          const SizedBox(width: 16),
          _buildActionCard('URL Reader', 'Extract text', LucideIcons.link, onSurface.withValues(alpha: 0.1), onSurface, isDark, _showUrlDialog),
          const SizedBox(width: 16),
          _buildActionCard('Random', 'Unread discovery', LucideIcons.shuffle, onSurface.withValues(alpha: 0.1), onSurface, isDark, _pickRandomUnread),
          const SizedBox(width: 20),
        ],
      ),
    );
  }

  Widget _buildActionCard(String title, String subtitle, IconData icon, Color iconBg, Color onSurface, bool isDark, VoidCallback onTap) {
    final cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(16)),
              child: Icon(icon, color: iconBg == const Color(0xFFFF3B3B) ? Colors.white : onSurface, size: 24),
            ),
            const SizedBox(height: 16),
            Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: onSurface)),
            const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(fontSize: 12, color: onSurface.withValues(alpha: 0.4))),
          ],
        ),
      ),
    );
  }

  Widget _buildContinueReading(Session session, Color onSurface, bool isDark) {
    final totalWords = session.content.split(RegExp(r'\s+')).length;
    final progress = ((session.position + 1) / totalWords).clamp(0.0, 1.0);
    final cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('CONTINUE READING', style: TextStyle(fontSize: 12, letterSpacing: 1.5, color: onSurface.withValues(alpha: 0.3), fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(session.title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: onSurface)),
                          const SizedBox(height: 4),
                          Text('${(progress * 100).toInt()}% • $totalWords words', style: TextStyle(fontSize: 14, color: onSurface.withValues(alpha: 0.5))),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () async {
                        await ref.read(readerProvider.notifier).loadSession(session);
                        if (mounted) {
                          await context.push('/reader');
                          _loadSessions();
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(color: Color(0xFFFF3B3B), shape: BoxShape.circle),
                        child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 24),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 24, right: 24, bottom: 20),
                child: Container(
                  height: 6,
                  width: double.infinity,
                  decoration: BoxDecoration(color: onSurface.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(3)),
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: progress,
                    child: Container(decoration: BoxDecoration(color: const Color(0xFFFF3B3B), borderRadius: BorderRadius.circular(3))),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDemoBar(Color onSurface, bool isDark) {
    final cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    return GestureDetector(
      onTap: _runDemo,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            const Icon(Icons.bolt, color: Color(0xFFFF3B3B), size: 24),
            const SizedBox(width: 12),
            Text('Try a 60-second demo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: onSurface)),
          ],
        ),
      ),
    );
  }

  Widget _buildProcessingOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.85),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                color: Color(0xFFFF3B3B),
                strokeWidth: 4,
              ),
            ),
            const SizedBox(height: 32),
            Text(_processingLabel, style: const TextStyle(color: Color(0xFFFF3B3B), fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: 14)),
            const SizedBox(height: 8),
            Text('Synthesizing content neurons...', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
          ],
        ),
      ),
    );
  }

  void _showTopicDialog() {
    _showInputDialog(
      title: 'AI Topic Generator',
      hint: 'Enter any topic (e.g. Quantum Physics)',
      actionLabel: 'Generate',
      onConfirm: (val) => _handleAiAction((p) => p.generateTopic(val), 'RESEARCHING TOPIC'),
    );
  }

  void _showWikiDialog() {
    _showInputDialog(
      title: 'Wikipedia Fetcher',
      hint: 'Article title...',
      actionLabel: 'Fetch',
      onConfirm: (val) => _handleAiAction((p) => p.fetchWikipedia(val), 'ACCESSING KNOWLEDGE'),
    );
  }

  void _showUrlDialog() {
    _showInputDialog(
      title: 'URL Reader',
      hint: 'https://...',
      actionLabel: 'Extract',
      onConfirm: (val) => _handleAiAction((p) => p.fetchUrl(val), 'PARSING WEBPAGE'),
    );
  }

  void _showInputDialog({required String title, required String hint, required String actionLabel, required Function(String) onConfirm}) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(controller: controller, decoration: InputDecoration(hintText: hint)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () { Navigator.pop(context); onConfirm(controller.text.trim()); }, child: Text(actionLabel)),
        ],
      ),
    );
  }

  Future<void> _handleAiAction(Future<String> Function(AIProvider p) action, String label) async {
    final aiService = ref.read(aiServiceProvider);
    final provider = await aiService.getProvider();
    if (provider == null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('AI not configured in settings.')));
      return;
    }

    setState(() { _isProcessing = true; _processingLabel = label; });
    try {
      final result = await action(provider);
      if (mounted) {
        context.push('/preview', extra: {'title': 'AI Generated', 'content': result, 'id': null});
        _loadSessions();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _pickRandomUnread() {
    if (sessions.isEmpty) return;
    final unread = sessions.where((s) => s.position == 0).toList();
    final list = unread.isEmpty ? sessions : unread;
    final random = list[math.Random().nextInt(list.length)];
    ref.read(readerProvider.notifier).loadSession(random);
    context.push('/reader');
  }

  Future<void> _runDemo() async {
    final settings = ref.read(settingsProvider);
    await ref.read(readerProvider.notifier).loadText('Welcome to iReader', demoText, wpm: settings.defaultWpm);
    if (mounted) {
      await context.push('/reader');
      ref.read(settingsProvider.notifier).completeDemo();
      _loadSessions();
    }
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['txt', 'pdf', 'docx']);
    if (result == null || result.files.single.path == null) return;

    setState(() { _isProcessing = true; _processingLabel = 'EXTRACTING FILE'; });
    final file = File(result.files.single.path!);
    final extension = result.files.single.extension?.toLowerCase();
    String content = '';
    String title = result.files.single.name;

    try {
      if (extension == 'txt') content = await file.readAsString();
      else if (extension == 'pdf') {
        final PdfDocument document = PdfDocument(inputBytes: await file.readAsBytes());
        content = PdfTextExtractor(document).extractText();
        document.dispose();
      } else if (extension == 'docx') content = docxToText(await file.readAsBytes());
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error reading file: $e')));
    }

    setState(() => _isProcessing = false);
    if (content.trim().isNotEmpty && mounted) {
      context.push('/preview', extra: {'title': title, 'content': content, 'id': null});
      _loadSessions();
    }
  }
}
