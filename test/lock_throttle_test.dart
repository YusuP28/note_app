// Pure-Dart test. Jalankan: dart test/lock_throttle_test.dart
import 'dart:io';

import '../lib/services/lock_throttle.dart';

void main() {
  _check('4 kegagalan belum mengunci', LockThrottle.secondsAfter(4) == 0);
  _check('kegagalan ke-5 mengunci 30 detik',
      LockThrottle.secondsAfter(5) == 30);
  _check('kegagalan ke-9 masih 30 detik',
      LockThrottle.secondsAfter(9) == 30);
  _check('kegagalan ke-10 mengunci 300 detik',
      LockThrottle.secondsAfter(10) == 300);
  _check('sisa waktu dihitung dari lockUntil',
      LockThrottle.remaining(10000, 5000) == 5);
  _check('lock yang sudah lewat bernilai 0',
      LockThrottle.remaining(4999, 5000) == 0);

  stdout.writeln('lock_throttle: selesai');
}

void _check(String name, bool ok) {
  if (ok) {
    stdout.writeln('PASS: $name');
  } else {
    stderr.writeln('FAIL: $name');
    exitCode = 1;
  }
}
