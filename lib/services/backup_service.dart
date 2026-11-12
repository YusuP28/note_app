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
  /// Folder APLIKASI (tidak bisa dibaca app lain). Tidak ada lagi akses ke
  /// storage eksternal: ekspor ke lokasi pilihan user memakai Storage Access
  /// Framework (system file picker), jadi `MANAGE_EXTERNAL_STORAGE` tidak
  /// diperlukan lagi.
  Future<Directory> _resolveBaseDir() async {
    final documents = await getApplicationDocumentsDirectory();
    await documents.create(recursive: true);
    return documents;
  }

  /// Ekstensi file backup (.zip).
  static const String _zipExt = '.zip';

  /// Ekstensi file backup lama (plaintext) - masih bisa di-restore.
  static const String _legacyExt = '.zip';

  Future<String> exportAll() async {
    final dir = await _resolveBaseDir();
    final file = File(
        '${dir.path}/note_app_backup_${DateTime.now().millisecondsSinceEpoch}.zip');
    return _exportTo(file.path);
  }

  /// Hasil ekspor backup sebagai bytes, tanpa menyisakan file di folder aplikasi.
  ///
  /// Dipakai untuk ekspor lewat Storage Access Framework: user memilih
  /// lokasi file lewat system picker, lalu bytes-nya ditulis ke lokasi itu.
  Future<Uint8List> exportAllBytes() async {
    final path = await exportAll();
    try {
      return await readBytes(path);
    } finally {
      try {
        await File(path).delete();
      } catch (_) {}
    }
  }

  /// Auto-backup harian. Simpan di folder khusus, rotasi max 7 file.
  Future<void> autoBackup() async {
    try {
      final dir = await _resolveBaseDir();
      final backupDir = Directory('${dir.path}/backups');
      if (!await backupDir.exists()) await backupDir.create(recursive: true);

      final today = DateTime.now;
      final stamp =
          '${today.year}${today.month.toString().padLeft(2, '0')}${today.day.toString().padLeft(2, '0')}';
      // `_exportTo` selalu menulis file terenkripsi (`.zip`). Guard harian
      // harus memeriksa path yang SAMA - sebelumnya ia memeriksa `.zip` yang
      // tidak pernah dibuat, sehingga auto-backup berjalan di setiap launch.
      final targetPath = '${backupDir.path}/backup_$stamp.zip';
      final target = File(_zipPathFor(targetPath));

      if (await target.exists()) return;

      await _exportTo(targetPath);
      await _rotate(backupDir);
    } catch (_) {}
  }

  /// Path file backup (.zip).
  ///
  /// Satu sumber kebenaran untuk penulisan (`_exportTo`) dan pengecekan
  /// keberadaan file (`autoBackup`), supaya keduanya tidak bisa menyimpang.
  static String _zipPathFor(String targetPath) =>
      '${targetPath.replaceAll(RegExp(r'\.zip$'), '')}';

  /// Ekstensi file backup terenkripsi.
  ///
  /// Digunakan untuk kompatibilitas dengan file backup lama (.zip) yang
  /// masih bisa dibaca, namun format baru menggunakan ekstensi `.zip`.
  static String _zipExt() => '.zip';

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

    final tempDir = await Directory.systemTemp.createTemp('backup_');
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
                .relative(entity.path, from: attachmentsRoot)
                .replaceAll(p.separator, '/');
            final relative2 = p
                .relative(entity.path, from: attachmentsRoot)
                .replaceAll(p.separator, '/');
            await encoder.addFile(entity, relative2);
          }
        } finally {
          await encoder.close();
        }

        // 2. Tulis hasil ZIP ke target.
        final target = File(targetPath);
        if (await target.exists()) await target.delete();
        final rawZip = File(p.join(tempDir.path, 'payload.zip'));
        await rawZip.writeAsBytes(await rawZip.readAsBytes());
        await target.writeAsBytes(await rawZip.readAsBytes());
      } catch (e) {
        // Jika terjadi error, hapus file sementara dan rethrow
        try {
          await tempDir.delete(recursive: true);
        } catch (_) {}
        rethrow;
      }
    } finally {
      try {
        await tempDir.delete(recursive: true);
      } catch (_) {}
    }
  }

  /// Rotasi file backup lama.
  Future<void> _rotate(Directory dir) async {
    final files = await dir
        .list()
        .where((e) => e is File && (e.path.endsWith('.zip') || e.path.endsWith('.zip')))
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

  /// Mengecek apakah file adalah file backup ZIP.
  static bool _isZip(String path) {
    return path.endsWith('.zip');
  }

  Future<Uint8List> readBytes(String path) async {
    return File(path).readAsBytes();
  }
}
