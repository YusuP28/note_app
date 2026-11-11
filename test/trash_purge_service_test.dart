import 'package:flutter_test/flutter_test.dart';
import 'package:note_app/services/trash_purge_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Waktu acuan supaya test tidak bergantung waktu nyata.
  final now = DateTime(2026, 11, 11, 8, 0, 0);

  group('TrashPurgeService.shouldRun', () {
    test('true kalau belum pernah purge (lastRun null)', () async {
      final hasil = await TrashPurgeService.shouldRun(
        lastRun: null,
        days: 30,
        now: now,
      );

      expect(hasil, isTrue);
    });

    test('false kalau purge terakhir 1 jam lalu (belum 1 hari)', () async {
      final hasil = await TrashPurgeService.shouldRun(
        lastRun: now.subtract(const Duration(hours: 1)),
        days: 30,
        now: now,
      );

      expect(hasil, isFalse);
    });

    test('true kalau purge terakhir 2 hari lalu', () async {
      final hasil = await TrashPurgeService.shouldRun(
        lastRun: now.subtract(const Duration(days: 2)),
        days: 30,
        now: now,
      );

      expect(hasil, isTrue);
    });

    test('true kalau purge terakhir tepat 1 hari lalu (>= 1 hari penuh)', () async {
      final hasil = await TrashPurgeService.shouldRun(
        lastRun: now.subtract(const Duration(days: 1)),
        days: 30,
        now: now,
      );

      expect(hasil, isTrue);
    });

    test('false kalau purge terakhir hampir 1 hari lalu (kurang dari 1 hari)', () async {
      final hasil = await TrashPurgeService.shouldRun(
        lastRun: now.subtract(const Duration(days: 1, seconds: -1)),
        days: 30,
        now: now,
      );

      expect(hasil, isFalse);
    });
  });

  group('TrashPurgeService.runIfDue', () {
    late List<int> hariPurge;

    setUp(() {
      hariPurge = <int>[];
      SharedPreferences.setMockInitialValues({});
    });

    TrashPurgeService buatService() => TrashPurgeService(
          purge: (days) async => hariPurge.add(days),
        );

    test('purge dijalankan saat belum pernah jalan, lalu timestamp disimpan', () async {
      final service = buatService();

      await service.runIfDue(days: 30);

      expect(hariPurge, <int>[30]);

      final prefs = await SharedPreferences.getInstance();
      final tersimpan = prefs.getInt(TrashPurgeService.lastRunKey);
      expect(tersimpan, isNotNull);
      expect(tersimpan, isPositive);
    });

    test('purge tidak dijalankan kalau terakhir jalan kurang dari 1 hari', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
        TrashPurgeService.lastRunKey,
        DateTime.now().subtract(const Duration(hours: 2)).millisecondsSinceEpoch,
      );

      final service = buatService();
      await service.runIfDue(days: 30);

      expect(hariPurge, isEmpty);

      // Timestamp lama tidak boleh ditimpa.
      final setelah = prefs.getInt(TrashPurgeService.lastRunKey);
      expect(setelah, isNotNull);
    });

    test('purge dijalankan lagi kalau sudah lewat 1 hari', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
        TrashPurgeService.lastRunKey,
        DateTime.now().subtract(const Duration(days: 3)).millisecondsSinceEpoch,
      );

      final service = buatService();
      await service.runIfDue(days: 30);

      expect(hariPurge, <int>[30]);

      final setelah = prefs.getInt(TrashPurgeService.lastRunKey);
      expect(setelah, isNotNull);
      expect(setelah,
          greaterThan(DateTime.now()
              .subtract(const Duration(days: 3))
              .millisecondsSinceEpoch));
    });

    test('timestamp tidak disimpan kalau purge gagal', () async {
      final service = TrashPurgeService(
        purge: (days) async => throw Exception('gagal'),
      );

      await expectLater(service.runIfDue(days: 30), throwsException);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt(TrashPurgeService.lastRunKey), isNull);
    });
  });
}
