import 'package:note_app_core/note_app_core.dart';
import 'package:test/test.dart';

void main() {
  group('LockoutPolicy', () {
    test('kegagalan di bawah batas tidak mengunci', () {
      for (var fails = 0; fails < LockoutPolicy.freeAttempts; fails++) {
        final decision = LockoutPolicy.decide(fails);
        expect(decision.lockSeconds, 0);
        expect(decision.isLocked, isFalse);
        expect(decision.failCount, fails);
      }
    });

    test('kegagalan ke-5 mengunci 30 detik', () {
      final decision = LockoutPolicy.decide(5);

      expect(decision.lockSeconds, LockoutPolicy.shortLockSeconds);
      expect(decision.isLocked, isTrue);
    });

    test('kegagalan ke-10 mengunci 5 menit', () {
      final decision = LockoutPolicy.decide(10);

      expect(decision.lockSeconds, LockoutPolicy.longLockSeconds);
    });

    test('kegagalan di atas 10 tetap 5 menit', () {
      expect(LockoutPolicy.decide(50).lockSeconds, LockoutPolicy.longLockSeconds);
    });

    test('jumlah kegagalan negatif dinormalisasi ke 0', () {
      final decision = LockoutPolicy.decide(-5);

      expect(decision.failCount, 0);
      expect(decision.lockSeconds, 0);
    });
  });
}
