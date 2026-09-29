import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../models/note.dart';
import 'database_service.dart';

class MigrationService {
  static const _legacyFile = 'notes.json';
  static const _doneFlag = 'notes.json.migrated';

  Future<bool> migrateIfNeeded() async {
    final dir = await getApplicationDocumentsDirectory();
    final legacy = File('${dir.path}/$_legacyFile');
    final flag = File('${dir.path}/$_doneFlag');

    if (await flag.exists()) return false;
    if (!await legacy.exists()) return false;

    try {
      final content = await legacy.readAsString();
      final List<dynamic> data = jsonDecode(content);
      if (data.isEmpty) {
        await flag.writeAsString('empty');
        return false;
      }

      final db = await DatabaseService().database;
      final uuid = const Uuid();
      final batch = db.batch();

      for (final item in data) {
        final m = item as Map<String, dynamic>;
        final createdAt = DateTime.tryParse(m['createdAt'] as String? ?? '') ?? DateTime.now();
        final updatedAt = DateTime.tryParse(m['updatedAt'] as String? ?? '') ?? createdAt;
        batch.insert('notes', {
          'id': (m['id'] as String?) ?? uuid.v4(),
          'title': (m['title'] as String?) ?? '',
          'content': (m['content'] as String?) ?? '',
          'notebook_id': null,
          'color': null,
          'is_pinned': 0,
          'is_archived': 0,
          'is_trashed': 0,
          'is_locked': 0,
          'trashed_at': null,
          'sort_order': 0,
          'created_at': createdAt.millisecondsSinceEpoch,
          'updated_at': updatedAt.millisecondsSinceEpoch,
        });
      }

      await batch.commit(noResult: true);
      await flag.writeAsString('migrated:${data.length}');
      return true;
    } catch (_) {
      return false;
    }
  }
}
