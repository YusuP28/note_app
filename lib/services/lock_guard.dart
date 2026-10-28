import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/note.dart';
import '../providers/note_provider.dart';
import 'lock_service.dart';

Future<bool> assertUnlocked(BuildContext context, Note note) async {
  if (!note.isLocked) return true;
  if (!context.mounted) return false;

  try {
    final lock = LockService();
    if (!await lock.isEnabled()) return true;
    if (!context.mounted) return false;

    return await _verifyIdentity(
      context,
      lock,
      title: 'Catatan Terkunci',
      reason: 'Verifikasi untuk membuka catatan terkunci',
      confirmLabel: 'Buka',
    );
  } catch (e) {
    debugPrint('assertUnlocked error: $e');
    return false;
  }
}

Future<bool> toggleNoteLock(BuildContext context, Note note) async {
  try {
    final lock = LockService();
    final enabled = await lock.isEnabled();

    if (!enabled) {
      if (!note.isLocked) {
        if (context.mounted) {
          _snack(context, 'Aktifkan PIN di Pengaturan > Kunci Aplikasi');
        }
        return false;
      }
      // ⚠️ Note masih locked tapi PIN disabled → tidak bisa dibuka
      // Tampar ke _verifyIdentity untuk unlock (hanya gagal jika user input salah)
    } else {
      if (!context.mounted) return false;
      final verified = await _verifyIdentity(
        context,
        lock,
        title: note.isLocked ? 'Buka Kunci Catatan' : 'Kunci Catatan',
        reason: note.isLocked
            ? 'Verifikasi untuk membuka kunci catatan'
            : 'Verifikasi untuk mengunci catatan',
        confirmLabel: note.isLocked ? 'Buka Kunci' : 'Kunci',
      );
      if (!verified) return false;
    }

    if (!context.mounted) return false;
    await context.read<NoteProvider>().toggleLock(note);
    if (context.mounted) {
      _snack(context, note.isLocked ? 'Catatan dikunci' : 'Kunci dibuka');
    }
    return true;
  } catch (e) {
    debugPrint('toggleNoteLock error: $e');
    return false;
  }
}

Future<bool> _verifyIdentity(
  BuildContext context,
  LockService lock, {
  required String title,
  required String reason,
  required String confirmLabel,
}) async {
  try {
  var fpEnabled = false;
  try {
    fpEnabled = await lock.isFingerprintEnabled();
    if (fpEnabled && await lock.canUseBiometric()) {
      final ok = await lock
          .authenticateBiometric(reason: reason)
          .timeout(const Duration(seconds: 30), onTimeout: () => false);
      if (ok) return true;
    }
  } catch (_) {}

  if (!context.mounted) return false;
  final hint = await lock.getHint();
  if (!context.mounted) return false;

  final ctrl = TextEditingController();
  final result = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            obscureText: true,
            maxLength: 6,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'PIN',
              hintText: hint != null ? 'Hint: $hint' : null,
              border: const OutlineInputBorder(),
              counterText: '',
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, 'forgot'),
                child: const Text('Lupa PIN?'),
              ),
              if (fpEnabled)
                TextButton(
                  onPressed: () => Navigator.pop(ctx, 'bio'),
                  child: const Text('Fingerprint'),
                ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  ctrl.dispose();

  if (result == null) return false;
  if (result == 'bio') {
    return lock.authenticateBiometric(reason: reason);
  }
  if (result == 'forgot') {
    if (!context.mounted) return false;
    return _promptBackupCode(context, lock);
  }

  final valid = await lock.verifyPin(result);
  if (!valid && context.mounted) {
    _snack(context, 'PIN salah');
  }
  return valid;
  } catch (e) {
    debugPrint('_verifyIdentity error: $e');
    return false;
  }
}

Future<bool> _promptBackupCode(BuildContext context, LockService lock) async {
  final codeCtrl = TextEditingController();
  final newPinCtrl = TextEditingController();

  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Reset PIN'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Masukkan backup code + PIN baru'),
          const SizedBox(height: 12),
          TextField(
            controller: codeCtrl,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: const InputDecoration(
              labelText: 'Backup Code',
              border: OutlineInputBorder(),
              counterText: '',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: newPinCtrl,
            keyboardType: TextInputType.number,
            obscureText: true,
            maxLength: 6,
            decoration: const InputDecoration(
              labelText: 'PIN Baru',
              border: OutlineInputBorder(),
              counterText: '',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Reset'),
        ),
      ],
    ),
  );

  final code = codeCtrl.text.trim();
  final newPin = newPinCtrl.text.trim();
  codeCtrl.dispose();
  newPinCtrl.dispose();

  if (ok != true) return false;

  final success = await lock.resetWithBackupCode(code, newPin);
  if (!context.mounted) return false;
  _snack(
    context,
    success ? 'PIN berhasil direset' : 'Backup code salah',
  );
  return false;
}

void _snack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
  );
}
