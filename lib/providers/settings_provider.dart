import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum SortBy {
  updatedDesc,
  updatedAsc,
  createdDesc,
  createdAsc,
  titleAsc,
  titleDesc,
}

enum ViewMode { list, grid }

class SettingsProvider extends ChangeNotifier {
  static const _kSort = 'sort_by';
  static const _kView = 'view_mode';
  static const _kSound = 'notification_sound';
  static const _kAutoBackupDays = 'auto_backup_days';
  static const _kLastAutoBackup = 'last_auto_backup';

  SortBy _sort = SortBy.updatedDesc;
  ViewMode _view = ViewMode.list;
  String _notificationSound = 'sound1';
  int _autoBackupDays = 0; // 0 = off
  int _lastAutoBackupMs = 0;

  SortBy get sort => _sort;
  ViewMode get view => _view;
  String get notificationSound => _notificationSound;
  int get autoBackupDays => _autoBackupDays;
  bool get autoBackupEnabled => _autoBackupDays > 0;
  DateTime? get lastAutoBackup => _lastAutoBackupMs > 0
      ? DateTime.fromMillisecondsSinceEpoch(_lastAutoBackupMs)
      : null;

  // Alias untuk kompatibilitas (kalau ada yang pakai isGrid)
  bool get isGrid => _view == ViewMode.grid;
  String get sortOption => _sort.name;

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    final s = p.getString(_kSort);
    final v = p.getString(_kView);
    final snd = p.getString(_kSound);

    _sort = SortBy.values.firstWhere(
      (e) => e.name == s,
      orElse: () => SortBy.updatedDesc,
    );
    _view = ViewMode.values.firstWhere(
      (e) => e.name == v,
      orElse: () => ViewMode.list,
    );
    _notificationSound = snd ?? 'sound1';
    _autoBackupDays = p.getInt(_kAutoBackupDays) ?? 0;
    _lastAutoBackupMs = p.getInt(_kLastAutoBackup) ?? 0;

    notifyListeners();
  }

  Future<void> setSort(SortBy s) async {
    _sort = s;
    final p = await SharedPreferences.getInstance();
    await p.setString(_kSort, s.name);
    notifyListeners();
  }

  Future<void> setView(ViewMode v) async {
    _view = v;
    final p = await SharedPreferences.getInstance();
    await p.setString(_kView, v.name);
    notifyListeners();
  }

  Future<void> toggleView() async {
    await setView(_view == ViewMode.list ? ViewMode.grid : ViewMode.list);
  }

  Future<void> setAutoBackupDays(int days) async {
    _autoBackupDays = days;
    final p = await SharedPreferences.getInstance();
    await p.setInt(_kAutoBackupDays, days);
    notifyListeners();
  }

  Future<void> setLastAutoBackup(DateTime t) async {
    _lastAutoBackupMs = t.millisecondsSinceEpoch;
    final p = await SharedPreferences.getInstance();
    await p.setInt(_kLastAutoBackup, _lastAutoBackupMs);
    notifyListeners();
  }

  /// Cek apakah harus auto-backup sekarang
  bool shouldAutoBackup() {
    if (!autoBackupEnabled) return false;
    final last = lastAutoBackup;
    if (last == null) return true;
    return DateTime.now().difference(last).inDays >= _autoBackupDays;
  }

  Future<void> setNotificationSound(String sound) async {
    _notificationSound = sound;
    final p = await SharedPreferences.getInstance();
    await p.setString(_kSound, sound);
    notifyListeners();
  }

  // Kompatibilitas dengan versi lama (String-based)
  Future<void> setSortOption(String option) async {
    final s = SortBy.values.firstWhere(
      (e) => e.name == option,
      orElse: () => SortBy.updatedDesc,
    );
    await setSort(s);
  }
}
