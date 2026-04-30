import 'package:flutter/material.dart';

class AppTheme {
  static const accent = Color(0xFFFF3B3B);

  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        useMaterial3: true,
        colorScheme: const ColorScheme.dark(primary: accent),
      );

  static ThemeData get light => ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF3F3F5),
        useMaterial3: true,
        colorScheme: const ColorScheme.light(primary: accent),
      );
}
