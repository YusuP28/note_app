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
  - PIN hash SHA-256 (aman, bukan plain text)
  - Hint untuk bantuan jika lupa PIN
  - Backup code 6 digit (emergency reset)
  - Fingerprint support (local_auth)
- **Lock per catatan** - pilih catatan mana yang dikunci
  - Icon gembok di card catatan locked
  - Prompt PIN saat buka catatan terkunci
  - Menu "Kunci Catatan" / "Buka Kunci" di long-press

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
- Timestamp dibuat & diubah
- Sort: 6 opsi (terbaru/terlama diubah/dibuat, A-Z, Z-A)

### Pencarian
- Search global di judul & isi
- Debounce 250 ms

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
- Auto-backup harian (rotasi 7 file)
- Export / Import backup JSON (Gabung atau Ganti)
- Export per catatan (TXT / Markdown)
- Migrasi otomatis JSON v1 -> SQLite v2

### Sinkronisasi (opsional)
- **Google Drive backup** - sync otomatis/manual
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

- APK release di-sign dengan debug key (cukup untuk sideload, bukan Play Store)
- Build lokal di Termux ARM64 GAGAL (aapt2 tidak tersedia) - wajib GH Actions
- Build otomatis: push ke `main` -> APK debug + push tag `v*` -> APK release

---

## Stack

Flutter 3.24.5 + Dart 3
- **State**: Provider
- **DB**: sqflite (SQLite lokal)
- **Editor**: flutter_quill 9.6
- **Storage**: shared_preferences, path_provider
- **File**: file_picker, image_picker, share_plus
- **Cloud**: google_sign_in, googleapis
- **Security**: crypto (SHA-256), local_auth (biometric)
- **UI**: flutter_colorpicker
- **Utils**: intl, uuid

---

## Changelog

Lihat [CHANGELOG.md](CHANGELOG.md).

---

## Lisensi

Personal project.
