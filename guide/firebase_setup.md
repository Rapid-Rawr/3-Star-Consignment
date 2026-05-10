# 🔥 Panduan Setup Firebase

Panduan ini wajib diikuti sebelum bisa menjalankan proyek. Tanpa file konfigurasi Firebase yang benar, aplikasi **tidak bisa build**.

---

## Prasyarat

Sebelum memulai, pastikan kamu sudah menginstall:

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (versi ≥ 3.x)
- [Dart SDK](https://dart.dev/get-dart)
- [Android Studio](https://developer.android.com/studio) atau emulator/device fisik
- Akses ke Firebase project **test-4d7e0** — jika belum punya, **minta ke PM**

---

## Langkah 1 — Download `google-services.json`

1. Buka [Firebase Console](https://console.firebase.google.com/u/0/project/test-4d7e0/settings/general/android:com.example.star_consignment)
2. Masuk ke **Project Settings → General**
3. Scroll ke bawah ke bagian **"Your apps"**
4. Klik tombol **Download google-services.json**

![Screenshot Download Google Service JSON](../assets/images/Screenshot%20Download%20Google%20Service%20JSON%20File.png)

> ⚠️ Jika tombol download tidak muncul, berarti kamu **belum punya akses** ke project Firebase. Hubungi PM untuk minta akses.

---

## Langkah 2 — Letakkan File di Lokasi yang Benar

Setelah download, letakkan file `google-services.json` di:

```
android/
└── app/
    └── google-services.json   ← di sini
```

![Screenshot Location Google Service JSON](../assets/images/Screenshot%20Guide%20Google%20Service%20Location.png)

> ❌ Jangan letakkan di root proyek atau folder lain — hanya di `android/app/`

---

## Langkah 3 — Generate `firebase_options.dart` dengan FlutterFire CLI

File `lib/firebase_options.dart` **tidak di-commit ke Git** (ada di `.gitignore`) karena berisi konfigurasi sensitif. Kamu harus generate sendiri.

### Install FlutterFire CLI (sekali saja)

```bash
dart pub global activate flutterfire_cli
```

Jika muncul warning PATH, tambahkan path berikut ke environment variable sistem:
```
%APPDATA%\Pub\Cache\bin
```

### Jalankan konfigurasi

Di **root folder proyek** (tempat `pubspec.yaml` berada):

```bash
flutterfire configure --project=test-4d7e0
```

Saat diminta memilih platform, pilih **android** (dan platform lain jika diperlukan).

File `lib/firebase_options.dart` akan otomatis terbuat/terupdate. ✅

> 💡 Kamu perlu login dengan akun Google yang punya akses ke Firebase project. Jika diminta login, ikuti instruksi di terminal.

---

## Langkah 4 — Install Dependencies & Jalankan

```bash
flutter pub get
flutter run
```

Jika ada error saat build, coba:

```bash
flutter clean
flutter pub get
flutter run
```

---

## Troubleshooting

### ❌ `google-services.json` tidak ditemukan
Pastikan file berada di `android/app/google-services.json`, bukan di tempat lain.

### ❌ `firebase_options.dart` tidak ditemukan
Jalankan ulang `flutterfire configure --project=test-4d7e0`.

### ❌ FlutterFire CLI tidak dikenali
Pastikan `%APPDATA%\Pub\Cache\bin` sudah ada di PATH, atau jalankan:
```bash
dart pub global activate flutterfire_cli
```

### ❌ Permission denied / tidak bisa akses Firebase project
Hubungi PM untuk mendapatkan akses ke Firebase project **test-4d7e0**.

### ❌ Build gagal setelah setup
Coba `flutter clean` lalu `flutter pub get` dan build ulang.

---

## File yang Tidak Di-commit (`.gitignore`)

Berikut file Firebase yang **sengaja tidak ada di repository** dan harus kamu buat sendiri:

| File | Alasan |
|---|---|
| `android/app/google-services.json` | Konfigurasi sensitif per-developer |
| `lib/firebase_options.dart` | Di-generate otomatis oleh FlutterFire CLI |

---

## Setelah Setup Berhasil

Baca juga panduan lainnya sebelum mulai ngoding:

- [Rules tema & warna](../rules/theme.md)
- [Rules notifikasi (snackbar, dialog)](../rules/notifikasi.md)
