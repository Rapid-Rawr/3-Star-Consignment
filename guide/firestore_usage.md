# 📖 Panduan Penggunaan Firestore di Proyek Ini

Panduan ini hanya mencakup operasi Firestore yang **benar-benar dipakai** di proyek ini.

---

## Konsep Dasar — Dua Layer Data

```
Flutter App
    ↓ tulis/baca
[Cache Lokal (SQLite)] ← selalu ada, instant
    ↕ sinkron otomatis (background)
[Firebase Server]      ← butuh internet
```

- Operasi **write** (`add`, `update`, `delete`) selalu resolve **instant** meski offline — data masuk cache dulu, lalu dikirim ke server saat ada internet.
- Operasi **read sekali** (`get()`) butuh internet, kecuali data sudah ada di cache.
- Operasi **stream** (`snapshots()`) selalu jalan — mengambil dari cache offline, lalu update saat server merespons.

---

## Yang Dipakai di Proyek Ini

### 1. Stream Realtime — `snapshots()`

Dipakai di **semua halaman list** (client, operator). UI otomatis terupdate saat data berubah.

```dart
// Di controller
Stream<QuerySnapshot> getClientsStream() {
  return firestore
      .collection('clients')
      .snapshots(includeMetadataChanges: true); // ← wajib untuk deteksi pending
}
```

```dart
// Di view — pakai StreamBuilder
StreamBuilder<QuerySnapshot>(
  stream: _controller.getClientsStream(),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const CircularProgressIndicator();
    }
    if (snapshot.hasError) return Text('Error: ${snapshot.error}');
    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
      return const Text('Belum ada data');
    }

    final docs = snapshot.data!.docs;
    return ListView.builder(
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final doc  = docs[index];
        final data = doc.data() as Map<String, dynamic>;
        final isPending = doc.metadata.hasPendingWrites; // ← status sinkronisasi
        return Text(data['name']);
      },
    );
  },
)
```

---

### 2. Read Sekali + Filter — `.where().get()`

Dipakai di **`checkEmailExists`** (operator/karyawan) dan **`syncPhotoUrl`** (auth).
Berguna untuk cek data sebelum menulis, bukan untuk tampilan.

```dart
// Contoh: cek apakah email sudah ada
final query = await firestore
    .collection('users')
    .where('gmail', isEqualTo: email.toLowerCase())
    .limit(1) // stop setelah ketemu 1 — lebih efisien
    .get();

final exists = query.docs.isNotEmpty;
```

> ⚠️ `.get()` butuh internet dan bisa gagal saat offline. Jangan gunakan untuk tampilan utama — gunakan `snapshots()`.

---

### 3. Tambah Dokumen — `.add()`

Auto-generate ID dokumen.

```dart
await firestore.collection('clients').add({
  'name': name.trim(),
  'phone': phone.trim(),
  'address': address.trim(),
  'debt': debt,
  'createdAt': FieldValue.serverTimestamp(), // timestamp dari server Firebase
});
```

---

### 4. Update Dokumen — `.doc(id).update()`

Update hanya field yang disebutkan, field lain tidak berubah.

```dart
await firestore.collection('clients').doc(id).update({
  'name': name.trim(),
  'debt': debt,
  'updatedAt': FieldValue.serverTimestamp(),
});
```

---

### 5. Hapus Dokumen — `.doc(id).delete()`

```dart
await firestore.collection('clients').doc(docId).delete();
```

---

## Pola Wrapper di Proyek Ini

Semua operasi write dibungkus di controller dan mengembalikan `Map` agar view bisa cek hasilnya:

```dart
// Di controller
Future<Map<String, dynamic>> createClient({...}) async {
  try {
    await firestore.collection('clients').add({...});
    return {'success': true};
  } catch (e) {
    return {'success': false, 'error': e.toString()};
  }
}
```

```dart
// Di view — tutup dialog SEBELUM await agar tidak hang saat offline
onPressed: () async {
  if (formKey.currentState!.validate()) {
    Navigator.pop(dialogContext);           // tutup dialog dulu
    final result = await _controller.createClient(...);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result['success'] == true
            ? 'Berhasil ditambahkan'
            : result['error'] ?? 'Terjadi kesalahan'),
        backgroundColor: result['success'] == true ? Colors.green : Colors.red,
      ));
    }
  }
}
```

---

## Cara Kerja Pending (Icon ⏰)

Saat tidak ada internet, data masuk cache lokal. Icon ⏰ muncul otomatis lewat `hasPendingWrites`:

```
User tekan Tambah
    ↓
Navigator.pop()       ← dialog tutup langsung
    ↓
firestore.add()       ← simpan ke cache lokal, resolve instant
    ↓
Stream emit → hasPendingWrites = true
    ↓
Icon ⏰ muncul di kartu
    ↓
[Background] Firestore coba kirim ke server...
    ↓ (saat internet tersedia)
Server konfirmasi → hasPendingWrites = false
    ↓
Icon ⏰ hilang otomatis ✅
```

```dart
// Di itemBuilder ListView:
final isPending = doc.metadata.hasPendingWrites;

if (isPending)
  Row(children: [
    Icon(Icons.access_time_rounded, size: 12, color: Colors.orange),
    SizedBox(width: 4),
    Text('Menunggu sinkronisasi...', style: TextStyle(fontSize: 10, color: Colors.orange)),
  ]),
```

> `includeMetadataChanges: true` di stream **wajib** agar UI ikut update saat icon mau hilang.
> Tanpanya, stream tidak akan emit event saat `hasPendingWrites` berubah `true → false`.
