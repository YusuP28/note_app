# Changelog

Format: [Keep a Changelog](https://keepachangelog.com/)
Versioning: [Semantic Versioning](https://semver.org/)

## [2.3.0] - 2026-10-01

### Ditambahkan
- **Multi-select mode** — pilih banyak catatan + aksi batch
  (hapus/arsip/pin)
- **Mode Baca** (read-only) — preview catatan tanpa edit
  - Bisa switch ke edit
  - Share/copy dari mode baca
- **Background gambar per catatan**
  - Pilih dari galeri/kamera
  - Slider transparansi (0-100%)
  - Tampil di editor, NoteCard grid & list
- **Grid 3 kolom** (aspect 1:0.85)
- **Long-press context menu**:
  - Buka & Edit
  - Mode Baca
  - Sematkan / Lepas
  - Arsipkan
  - Bagikan sebagai .txt
  - Bagikan sebagai Teks
  - Salin Teks
  - Info
  - Pindah ke Sampah
- **Border grid** warna primary default (tipis),
  selected lebih tebal
- **Menu editor dirapikan** (PopupMenu 3-titik)

### Diubah
- Icon baru (fg + bg warna)
- AppBar editor dirapikan (overflow menu)
- NoteCard visual selection indicator

### Diperbaiki
- Grid text overlap pada judul panjang
- Background image hilang-timbul (gaplessPlayback)
- BG image tidak muncul di Mode Baca
- Mode Baca — readOnly via QuillController

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
  - Tap → preview fullscreen (zoom)
- **Google Drive Backup** (OAuth)
  - Login Google
  - Backup ke appDataFolder (tersembunyi)
  - Restore dari Drive
  - Multi-user support (akun terisolasi)
  - Publish OAuth consent
- **Auto-backup terjadwal** (1-7 hari)
- **Rotasi backup** (simpan 5 terbaru, hapus otomatis)
- **Toggle "Ukuran Foto Asli"**
- **Fixed keystore signing** via GitHub Secrets

### Diubah
- Editor: TextField → QuillEditor
- Konten disimpan sebagai Delta JSON
- NoteCard & search pakai plainText
- DB schema v6 (attachments, plain_text)
- AndroidManifest: permission INTERNET

### Diperbaiki
- Socket exception "Failed host lookup"
- Quill API compatibility (v9.6)
- Build Gradle error ":gal"
- NoteCard tampil Delta JSON mentah

### Dihapus
- flutter_quill_extensions

## [2.1.0] - 2026-09-29

### Ditambahkan
- Reminder (native AlarmManager Kotlin)
- Notif full-screen alarm-style
- Suara notif (sound1-3) + kustom
- Sort 6 opsi
- Grid/List toggle
- Auto-save draft (per-note key)
- Auto-save saat back (PopScope)
- Warna editor auto-kontras
- Icon adaptive

## [2.0.0] - 2026-09-29

### Ditambahkan
- SQLite + Provider
- Notebook (nested), Tag, Pin, Archive, Trash
- Search (LIKE query)
- Dark Mode + seed color
- Color picker per catatan
- Auto-backup harian
- Migration JSON v1 → SQLite v2

## [1.0] - 2026-09-17

### Ditambahkan
- Aplikasi catatan Flutter (Android + Web)
- CRUD dasar
- Persistensi JSON (Android)
- Export/Import JSON
- Share ke aplikasi lain
- GitHub Actions: auto-build

---

[2.3.0]: https://github.com/YusuP28/note_app/releases/tag/v2.3.0
[2.2.0]: https://github.com/YusuP28/note_app/releases/tag/v2.2.0
[2.1.0]: https://github.com/YusuP28/note_app/releases/tag/v2.1.0
[2.0.0]: https://github.com/YusuP28/note_app/releases/tag/v2.0.0
[1.0]: https://github.com/YusuP28/note_app/releases/tag/v1.0
