import 'package:note_app_core/note_app_core.dart';
import 'package:test/test.dart';

void main() {
  group('NoteListState', () {
    test('awalnya menampilkan daftar normal dan tidak ada pencarian aktif', () {
      final state = NoteListState<int>();
      state.setNormal([1, 2, 3]);

      expect(state.notes, <int>[1, 2, 3]);
      expect(state.hasSearch, isFalse);
      expect(state.query, isEmpty);
    });

    test('hasil pencarian aktif menggantikan daftar normal', () {
      final state = NoteListState<int>();
      state.setNormal([1, 2, 3]);
      state.mulaiPencarian('kunci');
      state.setSearchResults(<int>[7]);

      expect(state.notes, <int>[7]);
      expect(state.hasSearch, isTrue);
      expect(state.query, 'kunci');
    });

    test('clearSearch mengembalikan daftar normal dan menghapus query', () {
      final state = NoteListState<int>();
      state.setNormal([1, 2, 3]);
      state.mulaiPencarian('kunci');
      state.setSearchResults(<int>[7]);

      state.clearSearch();

      expect(state.notes, <int>[1, 2, 3]);
      expect(state.hasSearch, isFalse);
      expect(state.query, isEmpty);
    });

    test('token pencarian menandai hasil yang sudah basi', () {
      final state = NoteListState<int>();

      final tokenLama = state.mulaiPencarian('kunci');
      final tokenBaru = state.mulaiPencarian('kunci lain');

      expect(state.isStale(tokenLama), isTrue);
      expect(state.isStale(tokenBaru), isFalse);
    });

    test('mulaiPencarian menandai pencarian sedang berjalan', () {
      final state = NoteListState<int>();
      state.setNormal([1, 2, 3]);
      state.mulaiPencarian('kunci');

      expect(state.searching, isTrue);
      expect(state.hasSearch, isFalse);
    });

    test('selama pencarian berjalan daftar normal tidak ditampilkan', () {
      final state = NoteListState<int>();
      state.setNormal([1, 2, 3]);

      state.mulaiPencarian('kunci');

      expect(state.notes, isEmpty);
      expect(state.searching, isTrue);
    });

    test('hasil lama tetap terlihat sampai hasil baru arrives', () {
      final state = NoteListState<int>();
      state.setNormal([1, 2, 3]);
      state.mulaiPencarian('kunci');
      state.setSearchResults(<int>[7]);

      state.mulaiPencarian('kunci lain');

      expect(state.notes, <int>[7]);
      expect(state.searching, isTrue);
    });

    test('clearSearch membatalkan pencarian yang sedang berjalan', () {
      final state = NoteListState<int>();
      final token = state.mulaiPencarian('kunci');

      state.clearSearch();

      expect(state.isStale(token), isTrue);
      expect(state.searching, isFalse);
    });

    test('daftar hasil pencarian tidak bisa diubah diam-diam', () {
      final state = NoteListState<int>();
      state.setNormal([1, 2]);

      expect(() => state.notes.add(3), throwsUnsupportedError);
      expect(() => state.notes[0] = 9, throwsUnsupportedError);
    });
  });
}
