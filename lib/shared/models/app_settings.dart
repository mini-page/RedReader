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
  final bool hasRunDemo;
  final bool hideStatusBar;
  final bool showNavLabels;

  const AppSettings({
    this.defaultWpm = 350,
    this.defaultChunkSize = 1,
    this.fontSize = 48,
    this.pauseOnPunctuation = true,
    this.orpColorValue = 0xFFFF3B3B,
    this.themeMode = ThemeMode.dark,
    this.showOledBlack = true,
    this.fontFamily = 'Inter',
    this.hasCompletedOnboarding = false,
    this.hasRunDemo = false,
    this.hideStatusBar = false,
    this.showNavLabels = true,
  });

  factory AppSettings.initial() => const AppSettings();

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
    bool? hasRunDemo,
    bool? hideStatusBar,
    bool? showNavLabels,
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
        hasCompletedOnboarding:
            hasCompletedOnboarding ?? this.hasCompletedOnboarding,
        hasRunDemo: hasRunDemo ?? this.hasRunDemo,
        hideStatusBar: hideStatusBar ?? this.hideStatusBar,
        showNavLabels: showNavLabels ?? this.showNavLabels,
      );
}
