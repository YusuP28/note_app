import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:note_app_core/note_app_core.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../models/note.dart';
import '../services/database_service.dart';
import '../services/attachment_service.dart';
import '../services/alarm_service.dart';

// `NoteFilter` kini hidup di package core. Diekspor ulang supaya file lain
// yang mengimpor provider ini tidak perlu mengubah import-nya.
export 'package:note_app_core/note_app_core.dart' show NoteFilter;

class NoteProvider extends ChangeNotifier {
  @override
  void dispose() {
    _disposed = true;
    // Cleanup jika ada resources (timer, stream, dll)
    super.dispose();
  }
  final DatabaseService _db = DatabaseService();
  final AlarmService _alarm = AlarmService();
  final _uuid = const Uuid();

  List<Note> _notes = [];
  // State daftar (normal + hasil pencarian aktif) dikelola di package core
  // supaya aturannya bisa diuji tanpa database.
  final NoteListState<Note> _listState = NoteListState<Note>();
  NoteFilter _filter = NoteFilter.all;
  String? _notebookIdFilter;
  String? _tagIdFilter;
  bool _loading = false;
  String? _error;
  SortBy _sortBy = SortBy.updatedDesc;
  bool _disposed = false;

  List<Note> get notes => _listState.notes;
  NoteFilter get filter => _filter;
  String? get notebookIdFilter => _notebookIdFilter;
  String? get tagIdFilter => _tagIdFilter;
  String get query => _listState.query;
  bool get loading => _loading;
  String? get error => _error;
  SortBy get sortBy => _sortBy;

  /// Apakah sedang ada pencarian yang belum selesai?
  bool get searching => _listState.searching;

  /// Hapus hasil pencarian aktif dan kembalikan daftar ke kondisi normal.
  ///
  /// Dipanggil saat SearchScreen ditutup supaya Home tidak lagi menampilkan
  /// hasil pencarian.
  void clearSearch() {
    if (_disposed) return;
    _listState.clearSearch();
    notifyListeners();
  }

