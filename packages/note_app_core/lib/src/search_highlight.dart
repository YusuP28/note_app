/// Posisi highlight kata kunci - pure Dart (tanpa Flutter).
///
/// Dipisah dari `edit_screen.dart` supaya aturan pencocokan kata kunci
/// (case-insensitive, tanpa menggeser offset highlight) bisa diuji tanpa
/// Flutter SDK.
library;

/// Posisi (offset) semua kemunculan [query] di dalam [teks].
///
/// Pencocokan bersifat case-insensitive, tetapi **offset selalu merujuk ke
/// [teks] asli**. Tidak ada salinan lowercase yang dipakai sebagai acuan,
/// sehingga posisi highlight tidak bergeser untuk karakter yang bentuk
/// lowercase-nya panjangnya berbeda (mis. 'İ' -> 'i̇').
///
/// Kemunculan yang tumpang tindih tidak dihitung dua kali: setelah sebuah
/// kecocokan ditemukan, pencarian lanjut dari `pos + query.length`.
///
/// Panjang kata kunci yang dipakai untuk menyorot teks adalah
/// `query.length` (panjang asli, bukan panjang lowercase-nya).
List<int> cariPosisiHighlight(String teks, String query) {
  if (query.isEmpty || teks.isEmpty) return const <int>[];
  if (query.length > teks.length) return const <int>[];

  final hasil = <int>[];
  var pos = 0;
  final batas = teks.length - query.length;
  while (pos <= batas) {
    if (_cocokDi(teks, pos, query)) {
      hasil.add(pos);
      pos += query.length;
    } else {
      pos++;
    }
  }
  return hasil;
}

/// Apakah [query] cocok dengan [teks] mulai offset [pos] (case-insensitive)?
bool _cocokDi(String teks, int pos, String query) {
  for (var i = 0; i < query.length; i++) {
    if (!_samaUnit(teks.codeUnitAt(pos + i), query.codeUnitAt(i))) return false;
  }
  return true;
}

/// Sama persis, atau sama setelah bentuk lowercase-nya (1 unit sama 1 unit).
///
/// Kalau bentuk lowercase-nya lebih dari satu unit (mis. 'İ' -> 'i̇'),
/// karakter dianggap berbeda supaya panjang teks tidak pernah berubah dan
/// offset highlight tetap akurat.
bool _samaUnit(int a, int b) {
  if (a == b) return true;
  final la = String.fromCharCode(a).toLowerCase();
  final lb = String.fromCharCode(b).toLowerCase();
  if (la.length != 1 || lb.length != 1) return false;
  return la.codeUnitAt(0) == lb.codeUnitAt(0);
}
