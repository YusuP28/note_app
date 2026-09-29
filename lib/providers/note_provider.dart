import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/note.dart';
import '../services/database_service.dart';

enum NoteFilter { all, pinned, archived, trashed }

class NoteProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  final _uuid = const Uuid();

  List<Note> _notes = [];
  List<Note> _filtered = [];
  NoteFilter _filter = NoteFilter.all;
  String? _notebookIdFilter;
  String? _tagIdFilter;
  String _query = '';
  bool _loading = false;
  String? _error;

  List<Note> get notes => List.unmodifiable(_filtered);
  NoteFilter get filter => _filter;
  String? get notebookIdFilter => _notebookIdFilter;
  String? get tagIdFilter => _tagIdFilter;
  String get query => _query;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final db = await _db.database;
      final rows = await db.query('notes',
          orderBy: 'is_pinned DESC, updated_at DESC');
      _notes = [];
      for (final r in rows) {
        final tagRows = await db.query('note_tags',
            columns: ['tag_id'], where: 'note_id = ?', whereArgs: [r['id']]);
        final tags = tagRows.map((e) => e['tag_id'] as String).toList();
        _notes.add(Note.fromMap(r, tags: tags));
      }
      _applyFilter();
    } catch (e, st) {
      _error = 'Load gagal: $e';
      debugPrint('NoteProvider.load ERROR: $e\n$st');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void setFilter(NoteFilter f) {
    _filter = f;
    _applyFilter();
    notifyListeners();
  }

  void setNotebookFilter(String? id) {
    _notebookIdFilter = id;
    _applyFilter();
    notifyListeners();
  }

  void setTagFilter(String? id) {
    _tagIdFilter = id;
    _applyFilter();
    notifyListeners();
  }

  Future<void> search(String q) async {
    _query = q.trim();
    if (_query.isEmpty) {
      _applyFilter();
      notifyListeners();
      return;
    }
    try {
      final db = await _db.database;
      final esc = _query
          .replaceAll(r'\', r'\\')
          .replaceAll('%', r'\%')
          .replaceAll('_', r'\_');
      final like = '%$esc%';
      final rows = await db.rawQuery(
        "SELECT * FROM notes "
        "WHERE is_trashed = 0 AND is_archived = 0 "
        "AND (title LIKE ? ESCAPE '\\' OR content LIKE ? ESCAPE '\\') "
        "ORDER BY is_pinned DESC, updated_at DESC",
        [like, like],
      );
      _filtered = rows.map((r) => Note.fromMap(r)).toList();
    } catch (e) {
      _filtered = [];
      debugPrint('search error: $e');
    }
    notifyListeners();
  }

  void _applyFilter() {
    _filtered = _notes.where((n) {
      switch (_filter) {
        case NoteFilter.all:
          if (n.isTrashed || n.isArchived) return false;
          break;
        case NoteFilter.pinned:
          if (!n.isPinned || n.isTrashed || n.isArchived) return false;
          break;
        case NoteFilter.archived:
          if (!n.isArchived || n.isTrashed) return false;
          break;
        case NoteFilter.trashed:
          if (!n.isTrashed) return false;
          break;
      }
      if (_notebookIdFilter != null && n.notebookId != _notebookIdFilter) return false;
      if (_tagIdFilter != null && !n.tagIds.contains(_tagIdFilter)) return false;
      return true;
    }).toList();
  }

  Future<Note> addNote({String title = '', String content = '', String? notebookId}) async {
    final now = DateTime.now();
    final note = Note(
      id: _uuid.v4(),
      title: title,
      content: content,
      notebookId: notebookId,
      createdAt: now,
      updatedAt: now,
    );
    final db = await _db.database;
    await db.insert('notes', note.toMap());
    _notes.insert(0, note);
    _applyFilter();
    notifyListeners();
    return note;
  }

  Future<void> updateNote(Note note) async {
    note.updatedAt = DateTime.now();
    final db = await _db.database;
    await db.update('notes', note.toMap(), where: 'id = ?', whereArgs: [note.id]);
    await db.delete('note_tags', where: 'note_id = ?', whereArgs: [note.id]);
    for (final tagId in note.tagIds) {
      try {
        await db.insert('note_tags', {'note_id': note.id, 'tag_id': tagId});
      } catch (_) {}
    }
    final i = _notes.indexWhere((n) => n.id == note.id);
    if (i >= 0) {
      _notes[i] = note;
    } else {
      _notes.insert(0, note);
    }
    _applyFilter();
    notifyListeners();
  }

  Future<void> togglePin(Note note) async {
    note.isPinned = !note.isPinned;
    await updateNote(note);
  }

  Future<void> archive(Note note, bool archive) async {
    note.isArchived = archive;
    await updateNote(note);
  }

  Future<void> trash(Note note) async {
    note.isTrashed = true;
    note.trashedAt = DateTime.now();
    await updateNote(note);
  }

  Future<void> restore(Note note) async {
    note.isTrashed = false;
    note.trashedAt = null;
    await updateNote(note);
  }

  Future<void> deletePermanently(String id) async {
    final db = await _db.database;
    await db.delete('notes', where: 'id = ?', whereArgs: [id]);
    _notes.removeWhere((n) => n.id == id);
    _applyFilter();
    notifyListeners();
  }

  Future<void> emptyTrash() async {
    final db = await _db.database;
    final ids = _notes.where((n) => n.isTrashed).map((n) => n.id).toList();
    for (final id in ids) {
      await db.delete('notes', where: 'id = ?', whereArgs: [id]);
    }
    _notes.removeWhere((n) => n.isTrashed);
    _applyFilter();
    notifyListeners();
  }

  Future<void> purgeOldTrash({int days = 30}) async {
    final cutoff = DateTime.now().subtract(Duration(days: days)).millisecondsSinceEpoch;
    final db = await _db.database;
    await db.delete('notes',
        where: 'is_trashed = 1 AND trashed_at IS NOT NULL AND trashed_at < ?',
        whereArgs: [cutoff]);
    await load();
  }
}
