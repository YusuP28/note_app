import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum SortBy { updatedDesc, updatedAsc, createdDesc, createdAsc, titleAsc, titleDesc }
enum ViewMode { list, grid }

class SettingsProvider extends ChangeNotifier {
  static const _kSort = 'sort_by';
  static const _kView = 'view_mode';

  SortBy _sort = SortBy.updatedDesc;
  ViewMode _view = ViewMode.list;

  SortBy get sort => _sort;
  ViewMode get view => _view;

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    final s = p.getString(_kSort);
    final v = p.getString(_kView);

    _sort = SortBy.values.firstWhere((e) => e.name == s,
        orElse: () => SortBy.updatedDesc);
    _view = ViewMode.values.firstWhere((e) => e.name == v,
        orElse: () => ViewMode.list);

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
}
