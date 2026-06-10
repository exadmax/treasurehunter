import 'package:flutter/material.dart';

ThemeData buildTheme() {
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFFFFB703),
      primary: const Color(0xFFFFB703),
      secondary: const Color(0xFF023047),
    ),
    useMaterial3: true,
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFFFB703),
      foregroundColor: Color(0xFF023047),
      elevation: 0,
      centerTitle: true,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFFB703),
        foregroundColor: const Color(0xFF023047),
        textStyle:
            const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        padding:
            const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    cardTheme: CardTheme(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
    ),
    fontFamily: 'Roboto',
  );
}
