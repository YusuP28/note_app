import 'package:flutter_test/flutter_test.dart';
import 'package:note_app/models/note.dart';

/// Bangun [Note] uji. Isi ciphertext dipakai apa adanya - `NoteCipher`
/// mengenali ciphertext hanya lewat magic header `NBNOTE1`.
Note buildNote({
  String content = '{"ops":[{"insert":"halo"}]}',
  String plainText = 'halo',
  bool isLocked = true,
}) {
  final now = DateTime.now();
  return Note(
    id: 'n1',
    content: content,
    plainText: plainText,
    isLocked: isLocked,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('Note.decryptFailed', () {
    test('false untuk catatan biasa yang sudah terbaca', () {
      expect(buildNote().decryptFailed, isFalse);
    });

    test('false untuk catatan tidak terkunci', () {
      expect(buildNote(isLocked: false).decryptFailed, isFalse);
    });

    test('true kalau isi masih ciphertext (dekripsi gagal)', () {
      final n = buildNote(
        content: 'NBNOTE1.aaa.bbb.ccc',
        plainText: 'NBNOTE1.aaa.bbb.ccc',
      );

      expect(n.decryptFailed, isTrue);
    });

    test('true kalau hanya plain_text yang masih ciphertext', () {
      final n = buildNote(plainText: 'NBNOTE1.aaa.bbb.ccc');

      expect(n.decryptFailed, isTrue);
    });

    test('catatan kosong tidak dianggap gagal dekripsi', () {
      final n = buildNote(content: '', plainText: '');

      expect(n.decryptFailed, isFalse);
    });
  });
}
