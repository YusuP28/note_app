import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const _kMode = 'theme_mode';
  static const _kColor = 'theme_color';

  ThemeMode _mode = ThemeMode.system;
  Color _seed = const Color(0xFF6750A4);

  ThemeMode get mode => _mode;
  Color get seed => _seed;
  bool get isDark => _mode == ThemeMode.dark;

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    final modeStr = p.getString(_kMode);
    final colorVal = p.getInt(_kColor);
    _mode = switch (modeStr) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    if (colorVal != null) {
      _seed = Color(colorVal);
    }
    notifyListeners();
  }

  Future<void> setMode(ThemeMode m) async {
    _mode = m;
    final p = await SharedPreferences.getInstance();
    await p.setString(_kMode, m.name);
    notifyListeners();
  }

  Future<void> setSeed(Color c) async {
    _seed = c;
    final p = await SharedPreferences.getInstance();
    await p.setInt(_kColor, c.value);
    notifyListeners();
  }
}
