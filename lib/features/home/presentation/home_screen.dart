import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/demo_text.dart';
import '../../reader/presentation/reader_controller.dart';
import '../../../shared/models/session.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  List<Session> sessions = const [];

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
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('REDEYE', style: TextStyle(fontSize: 42, letterSpacing: 4, fontWeight: FontWeight.w300)),
                Text('Speed reading, distilled.', style: TextStyle(fontSize: 17, color: Colors.grey))
              ]),
              IconButton(onPressed: () => context.push('/settings'), icon: const Icon(Icons.settings, size: 32)),
            ]),
            const SizedBox(height: 12),
            Wrap(spacing: 12, runSpacing: 12, children: [
              FilledButton.tonal(onPressed: _openPasteDialog, child: const Text('Paste text')),
              FilledButton.tonal(onPressed: _pickTxt, child: const Text('Upload TXT')),
              FilledButton.tonal(onPressed: _runDemo, child: const Text('Run demo')),
            ]),
            const SizedBox(height: 20),
            const Text('Library', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: sessions.length,
                itemBuilder: (_, i) {
                  final s = sessions[i];
                  return Card(
                    child: ListTile(
                      title: Text(s.title),
                      subtitle: Text('${s.position + 1} / ${s.content.split(RegExp(r'\s+')).length} • ${s.wpm} wpm'),
                      onTap: () async {
                        await ref.read(readerProvider.notifier).loadSession(s);
                        if (mounted) context.push('/reader');
                      },
                    ),
                  );
                },
              ),
            )
          ]),
        ),
      ),
    );
  }

  Future<void> _runDemo() async {
    await ref.read(readerProvider.notifier).loadText('Demo', demoText);
    if (mounted) context.push('/reader');
    await _loadSessions();
  }

  Future<void> _openPasteDialog() async {
    final controller = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Paste text'),
        content: TextField(controller: controller, minLines: 6, maxLines: 10),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
              onPressed: () async {
                if (controller.text.trim().isEmpty) return;
                await ref.read(readerProvider.notifier).loadText('Pasted text', controller.text.trim());
                if (mounted) Navigator.pop(context);
                if (mounted) context.push('/reader');
                await _loadSessions();
              },
              child: const Text('Start')),
        ],
      ),
    );
  }

  Future<void> _pickTxt() async {
    final result = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['txt']);
    if (result == null || result.files.single.path == null) return;
    final path = result.files.single.path!;
    final content = await File(path).readAsString();
    await ref.read(readerProvider.notifier).loadText(result.files.single.name, content);
    if (mounted) context.push('/reader');
    await _loadSessions();
  }
}
