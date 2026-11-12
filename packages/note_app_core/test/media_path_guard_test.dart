import 'package:note_app_core/note_app_core.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('MediaPathGuard', () {
    final root = p.join('/data', 'app', 'docs', 'attachments');

    test('toRelative mengubah path di dalam root jadi path relatif', () {
      final absolute = p.join(root, 'img', 'a.png');

      expect(toRelativeMediaPath(absolute, root), 'attachments/img/a.png');
    });

    test('toRelative mengembalikan nilai apa adanya untuk path di luar root', () {
      expect(
        toRelativeMediaPath('/etc/passwd', root),
        '/etc/passwd',
      );
    });

    test('toAbsolute mengubah path relatif jadi path absolut di dalam root', () {
      expect(
        toAbsoluteMediaPath('attachments/img/a.png', root),
        p.join(root, 'img', 'a.png'),
      );
    });

    test('toAbsolute menolak path traversal ../', () {
      expect(
        () => toAbsoluteMediaPath('attachments/../../../../etc/passwd', root),
        throwsA(isA<MediaPathException>()),
      );
    });

    test('toAbsolute menolak path traversal tersembunyi di tengah path', () {
      expect(
        () => toAbsoluteMediaPath('attachments/img/../../../etc/passwd', root),
        throwsA(isA<MediaPathException>()),
      );
    });

    test('toAbsolute menolak path traversal dengan backslash', () {
      expect(
        () => toAbsoluteMediaPath(r'attachments\..\..\..\etc\passwd', root),
        throwsA(isA<MediaPathException>()),
      );
    });

    test('toAbsolute menolak path traversal ke root itu sendiri', () {
      expect(
        () => toAbsoluteMediaPath('attachments/..', root),
        throwsA(isA<MediaPathException>()),
      );
    });

    test('toAbsolute menerima null dan string kosong', () {
      expect(toAbsoluteMediaPath(null, root), isNull);
      expect(toAbsoluteMediaPath('', root), '');
    });

    test('toAbsolute mengembalikan nilai apa adanya untuk path non-attachment', () {
      expect(toAbsoluteMediaPath('/sdcard/other.png', root), '/sdcard/other.png');
    });
  });
}
