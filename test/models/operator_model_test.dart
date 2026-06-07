import 'package:flutter_test/flutter_test.dart';
import 'package:star_consignment/models/pengguna_models/operator_model.dart';

void main() {
  group('OperatorModel Tests', () {
    test(
        //Memastikan data Map Firestore berhasil diubah menjadi object OperatorModel
      'fromMap creates object correctly',
      () {
        final operator = OperatorModel.fromMap(
          'op1',
          {
            'username': 'Admin',
            'gmail': 'admin@test.com',
            'Role': 'admin',
            'photoUrl': 'photo.jpg',
          },
        );

        expect(operator.id, 'op1');
        expect(operator.name, 'Admin');
        expect(operator.email, 'admin@test.com');
        expect(operator.role, 'admin');
        expect(operator.photoUrl, 'photo.jpg');
      },
    );

    test(
        //Memastikan nilai default ('' dan null) digunakan jika data tidak ada
      'fromMap returns default values when fields are missing',
      () {
        final operator = OperatorModel.fromMap(
          'op1',
          {},
        );

        expect(operator.id, 'op1');
        expect(operator.name, '');
        expect(operator.email, '');
        expect(operator.role, '');
        expect(operator.photoUrl, null);
      },
    );

    test(
        //Memastikan object berhasil diubah kembali menjadi Map untuk disimpan ke Firestore
      'toMap converts object correctly',
      () {
        final operator = OperatorModel(
          id: 'op1',
          name: 'Admin',
          email: 'admin@test.com',
          role: 'admin',
          photoUrl: 'photo.jpg',
        );

        final map = operator.toMap();

        expect(map['username'], 'Admin');
        expect(map['gmail'], 'admin@test.com');
        expect(map['Role'], 'admin');
      },
    );

    test(
        //Menguji perubahan satu field tanpa mengubah field lainnya
      'copyWith updates selected fields',
      () {
        final original = OperatorModel(
          id: 'op1',
          name: 'Admin',
          email: 'admin@test.com',
          role: 'admin',
        );

        final updated = original.copyWith(
          name: 'Operator Baru',
        );

        expect(updated.id, 'op1');
        expect(updated.name, 'Operator Baru');
        expect(updated.email, 'admin@test.com');
        expect(updated.role, 'admin');
      },
    );

    test(
        //Menguji perubahan beberapa field sekaligus
      'copyWith updates multiple fields',
      () {
        final original = OperatorModel(
          id: 'op1',
          name: 'Admin',
          email: 'admin@test.com',
          role: 'admin',
        );

        final updated = original.copyWith(
          email: 'operator@test.com',
          role: 'operator',
        );

        expect(updated.email, 'operator@test.com');
        expect(updated.role, 'operator');
      },
    );

    test(
        //Menguji penggantian foto operator
      'copyWith can replace photoUrl',
      () {
        final original = OperatorModel(
          id: 'op1',
          name: 'Admin',
          email: 'admin@test.com',
          role: 'admin',
          photoUrl: 'old.jpg',
        );

        final updated = original.copyWith(
          photoUrl: 'new.jpg',
        );

        expect(updated.photoUrl, 'new.jpg');
      },
    );

    test(
        //Memastikan foto lama tetap dipertahankan jika photoUrl tidak diisi
      'copyWith keeps photoUrl when not provided',
      () {
        final original = OperatorModel(
          id: 'op1',
          name: 'Admin',
          email: 'admin@test.com',
          role: 'admin',
          photoUrl: 'photo.jpg',
        );

        final updated = original.copyWith(
          name: 'Admin Baru',
        );

        expect(updated.photoUrl, 'photo.jpg');
      },
    );
  });
}