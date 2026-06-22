import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:star_consignment/service/roles.dart';

import 'package:star_consignment/controllers/barang_controllers/konsinyasi_controller.dart';
import 'package:star_consignment/models/barang_models/katalog_model.dart';

CatalogModel _catalog({
  String id = 'item1',
  String name = 'Baju',
  double price = 150000,
  String category = 'Seragam',
}) {
  return CatalogModel(
    id: id,
    name: name,
    price: price,
    category: category,
    imagePath: 'image.jpg',
  );
}

Future<String> _addRequest(
  FakeFirebaseFirestore firestore, {
  String clientEmail = 'client@test.com',
}) async {
  final ref = await firestore
      .collection('consignment_requests')
      .add({
    'clientId': 'client1',
    'clientName': 'John Doe',
    'clientEmail': clientEmail,
    'status': 'pending',
    'items': [],
    'createdAt': DateTime.now(),
  });

  return ref.id;
}

void main() {
  group('createRequest', () {
  bv


      expect(result['success'], isTrue);

      final snap = await firestore
          .collection('consignment_requests')
          .get();

      expect(snap.docs.length, 1);
    });

    // Menguji apakah data client tersimpan dengan benar
    test('stores client data correctly', () async { 
      final firestore = FakeFirebaseFirestore();

      final controller = ConsignmentRequestController(
        firestore: firestore,
      );

      await controller.createRequest(
        catalogItems: [_catalog()],
        quantities: [2],
        clientId: 'client1',
        clientName: 'John Doe',
        clientEmail: 'john@test.com',
      );

      final snap = await firestore
          .collection('consignment_requests')
          .get();

      final data = snap.docs.first.data();

      expect(data['clientId'], 'client1');
      expect(data['clientName'], 'John Doe');
      expect(data['clientEmail'], 'john@test.com');
    });
  });

  group('getRequestsStream', () {
    // Menguji stream kosong jika belum ada data
    test('returns empty stream when no data exists', () async {
      final firestore = FakeFirebaseFirestore();

      final controller = ConsignmentRequestController(
        firestore: firestore,
      );

      final snap = await controller
          .getRequestsStream()
          .first;

      expect(snap.docs, isEmpty);
    });

    // Menguji stream mengembalikan data request
    test('returns request data from firestore', () async {
      final firestore = FakeFirebaseFirestore();

      await _addRequest(firestore);

      final controller = ConsignmentRequestController(
        firestore: firestore,
      );

      final snap = await controller
          .getRequestsStream()
          .first;

      expect(snap.docs.length, 1);
    });
  });

  group('getRequestsStreamForUser', () {
    // Menguji hanya data milik user yang ditampilkan
    test('returns only user requests', () async {
      final firestore = FakeFirebaseFirestore();

      await _addRequest(
        firestore,
        clientEmail: 'john@test.com',
      );

      await _addRequest(
        firestore,
        clientEmail: 'other@test.com',
      );

      final controller = ConsignmentRequestController(
        firestore: firestore,
      );

      final snap = await controller
          .getRequestsStreamForUser(
            'john@test.com',
          )
          .first;

      expect(snap.docs.length, 1);
      expect(
        snap.docs.first['clientEmail'],
        'john@test.com',
      );
    });
  });

  group('deleteRequest', () {
    // Menguji request berhasil dihapus
    test('deletes request successfully', () async {
      final firestore = FakeFirebaseFirestore();

      final id = await _addRequest(firestore);

      final controller = ConsignmentRequestController(
        firestore: firestore,
      );

      final result =
          await controller.deleteRequest(id);

      expect(result['success'], isTrue);

      final doc = await firestore
          .collection('consignment_requests')
          .doc(id)
          .get();

      expect(doc.exists, isFalse);
    });
  });

  group('getRequestsByRole', () {
    // Menguji admin dapat melihat semua request
    test('admin gets all requests', () async {
      final firestore = FakeFirebaseFirestore();

      await _addRequest(
        firestore,
        clientEmail: 'a@test.com',
      );

      await _addRequest(
        firestore,
        clientEmail: 'b@test.com',
      );

      final controller = ConsignmentRequestController(
        firestore: firestore,
      );

      final snap = await controller
          .getRequestsByRole(
            role: Roles.admin,
            email: 'a@test.com',
          )
          .first;

      expect(snap.docs.length, 2);
    });

    // Menguji client hanya melihat datanya sendiri
    test('client gets own requests only', () async {
      final firestore = FakeFirebaseFirestore();

      await _addRequest(
        firestore,
        clientEmail: 'john@test.com',
      );

      await _addRequest(
        firestore,
        clientEmail: 'other@test.com',
      );

      final controller = ConsignmentRequestController(
        firestore: firestore,
      );

      final snap = await controller
          .getRequestsByRole(
            role: Roles.client,
            email: 'john@test.com',
          )
          .first;

      expect(snap.docs.length, 1);
    });
  });
}