import 'package:note_app_core/note_app_core.dart';
import 'package:test/test.dart';

class _Note implements NoteLike {
  _Note(this.title, this.createdAt, this.updatedAt);
  @override
  final String title;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;
}

void main() {
  final t0 = DateTime(2024, 1, 1);
  final t1 = DateTime(2024, 6, 1);

  group('SortBy', () {
    test('label Bahasa Indonesia untuk setiap opsi', () {
      expect(SortBy.updatedDesc.label, 'Terbaru diubah');
      expect(SortBy.updatedAsc.label, 'Terlama diubah');
      expect(SortBy.createdDesc.label, 'Terbaru dibuat');
      expect(SortBy.createdAsc.label, 'Terlama dibuat');
      expect(SortBy.titleAsc.label, 'Judul A-Z');
      expect(SortBy.titleDesc.label, 'Judul Z-A');
    });

    test('updatedDesc menaruh yang terbaru dulu', () {
      final a = _Note('a', t0, t1);
      final b = _Note('b', t0, t0);
      expect(compareNotes(SortBy.updatedDesc, a, b), lessThan(0));
    });

    test('updatedAsc menaruh yang terlama dulu', () {
      final a = _Note('a', t0, t1);
      final b = _Note('b', t0, t0);
      expect(compareNotes(SortBy.updatedAsc, a, b), greaterThan(0));
    });

    test('createdDesc dan createdAsc memakai createdAt', () {
      final a = _Note('a', t1, t0);
      final b = _Note('b', t0, t1);
      expect(compareNotes(SortBy.createdDesc, a, b), lessThan(0));
      expect(compareNotes(SortBy.createdAsc, a, b), greaterThan(0));
    });

    test('titleAsc dan titleDesc membandingkan judul case-insensitive', () {
      final a = _Note('Apple', t0, t0);
      final b = _Note('banana', t0, t0);
      expect(compareNotes(SortBy.titleAsc, a, b), lessThan(0));
      expect(compareNotes(SortBy.titleDesc, a, b), greaterThan(0));
    });

    test('judul sama menghasilkan perbandingan 0', () {
      final a = _Note('Sama', t0, t0);
      final b = _Note('sama', t0, t0);
      expect(compareNotes(SortBy.titleAsc, a, b), 0);
    });
  });
}
