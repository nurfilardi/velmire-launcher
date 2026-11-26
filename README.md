# Velmire Launcher

Launcher Android (Flutter) untuk main SA-MP di HP. Bukan klien game: game dijalankan oleh klien SA-MP Android yang terpasang (default `com.gta.game`).

## Alur

1. Izinkan akses folder GTA.
2. Pilih data **Lite** atau **Original**.
3. Unduh dan ekstrak sekali.
4. Pilih server, lalu main.

Data diambil dari manifest milik sendiri:

```bash
flutter build apk --release --target-platform android-arm64 \
  --dart-define=PROVIDER_MANIFEST="https://hosting-lu/sources.json"
```

Format manifest:

```json
{"sources":[{"name":"Lite","url":"https://hosting-lu/lite.zip","size":587135343,"checksum":"<sha256>"},{"name":"Original","url":"https://hosting-lu/full.zip"}]}
```

Nama sumber berisi `Lite` dan `Original`/`Full`. Tanpa manifest, tombol unduh nonaktif; impor ZIP atau lewati ke menu utama tetap bisa.

## Fitur

- Daftar server Indonesia dari API publik sa-mp.co.id (cache 60 dtk, kredit di UI).
- Tambah server manual lewat IP/domain + port, dengan tes query UDP.
- Nick per server + password server, lalu connect.
- Unduh data dengan resume, batas ukuran, dan verifikasi SHA-256; impor ZIP; tulis `GTA/SAMP/settings.ini`.
- Tanpa backend, tanpa akun, tanpa aset game di repo/artifact.
- Tidak ada unduhan/instalasi klien dari dalam app.

## Yang tidak dilakukan app

- Tidak membawa, menghosting, atau menyediakan data GTA/klien SA-MP.
- Tidak mendukung `.7z`/`.rar` (pakai `.zip`).
- Tidak menjamin auto-connect di semua klien; app menulis setting yang dibaca klien kuzia15/Ryzellx lalu membuka activity `.SAMP`. Kalau klien mengabaikan setting, alamat disalin ke clipboard.

## Build lokal

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --release --target-platform android-arm64
```

Butuh Flutter 3.35.x dan Java 17. APK di `build/app/outputs/flutter-apk/`.

## CI

`.github/workflows/build.yml`: analyze + test + build arm64 tiap push. Push ke `main` memperbarui release `latest`; tag `v*` membuat release berversi. Set repo variable `PROVIDER_MANIFEST` untuk menanam manifest saat build.

Signing: set secrets `KEYSTORE_BASE64`, `KEYSTORE_PASSWORD`, `KEY_ALIAS`, `KEY_PASSWORD`. Tanpa itu build memakai debug key (khusus sideload/personal).

## Data & lisensi

- Data server: SA:MP Indonesia — https://sa-mp.co.id
- Font: Barlow & Barlow Condensed (SIL OFL 1.1), lihat `assets/fonts/OFL-*.txt`.
- Aplikasi ini tidak berafiliasi dengan Rockstar Games, Take-Two, atau tim SA-MP. Gunakan hanya dengan salinan game yang sah.
