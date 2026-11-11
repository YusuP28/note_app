/// Logika filter & urutan catatan - pure Dart (tanpa Flutter).
///
/// Dipisah dari `note_provider.dart` supaya aturan filter (status, notebook,
/// tag) dan aturan urutan (pinned di atas, sesuai `SortBy`) bisa diuji
/// tanpa Flutter SDK.
library;

import 'sort_options.dart';

/// Status filter catatan yang dipakai pengguna.
enum NoteFilter { all, pinned, archived, trashed }

/// Apakah catatan lolos [filter]?
///
/// `true` berarti catatan **tetap ditampilkan** untuk filter tersebut.
/// Aturan ini disalin persis dari logika `_applyFilter` lama di aplikasi.
bool matchesFilter(
  NoteFilter filter, {
  required bool isTrashed,
  required bool isArchived,
  required bool isPinned,
}) {
  switch (filter) {
    case NoteFilter.all:
      return !(isTrashed || isArchived);
    case NoteFilter.pinned:
      return isPinned && !isTrashed && !isArchived;
    case NoteFilter.archived:
      return isArchived && !isTrashed;
    case NoteFilter.trashed:
      return isTrashed;
  }
}

/// Tersaring catatan sesuai filter status + notebook + tag.
///
/// - [notebookId] - notebook yang sedang difilter (`null` = semua notebook).
/// - [tagId] - tag yang sedang difilter (`null` = semua tag).
/// - [hasTag] - apakah catatan punya tag [tagId] yang sedang difilter.
///   Callback ini harus dicek terhadap tag yang sama dengan [tagId].
/// - [notebookIdOf] - id notebook milik sebuah catatan.
List<T> applyNoteFilters<T>(
  List<T> notes,
  NoteFilter filter, {
  String? notebookId,
  String? tagId,
  required bool Function(T) isPinned,
  required bool Function(T) isTrashed,
  required bool Function(T) isArchived,
  required bool Function(T) hasTag,
  required String? Function(T) notebookIdOf,
}) {
  final hasil = <T>[];
  for (final catatan in notes) {
    if (!matchesFilter(
      filter,
      isTrashed: isTrashed(catatan),
      isArchived: isArchived(catatan),
      isPinned: isPinned(catatan),
    )) {
      continue;
    }
    if (notebookId != null && notebookIdOf(catatan) != notebookId) continue;
    if (tagId != null && !hasTag(catatan)) continue;
    hasil.add(catatan);
  }
  return hasil;
}

/// Mengurutkan catatan sesuai [sortBy].
///
/// Catatan yang disematkan (pinned) diletakkan di atas **hanya** bila
/// [filter] adalah [NoteFilter.all] atau [NoteFilter.pinned] - jadi saat
/// pengguna melihat arsip/sampah, urutan murni mengikuti [sortBy].
///
/// Pengurutan judul ([SortBy.titleAsc] / [SortBy.titleDesc]) juga murni
/// judul: tidak ada pemisahan pinned, jadi daftarnya benar-benar terurut A-Z.
///
/// [isPinned] boleh `null` kalau pemanggil tidak butuh pemisahan pinned.
List<T> sortNotes<T>(
  List<T> notes,
  SortBy sortBy, {
  required NoteLike Function(T) asNote,
  NoteFilter filter = NoteFilter.all,
  bool Function(T)? isPinned,
}) {
  final daftar = List<T>.of(notes);
  final bool judulMurni = sortBy == SortBy.titleAsc || sortBy == SortBy.titleDesc;
  final bool pinnedDiAtas = !judulMurni &&
      isPinned != null &&
      (filter == NoteFilter.all || filter == NoteFilter.pinned);
  daftar.sort((a, b) {
    if (pinnedDiAtas) {
      final aPinned = isPinned(a);
      final bPinned = isPinned(b);
      if (aPinned != bPinned) return aPinned ? -1 : 1;
    }
    return compareNotes(sortBy, asNote(a), asNote(b));
  });
  return daftar;
}
