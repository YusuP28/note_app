import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class QuillImageService {
  static final QuillImageService _i = QuillImageService._();
  factory QuillImageService() => _i;
  QuillImageService._();

  final ImagePicker _picker = ImagePicker();
  bool _useOriginal = false;

  void setUseOriginal(bool v) => _useOriginal = v;

  /// Pilih dari galeri, sisipkan sebagai gambar inline
  Future<void> insertFromGallery(QuillController controller) async {
    try {
      final files = await _picker.pickMultiImage(
        imageQuality: _useOriginal ? null : 85,
        maxWidth: _useOriginal ? null : 1920,
      );
      if (files.isEmpty) return;

      for (final f in files) {
        final saved = await _saveToApp(f);
        if (saved != null) _insertImage(controller, saved);
      }
    } catch (e) {
      debugPrint('insertFromGallery error: $e');
    }
  }

  /// Ambil dari kamera, sisipkan inline
  Future<void> insertFromCamera(QuillController controller) async {
    try {
      final f = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: _useOriginal ? null : 85,
        maxWidth: _useOriginal ? null : 1920,
      );
      if (f == null) return;
      final saved = await _saveToApp(f);
      if (saved != null) _insertImage(controller, saved);
    } catch (e) {
      debugPrint('insertFromCamera error: $e');
    }
  }

  /// Sisipkan gambar inline di posisi cursor
  void _insertImage(QuillController controller, String path) {
    final index = controller.selection.baseOffset;
    final length = controller.selection.extentOffset - index;

    // Newline sebelum gambar biar rapi
    final beforeNewline = _needsNewline(controller, index);

    controller.replaceText(
      index,
      length,
      BlockEmbed.image(path),
      TextSelection.collapsed(offset: index + 1),
    );

    // Tambah newline setelah gambar
    controller.replaceText(
      index + 2,
      0,
      '\n',
      TextSelection.collapsed(offset: index + 3),
    );
  }

  bool _needsNewline(QuillController controller, int index) {
    if (index <= 0) return true;
    final text = controller.document.toPlainText();
    if (index > text.length) return true;
    return text[index - 1] != '\n';
  }

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
}
