import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import 'attachment_file_store.dart';

class ImageAttachmentService {
  static final ImageAttachmentService _i = ImageAttachmentService._();
  factory ImageAttachmentService() => _i;
  ImageAttachmentService._();

  final ImagePicker _picker = ImagePicker();
  bool _useOriginal = false;

  void setUseOriginal(bool v) {
    _useOriginal = v;
    debugPrint('Use original quality: $v');
  }

  /// Ambil dari galeri
  Future<List<String>> pickFromGallery() async {
    try {
      final useOriginal = _useOriginal;
      final files = await _picker.pickMultiImage(
        imageQuality: useOriginal ? null : 85,
        maxWidth: useOriginal ? null : 1920,
      );
      if (files.isEmpty) return [];
      final saved = <String>[];
      for (final f in files) {
        final path = await AttachmentFileStore.instance.saveFile(f.path);
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
      final useOriginal = _useOriginal;
      final f = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: useOriginal ? null : 85,
        maxWidth: useOriginal ? null : 1920,
      );
      if (f == null) return null;
      return await AttachmentFileStore.instance.saveFile(f.path);
    } catch (e) {
      debugPrint('pickFromCamera error: $e');
      return null;
    }
  }
}