  void setSortBy(SortBy s) {
    _sortBy = s;
    _applyFilter();
    notifyListeners();
  }

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _notes = await muatDaftar();
      _applyFilter();
    } catch (e, st) {
      _error = 'Load gagal: $e';
      debugPrint('NoteProvider.load ERROR: $e\n$st');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Ambil seluruh catatan dari penyimpanan.
  ///
  /// Dipisah supaya bisa diuji tanpa database (sqflite butuh native, tidak
  /// tersedia di `flutter test`).
  @visibleForTesting
  Future<List<Note>> muatDaftar() async {
    final db = await _db.database;
    final rows = await db.query('notes');
    final hasil = <Note>[];
    for (final r in rows) {
      final tagRows = await db.query('note_tags',
          columns: ['tag_id'], where: 'note_id = ?', whereArgs: [r['id']]);
      final tags = tagRows.map((e) => e['tag_id'] as String).toList();
      hasil.add(Note.fromMap(_db.cipher.decryptRow(r), tags: tags));
    }
    return hasil;
  }

  /// Ambil baris mentah catatan yang cocok dengan kata kunci [query].
  ///
  /// Dipisah supaya bisa diuji tanpa database (sqflite butuh native, tidak
  /// tersedia di `flutter test`).
  @visibleForTesting
  Future<List<Map<String, Object?>>> ambilBarisPencarian(String query) async {
    final db = await _db.database;
    final esc = query
        .replaceAll(r'\', r'\\')
        .replaceAll('%', r'\%')
        .replaceAll('_', r'\_');
    final like = '%$esc%';
    // Kandidat diambil lebih luas: hanya sampah yang dikecualikan di SQL.
    // Status lain (arsip, pinned, semua) disaring lagi di Dart lewat
    // `applyNoteFilters` dengan filter yang sedang aktif.
    final rows = await db.rawQuery(
      "SELECT n.*, "
      "(SELECT GROUP_CONCAT(tag_id) FROM note_tags WHERE note_id = n.id) "
      "AS tag_ids "
      "FROM notes n "
      "WHERE n.is_trashed = 0 "
      "AND (n.title LIKE ? ESCAPE '\\' OR n.plain_text LIKE ? ESCAPE '\\')",
      [like, like],
    );
    return rows;
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
    final query = q.trim();
    if (query.isEmpty) {
      // Pencarian kosong -> kembalikan ke daftar normal.
      clearSearch();
      return;
    }
    final token = _listState.mulaiPencarian(query);
    try {
      final rows = await ambilBarisPencarian(query);
      if (_listState.isStale(token)) return; // hasil basi, abaikan
      final hasil = <Note>[];
      for (final r in rows) {
        final row = _db.cipher.decryptRow(r);
        // Catatan terkunci: isi di database berupa ciphertext, sehingga hasil
        // LIKE bisa saja bukan teks yang dicari. Buang baris yang isinya tidak
        // benar-benar mengandung kata kunci -> ciphertext tidak pernah tampil
        // di UI, tapi catatan terkunci yang cocok lewat JUDUL tetap ditemukan.
        if (!catatanLayakTampil(
          judul: row['title'] as String?,
          plainTersimpan: r['plain_text'] as String?,
          plainDidekripsi: row['plain_text'] as String?,
          query: query,
        )) {
          continue;
        }
        final rawTags = r['tag_ids'] as String?;
        final tags = rawTags == null || rawTags.isEmpty
            ? const <String>[]
            : rawTags.split(',');
        hasil.add(Note.fromMap(row, tags: tags));
      }
      // Hasil pencarian ikut filter status/notebook/tag yang sedang aktif dan
      // diurutkan dengan aturan yang sama seperti daftar utama.
      _listState.setSearchResults(_saringDanUrutkan(hasil, _filter));
    } catch (e) {
      if (_listState.isStale(token)) return;
      _listState.setSearchResults([]);
      debugPrint('search error: $e');
    }
    notifyListeners();
  }

  void _applyFilter() {
    _listState.setNormal(_saringDanUrutkan(_notes, _filter));
    if (_listState.hasSearch) {
      // Filter/urutan berubah -> segarkan hasil pencarian yang aktif.
      unawaited(search(_listState.query));
    }
  }

  /// Saring + urutkan catatan sesuai filter dan urutan aktif.
  List<Note> _saringDanUrutkan(List<Note> sumber, NoteFilter filter) {
    final tagId = _tagIdFilter;
    final tersaring = applyNoteFilters<Note>(
      sumber,
      filter,
      notebookId: _notebookIdFilter,
      tagId: tagId,
      isPinned: (n) => n.isPinned,
      isTrashed: (n) => n.isTrashed,
      isArchived: (n) => n.isArchived,
      hasTag: (n) => tagId != null && n.tagIds.contains(tagId),
      notebookIdOf: (n) => n.notebookId,
    );
    return sortNotes<Note>(
      tersaring,
      _sortBy,
      asNote: (n) => n,
      filter: filter,
      isPinned: (n) => n.isPinned,
    );
  }

  Future<Note> addNote(
      {String title = '', String content = '', String? notebookId}) async {
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
    final row = _db.cipher.encryptRow(note.toMap());
    await db.transaction((txn) async {
      await txn.update(
        'notes',
        row,
        where: 'id = ?',
        whereArgs: [note.id],
      );
      await txn.delete(
        'note_tags',
        where: 'note_id = ?',
        whereArgs: [note.id],
      );
      for (final tagId in note.tagIds) {
        try {
          await txn.insert(
            'note_tags',
            {'note_id': note.id, 'tag_id': tagId},
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
        } catch (_) {}
      }
    });
    final i = _notes.indexWhere((n) => n.id == note.id);
    if (i >= 0) {
      _notes[i] = note;
    } else {
      _notes.insert(0, note);
    }
    _applyFilter();
    notifyListeners();
  }

  String _buildNotifBody(Note note) {
    final plain = note.plainText.trim();
    if (plain.isNotEmpty) {
      return plain.length > 80 ? '${plain.substring(0, 80)}...' : plain;
    }
    final content = note.content.trim();
    if (content.isEmpty) return 'Waktunya buka catatan ini';
    return content.length > 80 ? '${content.substring(0, 80)}...' : content;
  }

  Future<void> setReminder(Note note, DateTime? when) async {
    debugPrint('setReminder: note=${note.id} when=$when');
    // Set field dulu, baru update DB + notify
    note.reminderAt = when;
    await updateNote(note);

    // Schedule notif SETELAH update (biar indicator & notif sinkron)
    if (when == null) {
      await _alarm.cancel(note.id);
      debugPrint('Reminder cleared for ${note.id}');
    } else {
      await _alarm.schedule(
        noteId: note.id,
        title: note.title.isEmpty ? 'Pengingat Catatan' : note.title,
        body: _buildNotifBody(note),
        when: when,
      );
      debugPrint('Reminder set for ${note.id} at $when');
    }
  }

  Future<void> toggleLock(Note note) async {
    note.isLocked = !note.isLocked;
    await updateNote(note);
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
    if (note.reminderAt != null) {
      await _alarm.cancel(note.id);
    }
    await updateNote(note);
  }

  Future<void> restore(Note note) async {
    note.isTrashed = false;
    note.trashedAt = null;
    await updateNote(note);
  }

  Future<void> deletePermanently(String id) async {
    await _alarm.cancel(id);
    final db = await _db.database;
    await db.delete('notes', where: 'id = ?', whereArgs: [id]);
    await AttachmentService().cleanupOrphans();
    _notes.removeWhere((n) => n.id == id);
    _applyFilter();
    notifyListeners();
  }

  Future<void> emptyTrash() async {
    final db = await _db.database;
    final ids = _notes.where((n) => n.isTrashed).map((n) => n.id).toList();
    for (final id in ids) {
      await _alarm.cancel(id);
      await db.delete('notes', where: 'id = ?', whereArgs: [id]);
    }
    await AttachmentService().cleanupOrphans();
    _notes.removeWhere((n) => n.isTrashed);
    _applyFilter();
    notifyListeners();
  }

  Future<void> purgeOldTrash({int days = 30}) async {
    final cutoff =
        DateTime.now().subtract(Duration(days: days)).millisecondsSinceEpoch;
    final db = await _db.database;
    await db.delete('notes',
        where: 'is_trashed = 1 AND trashed_at IS NOT NULL AND trashed_at < ?',
        whereArgs: [cutoff]);
    await AttachmentService().cleanupOrphans();
    await load();
  }
}
