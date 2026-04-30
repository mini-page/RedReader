import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'settings_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final controller = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Default WPM: ${settings.defaultWpm}'),
          Slider(
              value: settings.defaultWpm.toDouble(),
              min: 200,
              max: 900,
              divisions: 35,
              onChanged: (v) => controller.update(settings.copyWith(defaultWpm: v.round()))),
          Text('Font size: ${settings.fontSize.round()}'),
          Slider(value: settings.fontSize, min: 40, max: 90, divisions: 10, onChanged: (v) => controller.update(settings.copyWith(fontSize: v))),
          SwitchListTile(
            title: const Text('Pause on punctuation'),
            value: settings.pauseOnPunctuation,
            onChanged: (v) => controller.update(settings.copyWith(pauseOnPunctuation: v)),
          ),
          DropdownButtonFormField<ThemeMode>(
            initialValue: settings.themeMode,
            decoration: const InputDecoration(labelText: 'Theme'),
            items: const [
              DropdownMenuItem(value: ThemeMode.system, child: Text('System')),
              DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
              DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
            ],
            onChanged: (v) {
              if (v != null) controller.update(settings.copyWith(themeMode: v));
            },
          )
        ],
      ),
    );
  }
}
