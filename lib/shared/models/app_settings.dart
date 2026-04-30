import 'package:flutter/material.dart';

class AppSettings {
  final int defaultWpm;
  final double fontSize;
  final bool pauseOnPunctuation;
  final int orpColorValue;
  final ThemeMode themeMode;

  const AppSettings({
    this.defaultWpm = 550,
    this.fontSize = 72,
    this.pauseOnPunctuation = true,
    this.orpColorValue = 0xFFFF3B3B,
    this.themeMode = ThemeMode.dark,
  });

  AppSettings copyWith({int? defaultWpm, double? fontSize, bool? pauseOnPunctuation, int? orpColorValue, ThemeMode? themeMode}) => AppSettings(
        defaultWpm: defaultWpm ?? this.defaultWpm,
        fontSize: fontSize ?? this.fontSize,
        pauseOnPunctuation: pauseOnPunctuation ?? this.pauseOnPunctuation,
        orpColorValue: orpColorValue ?? this.orpColorValue,
        themeMode: themeMode ?? this.themeMode,
      );
}
