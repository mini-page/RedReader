import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../shared/models/app_settings.dart';

class SettingsController extends Notifier<AppSettings> {
  @override
  AppSettings build() {
    _load();
    return const AppSettings();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = state.copyWith(
      defaultWpm: prefs.getInt('defaultWpm') ?? state.defaultWpm,
      defaultChunkSize: prefs.getInt('defaultChunkSize') ?? state.defaultChunkSize,
      fontSize: prefs.getDouble('fontSize') ?? state.fontSize,
      pauseOnPunctuation: prefs.getBool('pauseOnPunctuation') ?? state.pauseOnPunctuation,
      orpColorValue: prefs.getInt('orpColorValue') ?? state.orpColorValue,
      themeMode: ThemeMode.values[prefs.getInt('themeMode') ?? state.themeMode.index],
      showOledBlack: prefs.getBool('showOledBlack') ?? state.showOledBlack,
      fontFamily: prefs.getString('fontFamily') ?? state.fontFamily,
      hasCompletedOnboarding: prefs.getBool('hasCompletedOnboarding') ?? state.hasCompletedOnboarding,
    );
  }

  Future<void> update(AppSettings next) async {
    state = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('defaultWpm', next.defaultWpm);
    await prefs.setInt('defaultChunkSize', next.defaultChunkSize);
    await prefs.setDouble('fontSize', next.fontSize);
    await prefs.setBool('pauseOnPunctuation', next.pauseOnPunctuation);
    await prefs.setInt('orpColorValue', next.orpColorValue);
    await prefs.setInt('themeMode', next.themeMode.index);
    await prefs.setBool('showOledBlack', next.showOledBlack);
    await prefs.setString('fontFamily', next.fontFamily);
    await prefs.setBool('hasCompletedOnboarding', next.hasCompletedOnboarding);
  }

  Future<void> completeOnboarding() async {
    await update(state.copyWith(hasCompletedOnboarding: true));
  }
}

final settingsProvider = NotifierProvider<SettingsController, AppSettings>(SettingsController.new);
