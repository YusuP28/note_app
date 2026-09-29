import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/notebook.dart';
import '../services/database_service.dart';

class NotebookProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  final _uuid = const Uuid();
  List<Notebook> _notebooks = [];
  bool _loading = false;

  List<Notebook> get notebooks => List.unmodifiable(_notebooks);
  bool get loading => _loading;

  List<Notebook> get roots => _notebooks.where((n) => n.parentId == null).toList();

  List<Notebook> childrenOf(String? parentId) =>
      _notebooks.where((n) => n.parentId == parentId).toList();

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    final db = await _db.database;
    final rows = await db.query('notebooks', orderBy: 'sort_order ASC, name ASC');
    _notebooks = rows.map((r) => Notebook.fromMap(r)).toList();
    _loading = false;
    notifyListeners();
  }

  Future<Notebook> add(String name, {String? parentId, int? color, String? icon}) async {
    final now = DateTime.now();
    final nb = Notebook(
      id: _uuid.v4(),
      name: name,
      parentId: parentId,
      color: color ?? 0xFF6750A4,
      icon: icon,
      createdAt: now,
      updatedAt: now,
    );
    final db = await _db.database;
    await db.insert('notebooks', nb.toMap());
    _notebooks.add(nb);
    notifyListeners();
    return nb;
  }

  Future<void> update(Notebook nb) async {
    nb.updatedAt = DateTime.now();
    final db = await _db.database;
    await db.update('notebooks', nb.toMap(), where: 'id = ?', whereArgs: [nb.id]);
    final i = _notebooks.indexWhere((n) => n.id == nb.id);
    if (i >= 0) _notebooks[i] = nb;
    notifyListeners();
  }

  Future<void> delete(String id) async {
    final db = await _db.database;
    await db.delete('notebooks', where: 'id = ?', whereArgs: [id]);
    _notebooks.removeWhere((n) => n.id == id);
    notifyListeners();
  }
}
