import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../shared/models/app_settings.dart';

class SettingsController extends Notifier<AppSettings> {
  @override
  AppSettings build() {
    load();
    return const AppSettings();
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    state = state.copyWith(
      defaultWpm: prefs.getInt('defaultWpm') ?? state.defaultWpm,
      fontSize: prefs.getDouble('fontSize') ?? state.fontSize,
      pauseOnPunctuation: prefs.getBool('pauseOnPunctuation') ?? state.pauseOnPunctuation,
      orpColorValue: prefs.getInt('orpColorValue') ?? state.orpColorValue,
      themeMode: ThemeMode.values[prefs.getInt('themeMode') ?? state.themeMode.index],
    );
  }

  Future<void> update(AppSettings next) async {
    state = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('defaultWpm', next.defaultWpm);
    await prefs.setDouble('fontSize', next.fontSize);
    await prefs.setBool('pauseOnPunctuation', next.pauseOnPunctuation);
    await prefs.setInt('orpColorValue', next.orpColorValue);
    await prefs.setInt('themeMode', next.themeMode.index);
  }
}

final settingsProvider = NotifierProvider<SettingsController, AppSettings>(SettingsController.new);
