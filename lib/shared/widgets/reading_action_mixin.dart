import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:docx_to_text/docx_to_text.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:go_router/go_router.dart';

import 'package:red_reader/core/services/ai_service.dart';
import 'package:red_reader/features/home/data/sessions_provider.dart';
import 'package:red_reader/core/services/article_service.dart';

mixin ReadingActionMixin<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  bool isProcessing = false;
  String processingLabel = 'EXTRACTING KNOWLEDGE';
  final _articleService = ArticleService();

  void setProcessing(bool value, [String label = 'EXTRACTING KNOWLEDGE']) {
    if (mounted) {
      setState(() {
        isProcessing = value;
        processingLabel = label;
      });
    }
  }

  void _showThemedSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message, 
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black, 
            fontWeight: FontWeight.bold,
            fontSize: 13,
          )
        ),
        backgroundColor: isError 
            ? const Color(0xFFFF3B3B) 
            : (isDark ? const Color(0xFF2C2C2E) : Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 10,
        margin: const EdgeInsets.all(20),
      ),
    );
  }

  Future<void> handleAiAction(Future<String> Function(AIProvider p) action, String label) async {
    final aiService = ref.read(aiServiceProvider);
    final provider = await aiService.getProvider();
    if (provider == null) {
      if (mounted) _showThemedSnackBar('AI not configured in settings.', isError: true);
      return;
    }

    setProcessing(true, label);
    try {
      final result = await action(provider);
      if (mounted) {
        context.push('/preview', extra: {'title': 'AI Generated', 'content': result, 'id': null});
        ref.invalidate(sessionsProvider);
      }
    } catch (e) {
      if (mounted) _showThemedSnackBar('AI Error: $e', isError: true);
    } finally {
      setProcessing(false);
    }
  }

  Future<void> pickFiles() async {
    final result = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['txt', 'pdf', 'docx']);
    if (result == null || result.files.single.path == null) return;

    setProcessing(true, 'EXTRACTING FILE');
    final file = File(result.files.single.path!);
    final extension = result.files.single.extension?.toLowerCase();
    String content = '';
    // Strip extension from name
    String title = result.files.single.name;
    if (title.contains('.')) {
      title = title.substring(0, title.lastIndexOf('.'));
    }

    try {
      if (extension == 'txt') {
        content = await file.readAsString();
      } else if (extension == 'pdf') {
        final PdfDocument document = PdfDocument(inputBytes: await file.readAsBytes());
        content = PdfTextExtractor(document).extractText();
        document.dispose();
      } else if (extension == 'docx') {
        content = docxToText(await file.readAsBytes());
      }
    } catch (e) {
      if (mounted) _showThemedSnackBar('File Error: $e', isError: true);
    }

    setProcessing(false);
    if (content.trim().isNotEmpty && mounted) {
      context.push('/preview', extra: {'title': title, 'content': content, 'id': null});
      
      // Use post frame to avoid element list conflict
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(sessionsProvider.notifier).refresh();
        }
      });
    }
  }

  void showInputDialog({required String title, required String hint, required String actionLabel, required Function(String) onConfirm}) {
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

  void showTopicDialog() {
    showInputDialog(
      title: 'AI Topic Generator',
      hint: 'Enter any topic (e.g. Quantum Physics)',
      actionLabel: 'Generate',
      onConfirm: (val) => handleAiAction((p) => p.generateTopic(val), 'RESEARCHING TOPIC'),
    );
  }

  void showWikiDialog() {
    showInputDialog(
      title: 'Wikipedia Fetcher',
      hint: 'Article title...',
      actionLabel: 'Fetch',
      onConfirm: (val) => handleAiAction((p) => p.fetchWikipedia(val), 'ACCESSING KNOWLEDGE'),
    );
  }

  void showUrlDialog() {
    showInputDialog(
      title: 'URL Reader',
      hint: 'https://...',
      actionLabel: 'Extract',
      onConfirm: (val) => extractAndRead(val),
    );
  }

  Future<void> extractAndRead(String url) async {
    setProcessing(true, 'PARSING WEBPAGE');
    try {
      final article = await _articleService.extractFromUrl(url);
      if (article != null && article.content.trim().isNotEmpty) {
        if (mounted) {
          context.push('/preview', extra: {'title': article.title, 'content': article.content, 'id': null});
          ref.invalidate(sessionsProvider);
        }
      } else {
        if (mounted) _showThemedSnackBar('Could not extract main content from this URL.', isError: true);
      }
    } catch (e) {
      if (mounted) _showThemedSnackBar('Network/Parsing Error: $e', isError: true);
    } finally {
      setProcessing(false);
    }
  }
}
