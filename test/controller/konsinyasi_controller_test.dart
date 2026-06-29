import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:star_consignment/service/roles.dart';
import 'package:star_consignment/controllers/barang_controllers/konsinyasi_controller.dart';
import 'package:star_consignment/models/barang_models/katalog_model.dart';
import 'package:star_consignment/models/barang_models/konsinyasi_model.dart';
 
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
  String clientId = 'client1',
  List<ConsignmentItemEntry> items = const [],
}) async {
  final request = ConsignmentRequestModel(
    id: '',
    clientId: clientId,
    clientName: 'John Doe',
    clientEmail: clientEmail,
    items: items.isEmpty ? [
      ConsignmentItemEntry(
        catalogId: 'item1',
        catalogName: 'Baju',
        catalogPrice: 150000,
        catalogCategory: 'Seragam',
        catalogImagePath: 'image.jpg',
        quantity: 2,
      )
    ] : items,
  );
  
  final ref = await firestore
      .collection('consignment_requests')
      .add(request.toMap());
 
  return ref.id;
}

void main() {
  group('Basic Requests Tests', () {
    test('creates request successfully', () async {
      final firestore = FakeFirebaseFirestore();
      final controller = ConsignmentRequestController(firestore: firestore);

      final result = await controller.createRequest(
        catalogItems: [_catalog()],
        quantities: [2],
        clientId: 'client1',
        clientName: 'John Doe',
        clientEmail: 'john@test.com',
      );

      expect(result['success'], isTrue);
      final snap = await firestore.collection('consignment_requests').get();
      expect(snap.docs.length, 1);
    });

    test('stores client data correctly', () async { 
      final firestore = FakeFirebaseFirestore();
      final controller = ConsignmentRequestController(firestore: firestore);

      await controller.createRequest(
        catalogItems: [_catalog()],
        quantities: [2],
        clientId: 'client1',
        clientName: 'John Doe',
        clientEmail: 'john@test.com',
      );

      final snap = await firestore.collection('consignment_requests').get();
      final data = snap.docs.first.data();

      expect(data['clientId'], 'client1');
      expect(data['clientName'], 'John Doe');
      expect(data['clientEmail'], 'john@test.com');
    });
  });

  group('Stream & Filter Tests', () {
    test('returns empty stream when no data exists', () async {
      final firestore = FakeFirebaseFirestore();
      final controller = ConsignmentRequestController(firestore: firestore);
      final snap = await controller.getRequestsStream().first;
      expect(snap.docs, isEmpty);
    });

    test('returns request data from firestore', () async {
      final firestore = FakeFirebaseFirestore();
      await _addRequest(firestore);
      final controller = ConsignmentRequestController(firestore: firestore);
      final snap = await controller.getRequestsStream().first;
      expect(snap.docs.length, 1);
    });

    test('returns only user requests', () async {
      final firestore = FakeFirebaseFirestore();
      await _addRequest(firestore, clientEmail: 'john@test.com');
      await _addRequest(firestore, clientEmail: 'other@test.com');

      final controller = ConsignmentRequestController(firestore: firestore);
      final snap = await controller.getRequestsStreamForUser('john@test.com').first;

      expect(snap.docs.length, 1);
      expect(snap.docs.first['clientEmail'], 'john@test.com');
    });

    test('admin gets all requests', () async {
      final firestore = FakeFirebaseFirestore();
      await _addRequest(firestore, clientEmail: 'a@test.com');
      await _addRequest(firestore, clientEmail: 'b@test.com');

      final controller = ConsignmentRequestController(firestore: firestore);
      final snap = await controller.getRequestsByRole(role: Roles.admin, email: 'a@test.com').first;
      expect(snap.docs.length, 2);
    });
  });

  group('Status & Approval Workflows', () {
    test('updateItemStatus changes item status and recalculates batch status', () async {
      final firestore = FakeFirebaseFirestore();
      final controller = ConsignmentRequestController(firestore: firestore);

      final docId = await _addRequest(firestore, items: [
        ConsignmentItemEntry(
          catalogId: 'item1', catalogName: 'Baju', catalogPrice: 100, catalogCategory: 'Cat', catalogImagePath: '', quantity: 2, itemStatus: ConsignmentItemStatus.pending
        ),
        ConsignmentItemEntry(
          catalogId: 'item2', catalogName: 'Celana', catalogPrice: 200, catalogCategory: 'Cat', catalogImagePath: '', quantity: 3, itemStatus: ConsignmentItemStatus.pending
        ),
      ]);

      final result = await controller.updateItemStatus(docId, 0, ConsignmentItemStatus.approved);
      expect(result['success'], isTrue);

      final snap = await firestore.collection('consignment_requests').doc(docId).get();
      final model = ConsignmentRequestModel.fromMap(snap.id, snap.data()!);

      expect(model.status, ConsignmentBatchStatus.processing);
      expect(model.items[0].itemStatus, ConsignmentItemStatus.approved);
      expect(model.items[1].itemStatus, ConsignmentItemStatus.pending);
    });

    test('updateItemStatus supports partial approval', () async {
      final firestore = FakeFirebaseFirestore();
      final controller = ConsignmentRequestController(firestore: firestore);

      final docId = await _addRequest(firestore);

      final result = await controller.updateItemStatus(docId, 0, ConsignmentItemStatus.partial, approvedQty: 1);
      expect(result['success'], isTrue);

      final snap = await firestore.collection('consignment_requests').doc(docId).get();
      final model = ConsignmentRequestModel.fromMap(snap.id, snap.data()!);

      expect(model.items[0].itemStatus, ConsignmentItemStatus.partial);
      expect(model.items[0].approvedQty, 1);
    });

    test('approveAllPending and rejectAllPending bulk operations', () async {
      final firestore = FakeFirebaseFirestore();
      final controller = ConsignmentRequestController(firestore: firestore);

      final docId = await _addRequest(firestore, items: [
        ConsignmentItemEntry(
          catalogId: 'item1', catalogName: 'Baju', catalogPrice: 100, catalogCategory: 'Cat', catalogImagePath: '', quantity: 2, itemStatus: ConsignmentItemStatus.pending
        ),
        ConsignmentItemEntry(
          catalogId: 'item2', catalogName: 'Celana', catalogPrice: 200, catalogCategory: 'Cat', catalogImagePath: '', quantity: 3, itemStatus: ConsignmentItemStatus.pending
        ),
      ]);

      var res = await controller.approveAllPending(docId);
      expect(res['success'], isTrue);
      
      var snap = await firestore.collection('consignment_requests').doc(docId).get();
      var model = ConsignmentRequestModel.fromMap(snap.id, snap.data()!);
      expect(model.items.every((i) => i.itemStatus == ConsignmentItemStatus.approved), isTrue);
      expect(model.status, ConsignmentBatchStatus.processing);

      await controller.cancelAllItems(docId);
      snap = await firestore.collection('consignment_requests').doc(docId).get();
      model = ConsignmentRequestModel.fromMap(snap.id, snap.data()!);
      expect(model.items.every((i) => i.itemStatus == ConsignmentItemStatus.pending), isTrue);

      res = await controller.rejectAllPending(docId);
      expect(res['success'], isTrue);
      
      snap = await firestore.collection('consignment_requests').doc(docId).get();
      model = ConsignmentRequestModel.fromMap(snap.id, snap.data()!);
      expect(model.items.every((i) => i.itemStatus == ConsignmentItemStatus.rejected), isTrue);
    });

    test('cannot approve all if batch is packed', () async {
      final firestore = FakeFirebaseFirestore();
      final controller = ConsignmentRequestController(firestore: firestore);
      final docId = await _addRequest(firestore);

      await firestore.collection('consignment_requests').doc(docId).update({
        'status': ConsignmentBatchStatus.packed.name,
      });

      final result = await controller.approveAllPending(docId);
      expect(result['success'], isFalse);
      expect(result['error'], 'Pengajuan sudah dikemas');
    });

    test('cannot reject all if batch is packed', () async {
      final firestore = FakeFirebaseFirestore();
      final controller = ConsignmentRequestController(firestore: firestore);
      final docId = await _addRequest(firestore);

      await firestore.collection('consignment_requests').doc(docId).update({
        'status': ConsignmentBatchStatus.packed.name,
      });

      final result = await controller.rejectAllPending(docId);
      expect(result['success'], isFalse);
      expect(result['error'], 'Pengajuan sudah dikemas');
    });

    test('cannot cancel all if batch is packed', () async {
      final firestore = FakeFirebaseFirestore();
      final controller = ConsignmentRequestController(firestore: firestore);
      final docId = await _addRequest(firestore);

      await firestore.collection('consignment_requests').doc(docId).update({
        'status': ConsignmentBatchStatus.packed.name,
      });

      final result = await controller.cancelAllItems(docId);
      expect(result['success'], isFalse);
      expect(result['error'], 'Pengajuan sudah dikemas');
    });
  });

  group('Packing Workflows', () {
    test('cannot update item if batch is packed', () async {
      final firestore = FakeFirebaseFirestore();
      final controller = ConsignmentRequestController(firestore: firestore);
      final docId = await _addRequest(firestore);

      await firestore.collection('consignment_requests').doc(docId).update({
        'status': ConsignmentBatchStatus.packed.name,
      });

      final result = await controller.updateItemStatus(docId, 0, ConsignmentItemStatus.approved);
      expect(result['success'], isFalse);
      expect(result['error'], 'Pengajuan sudah dikemas');
    });
  });

  group('Delete Tests', () {
    test('deletes request successfully', () async {
      final firestore = FakeFirebaseFirestore();
      final controller = ConsignmentRequestController(firestore: firestore);
      final id = await _addRequest(firestore);

      final result = await controller.deleteRequest(id);
      expect(result['success'], isTrue);

      final doc = await firestore.collection('consignment_requests').doc(id).get();
      expect(doc.exists, isFalse);
    });
  });
}
