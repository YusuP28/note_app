# Catatanku

Aplikasi catatan sederhana untuk Android. Dibuat dengan Flutter, di-build otomatis via GitHub Actions.

## Fitur

- Tambah catatan (judul + isi)
- Edit catatan
- Hapus catatan (tekan lama)
- Simpan otomatis (offline, tanpa internet)
- Export catatan ke file JSON
- Import catatan dari file JSON
- Share ke aplikasi lain (WhatsApp, dll)

## Cara Install

1. Buka tab Releases di GitHub
2. Download file app-release.apk dari rilis terbaru
3. Buka file APK di HP, izinkan install dari sumber tidak dikenal
4. Install, buka aplikasi

## Cara Build Sendiri

Aplikasi ini di-build otomatis via GitHub Actions setiap kali push ke branch main.

- Build Debug: setiap push ke main, output di tab Actions
- Build Release: setiap push tag v*, output di tab Releases

## Struktur Proyek

note_app/
  - .github/workflows/  : GitHub Actions (auto build)
  - android/            : Konfigurasi Android
  - lib/                : Kode Dart Flutter
  - pubspec.yaml        : Daftar dependency

## Teknologi

- Framework: Flutter 3.24.5
- Bahasa: Dart
- Android: Kotlin 1.9.24, Gradle 8.3, Java 17
- Build: GitHub Actions
- Storage: JSON file lokal

## Status

- v1.0 - Rilis pertama (build sukses)
- v1.1 - Rencana: icon final, Flutter Web preview

## Author

- YusuP28 - github.com/YusuP28

---

Dibuat dengan cinta dari HP + Termux + GitHub Actions
