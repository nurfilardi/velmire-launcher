# Velmire Launcher

Launcher Android (Flutter) untuk main SA-MP di HP. Bukan klien game: game dijalankan oleh klien SA-MP Android yang terpasang (default `com.gta.game`).

## Fitur

- Daftar server Indonesia dari API publik sa-mp.co.id (cache 60 dtk, kredit di UI).
- Tambah server manual lewat IP/domain + port, dengan tes query UDP.
- Nick per server + password server, lalu connect.
- Kelola data game: unduh zip dari URL milik sendiri (Lite/Original), import zip, cek status, hapus.
- Tulis `GTA/SAMP/settings.ini` (`[client] name/host/port`) sebelum membuka klien.
- Tanpa backend, tanpa akun, tanpa aset game di repo/artifact.

## Yang tidak dilakukan app

- Tidak membawa, menghosting, atau menyediakan data GTA/klien SA-MP.
- Tidak mendukung `.7z`/`.rar` (pakai `.zip`).
- Tidak menjamin auto-connect di semua klien; app menulis setting yang dibaca klien kuzia15/Ryzellx lalu membuka activity `.SAMP`. Kalau klien mengabaikan setting, alamat disalin ke clipboard.

## Build lokal

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --release --split-per-abi
```

Butuh Flutter 3.35.x dan Java 17. APK di `build/app/outputs/flutter-apk/`.

## CI

`.github/workflows/build.yml`: analyze + test + build split-per-abi tiap push. Tag `v*` membuat GitHub Release berisi APK.

Signing: set secrets `KEYSTORE_BASE64`, `KEYSTORE_PASSWORD`, `KEY_ALIAS`, `KEY_PASSWORD`. Tanpa itu build memakai debug key (khusus sideload/personal).

## Data & lisensi

- Data server: SA:MP Indonesia — https://sa-mp.co.id
- Font: Barlow & Barlow Condensed (SIL OFL 1.1), lihat `assets/fonts/OFL-*.txt`.
- Aplikasi ini tidak berafiliasi dengan Rockstar Games, Take-Two, atau tim SA-MP. Gunakan hanya dengan salinan game yang sah.
