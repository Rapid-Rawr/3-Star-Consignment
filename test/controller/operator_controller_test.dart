import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

import 'package:star_consignment/models/pengguna_models/operator_model.dart';
import 'package:star_consignment/controllers/pengguna_controllers/operator_controller.dart';


void main() {
  
  group('Uji OperatorModel', () {
    test('fromMap harus mengonversi data dari Firestore dengan benar (username -> name)', () {
      final map = {
        'username': 'Siti',
        'gmail': 'siti@gmail.com',
        'Role': 'Admin',
        'pendingDelete': true,
      };

      final model = OperatorModel.fromMap('doc_123', map);

      // Assert
      expect(model.id, 'doc_123');
      expect(model.name, 'Siti'); 
      expect(model.email, 'siti@gmail.com');
      expect(model.role, 'Admin');
      expect(model.pendingDelete, true);
    });

    test('toMap harus mengubah model menjadi format key Firestore yang tepat', () {
      final model = OperatorModel(
        id: 'doc_123',
        name: 'Joko',
        email: 'joko@gmail.com',
        role: 'Karyawan',
      );

      final map = model.toMap();

      expect(map['username'], 'Joko');
      expect(map['gmail'], 'joko@gmail.com');
      expect(map['Role'], 'Karyawan');
      expect(map.containsKey('id'), false);
    });

    test('copyWith harus menyalin objek dan hanya mengubah nilai yang dikirim', () {
      final model = OperatorModel(
        id: '1',
        name: 'Lama',
        email: 'lama@gmail.com',
        role: 'Karyawan',
      );

      // Action: Ubah nama dan role saja
      final updatedModel = model.copyWith(name: 'Baru', role: 'Admin');

      // Assert
      expect(updatedModel.id, '1'); // Tidak boleh berubah
      expect(updatedModel.email, 'lama@gmail.com'); // Tidak boleh berubah
      expect(updatedModel.name, 'Baru'); // Harus berubah
      expect(updatedModel.role, 'Admin'); // Harus berubah
    });
  });

 
  group('Uji OperatorController', () {
    late FakeFirebaseFirestore fakeFirestore;
    late OperatorController controller;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      controller = OperatorController(firestore: fakeFirestore);
    });

    group('Validasi Form (Pure Logic)', () {
      test('validateEmail harus memvalidasi aturan khusus @gmail.com', () {
        expect(controller.validateEmail('user@yahoo.com'), 'Email harus menggunakan @gmail.com');
        expect(controller.validateEmail('budi.santoso@gmail.com'), null); 
      });

      test('formatDisplayName harus memotong teks yang lebih dari 12 karakter', () {
        expect(controller.formatDisplayName('Budi Santoso'), 'Budi Santoso'); // 12 Karakter pas
        expect(controller.formatDisplayName('Budi SantosoX'), 'Budi Sant...'); // 13 Karakter dipotong
      });
    });

    group('Fitur Pencarian & Filter dengan OperatorModel Asli', () {
      final mockOperators = [
        OperatorModel(id: '1', name: 'Andi', email: 'andi@gmail.com', role: 'Admin'),
        OperatorModel(id: '2', name: 'Budi', email: 'budi@gmail.com', role: 'Karyawan'),
        OperatorModel(id: '3', name: 'Citra', email: 'citra@gmail.com', role: 'Karyawan'),
      ];

      test('filteredOperators harus bisa menggabungkan filter role dan pencarian teks', () {
        // 1. Set Role ke Karyawan (Sisa Budi dan Citra)
        controller.setRoleFilter('Karyawan');
        
        // 2. Set Pencarian ke 'citra' (Sisa Citra saja)
        controller.setSearchQuery('citra');
        
        final result = controller.filteredOperators(mockOperators);

        expect(result.length, 1);
        expect(result.first.name, 'Citra');
      });

      test('filteredOperators mencari teks di name, email, dan role', () {
        controller.setRoleFilter(null); // Tanpa filter role
        controller.setSearchQuery('admin'); // Mencari kata 'admin'
        
        final result = controller.filteredOperators(mockOperators);

        // Harus mendapatkan Andi karena role-nya Admin
        expect(result.length, 1);
        expect(result.first.name, 'Andi');
      });
    });

    group('Logika CRUD Database', () {
      test('createOperator menyimpan data menggunakan key yang sama dengan toMap Model', () async {
        final result = await controller.createOperator(
          name: '  Dani  ',
          email: ' DANI@GMAIL.COM ',
          role: 'Admin',
        );

        expect(result['success'], true);

        final snapshot = await fakeFirestore.collection('users').get();
        final data = snapshot.docs.first.data();
        
        // Memastikan controller dan model menggunakan bahasa "key" yang sama (username, gmail, Role)
        expect(data['username'], 'Dani'); 
        expect(data['gmail'], 'dani@gmail.com'); 
        expect(data['Role'], 'Admin');
      });

      test('deleteOperator mengatur pendingDelete menjadi true (Soft Delete)', () async {
        final docRef = await fakeFirestore.collection('users').add({
          'username': 'Eko',
          'gmail': 'eko@gmail.com',
          'Role': 'Karyawan'
        });

        await controller.deleteOperator(docRef.id);
        
        final docSnapshot = await docRef.get();
        // Memastikan status pendingDelete berubah di database
        expect(docSnapshot.data()!['pendingDelete'], true);
      });
    });
  });
}