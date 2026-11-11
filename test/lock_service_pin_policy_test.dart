import 'package:flutter_test/flutter_test.dart';
import 'package:note_app/services/lock_service.dart';
import 'package:note_app_core/note_app_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('LockService.setPin', () {
    test('menolak PIN lemah (angka berurutan)', () async {
      expect(
        () => LockService().setPin('123456'),
        throwsA(isA<PinPolicyException>()),
      );
    });

    test('menolak PIN lemah (digit sama semua)', () async {
      expect(
        () => LockService().setPin('111111'),
        throwsA(isA<PinPolicyException>()),
      );
    });

    test('menolak PIN terlalu pendek', () async {
      expect(
        () => LockService().setPin('1234'),
        throwsA(isA<PinPolicyException>()),
      );
    });

    test('menerima PIN acak 6 digit dan mengembalikan backup code', () async {
      final code = await LockService().setPin('583920');

      expect(code, isNotEmpty);
      expect(await LockService().verifyPin('583920'), isTrue);
    });
  });
}
