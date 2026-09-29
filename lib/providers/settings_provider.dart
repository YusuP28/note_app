import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  String _sortOption = 'updated_desc';
  bool _isGrid = true;
  String _notificationSound = 'sound1'; // sound1, sound2, sound3, atau custom path

  String get sortOption => _sortOption;
  bool get isGrid => _isGrid;
  String get notificationSound => _notificationSound;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _sortOption = prefs.getString('sort_option') ?? 'updated_desc';
    _isGrid = prefs.getBool('is_grid') ?? true;
    _notificationSound = prefs.getString('notification_sound') ?? 'sound1';
    notifyListeners();
  }

  Future<void> setSortOption(String option) async {
    _sortOption = option;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sort_option', option);
  }

  Future<void> toggleViewMode() async {
    _isGrid = !_isGrid;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_grid', _isGrid);
  }

  Future<void> setNotificationSound(String sound) async {
    _notificationSound = sound;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('notification_sound', sound);
  }
}
