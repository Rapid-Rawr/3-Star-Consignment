import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// TODO: Sesuaikan import ini dengan lokasi file ClientModel Anda
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

  group('ClientModel Tests - Data Pelanggan Sekolah', () {
    final seragamPramuka = BorrowedItem(
      catalogId: 'PRM-001',
      catalogName: 'Baju Pramuka Penggalang',
      catalogPrice: 85000.0,
      catalogCategory: 'Seragam Pramuka',
      quantity: 2,
    );

    test('Harus menghitung computedDebt (total utang/tagihan) dengan benar', () {
      final topiSekolah = BorrowedItem(
        catalogId: 'AKS-002',
        catalogName: 'Topi SD Merah Putih',
        catalogPrice: 20000.0,
        catalogCategory: 'Aksesoris',
        quantity: 2,
      );

      final client = ClientModel(
        id: 'client-sekolah-01',
        name: 'Koperasi SDN 1',
        phone: '08123456789',
        address: 'Jl. Pendidikan No. 1',
        debt: 0.0, // Ini properti debt static
        borrowedItems: [seragamPramuka, topiSekolah], 
      );

      // Kalkulasi Tagihan Baju: 
      // (85.000 * 2 Baju) + (20.000 * 2 Topi) = 170.000 + 40.000 = 210.000
      expect(client.computedDebt, 210000.0);
    });

    test('toMap tidak boleh menyertakan id dan pendingDelete saat disimpan ke database', () {
      final client = ClientModel(
        id: 'client-sekolah-02',
        name: 'Toko Seragam Bu Ani',
        phone: '08999888777',
        address: 'Pasar Baru Blok A',
        debt: 500000.0,
        pendingDelete: true,
      );

      final map = client.toMap();

      // Memastikan field 'id' dan 'pendingDelete' tidak ikut ter-serialize
      expect(map.containsKey('id'), isFalse);
      expect(map.containsKey('pendingDelete'), isFalse);
      expect(map['name'], 'Toko Seragam Bu Ani');
      expect(map['debt'], 500000.0);
    });

    test('Harus berhasil dikonversi dari Map (fromMap) beserta list barang seragam', () {
      final map = {
        'name': 'Bapak Budi (Wali Murid)',
        'phone': '08111222333',
        'address': 'Perumahan Guru Blok C',
        'debt': 0.0,
        'pendingDelete': false,
        'borrowedItems': [
          seragamPramuka.toMap(),
        ]
      };

      final client = ClientModel.fromMap('doc_id_999', map);

      expect(client.id, 'doc_id_999');
      expect(client.name, 'Bapak Budi (Wali Murid)');
      expect(client.pendingDelete, false);
      expect(client.borrowedItems.length, 1);
      expect(client.borrowedItems.first.catalogName, 'Baju Pramuka Penggalang');
    });

    test('Fungsi copyWith harus mengganti nilai yang diubah spesifik saja', () {
      final client = ClientModel(
        id: 'client-sekolah-03',
        name: 'Koperasi SMPN 2',
        phone: '08555',
        address: 'Jl. Merdeka',
        debt: 150000.0,
      );

      // Simulasi update nomor telepon dan total hutang
      final updatedClient = client.copyWith(
        phone: '08555666777', 
        debt: 0.0 // Lunas
      );

      expect(updatedClient.id, 'client-sekolah-03'); // ID Tetap
      expect(updatedClient.name, 'Koperasi SMPN 2'); // Nama Tetap
      expect(updatedClient.phone, '08555666777'); // Berubah
      expect(updatedClient.debt, 0.0); // Berubah
    });
  });
}