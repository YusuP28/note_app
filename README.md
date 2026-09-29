# Catatanku (note_app)

Aplikasi catatan modern untuk Android & Web. Offline-first, tanpa perlu internet.

- **Android APK:** [Releases](https://github.com/YusuP28/note_app/releases)
- **Web Version:** https://yusup28.github.io/note_app/

---

## Fitur

### Organisasi
- **Notebook** - kelompokkan catatan per topik (mendukung sub-notebook)
- **Tag** - label multi-warna untuk filter cepat
- **Pin** - sematkan catatan penting di paling atas
- **Arsip** - sembunyikan catatan lama tanpa menghapus
- **Sampah** - soft delete, bisa dipulihkan atau dihapus permanen
- **Auto-purge** - catatan di sampah > 30 hari otomatis dibersihkan

### Catatan
- Judul + isi (teks bebas)
- Warna latar khusus per catatan
- Timestamp dibuat & diubah
- Sort: pinned dulu, lalu terbaru

### Pencarian
- Search global di judul & isi (LIKE query)
- Debounce 250 ms

### Tampilan
- **Dark Mode** (Ikuti Sistem / Terang / Gelap)
- **Warna Tema** (seed color)
- Material 3

### Data
- **SQLite** lokal (offline-first)
- **Auto-backup harian** (rotasi 7 file)
- **Export backup** JSON (notes + notebooks + tags)
- **Import backup** - mode Gabung atau Ganti
- **Export per catatan** - TXT atau Markdown
- **Migrasi otomatis** JSON v1 -> SQLite v2

---

## Cara Install

### Android
1. Buka tab [Releases](https://github.com/YusuP28/note_app/releases)
2. Download `app-release.apk` dari rilis terbaru
3. Buka file APK, izinkan install dari sumber tidak dikenal
4. Install & buka

### Web
1. Buka https://yusup28.github.io/note_app/
2. Data tersimpan di browser (localStorage)
3. Fitur native (export/import, auto-backup) TIDAK jalan di Web

---

## Known Limitations

### Web Version
- Export/import file: TIDAK jalan
- Auto-backup harian: TIDAK jalan
- Data tersimpan di browser (per-browser)

### Android Version
- Semua fitur jalan normal
- Data di SQLite lokal (offline)
- APK release di-sign dengan debug key (sideload OK, Play Store NO)

---

## Cara Build

Build otomatis via GitHub Actions:
- **APK Debug** - setiap push ke `main` (artifact)
- **APK Release** - setiap tag `v*` (auto-attach ke Releases)
- **Web** - setiap push ke `main` (GitHub Pages)

Build lokal di Termux ARM64 GAGAL (aapt2 tidak tersedia). Wajib GH Actions.

---

## Stack

- Flutter 3.24.5 (stable) + Dart 3
- Provider, sqflite, shared_preferences
- file_picker, share_plus, intl, uuid

---

## Changelog

Lihat [CHANGELOG.md](CHANGELOG.md).

---

## Lisensi

Personal project.
