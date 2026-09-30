import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ImageAttachmentService {
  static final ImageAttachmentService _i = ImageAttachmentService._();
  factory ImageAttachmentService() => _i;
  ImageAttachmentService._();

  final ImagePicker _picker = ImagePicker();

  /// Ambil dari galeri
  Future<List<String>> pickFromGallery() async {
    try {
      final files = await _picker.pickMultiImage(
        imageQuality: 85,
        maxWidth: 1920,
      );
      if (files.isEmpty) return [];
      final saved = <String>[];
      for (final f in files) {
        final path = await _saveToApp(f);
        if (path != null) saved.add(path);
      }
      return saved;
    } catch (e) {
      debugPrint('pickFromGallery error: $e');
      return [];
    }
  }

  /// Ambil dari kamera
  Future<String?> pickFromCamera() async {
    try {
      final f = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
      );
      if (f == null) return null;
      return await _saveToApp(f);
    } catch (e) {
      debugPrint('pickFromCamera error: $e');
      return null;
    }
  }

  /// Copy file ke folder app biar permanen (galeri bisa dihapus user)
  Future<String?> _saveToApp(XFile file) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final attDir = Directory('${dir.path}/attachments');
      if (!await attDir.exists()) await attDir.create(recursive: true);

      final ext = p.extension(file.path);
      final name = 'img_${DateTime.now().millisecondsSinceEpoch}$ext';
      final dest = '${attDir.path}/$name';

      await File(file.path).copy(dest);
      return dest;
    } catch (e) {
      debugPrint('_saveToApp error: $e');
      return null;
    }
  }

  /// Hapus file
  Future<void> deleteFile(String path) async {
    try {
      final f = File(path);
      if (await f.exists()) await f.delete();
    } catch (e) {
      debugPrint('deleteFile error: $e');
    }
  }
}
