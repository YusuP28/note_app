import 'package:note_app_core/note_app_core.dart';
import 'package:test/test.dart';

/// Catatan palsu untuk menguji logika filter & urutan tanpa Flutter SDK.
class _Catatan implements NoteLike {
  _Catatan({
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.isPinned = false,
    this.isTrashed = false,
    this.isArchived = false,
    this.notebookId,
    this.tagIds = const <String>[],
  });

  @override
  final String title;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;
  final bool isPinned;
  final bool isTrashed;
  final bool isArchived;
  final String? notebookId;
  final List<String> tagIds;
}

/// Bantu shorthand untuk memanggil applyNoteFilters.
List<_Catatan> _saring(
  List<_Catatan> catatan,
  NoteFilter filter, {
  String? notebookId,
  String? tagId,
}) {
  return applyNoteFilters<_Catatan>(
    catatan,
    filter,
    notebookId: notebookId,
    tagId: tagId,
    isPinned: (n) => n.isPinned,
    isTrashed: (n) => n.isTrashed,
    isArchived: (n) => n.isArchived,
    hasTag: (n) => n.tagIds.contains(tagId ?? ''),
    notebookIdOf: (n) => n.notebookId,
  );
}

/// Bantu shorthand untuk memanggil sortNotes.
List<String> _urutkan(
  List<_Catatan> catatan,
  SortBy sortBy, {
  NoteFilter filter = NoteFilter.all,
}) {
  return sortNotes<_Catatan>(
    catatan,
    sortBy,
    asNote: (n) => n,
    filter: filter,
    isPinned: (n) => n.isPinned,
  ).map((n) => n.title).toList();
}

