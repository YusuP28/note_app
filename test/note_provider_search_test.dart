import 'package:flutter_test/flutter_test.dart';
import 'package:note_app/models/note.dart';
import 'package:note_app/providers/note_provider.dart';
import 'package:note_app_core/note_app_core.dart';

/// Baris database palsu untuk menguji provider tanpa sqflite.
Map<String, Object?> baris({
  required String id,
  required String judul,
  String isi = '',
  int tersemat = 0,
  int diarsipkan = 0,
  int diSampah = 0,
  String? notebookId,
  String tagIds = '',
}) =>
    <String, Object?>{
      'id': id,
      'title': judul,
      'content': isi,
      'plain_text': isi,
      'is_pinned': tersemat,
      'is_archived': diarsipkan,
      'is_trashed': diSampah,
      'is_locked': 0,
      'notebook_id': notebookId,
      'created_at': 1704067200000,
      'updated_at': 1704067200000,
      'tag_ids': tagIds,
    };

/// Provider dengan sumber data palsu (tanpa sqflite).
class _ProviderUji extends NoteProvider {
  _ProviderUji({
    this.daftarNormal = const <Map<String, Object?>>[],
    this.barisPencarian = const <Map<String, Object?>>[],
  });

  final List<Map<String, Object?>> daftarNormal;
  final List<Map<String, Object?>> barisPencarian;

  @override
  Future<List<Note>> muatDaftar() async =>
      daftarNormal.map(Note.fromMap).toList();

  @override
  Future<List<Map<String, Object?>>> ambilBarisPencarian(String query) async =>
      barisPencarian;
}

void main() {
  group('NoteProvider - daftar dan pencarian', () {
    test('daftar normal tampil sebelum ada pencarian', () async {
      final provider = _ProviderUji(
        daftarNormal: <Map<String, Object?>>[
          baris(id: 'n1', judul: 'Satu'),
          baris(id: 'n2', judul: 'Dua'),
        ],
      );
      await provider.load();

      expect(provider.notes.map((n) => n.title), <String>['Satu', 'Dua']);
      expect(provider.query, isEmpty);
    });

    test('hasil pencarian menggantikan daftar normal saat aktif', () async {
      final provider = _ProviderUji(
        daftarNormal: <Map<String, Object?>>[
          baris(id: 'n1', judul: 'Satu'),
          baris(id: 'n2', judul: 'Dua'),
        ],
        barisPencarian: <Map<String, Object?>>[
          baris(id: 'n2', judul: 'Dua'),
        ],
      );
      await provider.load();

      await provider.search('dua');

      expect(provider.notes.map((n) => n.title), <String>['Dua']);
      expect(provider.query, 'dua');
    });

    test('clearSearch mengembalikan daftar normal', () async {
      final provider = _ProviderUji(
        daftarNormal: <Map<String, Object?>>[
          baris(id: 'n1', judul: 'Satu'),
          baris(id: 'n2', judul: 'Dua'),
        ],
        barisPencarian: <Map<String, Object?>>[
          baris(id: 'n2', judul: 'Dua'),
        ],
      );
      await provider.load();
      await provider.search('dua');
      expect(provider.notes.map((n) => n.title), <String>['Dua']);

      provider.clearSearch();

      expect(provider.notes.map((n) => n.title), <String>['Satu', 'Dua']);
      expect(provider.query, isEmpty);
    });

    test('pencarian kosong mengembalikan daftar normal', () async {
      final provider = _ProviderUji(
        daftarNormal: <Map<String, Object?>>[
          baris(id: 'n1', judul: 'Satu'),
        ],
        barisPencarian: <Map<String, Object?>>[
          baris(id: 'n2', judul: 'Dua'),
        ],
      );
      await provider.load();
      await provider.search('dua');

      await provider.search('');

      expect(provider.notes.map((n) => n.title), <String>['Satu']);
      expect(provider.query, isEmpty);
    });

    test('pencarian menghormati filter status aktif', () async {
      final provider = _ProviderUji(
        daftarNormal: const <Map<String, Object?>>[],
        barisPencarian: <Map<String, Object?>>[
          baris(id: 'n1', judul: 'Biasa'),
          baris(id: 'n2', judul: 'Semat', tersemat: 1),
        ],
      );
      await provider.load();

      // Filter "Disematkan" -> hanya catatan yang disematkan.
      provider.setFilter(NoteFilter.pinned);
      await provider.search('a');

      expect(provider.notes.map((n) => n.title), <String>['Semat']);
    });

    test('pencarian menghormati filter notebook dan tag aktif', () async {
      final provider = _ProviderUji(
        daftarNormal: const <Map<String, Object?>>[],
        barisPencarian: <Map<String, Object?>>[
          baris(id: 'n1', judul: 'Buku', notebookId: 'nb1'),
          baris(id: 'n2', judul: 'Buku', notebookId: 'nb2'),
          baris(id: 'n3', judul: 'Buku', notebookId: 'nb1', tagIds: 'tag1'),
        ],
      );
      await provider.load();

      provider.setNotebookFilter('nb1');
      await provider.search('buku');
      expect(provider.notes.map((n) => n.id), <String>['n1', 'n3']);

      provider.setNotebookFilter(null);
      provider.setTagFilter('tag1');
      await provider.search('buku');
      expect(provider.notes.map((n) => n.id), <String>['n3']);
    });

    test('pencarian menghormati urutan aktif', () async {
      final provider = _ProviderUji(
        daftarNormal: const <Map<String, Object?>>[],
        barisPencarian: <Map<String, Object?>>[
          baris(id: 'n1', judul: 'Brah'),
          baris(id: 'n2', judul: 'Alfa'),
        ],
      );
      await provider.load();

      provider.setSortBy(SortBy.titleAsc);
      await provider.search('a');

      expect(provider.notes.map((n) => n.title), <String>['Alfa', 'Brah']);
    });

    test('catatan terkunci yang cocok lewat judul tetap ditemukan', () async {
      // Isi terenkripsi (diawali header NBNOTE1) tidak bisa di-LIKE, jadi
      // catatan ini hanya boleh ditemukan lewat judulnya.
      final provider = _ProviderUji(
        daftarNormal: const <Map<String, Object?>>[],
        barisPencarian: <Map<String, Object?>>[
          baris(id: 'n1', judul: 'Rahasia', isi: 'NBNOTE1.abc.def.ghi'),
        ],
      );
      await provider.load();

      await provider.search('rahasia');

      expect(provider.notes.map((n) => n.title), <String>['Rahasia']);
    });
  });
}
