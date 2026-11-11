import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Penyimpanan file lampiran (gambar) milik aplikasi.
///
/// Dulu method `_saveToApp` ada duplikat 100% di
/// `image_attachment_service.dart` dan `quill_image_service.dart`.
/// Sekarang keduanya memakai store ini.
///
/// Format nama file TIDAK boleh diubah:
/// `img_<millisecondsSinceEpoch><ext>` di dalam folder
/// `<appDocuments>/attachments`, supaya file lama tetap bisa dibaca.
class AttachmentFileStore {
  static final AttachmentFileStore instance = AttachmentFileStore._();

  AttachmentFileStore._();

  static const String _attachmentsFolder = 'attachments';

  /// Path absolut folder tempat file lampiran disimpan.
  Future<String> attachmentsRoot() async {
    final documents = await getApplicationDocumentsDirectory();
    final root = Directory(p.join(documents.path, _attachmentsFolder));
    if (!root.existsSync()) {
      try {
        await root.create(recursive: true);
      } catch (e) {
        debugPrint('attachmentsRoot create error: $e');
      }
    }
    return root.path;
  }

  /// Salin file dari [sourcePath] ke folder attachments aplikasi.
  ///
  /// Return path absolut file hasil salinan, atau `null` kalau gagal
  /// (mis. file sumber tidak ada).
  Future<String?> saveFile(String sourcePath) async {
    try {
      final source = File(sourcePath);
      if (!await source.exists()) return null;

      final attDir = Directory(await attachmentsRoot());
      if (!await attDir.exists()) await attDir.create(recursive: true);

      final ext = p.extension(sourcePath);
      final name = 'img_${DateTime.now().millisecondsSinceEpoch}$ext';
      final dest = p.join(attDir.path, name);

      await source.copy(dest);
      return dest;
    } catch (e) {
      debugPrint('saveFile error: $e');
      return null;
    }
  }

  /// Hapus file lampiran. Aman dipanggil untuk file yang sudah hilang.
  Future<void> deleteFile(String path) async {
    try {
      final f = File(path);
      if (await f.exists()) await f.delete();
    } catch (e) {
      debugPrint('deleteFile error: $e');
    }
  }
}
