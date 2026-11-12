/// State daftar catatan: daftar normal + hasil pencarian aktif - pure Dart.
///
/// Dipisah dari `NoteProvider` supaya perilaku "hasil pencarian tidak
/// mencemari daftar utama" bisa diuji tanpa Flutter SDK maupun database.
library;

/// Menyimpan daftar normal (hasil filter + urutan) dan hasil pencarian aktif.
///
/// Aturan dasarnya:
/// - [notes] menampilkan hasil pencarian kalau ada, kalau tidak daftar normal.
/// - Selama pencarian berjalan ([searching]) dan belum ada hasil, [notes]
///   sengaja kosong supaya daftar normal tidak ikut terlihat sebagai
///   "hasil pencarian".
/// - [clearSearch] membuang hasil pencarian dan mengembalikan daftar normal.
class NoteListState<T> {
  List<T> _normal = const [];
  List<T>? _searchResults;
  String _query = '';
  int _searchToken = 0;
  bool _searching = false;

  /// Daftar yang ditampilkan: hasil pencarian kalau ada, kalau tidak daftar
  /// normal.
  List<T> get notes {
    final hasil = _searchResults;
    if (hasil != null) return List<T>.unmodifiable(hasil);
    if (_searching) return List<T>.unmodifiable(const []);
    return List<T>.unmodifiable(_normal);
  }

  /// Daftar normal (setelah filter + urutan).
  List<T> get normal => List<T>.unmodifiable(_normal);

  /// Hasil pencarian aktif, `null` kalau belum ada hasil pencarian.
  List<T>? get searchResults =>
      _searchResults == null ? null : List<T>.unmodifiable(_searchResults!);

  /// Kata kunci pencarian terakhir.
  String get query => _query;

  /// Apakah ada hasil pencarian aktif?
  bool get hasSearch => _searchResults != null;

  /// Apakah pencarian sedang berjalan (belum ada hasil)?
  bool get searching => _searching;

  /// Token pencarian terakhir - dipakai untuk membatalkan hasil yang basi.
  int get searchToken => _searchToken;

  /// Ganti daftar normal.
  void setNormal(List<T> nilai) => _normal = List<T>.of(nilai);

  /// Simpan hasil pencarian aktif.
  void setSearchResults(List<T> nilai) {
    _searchResults = List<T>.of(nilai);
    _searching = false;
  }

  /// Mulai pencarian baru.
  ///
  /// Hasil pencarian sebelumnya tetap terlihat sampai hasil baru arrives, jadi
  /// tidak ada kedipan kosong. [searching] menandakan pencarian masih jalan.
  ///
  /// Mengembalikan token pencarian. Hasil pencarian dengan token yang lebih
  /// lama harus diabaikan (lihat [isStale]).
  int mulaiPencarian(String query) {
    _query = query;
    _searchToken++;
    _searching = true;
    return _searchToken;
  }

  /// Apakah [token] sudah basi, jadi hasilnya harus diabaikan?
  bool isStale(int token) => token != _searchToken;

  /// Hapus hasil pencarian aktif -> kembali ke daftar normal.
  ///
  /// Pencarian yang sedang berjalan dibatalkan (token-nya naik).
  void clearSearch() {
    _searchToken++;
    _searchResults = null;
    _searching = false;
    _query = '';
  }
}
