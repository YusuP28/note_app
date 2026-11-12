import 'package:flutter/material.dart';
import 'package:note_app_core/note_app_core.dart';

import '../../../services/lock_service.dart';
import 'section_header.dart';

/// Section "Keamanan" di layar pengaturan.
///
/// Berisi kunci aplikasi (PIN + kode backup) dan toggle sidik jari.
///
/// Teks UI, ikon, dan urutan tile sama persis dengan versi lama; yang
/// berubah hanya letak kodenya.
class SecuritySection extends StatelessWidget {
  const SecuritySection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SettingsSectionHeader('Keamanan'),
        ListTile(
          leading: const Icon(Icons.lock_outline),
          title: const Text('Kunci Aplikasi'),
          subtitle: const Text('PIN + fingerprint untuk catatan terkunci'),
          onTap: () => _openLockSettings(context),
        ),
        const _FingerprintUnlockTile(),
      ],
    );
  }

  Future<void> _openLockSettings(BuildContext context) async {
    final lock = LockService();
    final enabled = await lock.isEnabled();
    if (!context.mounted) return;

    final canBio = enabled ? await lock.canUseBiometric() : false;
    var fpEnabled = enabled ? await lock.isFingerprintEnabled() : false;
    if (!context.mounted) return;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(enabled ? 'Kunci Aplikasi' : 'Aktifkan Kunci?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(enabled
                  ? 'Fitur kunci aktif. Mau ubah atau matikan?'
                  : 'Aktifkan PIN untuk mengunci catatan tertentu.'),
              if (enabled && canBio) ...[
                const SizedBox(height: 16),
                const Divider(),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: const Icon(Icons.fingerprint),
                  title: const Text('Fingerprint'),
                  subtitle: Text(fpEnabled
                      ? 'Aktif — verifikasi pakai sidik jari'
                      : 'Nonaktif — pakai PIN saja'),
                  value: fpEnabled,
                  onChanged: (v) async {
                    await lock.setFingerprint(v);
                    setLocal(() => fpEnabled = v);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(v
                                ? 'Fingerprint diaktifkan'
                                : 'Fingerprint dimatikan')),
                      );
                    }
                  },
                ),
              ] else if (enabled && !canBio) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.info_outline,
                        size: 18, color: Colors.orange.shade300),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Fingerprint tidak tersedia di device ini',
                        style: TextStyle(fontSize: 12, color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            if (enabled)
              TextButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await _changePin(context);
                },
                child: const Text('Ubah PIN'),
              ),
            if (enabled)
              TextButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await _disableLock(context);
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Matikan'),
              ),
            if (!enabled)
              FilledButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await _setupPin(context);
                },
                child: const Text('Aktifkan'),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _setupPin(BuildContext context) async {
    final pinCtrl = TextEditingController();
    final hintCtrl = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Buat PIN'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: pinCtrl,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: 'PIN (6 digit)',
                border: OutlineInputBorder(),
                counterText: '',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: hintCtrl,
              decoration: const InputDecoration(
                labelText: 'Hint (opsional)',
                hintText: 'Contoh: angka favorit',
                border: OutlineInputBorder(),
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
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (result != true) return;

    final pin = pinCtrl.text.trim();
    // Aturan kekuatan PIN (panjang, karakter, pola mudah ditebak) centrally
    // di [PinPolicy] supaya UI dan service memakai aturan yang sama.
    final pinError = PinPolicy.validate(pin);
    if (pinError != null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(pinError)),
        );
      }
      return;
    }
    final code = await LockService().setPin(pin, hint: hintCtrl.text.trim());
    if (context.mounted) {
      await _showBackupCodeDialog(context, code);
    }
  }

  Future<void> _changePin(BuildContext context) async {
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final hintCtrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ubah PIN'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldCtrl,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: 'PIN Lama',
                border: OutlineInputBorder(),
                counterText: '',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newCtrl,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: 'PIN Baru',
                border: OutlineInputBorder(),
                counterText: '',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: hintCtrl,
              decoration: const InputDecoration(
                labelText: 'Hint (opsional)',
                border: OutlineInputBorder(),
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
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    final lock = LockService();
    final valid = await lock.verifyPin(oldCtrl.text.trim());
    if (!valid) {
      final remain = await lock.lockoutRemainingSeconds();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              remain > 0
                  ? 'Terlalu banyak percobaan. Tunggu $remain detik.'
                  : 'PIN lama salah',
            ),
          ),
        );
      }
      return;
    }
    final newPin = newCtrl.text.trim();
    final newPinError = PinPolicy.validate(newPin);
    if (newPinError != null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(newPinError)),
        );
      }
      return;
    }
    final code = await lock.setPin(newPin, hint: hintCtrl.text.trim());
    if (context.mounted) {
      await _showBackupCodeDialog(context, code);
    }
  }

  Future<void> _disableLock(BuildContext context) async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Matikan Kunci'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          obscureText: true,
          maxLength: 6,
          decoration: const InputDecoration(
            labelText: 'PIN',
            border: OutlineInputBorder(),
            counterText: '',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Matikan'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    final lock = LockService();
    final valid = await lock.verifyPin(ctrl.text.trim());
    if (!valid) {
      final remain = await lock.lockoutRemainingSeconds();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              remain > 0
                  ? 'Terlalu banyak percobaan. Tunggu $remain detik.'
                  : 'PIN salah',
            ),
          ),
        );
      }
      return;
    }
    await LockService().disable();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kunci dimatikan')),
      );
    }
  }

  Future<void> _showBackupCodeDialog(BuildContext context, String code) async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kode Backup'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Simpan kode ini di tempat aman:'),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(ctx).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                code,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 6,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Kode ini bisa dipakai kalau lupa PIN. Sekali pakai, PIN akan direset.',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK, sudah dicatat'),
          ),
        ],
      ),
    );
  }
}

