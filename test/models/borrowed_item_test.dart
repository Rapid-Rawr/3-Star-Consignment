import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:star_consignment/models/pengguna_models/klien_model.dart'; 

void main() {
  group('BorrowedItem Tests - Data Baju Sekolah', () {
    final DateTime testDate = DateTime(2023, 7, 10); // Musim tahun ajaran baru
    final Timestamp testTimestamp = Timestamp.fromDate(testDate);

    test('Harus berhasil dikonversi ke Map (toMap)', () {
      final item = BorrowedItem(
        catalogId: 'SKL-001',
        catalogName: 'Kemeja Putih SD Lengan Pendek',
        catalogPrice: 75000.0,
        catalogCategory: 'Seragam Atasan',
        quantity: 3,
        lastReceivedAt: testDate,
      );

      final map = item.toMap();

      expect(map['catalogId'], 'SKL-001');
      expect(map['catalogName'], 'Kemeja Putih SD Lengan Pendek');
      expect(map['catalogPrice'], 75000.0);
      expect(map['quantity'], 3);
      expect(map['lastReceivedAt'], isA<Timestamp>());
      expect(map['lastReceivedAt'], testTimestamp);
    });

    test('Harus berhasil dikonversi dari Map (fromMap) dengan nilai default aman', () {
      final map = {
        'catalogId': 'SKL-002',
        'catalogName': 'Celana Merah SD Panjang',
        // Simulasi jika database Firestore menyimpan integer (num) alih-alih double
        'catalogPrice': 90000, 
        'catalogCategory': 'Seragam Bawahan',
        'quantity': 2,
        'lastReceivedAt': testTimestamp,
      };

      final item = BorrowedItem.fromMap(map);

      expect(item.catalogId, 'SKL-002');
      expect(item.catalogPrice, 90000.0); // Memastikan casting ke double berhasil
      expect(item.quantity, 2);
      expect(item.lastReceivedAt, testDate);
    });

    test('Fungsi accumulate harus menambah jumlah stok barang dan mengubah tanggal', () {
      final initialItem = BorrowedItem(
        catalogId: 'AKS-001',
        catalogName: 'Dasi SD Merah',
        catalogPrice: 15000.0,
        catalogCategory: 'Aksesoris',
        quantity: 5,
      );

      final newDate = DateTime(2023, 7, 15);
      // Klien mengambil lagi 10 dasi tambahan
      final accumulatedItem = initialItem.accumulate(10, newDate);

      expect(accumulatedItem.quantity, 15); // 5 + 10
      expect(accumulatedItem.lastReceivedAt, newDate);
      expect(accumulatedItem.catalogName, 'Dasi SD Merah'); // Properti lain tidak berubah
    });
  });

  group('Skenario Invalid (Negative Tests) - Memastikan Model Menolak Data Rusak', () {
    
    test('BorrowedItem.fromMap harus melempar TypeError jika harga adalah String', () {
      final mapFormatSalah = {
        'catalogId': 'ERR-001',
        'catalogName': 'Baju Salah Format',
        // Kesalahan umum: Harga tersimpan sebagai teks, bukan angka
        'catalogPrice': '75000', 
        'catalogCategory': 'Seragam',
      };

      // Karena model menggunakan (map['catalogPrice'] as num?), 
      // ini akan gagal (throw TypeError) saat runtime.
      expect(
        () => BorrowedItem.fromMap(mapFormatSalah),
        throwsA(isA<TypeError>()),
        reason: 'Model seharusnya tidak bisa melakukan casting String ke num',
      );

    });
  });

  
}