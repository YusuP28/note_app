import 'dart:convert';

import 'package:note_app_core/note_app_core.dart';

/// Menyembunyikan konten catatan terkunci di database SQLite.
///
/// Kolom `content` dan `plain_text` untuk catatan ber-`is_locked = 1` disimpan
/// sebagai ciphertext AES-256-GCM. Kunci disimpan di Android Keystore, jadi
/// plaintext tidak lagi bocor ke file database, ke backup, atau ke dump SQL.
///
/// Catatan yang TIDAK dikunci tetap plaintext - supaya pencarian global
/// (`plain_text LIKE ?`) tetap bekerja tanpa mendekripsi semua baris.
class NoteContentCipher {
  final NoteCipher? _cipher;

  NoteContentCipher._(this._cipher);

  /// Tanpa enkripsi (fallback saat kunci tidak tersedia).
  factory NoteContentCipher.disabled() => NoteContentCipher._(null);

  /// Dengan kunci dari [LocalKeyService].
  static Future<NoteContentCipher> fromKey(List<int> key) async =>
      NoteContentCipher._(NoteCipher(key));

  bool get isEnabled => _cipher != null;

  /// Enkripsi konten bila catatan terkunci.
  ///
  /// Status lock dibaca dari kolom `is_locked` di row itu sendiri - satu
  /// sumber kebenaran, supaya tidak mungkin salah pass flag dan membuat
  /// catatan tak terkunci ikut terenkripsi (atau sebaliknya).
  Map<String, dynamic> encryptRow(Map<String, dynamic> row) {
    if (!isEnabled) return row;
    if (!_isLocked(row)) return row;
    final out = Map<String, dynamic>.from(row);
    out['content'] = _encryptOrKeep(row['content'] as String?);
    out['plain_text'] = _encryptOrKeep(row['plain_text'] as String?);
    return out;
  }

  /// Apakah row ini menandai catatan terkunci?
  static bool _isLocked(Map<String, dynamic> row) {
    final value = row['is_locked'];
    if (value is int) return value == 1;
    if (value is bool) return value;
    return false;
  }

  /// Dekripsi konten bila ciphertext.
  Map<String, dynamic> decryptRow(Map<String, dynamic> row) {
    if (!isEnabled) return row;
    final out = Map<String, dynamic>.from(row);
    out['content'] = _decryptOrKeep(row['content'] as String?);
    out['plain_text'] = _decryptOrKeep(row['plain_text'] as String?);
    return out;
  }

  String _encryptOrKeep(String? value) {
    if (value == null || value.isEmpty) return value ?? '';
    if (_cipher!.isEncrypted(value)) return value;
    return _cipher!.encrypt(value);
  }

  /// Dekripsi satu teks bila masih berupa ciphertext.
  ///
  /// Dipakai oleh editor: konten catatan terkunci harus didekripsi **sebelum**
  /// dirender dan sebelum di-highlight, supaya yang tampil (dan yang disorot)
  /// adalah isi catatan, bukan sandi.
  ///
  /// Kalau dekripsi gagal (kunci berubah / data rusak), nilai asli dikembalikan
  /// apa adanya - lebih baik menampilkan sandi daripada menghapus isi catatan.
  String decryptText(String value) {
    if (!isEnabled) return value;
    return _cipher!.decryptOrKeep(value);
  }

  /// Dekripsi satu kolom, tanpa pernah menghapus isinya.
  ///
  /// Kalau dekripsi gagal, ciphertext ASLI dikembalikan apa adanya. Nilai
  /// kosong akan membuat catatan terkunci yang tersimpan ulang menimpa isinya
  /// yang asli dengan data kosong (data loss). Ciphertext yang masih utuh
  /// bisa dikenali lewat `NoteCipher.isEncryptedText` supaya UI bisa
  /// memberi tahu user.
  String _decryptOrKeep(String? value) {
    if (value == null || value.isEmpty) return value ?? '';
    return _cipher!.decryptOrKeep(value);
  }

  /// Helper untuk JSON delta (konten Quill).
  static String encodeDelta(Object? delta) => jsonEncode(delta);
}
