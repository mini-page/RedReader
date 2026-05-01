import 'dart:io';

import 'package:docx_to_text/docx_to_text.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../../../core/constants/demo_text.dart';
import '../../reader/presentation/reader_controller.dart';
import '../../settings/presentation/settings_controller.dart';
import '../../../shared/models/session.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  List<Session> sessions = const [];
  bool _isExtracting = false;

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
      backgroundColor: isDark ? (settings.showOledBlack ? Colors.black : const Color(0xFF121212)) : const Color(0xFFF6F6F6),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, onSurface, isDark),
                  const SizedBox(height: 32),
                  if (latestSession != null) ...[
                    _buildContinueReading(latestSession, onSurface, isDark),
                    const SizedBox(height: 24),
                  ],
                  _buildActionGrid(onSurface, isDark),
                  const SizedBox(height: 24),
                  _buildDemoBar(onSurface, isDark),
                  const SizedBox(height: 40),
                  _buildLibraryHeader(onSurface),
                  const SizedBox(height: 16),
                  if (sessions.isEmpty)
                    _buildEmptyLibrary(onSurface, isDark)
                  else
                    ...sessions.skip(latestSession != null ? 1 : 0).map((s) => _buildSessionCard(s, onSurface, isDark)),
                ],
              ),
            ),
            if (_isExtracting)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Color(0xFFFF3B3B)),
                      SizedBox(height: 16),
                      Text('Extracting text...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
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
            Image.asset('assets/images/app_icon.png', width: 32, height: 32),
            const SizedBox(width: 12),
            Text(
              'RedReader',
              style: TextStyle(
                fontSize: 24,
                letterSpacing: 3,
                fontWeight: FontWeight.w900,
                color: onSurface.withOpacity(0.9),
              ),
            ),
          ],
        ),
        Row(
          children: [
            _buildCircleIconButton(
              isDark ? Icons.wb_sunny_outlined : Icons.nightlight_round_outlined,
              onSurface,
              () => controller.update(settings.copyWith(themeMode: isDark ? ThemeMode.light : ThemeMode.dark)),
            ),
            const SizedBox(width: 12),
            _buildCircleIconButton(Icons.settings_outlined, onSurface, () async {
              await context.push('/settings');
              _loadSessions();
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildCircleIconButton(IconData icon, Color onSurface, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        color: onSurface.withOpacity(0.05),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: onSurface.withOpacity(0.8), size: 24),
        onPressed: onPressed,
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
        Text(
          'CONTINUE READING',
          style: TextStyle(
            fontSize: 12,
            letterSpacing: 1.5,
            color: onSurface.withOpacity(0.3),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            session.title,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${(progress * 100).toInt()}% • $totalWords words',
                            style: TextStyle(
                              fontSize: 15,
                              color: onSurface.withOpacity(0.5),
                            ),
                          ),
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
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF3B3B),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 36),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 4,
                  width: double.infinity,
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: progress,
                    child: Container(color: const Color(0xFFFF3B3B)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyLibrary(Color onSurface, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: onSurface.withOpacity(0.1),
          width: 1.5,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          Text(
            'No sessions yet',
            style: TextStyle(
              color: onSurface.withOpacity(0.6),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Paste an article or upload a file to start reading.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: onSurface.withOpacity(0.4),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionGrid(Color onSurface, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _buildActionCard(
            'Paste text',
            'From clipboard or type',
            Icons.edit_note_rounded,
            const Color(0xFFFF3B3B),
            onSurface,
            isDark,
            _openPasteDialog,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildActionCard(
            'Upload file',
            'PDF, DOCX, TXT',
            Icons.insert_drive_file_outlined,
            onSurface.withOpacity(0.1),
            onSurface,
            isDark,
            _pickFiles,
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard(String title, String subtitle, IconData icon, Color iconBg, Color onSurface, bool isDark, VoidCallback onTap) {
    final cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: iconBg == const Color(0xFFFF3B3B) ? Colors.white : onSurface, size: 28),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 13,
                color: onSurface.withOpacity(0.4),
              ),
            ),
          ],
        ),
      ),
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
          boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            const Icon(Icons.bolt, color: Color(0xFFFF3B3B), size: 24),
            const SizedBox(width: 12),
            Text(
              'Try a 60-second demo',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLibraryHeader(Color onSurface) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'LIBRARY',
          style: TextStyle(
            fontSize: 12,
            letterSpacing: 1.5,
            color: onSurface.withOpacity(0.3),
            fontWeight: FontWeight.bold,
          ),
        ),
        if (sessions.isNotEmpty)
          Text(
            '${sessions.length} items',
            style: TextStyle(
              fontSize: 12,
              color: onSurface.withOpacity(0.3),
            ),
          ),
      ],
    );
  }

  Widget _buildSessionCard(Session session, Color onSurface, bool isDark) {
    final totalWords = session.content.split(RegExp(r'\s+')).length;
    final progress = ((session.position + 1) / totalWords).clamp(0.0, 1.0);
    final cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 5, offset: const Offset(0, 2))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            title: Text(
              session.title,
              style: TextStyle(color: onSurface, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${(progress * 100).toInt()}% • $totalWords words • ${session.wpm} wpm',
              style: TextStyle(color: onSurface.withOpacity(0.5), fontSize: 13),
            ),
            trailing: Icon(Icons.chevron_right, color: onSurface.withOpacity(0.2)),
            onTap: () async {
              await ref.read(readerProvider.notifier).loadSession(session);
              if (mounted) {
                await context.push('/reader');
                _loadSessions();
              }
            },
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 3,
              width: double.infinity,
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: progress,
                child: Container(color: const Color(0xFFFF3B3B).withOpacity(0.7)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _runDemo() async {
    final settings = ref.read(settingsProvider);
    await ref.read(readerProvider.notifier).loadText('Welcome to RedReader', demoText, wpm: settings.defaultWpm);
    if (mounted) {
      await context.push('/reader');
      _loadSessions();
    }
  }

  Future<void> _openPasteDialog() async {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = isDark ? Colors.white : Colors.black;
    final cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Paste text', style: TextStyle(color: onSurface, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              autofocus: true,
              style: TextStyle(color: onSurface),
              decoration: InputDecoration(
                hintText: 'Enter title (Mandatory)',
                hintStyle: TextStyle(color: onSurface.withOpacity(0.3)),
                filled: true,
                fillColor: onSurface.withOpacity(0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: contentController,
              minLines: 6,
              maxLines: 10,
              style: TextStyle(color: onSurface),
              decoration: InputDecoration(
                hintText: 'Type or paste content here...',
                hintStyle: TextStyle(color: onSurface.withOpacity(0.3)),
                filled: true,
                fillColor: onSurface.withOpacity(0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFFFF3B3B), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: () async {
                if (titleController.text.trim().isEmpty || contentController.text.trim().isEmpty) return;
                final settings = ref.read(settingsProvider);
                await ref.read(readerProvider.notifier).loadText(titleController.text.trim(), contentController.text.trim(), wpm: settings.defaultWpm);
                if (mounted) {
                  Navigator.pop(context);
                  await context.push('/reader');
                  _loadSessions();
                }
              },
              child: const Text('Start')),
        ],
      ),
    );
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['txt', 'pdf', 'docx'],
    );
    if (result == null || result.files.single.path == null) return;

    setState(() => _isExtracting = true);
    final file = File(result.files.single.path!);
    final extension = result.files.single.extension?.toLowerCase();
    String content = '';
    String title = result.files.single.name;

    try {
      if (extension == 'txt') {
        content = await file.readAsString();
      } else if (extension == 'pdf') {
        final PdfDocument document = PdfDocument(inputBytes: await file.readAsBytes());
        content = PdfTextExtractor(document).extractText();
        document.dispose();
      } else if (extension == 'docx') {
        final bytes = await file.readAsBytes();
        content = docxToText(bytes);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error reading file: $e')));
    }

    setState(() => _isExtracting = false);

    if (content.trim().isNotEmpty) {
      final settings = ref.read(settingsProvider);
      await ref.read(readerProvider.notifier).loadText(title, content, wpm: settings.defaultWpm);
      if (mounted) {
        await context.push('/reader');
        _loadSessions();
      }
    }
  }
}
