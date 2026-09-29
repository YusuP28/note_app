import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/note.dart';
import 'database_service.dart';

class BackupService {
  static const int _maxAutoBackups = 7;

  Future<String> exportAll() async {
    final db = await DatabaseService().database;
    final notes = await db.query('notes');
    final notebooks = await db.query('notebooks');
    final tags = await db.query('tags');
    final noteTags = await db.query('note_tags');

    final payload = {
      'version': 2,
      'exportedAt': DateTime.now().toIso8601String(),
      'notes': notes,
      'notebooks': notebooks,
      'tags': tags,
      'noteTags': noteTags,
    };

    final dir = await getApplicationDocumentsDirectory();
    final file = File(
        '${dir.path}/note_app_backup_${DateTime.now().millisecondsSinceEpoch}.json');
    await file.writeAsString(jsonEncode(payload));
    return file.path;
  }

  /// Auto-backup harian. Simpan di folder khusus, rotasi max 7 file.
  Future<void> autoBackup() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${dir.path}/backups');
      if (!await backupDir.exists()) await backupDir.create(recursive: true);

      final today = DateTime.now();
      final stamp =
          '${today.year}${today.month.toString().padLeft(2, '0')}${today.day.toString().padLeft(2, '0')}';
      final target = File('${backupDir.path}/backup_$stamp.json');

      if (await target.exists()) return; // sudah backup hari ini

      final db = await DatabaseService().database;
      final notes = await db.query('notes');
      final notebooks = await db.query('notebooks');
      final tags = await db.query('tags');
      final noteTags = await db.query('note_tags');

      await target.writeAsString(jsonEncode({
        'version': 2,
        'exportedAt': today.toIso8601String(),
        'notes': notes,
        'notebooks': notebooks,
        'tags': tags,
        'noteTags': noteTags,
      }));

      await _rotate(backupDir);
    } catch (_) {}
  }

  Future<void> _rotate(Directory dir) async {
    final files = await dir
        .list()
        .where((e) => e is File && e.path.endsWith('.json'))
        .cast<File>()
        .toList();
    files.sort((a, b) => a.path.compareTo(b.path));
    while (files.length > _maxAutoBackups) {
      final old = files.removeAt(0);
      try {
        await old.delete();
      } catch (_) {}
    }
  }

  /// Import dari file JSON backup v2. [merge]=true → gabung, false → replace.
  Future<int> importFromFile(String path, {bool merge = true}) async {
    final file = File(path);
    final data = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    final db = await DatabaseService().database;

    if (!merge) {
      await db.delete('note_tags');
      await db.delete('notes');
      await db.delete('tags');
      await db.delete('notebooks');
    }

    int count = 0;
    final notes = (data['notes'] as List?) ?? [];
    for (final n in notes) {
      final m = Map<String, dynamic>.from(n as Map);
      final exists = await db.query('notes',
          columns: ['id'], where: 'id = ?', whereArgs: [m['id']], limit: 1);
      if (exists.isNotEmpty) continue;
      await db.insert('notes', m);
      count++;
    }

    for (final tbl in ['notebooks', 'tags']) {
      final rows = (data[tbl] as List?) ?? [];
      for (final r in rows) {
        final m = Map<String, dynamic>.from(r as Map);
        final exists = await db
            .query(tbl, columns: ['id'], where: 'id = ?', whereArgs: [m['id']], limit: 1);
        if (exists.isNotEmpty) continue;
        await db.insert(tbl, m);
      }
    }

    final nts = (data['noteTags'] as List?) ?? [];
    for (final nt in nts) {
      final m = Map<String, dynamic>.from(nt as Map);
      try {
        await db.insert('note_tags', m);
      } catch (_) {}
    }

    return count;
  }
}
