import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:note_app/services/attachment_file_store.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// Fake path_provider supaya `flutter test` (yang tidak punya implementasi
/// native path_provider) bisa mengembalikan folder dokumen yang bisa ditulis.
class _FakePathProvider extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  _FakePathProvider(this.documentsPath);

  final String documentsPath;

  @override
  Future<String?> getApplicationDocumentsPath() async => documentsPath;

  @override
  Future<String?> getApplicationSupportPath() async => documentsPath;

  @override
  Future<String?> getTemporaryPath() async => documentsPath;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory fakeDocs;
  late Directory sourceDir;

  setUp(() async {
    final base = Directory.systemTemp.createTempSync('note_app_afs_test_');
    fakeDocs = Directory('${base.path}/docs')..createSync(recursive: true);
    sourceDir = Directory('${base.path}/src')..createSync(recursive: true);
    PathProviderPlatform.instance = _FakePathProvider(fakeDocs.path);
  });

  tearDown(() {
    final base = fakeDocs.parent;
    if (base.existsSync()) base.deleteSync(recursive: true);
  });

  group('AttachmentFileStore', () {
    test('saveFile menyalin file yang ada ke folder attachments', () async {
      final source = File('${sourceDir.path}/foto.png')
        ..writeAsBytesSync(<int>[1, 2, 3, 4]);

      final hasil = await AttachmentFileStore.instance.saveFile(source.path);

      expect(hasil, isNotNull);
      expect(hasil, endsWith('.png'));
      expect(File(hasil!).existsSync(), isTrue);
      expect(File(hasil).readAsBytesSync(), <int>[1, 2, 3, 4]);
    });

    test('saveFile mengembalikan null kalau file sumber tidak ada', () async {
      final hasil = await AttachmentFileStore.instance
          .saveFile('${sourceDir.path}/tidak_ada.png');

      expect(hasil, isNull);
    });

    test('saveFile dua kali menghasilkan dua path berbeda (timestamp)', () async {
      final a = File('${sourceDir.path}/a.png')..writeAsBytesSync(<int>[1]);
      final b = File('${sourceDir.path}/b.png')..writeAsBytesSync(<int>[2]);

      final hasilA = await AttachmentFileStore.instance.saveFile(a.path);
      // Beri jeda supaya millisecondsSinceEpoch tidak sama.
      await Future<void>.delayed(const Duration(milliseconds: 5));
      final hasilB = await AttachmentFileStore.instance.saveFile(b.path);

      expect(hasilA, isNotNull);
      expect(hasilB, isNotNull);
      expect(hasilA, isNot(equals(hasilB)));
      expect(File(hasilA!).existsSync(), isTrue);
      expect(File(hasilB!).existsSync(), isTrue);
    });

    test('nama file hasil simpan mengikuti format img_<timestamp><ext>', () async {
      final source = File('${sourceDir.path}/gambar.jpeg')
        ..writeAsBytesSync(<int>[9, 9]);

      final hasil = await AttachmentFileStore.instance.saveFile(source.path);

      expect(hasil, isNotNull);
      final nama = hasil!.split('/').last;
      expect(nama, matches(RegExp(r'^img_\d+\.jpeg$')));
    });

    test('attachmentsRoot menunjuk ke folder attachments di dokumen app', () async {
      final root = await AttachmentFileStore.instance.attachmentsRoot();

      expect(root, '${fakeDocs.path}/attachments');
    });

    test('attachmentsRoot membuat folder attachments kalau belum ada', () async {
      final attachments = Directory('${fakeDocs.path}/attachments');
      expect(attachments.existsSync(), isFalse);

      final root = await AttachmentFileStore.instance.attachmentsRoot();

      expect(Directory(root).existsSync(), isTrue);
    });

    test('attachmentsRoot idempoten saat dipanggil berkali-kali', () async {
      final rootA = await AttachmentFileStore.instance.attachmentsRoot();
      final rootB = await AttachmentFileStore.instance.attachmentsRoot();

      expect(rootA, rootB);
      expect(Directory(rootA).existsSync(), isTrue);
    });

    test('saveFile tetap bisa dipakai setelah folder attachments dihapus manual', () async {
      final source = File('${sourceDir.path}/folder.png')
        ..writeAsBytesSync(<int>[1, 2]);

      // Pastikan folder pernah dibuat, lalu hapus manual supaya
      // ensure-pembuatan folder diuji ulang oleh `saveFile`.
      final root = await AttachmentFileStore.instance.attachmentsRoot();
      Directory(root).deleteSync(recursive: true);

      final hasil = await AttachmentFileStore.instance.saveFile(source.path);

      expect(hasil, isNotNull);
      expect(File(hasil!).existsSync(), isTrue);
    });

    test('deleteFile menghapus file yang ada dan aman kalau file hilang', () async {
      final source = File('${sourceDir.path}/hapus.png')
        ..writeAsBytesSync(<int>[7]);
      final hasil = await AttachmentFileStore.instance.saveFile(source.path);
      expect(File(hasil!).existsSync(), isTrue);

      await AttachmentFileStore.instance.deleteFile(hasil);
      expect(File(hasil).existsSync(), isFalse);

      // Menghapus file yang sudah tidak ada tidak boleh melempar error.
      await AttachmentFileStore.instance.deleteFile(hasil);
    });
  });
}
