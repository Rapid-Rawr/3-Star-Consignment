# 📖 Panduan Penggunaan Firestore di Flutter

Panduan ini menjelaskan cara read dan write data ke Firestore dalam kode Dart/Flutter,
termasuk cara kerja offline cache dan deteksi pending (belum tersinkron ke server).

---

## Konsep Dasar

Firestore menggunakan dua layer data:

```
Flutter App
    ↓ tulis/baca
[Cache Lokal (SQLite)] ← selalu ada, instant
    ↕ sinkron otomatis
[Firebase Server]      ← butuh internet
```

Artinya: **semua operasi write selalu berhasil secara lokal** meski offline.
Data akan dikirim ke server secara otomatis saat internet tersedia.

---

## Mendapatkan Instance Firestore

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

final firestore = FirebaseFirestore.instance;
```

---

## WRITE — Menulis Data

### Tambah dokumen baru (auto-ID)

```dart
await firestore.collection('clients').add({
  'name': 'Budi Santoso',
  'phone': '081234567890',
  'debt': 150000.0,
  'createdAt': FieldValue.serverTimestamp(), // waktu dari server
});
```

### Buat dokumen dengan ID manual

```dart
await firestore.collection('clients').doc('custom-id-123').set({
  'name': 'Ani',
});
```

### Update sebagian field (tidak menimpa semua)

```dart
await firestore.collection('clients').doc(docId).update({
  'debt': 0,
  'updatedAt': FieldValue.serverTimestamp(),
});
```

### Hapus dokumen

```dart
await firestore.collection('clients').doc(docId).delete();
```

> 💡 Semua operasi di atas menggunakan `await` dan langsung resolve meski offline,
> karena Firestore menulis ke cache lokal terlebih dahulu.

---

## READ — Membaca Data

### Baca sekali (one-time get)

```dart
final snapshot = await firestore.collection('clients').get();

for (final doc in snapshot.docs) {
  final data = doc.data();         // Map<String, dynamic>
  final id   = doc.id;             // ID dokumen
  print('$id: ${data['name']}');
}
```

### Baca satu dokumen

```dart
final doc = await firestore.collection('clients').doc(docId).get();

if (doc.exists) {
  print(doc.data()?['name']);
}
```

---

## STREAM — Baca Real-time

Stream memungkinkan UI **otomatis terupdate** saat data berubah di Firestore.

### Stream basic

```dart
Stream<QuerySnapshot> getClientsStream() {
  return firestore.collection('clients').snapshots();
}
```

### Stream dengan metadata changes (untuk deteksi pending)

```dart
Stream<QuerySnapshot> getClientsStream() {
  return firestore
      .collection('clients')
      .snapshots(includeMetadataChanges: true); // ← tambahkan ini
}
```

`includeMetadataChanges: true` membuat stream juga memancarkan event saat
status sinkronisasi dokumen berubah (bukan hanya saat data berubah).

### Gunakan di Widget dengan `StreamBuilder`

```dart
StreamBuilder<QuerySnapshot>(
  stream: _controller.getClientsStream(),
  builder: (context, snapshot) {
    // Masih loading
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const CircularProgressIndicator();
    }

    // Ada error
    if (snapshot.hasError) {
      return Text('Error: ${snapshot.error}');
    }

    // Data kosong
    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
      return const Text('Belum ada data');
    }

    // Tampilkan data
    final docs = snapshot.data!.docs;
    return ListView.builder(
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final doc  = docs[index];
        final data = doc.data() as Map<String, dynamic>;
        return Text(data['name'] ?? '');
      },
    );
  },
)
```

---

## Metadata & Pending Writes

Setiap `DocumentSnapshot` memiliki property `metadata` yang berisi info sinkronisasi:

```dart
final doc = docs[index];

doc.metadata.hasPendingWrites  // true = ditulis lokal, belum dikonfirmasi server
doc.metadata.isFromCache       // true = data berasal dari cache lokal
```

### Cara pakai di UI (contoh dari proyek ini)

```dart
final items = snapshot.data!.docs
    .map((doc) => (
          data: MyModel.fromMap(doc.id, doc.data() as Map<String, dynamic>),
          isPending: doc.metadata.hasPendingWrites, // ← ambil status pending
        ))
    .toList();

// Di dalam ListView item:
if (isPending)
  Row(children: [
    Icon(Icons.access_time_rounded, size: 12, color: Colors.orange),
    SizedBox(width: 4),
    Text('Menunggu sinkronisasi...', style: TextStyle(fontSize: 10)),
  ]),
```

### Alur lengkap pending

```
User tekan Tambah → form valid
    ↓
Navigator.pop()           ← dialog ditutup langsung
    ↓
firestore.add({...})      ← simpan ke cache lokal, resolve instantly
    ↓
Stream emit (hasPendingWrites = true)
    ↓
Icon ⏰ muncul di kartu
    ↓
[Background] Firestore coba kirim ke server Firebase
    ↓ (saat internet tersedia)
Server konfirmasi → Stream emit (hasPendingWrites = false)
    ↓
Icon ⏰ hilang otomatis ✅
```

> ⚠️ Tutup dialog **sebelum** `await` agar dialog tidak mengantung saat offline.
> Tampilkan snackbar menggunakan `context` halaman (bukan `dialogContext`).

---

## Query — Filter & Sort

```dart
// Where
firestore.collection('clients')
    .where('debt', isGreaterThan: 0)
    .get();

// Order
firestore.collection('clients')
    .orderBy('createdAt', descending: true)
    .get();

// Limit
firestore.collection('clients')
    .limit(10)
    .get();

// Gabungan
firestore.collection('clients')
    .where('debt', isGreaterThan: 0)
    .orderBy('debt', descending: true)
    .limit(20)
    .snapshots();
```
Di console firestore query builder juga ada
---

## Pola Controller di Proyek Ini

Proyek ini memisahkan logika Firestore ke dalam **Controller** terpisah:

```
lib/
├── controllers/
│   ├── client_controller.dart    ← semua logika Firestore untuk clients
│   └── operator_controller.dart  ← semua logika Firestore untuk operators
├── models/
│   └── client_model.dart         ← struktur data (fromMap / toMap)
└── views/
    └── client_page.dart          ← UI, hanya memanggil controller
```

### Contoh pattern controller

```dart
class ClientController {
  final FirebaseFirestore firestore;
  ClientController({required this.firestore});

  // Stream untuk UI
  Stream<QuerySnapshot> getClientsStream() {
    return firestore
        .collection('clients')
        .snapshots(includeMetadataChanges: true);
  }

  // Write — return Map agar view bisa cek success/error
  Future<Map<String, dynamic>> createClient({...}) async {
    try {
      await firestore.collection('clients').add({...});
      return {'success': true};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}
```

### Di view, selalu tutup dialog sebelum await

```dart
onPressed: () async {
  if (formKey.currentState!.validate()) {
    Navigator.pop(dialogContext);          // tutup dulu
    final result = await _controller.createClient(...);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['success'] == true
              ? 'Berhasil ditambahkan'
              : result['error'] ?? 'Terjadi kesalahan'),
          backgroundColor: result['success'] == true
              ? Colors.green : Colors.red,
        ),
      );
    }
  }
}
```

---

## Referensi

- [Dokumentasi Firestore Flutter](https://firebase.google.com/docs/firestore/quickstart?hl=id)
- [Offline support Firestore](https://firebase.google.com/docs/firestore/manage-data/enable-offline)
- [StreamBuilder dokumentasi Flutter](https://api.flutter.dev/flutter/widgets/StreamBuilder-class.html)