/// Toggle "Buka Catatan dengan Sidik Jari".
/// Preferensi disimpan di SharedPreferences lewat [LockService].
class _FingerprintUnlockTile extends StatefulWidget {
  const _FingerprintUnlockTile();

  @override
  State<_FingerprintUnlockTile> createState() => _FingerprintUnlockTileState();
}

class _FingerprintUnlockTileState extends State<_FingerprintUnlockTile> {
  bool _loading = true;
  bool _pinEnabled = false;
  bool _supported = false;
  bool _enabled = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final lock = LockService();
    final pinEnabled = await lock.isEnabled();
    final supported = pinEnabled && await lock.canUseBiometric();
    final enabled = pinEnabled && await lock.isFingerprintEnabled();
    if (!mounted) return;
    setState(() {
      _pinEnabled = pinEnabled;
      _supported = supported;
      _enabled = enabled;
      _loading = false;
    });
  }

  Future<void> _toggle(bool value) async {
    if (!_supported) {
      // Refresh dulu — bisa jadi PIN baru saja diaktifkan dari dialog lain.
      await _load();
      if (!mounted) return;
    }
    if (!_supported) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _pinEnabled
                ? 'Perangkat tidak mendukung sidik jari'
                : 'Aktifkan Kunci Aplikasi (PIN) terlebih dahulu',
          ),
        ),
      );
      return;
    }
    await LockService().setFingerprint(value);
    if (!mounted) return;
    setState(() => _enabled = value);
  }

  @override
  Widget build(BuildContext context) {
    final subtitle = _loading
        ? 'Memeriksa...'
        : !_pinEnabled
            ? 'Aktifkan Kunci Aplikasi dulu'
            : !_supported
                ? 'Tidak tersedia di perangkat ini'
                : (_enabled
                    ? 'Aktif — buka catatan dengan sidik jari'
                    : 'Nonaktif');

    return SwitchListTile(
      secondary: const Icon(Icons.fingerprint),
      title: const Text('Buka Catatan dengan Sidik Jari'),
      subtitle: Text(subtitle),
      value: _enabled,
      onChanged: _loading ? null : _toggle,
    );
  }
}
