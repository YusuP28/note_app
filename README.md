# Catatanku (note_app)

Aplikasi catatan modern untuk Android. Offline-first, tanpa internet.

**Download APK:** [Releases](https://github.com/YusuP28/note_app/releases)

---

## Fitur

### Organisasi
- **Notebook** - kelompokkan catatan per topik (nested)
- **Tag** - label multi-warna untuk filter
- **Pin** - sematkan catatan di atas
- **Arsip** - sembunyikan tanpa hapus
- **Sampah** - soft delete, bisa dipulihkan
- **Auto-purge** - sampah > 30 hari otomatis dibersihkan

### Catatan
- Judul + isi teks bebas
- Warna latar per catatan
- Timestamp dibuat & diubah
- Sort: pinned dulu, lalu terbaru

### Pencarian
- Search global di judul & isi
- Debounce 250 ms

### Tampilan
- Dark Mode (Ikuti Sistem / Terang / Gelap)
- Warna Tema (seed color)
- Material 3

### Data
- SQLite lokal (offline-first)
- Auto-backup harian (rotasi 7 file)
- Export / Import backup JSON (Gabung atau Ganti)
- Export per catatan (TXT / Markdown)
- Migrasi otomatis JSON v1 -> SQLite v2

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

Flutter 3.24.5 + Dart 3 - Provider - sqflite - shared_preferences - file_picker - share_plus - intl - uuid

---

## Changelog

Lihat [CHANGELOG.md](CHANGELOG.md).

---

## Lisensi

Personal project.
