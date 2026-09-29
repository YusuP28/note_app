# Changelog

Format: [Keep a Changelog](https://keepachangelog.com/)
Versioning: [Semantic Versioning](https://semver.org/)

## [Unreleased]

### Rencana v2.1
- Reminder & notifikasi per catatan
- Sort (judul / tanggal)
- Grid/List view toggle
- Markdown mode
- Auto-save draft + Undo/Redo

### Rencana v2.2
- Attach gambar & audio
- Sketsa / drawing canvas
- Export PDF

### Rencana v2.3
- Lock catatan (PIN/pattern)
- Biometrik
- Private Space

## [2.0.0] - 2026-09-29

### Ditambahkan
- SQLite (ganti JSON)
- Provider (ganti setState)
- Notebook (nested)
- Tag dengan warna
- Pin / Arsip / Sampah (soft delete + purge 30 hari)
- Search global (judul + isi)
- Dark Mode + seed color
- Color picker per catatan
- Auto-backup harian (rotasi 7 file)
- Migrasi otomatis JSON v1 -> SQLite v2
- Import (merge / replace) + Export TXT/MD
- Empty state & error UI

### Diubah
- Struktur folder: `screens/<sub>/`
- DB: `note_app_v3.db`

### Diperbaiki
- Loading hang (try/catch + Coba Lagi)
- Save catatan baru
- Tema warna tidak berubah (Color.value)
- Export Android 11+

### Dihapus
- FTS5 (tidak didukung sqflite Android -> LIKE)
- File v1 lama

## [1.0] - 2026-09-17

### Ditambahkan
- Aplikasi catatan Flutter (Android + Web)
- CRUD dasar
- Persistensi JSON (Android), localStorage (Web)
- Export/Import JSON (Android)
- Share ke aplikasi lain
- GH Actions: auto-build APK + Web

---

[Unreleased]: https://github.com/YusuP28/note_app/compare/v2.0.0...HEAD
[2.0.0]: https://github.com/YusuP28/note_app/releases/tag/v2.0.0
[1.0]: https://github.com/YusuP28/note_app/releases/tag/v1.0
