# 🎨 Panduan Tema — 3 Star Consignment

Dokumen ini berisi aturan dan konvensi warna untuk developer agar semua halaman
baru konsisten dalam mode **Light** maupun **Dark**.

---

## 📐 Sistem Warna

| Nama         | Hex         | Digunakan untuk                              |
|--------------|-------------|----------------------------------------------|
| `darkSurface`  | `#1D1B20`   | Background halaman & AppBar di Dark Mode     |
| `textDark`     | `#49454F`   | Teks & ikon di area putih (Light Mode)       |
| `gradStart`    | `#67636D`   | Awal gradient container (Sign In/Out)        |
| `gradEnd`      | `#1D1B20`   | Akhir gradient container                     |
| `white`        | `#FFFFFF`   | Background halaman & AppBar di Light Mode    |

---

## ✅ Aturan Dasar

### 1. Jangan hardcode warna secara langsung

❌ Salah:
```dart
Container(color: Colors.white)
Text('Halo', style: TextStyle(color: Colors.black))
```

✅ Benar — gunakan `Theme.of(context)`:
```dart
Container(color: Theme.of(context).scaffoldBackgroundColor)
Text('Halo', style: TextStyle(color: Theme.of(context).colorScheme.onSurface))
```

---

### 2. Untuk warna custom `#49454F` (teks/ikon di area putih)

Tetap boleh hardcode `Color(0xFF49454F)` **hanya** jika widget tersebut memang selalu
di atas background putih (contoh: drawer header, ListTile Settings).

Jika widget bisa muncul di atas background dark, gunakan `Theme.of(context).colorScheme.onSurface`.

---

### 3. AppBar — jangan set `backgroundColor` manual

AppBar sudah dikonfigurasi di `ThemeData` secara global:
- **Light:** putih, ikon `#1D1B20`
- **Dark:** `#1D1B20`, ikon putih

Cukup tulis:
```dart
AppBar(
  title: const Text('Nama Halaman'),
)
```

Jangan tambahkan `backgroundColor:` kecuali ada kebutuhan khusus.

---

### 4. Scaffold background — jangan set manual

Scaffold background sudah dikonfigurasi secara global:
- **Light:** `Colors.white`
- **Dark:** `Color(0xFF1D1B20)`

Cukup tulis:
```dart
Scaffold(
  body: ...,
)
```

---

### 5. Cek dark mode di widget jika perlu logika kondisional

```dart
final isDark = Theme.of(context).brightness == Brightness.dark;

Container(
  color: isDark ? const Color(0xFF1D1B20) : Colors.white,
)
```

---

### 6. Gradient container (Sign In / Sign Out area)

Selalu gunakan warna ini untuk container bergradient:
```dart
decoration: const BoxDecoration(
  gradient: LinearGradient(
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
    colors: [Color(0xFF67636D), Color(0xFF1D1B20)],
  ),
),
```
Teks dan ikon di dalam gradient container selalu menggunakan `Colors.white`.

---

## 🗂 Struktur File Penting

```
lib/
├── main.dart                   ← ThemeData (light & dark) dikonfigurasi di sini
├── utils/
│   └── theme_notifier.dart     ← ValueNotifier<ThemeMode> global
├── widgets/
│   └── app_drawer.dart         ← Contoh implementasi dark mode yang benar
└── controllers/
    └── auth_controller.dart    ← Tidak berisi warna apapun (logika saja)
```

---

## 🔄 Toggle Dark Mode

Dark mode dikontrol oleh `themeNotifier` di `lib/utils/theme_notifier.dart`.

```dart
import 'package:star_consignment/utils/theme_notifier.dart';

// Aktifkan dark mode
themeNotifier.value = ThemeMode.dark;

// Kembali ke light mode
themeNotifier.value = ThemeMode.light;
```

Untuk listen perubahan tema di widget:
```dart
ValueListenableBuilder<ThemeMode>(
  valueListenable: themeNotifier,
  builder: (_, mode, __) {
    final isDark = mode == ThemeMode.dark;
    return Text(isDark ? 'Dark' : 'Light');
  },
);
```
