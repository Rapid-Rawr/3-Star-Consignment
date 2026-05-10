# Aturan Notifikasi — SnackBar, Dialog, dan Feedback

Panduan ini menjelaskan kapan dan bagaimana menggunakan notifikasi di aplikasi 3 Star Consignment agar konsisten di seluruh fitur.

---

## 1. Komponen yang Tersedia

| Komponen | File | Kapan dipakai |
|---|---|---|
| `SnackBar` | bawaan Flutter | Notifikasi ringan, tidak perlu aksi dari user |
| `showAppDialog()` | `lib/widgets/app_dialog.dart` | Konfirmasi atau informasi penting yang perlu respons |
| `GradientButton` | `lib/widgets/gradient_button.dart` | Tombol berbackground gradient (dipakai di dalam dialog) |

---

## 2. SnackBar

### ✅ Gunakan untuk:
- Konfirmasi aksi yang sudah berhasil (login, logout, simpan data)
- Pesan singkat yang hilang otomatis

### ❌ Jangan gunakan untuk:
- Error yang membutuhkan tindak lanjut dari user
- Informasi penting yang tidak boleh terlewat

### Aturan format:
```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text('Pesan di sini'),
    duration: const Duration(seconds: 2), // default: 2-3 detik
  ),
);
```

### Contoh pesan yang benar:
| Situasi | Pesan |
|---|---|
| Login berhasil | `"Anda berhasil masuk sebagai {nama}"` |
| Logout berhasil | `"Anda telah berhasil keluar"` |
| Data tersimpan | `"Data berhasil disimpan"` |

---

## 3. AppDialog (`showAppDialog`)

### ✅ Gunakan untuk:
- Konfirmasi aksi yang **tidak bisa dibatalkan** (hapus, keluar)
- Error penting yang butuh respons user (tidak ada koneksi, error kritis)

### ❌ Jangan gunakan untuk:
- Notifikasi ringan yang tidak butuh aksi — gunakan SnackBar

### Cara pakai:
```dart
showAppDialog(
  context: context,
  title: 'Judul Dialog',
  titleIcon: const Icon(Icons.warning_amber_rounded), // opsional
  content: 'Isi pesan di sini.',
  actions: [
    AppDialogAction(
      label: 'Batal',
      onPressed: () => Navigator.pop(context),
      // type default = AppDialogActionType.flat (tanpa background)
    ),
    AppDialogAction(
      label: 'Konfirmasi',
      type: AppDialogActionType.gradient, // tombol berbackground
      onPressed: () { /* aksi */ },
    ),
  ],
);
```

### Jenis tombol di dialog:

| Type | Tampilan | Kapan dipakai |
|---|---|---|
| `AppDialogActionType.flat` | Teks polos (tanpa background) | Batal, Tutup, OK |
| `AppDialogActionType.gradient` | Background gradient (gelap/terang sesuai tema) | Aksi utama/destruktif |

---

## 4. GradientButton (standalone)

Dipakai di luar dialog jika membutuhkan tombol dengan style yang sama.

```dart
GradientButton(
  label: 'Simpan',
  onPressed: () { ... },
  borderRadius: 20, // opsional, default 20
)
```

---

## 5. Aturan Umum

- **Tidak ada koneksi internet** → selalu gunakan `showAppDialog` (bukan SnackBar)
- **User cancel** (tutup popup sendiri) → tidak perlu notifikasi apapun
- **Aksi destruktif** (hapus, keluar) → wajib ada konfirmasi dialog terlebih dahulu
- **Semua komponen sudah dark mode ready** — tidak perlu kode tambahan untuk tema
