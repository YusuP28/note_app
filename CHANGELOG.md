# Changelog

Format: [Keep a Changelog](https://keepachangelog.com/)
Versioning: [Semantic Versioning](https://semver.org/)

## [Unreleased]

### Rencana v2.3
- Sketch pad (gambar tangan)
- Voice notes (rekam audio)
- Checklist interaktif
- Export PDF
- Markdown mode
- Undo/Redo di editor

### Rencana v2.4
- Lock catatan (PIN/biometrik)
- Private Space
- Home screen widget

## [2.2.0] - 2026-09-30

### Ditambahkan
- **Rich text editor** (flutter_quill 9.6.0)
  - Bold, italic, underline, strikethrough
  - Bullet list, numbered list, checklist
  - Header style (H1-H6)
  - Undo/Redo
  - Auto-save draft (Delta JSON)
- **Attach gambar inline** di editor
  - Dari galeri (multi-select)
  - Dari kamera
  - Sisip di posisi cursor
  - Thumbnail 90×90
  - Tap gambar → preview full-screen (zoom)
- **Google Drive Backup** (OAuth)
  - Login Google
  - Backup ke appDataFolder (tersembunyi)
  - Restore dari Drive
  - Multi-user support (akun terisolasi)
  - Publish OAuth consent (unlimited user)
- **Auto-backup terjadwal** (1-7 hari)
- **Rotasi backup** (simpan 5 terbaru, hapus otomatis)
- **Toggle "Ukuran Foto Asli"** (kompres vs original)
- **Fixed keystore signing** via GitHub Secrets

### Diubah
- Editor: `TextField` → `QuillEditor`
- Konten disimpan sebagai Delta JSON
- NoteCard & search pakai `plainText`
- DB schema v6 (kolom `attachments`, `plain_text`)
- AndroidManifest: tambah permission `INTERNET` + `ACCESS_NETWORK_STATE`

### Diperbaiki
- Socket exception "Failed host lookup" (Restricted Networking Mode)
- Quill API compatibility (v9.6 signature)
- Build Gradle error ":gal" (hapus flutter_quill_extensions)
- NoteCard tampil Delta JSON mentah

### Dihapus
- `flutter_quill_extensions` (pull dep "gal" → error Gradle)

## [2.1.0] - 2026-09-29

### Ditambahkan
- Reminder (native AlarmManager Kotlin)
- Notif full-screen alarm-style + suara + getar
- Suara notif (sound1-3) + kustom file_picker
- Sort 6 opsi (updated/created asc-desc, judul A-Z/Z-A)
- Grid/List toggle
- Auto-save draft (per-note key)
- Auto-save saat back (PopScope)
- Warna editor auto-kontras (computeLuminance)
- Icon adaptive (fg + bg warna logo)

## [2.0.0] - 2026-09-29

### Ditambahkan
- SQLite + Provider
- Notebook (nested), Tag, Pin, Archive, Trash
- Search (LIKE query)
- Dark Mode + seed color
- Color picker per catatan
- Auto-backup harian (rotasi 7 file)
- Migration JSON v1 → SQLite v2
- Import/Export JSON (merge/replace)

## [1.0] - 2026-09-17

### Ditambahkan
- Aplikasi catatan Flutter (Android + Web)
- CRUD dasar
- Persistensi JSON (Android), localStorage (Web)
- Export/Import JSON (Android)
- Share ke aplikasi lain
- GitHub Actions: auto-build APK + Web

---

[Unreleased]: https://github.com/YusuP28/note_app/compare/v2.2.0...HEAD
[2.2.0]: https://github.com/YusuP28/note_app/releases/tag/v2.2.0
[2.1.0]: https://github.com/YusuP28/note_app/releases/tag/v2.1.0
[2.0.0]: https://github.com/YusuP28/note_app/releases/tag/v2.0.0
[1.0]: https://github.com/YusuP28/note_app/releases/tag/v1.0
