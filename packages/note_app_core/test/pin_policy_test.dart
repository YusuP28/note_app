import 'package:note_app_core/note_app_core.dart';
import 'package:test/test.dart';

void main() {
  group('PinPolicy', () {
    test('PIN di bawah 6 digit ditolak', () {
      expect(PinPolicy.isValid('12345'), isFalse);
      expect(PinPolicy.validate('12345'), contains('6 digit'));
    });

    test('PIN di atas 6 digit ditolak', () {
      expect(PinPolicy.isValid('1234567'), isFalse);
      expect(PinPolicy.validate('1234567'), contains('6 digit'));
    });

    test('PIN non-angka ditolak', () {
      expect(PinPolicy.isValid('12a456'), isFalse);
      expect(PinPolicy.validate('12a456'), contains('angka'));
    });

    test('PIN berurutan menaik ditolak', () {
      expect(PinPolicy.isValid('123456'), isFalse);
      expect(PinPolicy.isValid('890123'), isFalse);
    });

    test('PIN berurutan menurun ditolak', () {
      expect(PinPolicy.isValid('654321'), isFalse);
      expect(PinPolicy.isValid('210987'), isFalse);
    });

    test('PIN dengan digit yang sama semua ditolak', () {
      expect(PinPolicy.isValid('111111'), isFalse);
      expect(PinPolicy.isValid('000000'), isFalse);
    });

    test('PIN acak 6 digit diterima', () {
      expect(PinPolicy.isValid('583920'), isTrue);
      expect(PinPolicy.validate('583920'), isNull);
    });

    test('isWeak menandai hanya pola lemah, bukan PIN acak', () {
      expect(PinPolicy.isWeak('123456'), isTrue);
      expect(PinPolicy.isWeak('654321'), isTrue);
      expect(PinPolicy.isWeak('111111'), isTrue);
      expect(PinPolicy.isWeak('583920'), isFalse);
    });

    test('PIN pendek tidak dianggap lemah, hanya tidak valid', () {
      expect(PinPolicy.isWeak('123'), isFalse);
      expect(PinPolicy.isValid('123'), isFalse);
    });
  });
}
