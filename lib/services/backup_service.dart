import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:note_app_core/note_app_core.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'attachment_service.dart';
import 'backup_passphrase_service.dart';
import 'database_service.dart';

class BackupService {
  static const int _backupVersion = 3;
  static const int _maxAutoBackups = 7;
  static const String _attachmentsFolder = 'attachments';
  static const String _dataFileName = 'data.json';
  static const Set<String> _mediaEmbedKeys = {
    'image',
    'video',
    'audio',
    'file',
  };

  final BackupPassphraseService _passphrases = BackupPassphraseService();

  /// Direktori tujuan backup.
  ///
  /// Default-nya folder APLIKASI (tidak bisa dibaca app lain), bukan
  /// /sdcard/Download. Folder publik hanya dipakai kalau user benar-benar
  /// minta ekspor ke lokasi yang bisa dipilihnya.
  Future<Directory> _resolveBaseDir({bool preferPublic = false}) async {
    if (preferPublic) {
      final publicDir = Directory(_publicBackupPath);
      if (await _ensureWritable(publicDir)) return publicDir;
    }

    final documents = await getApplicationDocumentsDirectory();
    await documents.create(recursive: true);
    return documents;
  }

  static const String _publicBackupPath = '/sdcard/Download/note_app';

  /// Ekstensi file backup terenkripsi.
  static const String _encryptedExt = '.nbak';

  /// Ekstensi file backup lama (plaintext) - masih bisa di-restore.
  static const String _legacyExt = '.zip';

  Future<String> exportAll({bool preferPublic = false}) async {
    final dir = await _resolveBaseDir(preferPublic: preferPublic);
    final file = File(
        '${dir.path}/note_app_backup_${DateTime.now().millisecondsSinceEpoch}.zip');
    return _exportTo(file.path);
  }

  /// Auto-backup harian. Simpan di folder khusus, rotasi max 7 file.
  Future<void> autoBackup() async {
    try {
      final dir = await _resolveBaseDir();
      final backupDir = Directory('${dir.path}/backups');
      if (!await backupDir.exists()) await backupDir.create(recursive: true);

      final today = DateTime.now();
      final stamp =
          '${today.year}${today.month.toString().padLeft(2, '0')}${today.day.toString().padLeft(2, '0')}';
      final target = File('${backupDir.path}/backup_$stamp.zip');

      if (await target.exists()) return;

      await _exportTo(target.path);
      await _rotate(backupDir);
    } catch (_) {}
  }

