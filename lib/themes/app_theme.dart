import 'package:flutter/material.dart';
import 'neumo.dart';

class AppTheme {
  static ThemeData light(Color seed) => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: Neumo.lightBg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.light,
          surface: Neumo.lightBg,
        ),
      );

  static ThemeData dark(Color seed) => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Neumo.darkBg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.dark,
          surface: Neumo.darkBg,
        ),
      );
}
