# Catatanku (note_app)

Aplikasi catatan modern untuk Android. Offline-first, tanpa internet.

**Download APK:** [Releases](https://github.com/YusuP28/note_app/releases)

---

## Fitur

### Organisasi
- **Notebook** - kelompokkan catatan per topik (nested)
- **Tag** - label multi-warna (15 preset color picker)
- **Pin** - sematkan catatan di atas
- **Arsip** - sembunyikan tanpa hapus
- **Sampah** - soft delete, bisa dipulihkan
- **Auto-purge** - sampah > 30 hari otomatis dibersihkan

### Keamanan
- **PIN Lock master** - kunci catatan tertentu dengan PIN
  - PIN hash **PBKDF2-HMAC-SHA256** 210.000 iterasi + salt acak (bukan plain text)
  - Throttle: 5 gagal = 30 detik, 10 gagal = 5 menit
  - Hint untuk bantuan jika lupa PIN
  - Backup code 6 digit (emergency reset, **sekali pakai** + tunduk throttle yang sama dengan PIN)
  - **Fingerprint Unlock (toggle)** — aktifkan/nonaktifkan biometric di Settings
- **Lock per catatan** - pilih catatan mana yang dikunci
  - Icon gembok di card catatan locked
  - Prompt PIN saat buka catatan terkunci
  - Menu "Kunci Catatan" / "Buka Kunci" di long-press
  - **Isi catatan terkunci dienkripsi di database** (AES-256-GCM, kunci di Android Keystore)
- **Backup terenkripsi** — seluruh arsip (catatan + lampiran) dienkripsi AES-256-GCM
  - Kunci diturunkan dari **passphrase** (PBKDF2 210.000 iterasi) → backup bisa dipulihkan di perangkat lain
  - Passphrase diatur di Settings → "Passphrase Backup"
  - Backup lama (ZIP/JSON plaintext) tetap bisa di-restore
- **Hardening Android** — `FLAG_SECURE` (tidak bisa screenshot), `network_security_config` (cleartext traffic mati), `allowBackup=false`, build release wajib signed dengan keystore asli

### Catatan
- Judul + isi teks bebas
- Editor rich text (flutter_quill)
  - Bold, italic, underline, strikethrough
  - Bullet, numbered, checklist
  - Quote, link, code block
  - Indent, alignment, text color
  - Header style
- Warna latar per catatan
- Background image per catatan (opacity custom)
- **Global Background** — wallpaper untuk seluruh aplikasi (Settings)
- **Kustomisasi Background Sidebar (Drawer)** — gambar & transparansi khusus untuk navigasi
- Timestamp dibuat & diubah
- Sort: 6 opsi (terbaru/terlama diubah/dibuat, A-Z, Z-A)

### Pencarian
- Search global di judul & isi
- Debounce 250 ms
- **Highlight Kuning & Auto-scroll** — kata kunci disorot saat buka catatan dari hasil cari
- **Pencarian dalam Catatan (Highlight)** — temukan teks di dalam catatan dengan highlight kuning

### Tampilan
- Dark Mode (Ikuti Sistem / Terang / Gelap)
- Warna Tema (seed color)
- Material 3
- **Neumorphism design system**
  - Soft shadow (raised + pressed states)
  - Support light + dark mode
  - Custom widget: NeumoCard, NeumoFab, NeumoIconButton, NeumoChip
- **Multi-view**: List / Grid
- **Multi-select mode** - pilih banyak catatan + aksi batch

### Data
- SQLite lokal (offline-first)
- Auto-backup harian (rotasi 7 file) — disimpan di **folder privat aplikasi**, terenkripsi
- Export / Import backup **terenkripsi** (`.nbak`) — catatan + lampiran (Gabung atau Ganti)
  - Backup lama `.zip` / `.json` (plaintext) masih bisa di-restore
- Export per catatan (TXT / Markdown)
- Migrasi otomatis JSON v1 -> SQLite v2

### Sinkronisasi (opsional)
- **Google Drive backup** - sync otomatis/manual (payload terenkripsi)
- **Auto-backup** - pilih interval (1 hari / 3 hari / 7 hari / dst)
- **Restore dari Drive** - download + replace data

---

## Cara Install

1. Buka tab [Releases](https://github.com/YusuP28/note_app/releases)
2. Download `app-release.apk` dari rilis terbaru
3. Buka file APK, izinkan install dari sumber tidak dikenal
4. Install & buka

---

## Catatan

- Build release **wajib** signed dengan keystore asli — build GAGAL kalau keystore hilang (no fallback ke debug key)
- Build lokal di Termux ARM64 GAGAL (aapt2 tidak tersedia) - wajib GH Actions
- Build otomatis: push ke `main` -> APK debug + push tag `v*` -> APK release
- CI menjalankan `flutter analyze` + `flutter test` (app) + `dart test` (note_app_core) sebelum build

---

## Stack

Flutter 3.24.5 + Dart 3
- **State**: Provider
- **DB**: sqflite (SQLite lokal)
- **Editor**: flutter_quill 9.6
- **Storage**: shared_preferences, path_provider, flutter_secure_storage (Android Keystore)
- **File**: file_picker, image_picker, share_plus
- **Cloud**: google_sign_in, googleapis
- **Security**: crypto, pointycastle (AES-256-GCM), local_auth (biometric)
- **Logika inti**: `packages/note_app_core` (pure Dart — enkripsi backup, guard path, policy lockout)
- **Utils**: intl, uuid

---

## Changelog

Lihat [CHANGELOG.md](CHANGELOG.md).

---

## Lisensi

Personal project.
