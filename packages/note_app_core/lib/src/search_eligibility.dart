/// Kelayakan baris hasil pencarian global - pure Dart (tanpa Flutter).
///
/// Dipisah dari `note_provider.dart` supaya aturan ini bisa diuji tanpa
/// Flutter SDK maupun database.
library;

import 'note_cipher.dart';

/// Apakah baris hasil pencarian layak ditampilkan di UI?
///
/// [judul] dan [plainTersimpan] diambil dari baris database apa adanya,
/// sedangkan [plainDidekripsi] adalah isi setelah proses dekripsi.
///
/// Catatan terkunci menyimpan `plain_text` sebagai ciphertext, sehingga
/// hasil `LIKE` atas kolom itu bisa cocok secara kebetulan. Karena itu:
///
/// - Kalau kata kunci cocok di [judul] (judul tidak dienkripsi) -> layak.
/// - Kalau isi biasa (bukan ciphertext) -> `LIKE` sudah mencocokkan teks
///   asli -> layak.
/// - Kalau isinya ciphertext -> hanya layak kalau isi hasil dekripsi
///   benar-benar mengandung kata kunci. Kalau dekripsi gagal, isinya masih
///   ciphertext sehingga tidak boleh tampil.
bool catatanLayakTampil({
  required String? judul,
  required String? plainTersimpan,
  required String? plainDidekripsi,
  required String query,
}) {
  final kunci = query.trim().toLowerCase();
  if (kunci.isEmpty) return false;

  // Judul disimpan sebagai plaintext, jadi cocok lewat judul selalu sah.
  if ((judul ?? '').toLowerCase().contains(kunci)) return true;

  final tersimpan = plainTersimpan ?? '';
  if (!NoteCipher.isEncryptedText(tersimpan)) {
    // Isi biasa: `LIKE` sudah mencocokkan teks aslinya.
    return true;
  }

  // Isi terenkripsi: yang dicari hanya isi hasil dekripsi.
  final didekripsi = plainDidekripsi ?? '';
  if (didekripsi == tersimpan) return false; // dekripsi gagal
  return didekripsi.toLowerCase().contains(kunci);
}
