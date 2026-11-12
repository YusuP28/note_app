import 'package:note_app_core/note_app_core.dart';

/// Enkripsi konten catatan terkunci (kolom `content` dan `plain_text`).
///
/// Catatan yang dikunci user disimpan terenkripsi di SQLite sehingga plaintext
/// tidak bocor ke database file, ke backup, maupun ke dump SQL.
///
/// Ciphertext bersifat self-describing (memakai magic header), jadi data
/// lama yang belum terenkripsi tetap bisa dibaca tanpa error.
class NoteCipher {
  final BackupCrypto _crypto;

  NoteCipher(List<int> key) : _crypto = BackupCrypto(key);

  /// Enkripsi teks. Output sudah self-describing (ada magic header).
  String encrypt(String plaintext) => _crypto.encryptString(plaintext);

  /// Dekripsi teks.
  ///
  /// Jika teks tidak terenkripsi (mis. catatan lama sebelum fitur ini aktif),
  /// dikembalikan apa adanya supaya tidak kehilangan data.
  String decrypt(String value) {
    if (!value.startsWith(BackupCrypto.magic)) return value;
    return _crypto.decryptString(value);
  }

  /// Dekripsi teks, tapi TIDAK PERNAH menghapus isinya.
  ///
  /// Kalau dekripsi gagal (kunci berubah / data rusak / ciphertext rusak),
  /// nilai asli dikembalikan apa adanya. Nilai kosong atau string error akan
  /// membuat catatan terkunci yang tersimpan ulang menimpa isi aslinya dengan
  /// data kosong - itu data loss. Lebih baik isinya tetap berupa ciphertext
  /// (yang bisa dikenali lewat [isEncryptedText]) daripada hilang.
  String decryptOrKeep(String value) {
    if (value.isEmpty) return value;
    if (!isEncryptedText(value)) return value;
    try {
      return _crypto.decryptString(value);
    } catch (_) {
      return value;
    }
  }

  /// Apakah nilai ini hasil enkripsi NoteCipher?
  bool isEncrypted(String value) => NoteCipher.isEncryptedText(value);

  /// Apakah nilai ini tampak seperti ciphertext hasil enkripsi NoteCipher?
  ///
  /// Bisa dipakai tanpa instance NoteCipher (mis. untuk memeriksa nilai yang
  /// diambil langsung dari database sebelum didekripsi).
  static bool isEncryptedText(String value) =>
      value.startsWith(BackupCrypto.magic);
}
