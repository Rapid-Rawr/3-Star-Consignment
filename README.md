# 3-Star Consignment

Jangan lupa build ulang dulu sebelum anda mengerjakan atau restart dari vscode agar tau perubahan terbaru

> **Catatan:** Untuk akses CRUD gambar di Catalog minta file .env dari PM, karena file .env berisi anon key dan url lewat Supabase

## Untuk Terhubung Ke Firebase

1. download dulu file google-services.json dari firebase console
   [disini](https://console.firebase.google.com/u/0/project/test-4d7e0/settings/general/android:com.example.star_consignment?hl=id&fb_gclid=Cj0KCQiA9OnJBhD-ARIsAPV51xP0lyBAWYVKRmNyJpiQmdihTNngn4LVKG_pdUiIFq4Kj3o1XW2CPJIaApEeEALw_wcB)

Di bagian general -> Scroll Kebawah -> Download google-services.json

![Screenshot Download Google Service JSON File](assets/images/Screenshot%20Download%20Google%20Service%20JSON%20File.png)

Jika tidak muncul seperti gambar diatas berarti anda tidak punya akses, minta akses ke PM

2. letakkan di folder `android/app/`

![Screenshot Location Google Service JSON File](assets/images/Screenshot%20Guide%20Google%20Service%20Location.png)

3. Generate `firebase_options.dart` dengan FlutterFire CLI

   Install FlutterFire CLI (sekali saja):

   ```bash
   dart pub global activate flutterfire_cli
   ```

   Lalu jalankan di root folder proyek:

   ```bash
   flutterfire configure --project=test-4d7e0
   ```

   Pilih platform **android** saat diminta, file `lib/firebase_options.dart` akan otomatis terbuat/terupdate.

   > **Catatan:** Butuh login Google yang punya akses ke Firebase project. Jika belum, minta akses ke PM.
   >
4. Kemudian jalankan flutter clean dan flutter pub get, tunggu hingga selesai dan restart editor anda (VScode atau Android Studio)Kemudian jalankan flutter clean dan flutter pub get, tunggu hingga selesai dan restart editor anda (VScode atau Android Studio)
5. Yang terpenting di aplikasi login dulu pakai google agar bisa akses firebase, karena sudah di konfigurasi bahwa user yang tidak login tidak bisa akses firebase.
   Karena nantinya agar aman user yang tidak terdaftar atau belum login dibuat tidak bisa akses firebase.

## 📋 Rules dari PM — Baca sebelum ngoding!`<br>`(SEBISANYA SAJA, GAUSAH DIPAKSA NGIKUT SEMUA)

- Aturan warna tema background, text color, dll → [rules](rules/theme.md)
- Aturan penggunaan notfikasi seperti snackbar, dialog, dll → [rules](rules/notifikasi.md)

## Panduan

- Setup koneksi Firebase → [guide/firebase_setup.md](guide/firebase_setup.md)
- Cara read & write Firestore di kode Flutter → [guide/firestore_usage.md](guide/firestore_usage.md)

## Lanjutan

- [Dokumentasi Firebase untuk Flutter](https://firebase.google.com/docs/flutter/setup)
- [Lab: Buat aplikasi Flutter pertamamu](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Contoh Flutter yang berguna](https://docs.flutter.dev/cookbook)

Untuk bantuan memulai pengembangan Flutter, lihat
[dokumentasi online Flutter](https://docs.flutter.dev/)
