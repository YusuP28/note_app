import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../models/attachment.dart';
import 'database_service.dart';

class AttachmentService {
  static final AttachmentService _instance = AttachmentService._internal();
  factory AttachmentService() => _instance;
  AttachmentService._internal();

  static const String _attachmentsFolder = 'attachments';

  final DatabaseService _database = DatabaseService();
  final Uuid _uuid = const Uuid();

  Future<Attachment> saveAttachment({
    required String noteId,
    required String sourcePath,
    required String type,
    String? mimeType,
    int? durationMs,
  }) async {
    final source = File(sourcePath);
    if (!await source.exists()) {
      throw Exception('File sumber tidak ditemukan');
    }

    final documents = await getApplicationDocumentsDirectory();
    final folder =
        Directory(p.join(documents.path, _attachmentsFolder, noteId));
    await folder.create(recursive: true);

    final extension = p.extension(sourcePath);
    final id = _uuid.v4();
    final destination = File(p.join(folder.path, '$id$extension'));
    await source.copy(destination.path);

    final stat = await destination.stat();
    final attachment = Attachment(
      id: id,
      noteId: noteId,
      type: type,
      path: destination.path,
      mimeType: mimeType,
      sizeBytes: stat.size,
      durationMs: durationMs,
      createdAt: DateTime.now(),
    );

    try {
      await _database.insertAttachment(attachment);
    } catch (_) {
      try {
        await destination.delete();
      } catch (_) {}
      rethrow;
    }

    return attachment;
  }

  Future<void> deleteAttachment(String id) async {
    final db = await _database.database;
    final rows = await db.query(
      'note_attachments',
      columns: ['path'],
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return;

    final path = rows.first['path'] as String?;
    await _database.deleteAttachment(id);

    if (path != null) {
      try {
        final file = File(path);
        if (await file.exists()) await file.delete();
      } catch (_) {}
    }
  }

  Future<int> cleanupOrphans() async {
    final documents = await getApplicationDocumentsDirectory();
    final root = Directory(p.join(documents.path, _attachmentsFolder));
    if (!await root.exists()) return 0;

    final db = await _database.database;
    final rows = await db.query('note_attachments', columns: ['path']);
    final referenced = rows
        .map((row) => row['path'] as String?)
        .whereType<String>()
        .map(p.normalize)
        .toSet();

    var deleted = 0;
    final directories = <Directory>[];

    await for (final entity in root.list(recursive: true, followLinks: false)) {
      if (entity is Directory) {
        directories.add(entity);
        continue;
      }
      if (entity is! File) continue;

      final relative = p.relative(entity.path, from: root.path);
      if (!relative.contains(p.separator)) continue;
      if (referenced.contains(p.normalize(entity.path))) continue;

      try {
        await entity.delete();
        deleted++;
      } catch (_) {}
    }

    directories.sort((a, b) => b.path.length.compareTo(a.path.length));
    for (final directory in directories) {
      try {
        if (await directory.list().isEmpty) await directory.delete();
      } catch (_) {}
    }

    return deleted;
  }
}