void main() {
  final t0 = DateTime(2024, 1, 1);
  final t1 = DateTime(2024, 6, 1);
  final t2 = DateTime(2024, 11, 1);

  group('matchesFilter', () {
    test('filter all menerima catatan normal dan menolak trash/arsip', () {
      expect(
        matchesFilter(NoteFilter.all,
            isTrashed: false, isArchived: false, isPinned: false),
        isTrue,
      );
      expect(
        matchesFilter(NoteFilter.all,
            isTrashed: true, isArchived: false, isPinned: false),
        isFalse,
      );
      expect(
        matchesFilter(NoteFilter.all,
            isTrashed: false, isArchived: true, isPinned: false),
        isFalse,
      );
    });

    test('filter pinned hanya menerima catatan yang disematkan', () {
      expect(
        matchesFilter(NoteFilter.pinned,
            isTrashed: false, isArchived: false, isPinned: true),
        isTrue,
      );
      expect(
        matchesFilter(NoteFilter.pinned,
            isTrashed: false, isArchived: false, isPinned: false),
        isFalse,
      );
      expect(
        matchesFilter(NoteFilter.pinned,
            isTrashed: true, isArchived: false, isPinned: true),
        isFalse,
      );
      expect(
        matchesFilter(NoteFilter.pinned,
            isTrashed: false, isArchived: true, isPinned: true),
        isFalse,
      );
    });

    test('filter archived menolak catatan trash walau sudah diarsipkan', () {
      expect(
        matchesFilter(NoteFilter.archived,
            isTrashed: false, isArchived: true, isPinned: false),
        isTrue,
      );
      expect(
        matchesFilter(NoteFilter.archived,
            isTrashed: false, isArchived: false, isPinned: false),
        isFalse,
      );
      expect(
        matchesFilter(NoteFilter.archived,
            isTrashed: true, isArchived: true, isPinned: false),
        isFalse,
      );
    });

    test('filter trashed hanya menerima catatan yang di trash', () {
      expect(
        matchesFilter(NoteFilter.trashed,
            isTrashed: true, isArchived: false, isPinned: false),
        isTrue,
      );
      expect(
        matchesFilter(NoteFilter.trashed,
            isTrashed: false, isArchived: false, isPinned: false),
        isFalse,
      );
    });
  });

  group('applyNoteFilters', () {
    final alpha = _Catatan(
      title: 'Alpha',
      createdAt: t0,
      updatedAt: t0,
      notebookId: 'nb1',
      tagIds: const <String>['tag1'],
    );
    final beta = _Catatan(
      title: 'Beta',
      createdAt: t0,
      updatedAt: t0,
      notebookId: 'nb2',
      tagIds: const <String>['tag2'],
    );
    final gamma = _Catatan(
      title: 'Gamma',
      createdAt: t0,
      updatedAt: t0,
      notebookId: 'nb1',
      tagIds: const <String>['tag1', 'tag2'],
    );
    final semua = <_Catatan>[alpha, beta, gamma];

    test('tanpa filter notebook dan tag semua catatan lolos', () {
      final hasil = _saring(semua, NoteFilter.all);
      expect(hasil.map((n) => n.title), <String>['Alpha', 'Beta', 'Gamma']);
    });

    test('filter notebook menyisakan catatan pada notebook yang dipilih', () {
      final hasil = _saring(semua, NoteFilter.all, notebookId: 'nb1');
      expect(hasil.map((n) => n.title), <String>['Alpha', 'Gamma']);
    });

    test('filter tag menyisakan catatan yang punya tag tersebut', () {
      final hasil = _saring(semua, NoteFilter.all, tagId: 'tag2');
      expect(hasil.map((n) => n.title), <String>['Beta', 'Gamma']);
    });

    test('kombinasi filter notebook dan tag berlaku bersamaan', () {
      final hasil =
          _saring(semua, NoteFilter.all, notebookId: 'nb1', tagId: 'tag2');
      expect(hasil.map((n) => n.title), <String>['Gamma']);
    });

    test('filter status tetap berlaku bersama filter notebook', () {
      final arsip = _Catatan(
        title: 'Arsip',
        createdAt: t0,
        updatedAt: t0,
        isArchived: true,
        notebookId: 'nb1',
      );
      final hasil =
          _saring(<_Catatan>[alpha, arsip], NoteFilter.all, notebookId: 'nb1');
      expect(hasil.map((n) => n.title), <String>['Alpha']);

      final hasilArsip = _saring(
          <_Catatan>[alpha, arsip], NoteFilter.archived, notebookId: 'nb1');
      expect(hasilArsip.map((n) => n.title), <String>['Arsip']);
    });

    test('filter trashed menampilkan catatan yang di trash', () {
      final sampah = _Catatan(
        title: 'Sampah',
        createdAt: t0,
        updatedAt: t0,
        isTrashed: true,
      );
      final hasil = _saring(<_Catatan>[alpha, sampah], NoteFilter.trashed);
      expect(hasil.map((n) => n.title), <String>['Sampah']);
    });
  });

  group('sortNotes', () {
    final a = _Catatan(title: 'Bravo', createdAt: t0, updatedAt: t0);
    final b = _Catatan(title: 'Charlie', createdAt: t1, updatedAt: t2);
    final c = _Catatan(title: 'Alpha', createdAt: t2, updatedAt: t1);
    final semua = <_Catatan>[a, b, c];
    final pinned = _Catatan(
      title: 'Zulu',
      createdAt: t0,
      updatedAt: t0,
      isPinned: true,
    );

    test('updatedDesc menaruh yang terbaru diubah dulu', () {
      expect(_urutkan(semua, SortBy.updatedDesc),
          <String>['Charlie', 'Alpha', 'Bravo']);
    });

    test('updatedAsc menaruh yang terlama diubah dulu', () {
      expect(_urutkan(semua, SortBy.updatedAsc),
          <String>['Bravo', 'Alpha', 'Charlie']);
    });

    test('createdDesc dan createdAsc memakai createdAt', () {
      expect(_urutkan(semua, SortBy.createdDesc),
          <String>['Alpha', 'Charlie', 'Bravo']);
      expect(_urutkan(semua, SortBy.createdAsc),
          <String>['Bravo', 'Charlie', 'Alpha']);
    });

    test('titleAsc dan titleDesc membandingkan judul case-insensitive', () {
      expect(_urutkan(semua, SortBy.titleAsc), <String>['Alpha', 'Bravo', 'Charlie']);
      expect(_urutkan(semua, SortBy.titleDesc), <String>['Charlie', 'Bravo', 'Alpha']);
    });

    test('catatan disematkan di atas untuk semua SortBy', () {
      for (final sortBy in SortBy.values) {
        final hasil = _urutkan(<_Catatan>[a, b, pinned], sortBy);
        expect(hasil.first, 'Zulu', reason: 'pinned harus di atas untuk $sortBy');
      }
    });

    test('urutan judul tetap menyematkan catatan di atas', () {
      final hasil = _urutkan(<_Catatan>[pinned, a], SortBy.titleAsc);
      expect(hasil, <String>['Zulu', 'Bravo']);
      expect(_urutkan(<_Catatan>[pinned, a], SortBy.titleDesc),
          <String>['Zulu', 'Bravo']);
    });

    test('filter arsip dan sampah tidak memisahkan pinned di atas', () {
      final daftar = <_Catatan>[c, pinned];
      expect(
        _urutkan(daftar, SortBy.updatedDesc, filter: NoteFilter.archived),
        <String>['Alpha', 'Zulu'],
      );
      expect(
        _urutkan(daftar, SortBy.updatedDesc, filter: NoteFilter.trashed),
        <String>['Alpha', 'Zulu'],
      );
    });
  });
}
