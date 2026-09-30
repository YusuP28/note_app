import 'dart:io';
import 'package:flutter/material.dart';
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

  Future<void> insertFromGallery(QuillController controller) async {
    try {
      final files = await _picker.pickMultiImage(
        imageQuality: _useOriginal ? null : 85,
        maxWidth: _useOriginal ? null : 1920,
      );
      if (files.isEmpty) return;
      for (final f in files) {
        final saved = await _saveToApp(f);
        if (saved != null) _insertImageBlock(controller, saved);
      }
    } catch (e) {
      debugPrint('insertFromGallery error: $e');
    }
  }

  Future<void> insertFromCamera(QuillController controller) async {
    try {
      final f = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: _useOriginal ? null : 85,
        maxWidth: _useOriginal ? null : 1920,
      );
      if (f == null) return;
      final saved = await _saveToApp(f);
      if (saved != null) _insertImageBlock(controller, saved);
    } catch (e) {
      debugPrint('insertFromCamera error: $e');
    }
  }

  /// Sisip gambar sebagai block (dengan newline sebelum & sesudah)
  void _insertImageBlock(QuillController controller, String path) {
    final index = controller.selection.baseOffset;
    final length = controller.selection.extentOffset - index;

    final doc = controller.document;
    final text = doc.toPlainText();
    final needLeadingNl = index > 0 && index <= text.length && text[index - 1] != '\n';

    // Sisip newline sebelum (kalau perlu)
    if (needLeadingNl) {
      controller.replaceText(
        index,
        0,
        '\n',
        TextSelection.collapsed(offset: index + 1),
      );
    }

    final insertAt = index + (needLeadingNl ? 1 : 0);

    // Sisip BlockEmbed.image
    controller.replaceText(
      insertAt,
      length,
      BlockEmbed.image(path),
      TextSelection.collapsed(offset: insertAt + 1),
    );

    // Sisip newline setelah gambar
    controller.replaceText(
      insertAt + 1,
      0,
      '\n',
      TextSelection.collapsed(offset: insertAt + 2),
    );
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
