import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/tag.dart';
import '../services/database_service.dart';

class TagProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  final _uuid = const Uuid();
  List<Tag> _tags = [];

  List<Tag> get tags => List.unmodifiable(_tags);

  Future<void> load() async {
    final db = await _db.database;
    final rows = await db.query('tags', orderBy: 'name ASC');
    _tags = rows.map((r) => Tag.fromMap(r)).toList();
    notifyListeners();
  }

  Future<Tag?> findByName(String name) async {
    final db = await _db.database;
    final rows = await db.query('tags',
        where: 'LOWER(name) = ?', whereArgs: [name.toLowerCase().trim()], limit: 1);
    if (rows.isEmpty) return null;
    return Tag.fromMap(rows.first);
  }

  Future<Tag> add(String name, {int? color}) async {
    final existing = await findByName(name);
    if (existing != null) return existing;
    final tag = Tag(
      id: _uuid.v4(),
      name: name.trim(),
      color: color ?? 0xFF6750A4,
      createdAt: DateTime.now(),
    );
    final db = await _db.database;
    await db.insert('tags', tag.toMap());
    _tags.add(tag);
    _tags.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    notifyListeners();
    return tag;
  }

  Future<void> update(Tag tag) async {
    final db = await _db.database;
    await db.update('tags', tag.toMap(), where: 'id = ?', whereArgs: [tag.id]);
    final i = _tags.indexWhere((t) => t.id == tag.id);
    if (i >= 0) _tags[i] = tag;
    notifyListeners();
  }

  Future<void> delete(String id) async {
    final db = await _db.database;
    await db.delete('tags', where: 'id = ?', whereArgs: [id]);
    _tags.removeWhere((t) => t.id == id);
    notifyListeners();
  }
}
