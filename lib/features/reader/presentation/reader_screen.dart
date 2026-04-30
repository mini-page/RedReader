import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../settings/presentation/settings_controller.dart';
import 'reader_controller.dart';

class ReaderScreen extends ConsumerWidget {
  const ReaderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(readerProvider);
    final controller = ref.read(readerProvider.notifier);
    final settings = ref.watch(settingsProvider);
    final token = state.current;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 30),
            Text('${state.index + 1} / ${state.tokens.length}', style: const TextStyle(color: Colors.grey, fontSize: 24)),
            const Spacer(),
            Center(
              child: SizedBox(
                width: 340,
                height: 180,
                child: RepaintBoundary(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 80),
                    child: token == null
                        ? const SizedBox.shrink()
                        : _WordView(
                            key: ValueKey('${state.index}:${token.word}'),
                            word: token.word,
                            orpIndex: token.orpIndex,
                            fontSize: settings.fontSize,
                            orpColor: Color(settings.orpColorValue),
                          ),
                  ),
                ),
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Slider(value: state.wpm.toDouble(), min: 200, max: 900, divisions: 35, label: '${state.wpm} wpm', onChanged: controller.setWpm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(onPressed: () => controller.previous(), icon: const Icon(Icons.skip_previous, size: 38)),
                      IconButton(onPressed: () => state.isPlaying ? controller.pause() : controller.play(), icon: Icon(state.isPlaying ? Icons.pause_circle : Icons.play_circle, size: 72)),
                      IconButton(onPressed: () => controller.next(), icon: const Icon(Icons.skip_next, size: 38)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _WordView extends StatelessWidget {
  final String word;
  final int orpIndex;
  final double fontSize;
  final Color orpColor;

  const _WordView({super.key, required this.word, required this.orpIndex, required this.fontSize, required this.orpColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(word.length, (i) {
        return Text(
          word[i],
          style: TextStyle(
            fontSize: fontSize,
            height: 1,
            fontWeight: FontWeight.w500,
            color: i == orpIndex ? orpColor : Colors.white,
          ),
        );
      }),
    );
  }
}
