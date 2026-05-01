import 'package:flutter/material.dart';

class AppSettings {
  final int defaultWpm;
  final int defaultChunkSize;
  final double fontSize;
  final bool pauseOnPunctuation;
  final int orpColorValue;
  final ThemeMode themeMode;
  final bool showOledBlack;
  final String fontFamily;
  final bool hasCompletedOnboarding;

  const AppSettings({
    this.defaultWpm = 300,
    this.defaultChunkSize = 1,
    this.fontSize = 56,
    this.pauseOnPunctuation = true,
    this.orpColorValue = 0xFFFF3B3B,
    this.themeMode = ThemeMode.light,
    this.showOledBlack = true,
    this.fontFamily = 'Inter',
    this.hasCompletedOnboarding = false,
  });

  AppSettings copyWith({
    int? defaultWpm,
    int? defaultChunkSize,
    double? fontSize,
    bool? pauseOnPunctuation,
    int? orpColorValue,
    ThemeMode? themeMode,
    bool? showOledBlack,
    String? fontFamily,
    bool? hasCompletedOnboarding,
  }) =>
      AppSettings(
        defaultWpm: defaultWpm ?? this.defaultWpm,
        defaultChunkSize: defaultChunkSize ?? this.defaultChunkSize,
        fontSize: fontSize ?? this.fontSize,
        pauseOnPunctuation: pauseOnPunctuation ?? this.pauseOnPunctuation,
        orpColorValue: orpColorValue ?? this.orpColorValue,
        themeMode: themeMode ?? this.themeMode,
        showOledBlack: showOledBlack ?? this.showOledBlack,
        fontFamily: fontFamily ?? this.fontFamily,
        hasCompletedOnboarding: hasCompletedOnboarding ?? this.hasCompletedOnboarding,
      );
}
