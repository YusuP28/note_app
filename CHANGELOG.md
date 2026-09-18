# Changelog

Semua perubahan penting pada proyek ini akan didokumentasikan di file ini.

Format berdasarkan [Keep a Changelog](https://keepachangelog.com/),
dan proyek ini mengikuti [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Rencana v1.1
- Icon final (ganti placeholder ungu)
- Fix export web (pakai browser download)
- Fitur search catatan
- Kategori/tag catatan

## [1.0] - 2026-09-17

### Ditambahkan
- Aplikasi catatan Flutter (Android + Web)
- Fitur CRUD: tambah, edit, hapus catatan
- Persistensi offline: JSON (Android), localStorage (Web)
- Export catatan ke file JSON (Android)
- Import catatan dari file JSON (Android)
- Share ke aplikasi lain via share_plus (Android)
- GitHub Actions: auto-build APK debug & release
- GitHub Actions: auto-deploy web ke GitHub Pages
- README lengkap dengan dokumentasi
- Android config manual (Kotlin 1.9.24, Gradle 8.3, Java 17)
- Icon placeholder ungu

### Diketahui Belum Selesai
- Export web: tidak jalan (share_plus tidak support web)
- Import web: terbatas (file_picker)
- Icon: masih placeholder

---

[Unreleased]: https://github.com/YusuP28/note_app/compare/v1.0...HEAD
[1.0]: https://github.com/YusuP28/note_app/releases/tag/v1.0
