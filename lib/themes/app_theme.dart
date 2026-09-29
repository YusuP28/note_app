import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData light(Color seed) => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(seedColor: seed),
      );

  static ThemeData dark(Color seed) => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.dark),
      );
}
