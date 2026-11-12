/// Opsi pengurutan catatan beserta label Bahasa Indonesia.
///
/// Enum ini berada di package pure-Dart (`note_app_core`) supaya logika
/// pengurutan bisa diuji tanpa Flutter SDK.
enum SortBy {
  updatedDesc,
  updatedAsc,
  createdDesc,
  createdAsc,
  titleAsc,
  titleDesc,
}

/// Label Bahasa Indonesia untuk setiap opsi pengurutan.
extension SortByLabel on SortBy {
  String get label => switch (this) {
        SortBy.updatedDesc => 'Terbaru diubah',
        SortBy.updatedAsc => 'Terlama diubah',
        SortBy.createdDesc => 'Terbaru dibuat',
        SortBy.createdAsc => 'Terlama dibuat',
        SortBy.titleAsc => 'Judul A-Z',
        SortBy.titleDesc => 'Judul Z-A',
      };
}

/// Bentuk minimal data catatan yang dibutuhkan untuk pengurutan.
///
/// Dipakai agar comparator tidak bergantung pada model `Note` aplikasi
/// (yang butuh Flutter SDK).
abstract interface class NoteLike {
  String get title;
  DateTime get createdAt;
  DateTime get updatedAt;
}

/// Membandingkan dua catatan sesuai opsi pengurutan [sortBy].
///
/// Mengembalikan nilai negatif bila [a] mendahului [b], positif bila [a]
/// sesudah [b], dan 0 bila keduanya dianggap sama.
int compareNotes(SortBy sortBy, NoteLike a, NoteLike b) {
  switch (sortBy) {
    case SortBy.updatedDesc:
      return b.updatedAt.compareTo(a.updatedAt);
    case SortBy.updatedAsc:
      return a.updatedAt.compareTo(b.updatedAt);
    case SortBy.createdDesc:
      return b.createdAt.compareTo(a.createdAt);
    case SortBy.createdAsc:
      return a.createdAt.compareTo(b.createdAt);
    case SortBy.titleAsc:
      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    case SortBy.titleDesc:
      return b.title.toLowerCase().compareTo(a.title.toLowerCase());
  }
}
