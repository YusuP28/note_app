# Catatanku

Aplikasi catatan sederhana. Tersedia untuk Android (APK) dan Web (browser).

## Link

- **Android APK:** https://github.com/YusuP28/note_app/releases
- **Web Version:** https://yusup28.github.io/note_app/

## Fitur

- Tambah catatan (judul + isi)
- Edit catatan
- Hapus catatan (tekan lama)
- Simpan otomatis (offline, tanpa internet)
- Export catatan ke file JSON (Android)
- Import catatan dari file JSON (Android)
- Share ke aplikasi lain (WhatsApp, dll)

## Cara Install

### Android (APK)
1. Buka tab Releases
2. Download file app-release.apk dari rilis terbaru
3. Buka file APK di HP, izinkan install dari sumber tidak dikenal
4. Install, buka aplikasi

### Web (Browser)
1. Buka https://yusup28.github.io/note_app/
2. Aplikasi langsung jalan di browser
3. Data tersimpan di browser (localStorage)

## Known Limitations

### Web Version
- Export ke file: tidak jalan (share_plus tidak support web)
- Import dari file: terbatas (file_picker)
- Semua fitur CRUD jalan normal
- Data tersimpan di browser (localStorage, per-browser)

### Android Version
- Semua fitur jalan normal
- Data tersimpan di HP (offline)

## Cara Build Sendiri

Aplikasi ini di-build otomatis via GitHub Actions.

- Build APK: setiap push ke main (debug) atau tag v* (release)
- Build Web: setiap push ke main

Output:
- APK Debug: tab Actions
- APK Release: tab Releases
- Web: GitHub Pages

## Struktur Proyek

note_app/
  .github/workflows/  : GitHub Actions (build APK + Web)
  android/            : Konfigurasi Android
  lib/                : Kode Dart Flutter
  web/                : Konfigurasi Web
  pubspec.yaml        : Daftar dependency

## Teknologi

- Framework: Flutter 3.24.5
- Bahasa: Dart
- Android: Kotlin 1.9.24, Gradle 8.3, Java 17
- Build: GitHub Actions
- Storage: JSON file (Android), localStorage (Web)

## Status

- v1.0 - Rilis pertama (Android APK + Web)
- v1.1 - Rencana: icon final, fix export web, search

## Author

- YusuP28 - github.com/YusuP28

---

Dibuat dengan cinta dari HP + Termux + GitHub Actions