  Future<bool> _ensureWritable(Directory dir) async {
    try {
      if (!await dir.exists()) await dir.create(recursive: true);
      final probe = File(p.join(dir.path, '.note_app_write_test'));
      await probe.writeAsString('ok', flush: true);
      await probe.delete();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<String> _exportTo(String targetPath) async {
    final db = await DatabaseService().database;
    final documents = await getApplicationDocumentsDirectory();
    final attachmentsRoot = p.join(documents.path, _attachmentsFolder);

    final notes = await db.query('notes');
    final notebooks = await db.query('notebooks');
    final tags = await db.query('tags');
    final noteTags = await db.query('note_tags');
    final noteAttachments = await db.query('note_attachments');

    final payload = {
      'version': _backupVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'notes': notes
          .map((row) => _exportNote(row, attachmentsRoot))
          .toList(growable: false),
      'notebooks': notebooks,
      'tags': tags,
      'noteTags': noteTags,
      'noteAttachments': noteAttachments
          .map((row) => _exportAttachment(row, attachmentsRoot))
          .toList(growable: false),
    };

    final tempDir = await Directory.systemTemp.createTemp('note_app_backup_');
    final dataFile = File(p.join(tempDir.path, _dataFileName));
    final target = File(targetPath);

    try {
      await dataFile.writeAsString(jsonEncode(payload));
      await target.parent.create(recursive: true);
      if (await target.exists()) await target.delete();

      // 1. Susun ZIP di file sementara (data.json + attachments).
      final rawZip = File(p.join(tempDir.path, 'payload.zip'));
      final encoder = ZipFileEncoder();
      encoder.create(rawZip.path);
      try {
        await encoder.addFile(dataFile, _dataFileName);
        final attachmentsDir = Directory(attachmentsRoot);
        if (await attachmentsDir.exists()) {
          await for (final entity
              in attachmentsDir.list(recursive: true, followLinks: false)) {
            if (entity is! File) continue;
            final relative = p
                .relative(entity.path, from: attachmentsDir.path)
                .replaceAll(p.separator, '/');
            await encoder.addFile(
              entity,
              '$_attachmentsFolder/$relative',
              ZipFileEncoder.STORE,
            );
          }
        }
      } finally {
        await encoder.close();
      }

      // 2. Enkripsi SELURUH arsip (bukan cuma data.json) supaya lampiran
      //    (foto, dokumen) ikut terlindungi.
      final passphrase = await _resolvePassphrase();
      final sealed = BackupEnvelope.seal(await rawZip.readAsBytes(), passphrase);

      // 3. Tulis hasil enkripsi. Ekstensi .nbak menandai file terenkripsi.
      final encryptedTarget =
          File(targetPath.replaceAll(RegExp(r'\.zip$'), '') + _encryptedExt);
      await encryptedTarget.writeAsString(sealed, flush: true);

      return encryptedTarget.path;
    } finally {
      try {
        await tempDir.delete(recursive: true);
      } catch (_) {}
    }
  }

  /// Ambil passphrase backup. Kalau user belum pernah membuat, buat otomatis
  /// agar backup SELALU terenkripsi (tidak pernah ada file plaintext).
  Future<String> _resolvePassphrase() async {
    final existing = await _passphrases.passphrase();
    if (existing != null && existing.isNotEmpty) return existing;
    final generated = BackupPassphraseService.generatePassphrase();
    await _passphrases.setPassphrase(generated);
    return generated;
  }

  Future<void> _rotate(Directory dir) async {
    final files = await dir
        .list()
        .where((e) =>
            e is File &&
            (e.path.endsWith(_encryptedExt) ||
                e.path.endsWith(_legacyExt) ||
                e.path.endsWith('.json')))
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

  Future<Uint8List> readBytes(String path) async {
    return File(path).readAsBytes();
  }

  Future<String> writeTempBackup(Uint8List bytes, {String? fileName}) async {
    final dir = await getTemporaryDirectory();
    final lower = (fileName ?? '').toLowerCase();
    final extension = lower.endsWith('.json') ? 'json' : 'zip';
    final file = File(
        '${dir.path}/note_app_restore_${DateTime.now().millisecondsSinceEpoch}.$extension');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  Future<int> importFromFile(String path, {bool merge = true, String? passphrase}) async {
    final file = File(path);
    if (!await file.exists()) {
      throw Exception('File backup tidak ditemukan');
    }

    final documents = await getApplicationDocumentsDirectory();
    final attachmentsRoot = p.join(documents.path, _attachmentsFolder);
    final data = await _readBackup(file, attachmentsRoot, passphrase: passphrase);
    final db = await DatabaseService().database;

    final count = await db.transaction<int>((txn) async {
      if (!merge) {
        await txn.delete('note_tags');
        await txn.delete('note_attachments');
        await txn.delete('notes');
        await txn.delete('tags');
        await txn.delete('notebooks');
      }

      final pendingNotebooks = ((data['notebooks'] as List?) ?? [])
          .map((row) => Map<String, dynamic>.from(row as Map))
          .toList();

      while (pendingNotebooks.isNotEmpty) {
        final before = pendingNotebooks.length;
        for (final notebook
            in List<Map<String, dynamic>>.of(pendingNotebooks)) {
          final exists = await txn.query(
            'notebooks',
            columns: ['id'],
            where: 'id = ?',
            whereArgs: [notebook['id']],
            limit: 1,
          );
          if (exists.isNotEmpty) {
            pendingNotebooks.remove(notebook);
            continue;
          }
          try {
            await txn.insert('notebooks', notebook);
            pendingNotebooks.remove(notebook);
          } catch (_) {}
        }
        if (pendingNotebooks.length == before) break;
      }

      final tags = (data['tags'] as List?) ?? [];
      for (final row in tags) {
        final tag = Map<String, dynamic>.from(row as Map);
        final exists = await txn.query(
          'tags',
          columns: ['id'],
          where: 'id = ?',
          whereArgs: [tag['id']],
          limit: 1,
        );
        if (exists.isNotEmpty) continue;
        try {
          await txn.insert('tags', tag);
        } catch (_) {}
      }

      var importedNotes = 0;
      final notes = (data['notes'] as List?) ?? [];
      for (final row in notes) {
        final note = _importNote(
          Map<String, dynamic>.from(row as Map),
          attachmentsRoot,
        );
        final exists = await txn.query(
          'notes',
          columns: ['id'],
          where: 'id = ?',
          whereArgs: [note['id']],
          limit: 1,
        );
        if (exists.isNotEmpty) continue;

        var inserted = false;
        try {
          await txn.insert('notes', note);
          inserted = true;
        } catch (_) {
          if (note['notebook_id'] != null) {
            note['notebook_id'] = null;
            try {
              await txn.insert('notes', note);
              inserted = true;
            } catch (_) {}
          }
        }
        if (inserted) importedNotes++;
      }

      final noteTags = (data['noteTags'] as List?) ?? [];
      for (final row in noteTags) {
        final noteTag = Map<String, dynamic>.from(row as Map);
        try {
          await txn.insert('note_tags', noteTag);
        } catch (_) {}
      }

      final attachments = (data['noteAttachments'] as List?) ?? [];
      for (final row in attachments) {
        final attachment = _importAttachment(
          Map<String, dynamic>.from(row as Map),
          attachmentsRoot,
        );
        try {
          await txn.insert(
            'note_attachments',
            attachment,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        } catch (_) {}
      }

      return importedNotes;
    });

    if (!merge) {
      await AttachmentService().cleanupOrphans();
    }

    return count;
  }

  Future<Map<String, dynamic>> _readBackup(
    File file,
    String attachmentsRoot, {
    String? passphrase,
  }) async {
    // --- File terenkripsi (format baru .nbak) ---
    final rawText = await file.readAsString();
    if (BackupEnvelope.isEncrypted(rawText)) {
      final effective = passphrase?.trim().isNotEmpty == true
          ? passphrase!.trim()
          : await _resolvePassphraseForRestore();
      final decrypted = BackupEnvelope.open(rawText, effective);

      final tempDir =
          await Directory.systemTemp.createTemp('note_app_restore_');
      try {
        final zipFile = File(p.join(tempDir.path, 'payload.zip'));
        await zipFile.writeAsBytes(decrypted, flush: true);
        return await _readArchive(zipFile, tempDir, attachmentsRoot);
      } finally {
        try {
          await tempDir.delete(recursive: true);
        } catch (_) {}
      }
    }

    // --- File ZIP lama (plaintext, sebelum fitur enkripsi) ---
    if (await _isZip(file)) {
      final tempDir =
          await Directory.systemTemp.createTemp('note_app_restore_');
      try {
        return await _readArchive(file, tempDir, attachmentsRoot);
      } finally {
        try {
          await tempDir.delete(recursive: true);
        } catch (_) {}
      }
    }

    // --- File JSON polos (legacy) ---
    final decoded = jsonDecode(rawText);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Format backup tidak dikenali');
    }
    return decoded;
  }

  /// Ekstrak arsip ZIP (data.json + attachments) ke payload map.
  Future<Map<String, dynamic>> _readArchive(
    File archive,
    Directory tempDir,
    String attachmentsRoot,
  ) async {
    await extractFileToDisk(archive.path, tempDir.path);
    final dataFile = File(p.join(tempDir.path, _dataFileName));
    if (!await dataFile.exists()) {
      throw Exception('data.json tidak ditemukan di dalam backup');
    }
    final decoded =
        jsonDecode(await dataFile.readAsString()) as Map<String, dynamic>;
    await _copyAttachments(
      Directory(p.join(tempDir.path, _attachmentsFolder)),
      Directory(attachmentsRoot),
    );
    return decoded;
  }

  /// Passphrase untuk restore: pakai yang tersimpan, atau minta ke user.
  Future<String> _resolvePassphraseForRestore() async {
    final stored = await _passphrases.passphrase();
    if (stored != null && stored.isNotEmpty) return stored;
    throw const BackupDecryptException(
      'Belum ada passphrase backup di perangkat ini. Masukkan passphrase '
      'yang dipakai saat membuat backup.',
    );
  }

  Future<bool> _isZip(File file) async {
    final handle = await file.open();
    try {
      final header = await handle.read(2);
      return header.length == 2 && header[0] == 0x50 && header[1] == 0x4B;
    } finally {
      await handle.close();
    }
  }

  Future<void> _copyAttachments(Directory source, Directory target) async {
    if (!await source.exists()) return;
    await target.create(recursive: true);

    await for (final entity
        in source.list(recursive: true, followLinks: false)) {
      if (entity is! File) continue;
      final relative = p.relative(entity.path, from: source.path);
      final destination = p.join(target.path, relative);
      if (!p.isWithin(target.path, destination)) continue;
      await File(destination).parent.create(recursive: true);
      await entity.copy(destination);
    }
  }

  Map<String, dynamic> _exportNote(
    Map<String, dynamic> row,
    String attachmentsRoot,
  ) {
    final note = Map<String, dynamic>.from(row);
    note['content'] = _rewriteContent(
      note['content'] as String?,
      (value) => _toRelativeMedia(value, attachmentsRoot),
    );
    note['bg_image_path'] =
        _toRelativeMedia(note['bg_image_path'] as String?, attachmentsRoot);
    note['attachments'] = _mapAttachmentList(
      note['attachments'] as String?,
      (value) => _toRelativeMedia(value, attachmentsRoot),
    );
    return note;
  }

  Map<String, dynamic> _importNote(
    Map<String, dynamic> note,
    String attachmentsRoot,
  ) {
    note['content'] = _rewriteContent(
      note['content'] as String?,
      (value) => _toAbsoluteMedia(value, attachmentsRoot),
    );
    note['bg_image_path'] =
        _toAbsoluteMedia(note['bg_image_path'] as String?, attachmentsRoot);
    note['attachments'] = _mapAttachmentList(
      note['attachments'] as String?,
      (value) => _toAbsoluteMedia(value, attachmentsRoot),
    );
    return note;
  }

  Map<String, dynamic> _exportAttachment(
    Map<String, dynamic> row,
    String attachmentsRoot,
  ) {
    final attachment = Map<String, dynamic>.from(row);
    attachment['path'] =
        _toRelativeMedia(attachment['path'] as String?, attachmentsRoot);
    return attachment;
  }

  Map<String, dynamic> _importAttachment(
    Map<String, dynamic> row,
    String attachmentsRoot,
  ) {
    final attachment = Map<String, dynamic>.from(row);
    attachment['path'] =
        _toAbsoluteMedia(attachment['path'] as String?, attachmentsRoot);
    return attachment;
  }

  String? _toRelativeMedia(String? value, String attachmentsRoot) {
    // Path traversal dicegah di note_app_core (toRelativeMediaPath).
    return toRelativeMediaPath(value, attachmentsRoot);
  }

  String? _toAbsoluteMedia(String? value, String attachmentsRoot) {
    // Path traversal dicegah di note_app_core (toAbsoluteMediaPath).
    // Nilai path berasal dari file backup yang dikontrol penyerang, jadi
    // harus divalidasi sebelum dipakai.
    return toAbsoluteMediaPath(value, attachmentsRoot);
  }

  String? _mapAttachmentList(
    String? value,
    String? Function(String) transform,
  ) {
    if (value == null || value.isEmpty) return value;
    return value.split('|').map((path) => transform(path) ?? path).join('|');
  }

  String _rewriteContent(
    String? content,
    String? Function(String) transform,
  ) {
    if (content == null || content.isEmpty) return content ?? '';
    try {
      final decoded = jsonDecode(content);
      return jsonEncode(_mapEmbeds(decoded, transform));
    } catch (_) {
      return content;
    }
  }

  dynamic _mapEmbeds(
    dynamic node,
    String? Function(String) transform,
  ) {
    if (node is Map) {
      final mapped = <String, dynamic>{};
      node.forEach((key, value) {
        if (key is String && _mediaEmbedKeys.contains(key) && value is String) {
          mapped[key] = transform(value) ?? value;
        } else {
          mapped[key] = _mapEmbeds(value, transform);
        }
      });
      return mapped;
    }
    if (node is List) {
      return node.map((value) => _mapEmbeds(value, transform)).toList();
    }
    return node;
  }
}
