import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:star_consignment/controllers/pengguna_controllers/klien_controller.dart';



void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late ClientController controller;

  setUp(() {
    // 1. Inisialisasi database palsu
    fakeFirestore = FakeFirebaseFirestore();
    
    controller = ClientController(firestore: fakeFirestore);
  });

  group('Uji Validasi Form (Pure Logic)', () {
    test('validateName harus merespons dengan benar', () {
      expect(controller.validateName(null), 'Nama tidak boleh kosong');
      expect(controller.validateName('A'), 'Nama minimal 2 karakter');
      expect(controller.validateName('Budi Santoso'), null); // null berarti valid
    });

    test('validatePhone harus merespons dengan benar', () {
      expect(controller.validatePhone('123'), 'Nomor telepon minimal 8 digit');
      expect(controller.validatePhone('08123456789'), null);
    });
  });

  group('Uji Logika CRUD Database', () {
    test('createClient harus berhasil menambah data ke Firestore', () async {
      // Action: Buat client baru
      final result = await controller.createClient(
        name: 'Toko Maju',
        phone: '081234567890',
        email: 'toko@maju.com',
        address: 'Jl. Merdeka 1',
      );

      expect(result['success'], true);

      final snapshot = await fakeFirestore.collection('clients').get();
      expect(snapshot.docs.length, 1);
      expect(snapshot.docs.first.data()['name'], 'Toko Maju');
      expect(snapshot.docs.first.data()['debt'], 0); // Memastikan nilai default masuk
    });

    test('deleteClient harus menerapkan Soft Delete (pendingDelete: true)', () async {
      final docRef = await fakeFirestore.collection('clients').add({
        'name': 'Toko Mundur',
      });

      // Action: Panggil fungsi delete
      final result = await controller.deleteClient(docRef.id);

      expect(result['success'], true);
      
      // Verifikasi di database
      final docSnapshot = await docRef.get();
      expect(docSnapshot.data()!['pendingDelete'], true);
    });
  });

  group('Uji Logika Bisnis', () {
    test('addBorrowedItemsDirect harus menggabungkan item yang sama', () async {
      final docRef = await fakeFirestore.collection('clients').add({
        'name': 'Client A',
        'borrowedItems': [
          {'catalogId': 'item1', 'catalogPrice': 1000, 'quantity': 2}
        ]
      });

      // Action: Tambahkan item yang sama (item1)
      await controller.addBorrowedItemsDirect(
        clientId: docRef.id,
        newItems: [
          {'catalogId': 'item1', 'catalogPrice': 1000, 'quantity': 3}
        ],
      );

      // Assert: Quantity item1 seharusnya menjadi 2 + 3 = 5
      final updatedDoc = await docRef.get();
      final borrowedItems = updatedDoc.data()!['borrowedItems'] as List<dynamic>;
      
      expect(borrowedItems.length, 1); // Tidak membuat item baru di array
      expect(borrowedItems.first['quantity'], 5); // Quantity dijumlahkan
    });
  });
}