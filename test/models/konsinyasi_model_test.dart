import 'package:flutter_test/flutter_test.dart';
import 'package:star_consignment/models/barang_models/konsinyasi_model.dart';

void main() {
  group('ConsignmentItemEntry Tests', () {
    //Apakah data barang konsinyasi dari Firestore dapat diparsing dengan benar
    test('fromMap creates object correctly', () {
      final item = ConsignmentItemEntry.fromMap({
        'catalogId': 'item1',
        'catalogName': 'Baju',
        'catalogPrice': 150000,
        'catalogCategory': 'Seragam',
        'catalogImagePath': 'image.jpg',
        'quantity': 2,
        'approvedQty': 1,
        'itemStatus': 'approved',
      });

      expect(item.catalogId, 'item1');
      expect(item.catalogName, 'Baju');
      expect(item.catalogPrice, 150000);
      expect(item.catalogCategory, 'Seragam');
      expect(item.catalogImagePath, 'image.jpg');
      expect(item.quantity, 2);
      expect(item.approvedQty, 1);
      expect(
        item.itemStatus,
        ConsignmentItemStatus.approved,
      );
    });

    //Apakah model memberikan nilai default ketika data yang diterima kosong atau tidak lengkap
    test('fromMap returns default values', () {
      final item = ConsignmentItemEntry.fromMap({});

      expect(item.catalogId, '');
      expect(item.catalogName, '');
      expect(item.catalogPrice, 0);
      expect(item.catalogCategory, '');
      expect(item.quantity, 1);
      expect(item.approvedQty, isNull);
      expect(
        item.itemStatus,
        ConsignmentItemStatus.pending,
      );
    });

    //AMenguji proses konversi object ConsignmentItemEntry
    //menjadi Map<String, dynamic> yang siap disimpan ke Firestore.
    test('toMap converts object correctly', () {
      final item = ConsignmentItemEntry(
        catalogId: 'item1',
        catalogName: 'Baju',
        catalogPrice: 150000,
        catalogCategory: 'Seragam',
        quantity: 2,
        approvedQty: 1,
        itemStatus: ConsignmentItemStatus.approved,
      );

      final map = item.toMap();

      expect(map['catalogId'], 'item1');
      expect(map['catalogName'], 'Baju');
      expect(map['catalogPrice'], 150000);
      expect(map['catalogCategory'], 'Seragam');
      expect(map['quantity'], 2);
      expect(map['approvedQty'], 1);
      expect(map['itemStatus'], 'approved');
    });

    //Apakah method copyWith() dapat mengubah status barang tanpa mengubah data lain yang sudah ada.
    test('copyWith updates item status', () {
      final item = ConsignmentItemEntry(
        catalogId: 'item1',
        catalogName: 'Baju',
        catalogPrice: 150000,
        catalogCategory: 'Seragam',
        quantity: 2,
      );

      final updated = item.copyWith(
        itemStatus: ConsignmentItemStatus.approved,
      );

      expect(
        updated.itemStatus,
        ConsignmentItemStatus.approved,
      );

      expect(updated.catalogName, 'Baju');
      expect(updated.quantity, 2);
    });

    //Apakah jumlah barang yang disetujui (approvedQty) dapat diperbarui menggunakan method copyWith().
    test('copyWith updates approvedQty', () {
      final item = ConsignmentItemEntry(
        catalogId: 'item1',
        catalogName: 'Baju',
        catalogPrice: 150000,
        catalogCategory: 'Seragam',
        quantity: 2,
      );

      final updated = item.copyWith(
        approvedQty: 2,
      );

      expect(updated.approvedQty, 2);
    });

    //Apakah kemampuan copyWith() untuk menghapus nilai approvedQty dengan mengubahnya menjadi null.
    test('copyWith can clear approvedQty', () {
      final item = ConsignmentItemEntry(
        catalogId: 'item1',
        catalogName: 'Baju',
        catalogPrice: 150000,
        catalogCategory: 'Seragam',
        quantity: 2,
        approvedQty: 1,
      );

      final updated = item.copyWith(
        approvedQty: null,
      );

      expect(updated.approvedQty, isNull);
    });
  });

  //Apakah data request konsinyasi dari Firestore dapat diparsing dengan benar
  group('ConsignmentRequestModel Tests', () {
    test('fromMap creates object correctly', () {
      final request =
          ConsignmentRequestModel.fromMap(
        'req1',
        {
          'clientId': 'client1',
          'clientName': 'John Doe',
          'clientAddress': 'School A',
          'clientEmail': 'john@test.com',
          'status': 'processing',
          'items': [
            {
              'catalogId': 'item1',
              'catalogName': 'Baju',
              'catalogPrice': 150000,
              'catalogCategory': 'Seragam',
              'quantity': 2,
            }
          ],
        },
      );

      expect(request.id, 'req1');
      expect(request.clientId, 'client1');
      expect(request.clientName, 'John Doe');
      expect(request.clientAddress, 'School A');
      expect(request.clientEmail, 'john@test.com');

      expect(
        request.status,
        ConsignmentBatchStatus.processing,
      );

      expect(request.items.length, 1);
      expect(
        request.items.first.catalogName,
        'Baju',
      );
    });

    //Menguji kompatibilitas dengan struktur database lama. Jika field baru tidak tersedia
    test('fromMap supports legacy fields', () {
      final request =
          ConsignmentRequestModel.fromMap(
        'req1',
        {
          'userId': 'client1',
          'userName': 'John Doe',
          'userSchool': 'School A',
          'userEmail': 'john@test.com',
          'items': [],
        },
      );

      expect(request.clientId, 'client1');
      expect(request.clientName, 'John Doe');
      expect(request.clientAddress, 'School A');
      expect(request.clientEmail, 'john@test.com');
    });

    //Menguji apakah status request otomatis menjadi pending ketika field status tidak ditemukan pada data Firestore.
    test('fromMap defaults to pending status', () {
      final request =
          ConsignmentRequestModel.fromMap(
        'req1',
        {
          'items': [],
        },
      );

      expect(
        request.status,
        ConsignmentBatchStatus.pending,
      );
    });

    //Menguji proses konversi object ConsignmentRequestModel menjadi Map<String, dynamic> sebelum disimpan ke Firestore.
    test('toMap converts object correctly', () {
      final request = ConsignmentRequestModel(
        id: 'req1',
        clientId: 'client1',
        clientName: 'John Doe',
        clientEmail: 'john@test.com',
        items: [],
      );

      final map = request.toMap();

      expect(map['clientId'], 'client1');
      expect(map['clientName'], 'John Doe');
      expect(map['clientEmail'], 'john@test.com');
      expect(map['status'], 'pending');
    });

    //Menguji apakah daftar barang dalam request konsinyasi dapat diganti dengan daftar baru menggunakan method copyWithItems().
    test('copyWithItems replaces item list', () {
      final request = ConsignmentRequestModel(
        id: 'req1',
        clientId: 'client1',
        clientName: 'John Doe',
        clientEmail: 'john@test.com',
        items: [],
      );

      final updated = request.copyWithItems([
        ConsignmentItemEntry(
          catalogId: 'item1',
          catalogName: 'Baju',
          catalogPrice: 150000,
          catalogCategory: 'Seragam',
          quantity: 2,
        ),
      ]);

      expect(updated.items.length, 1);

      expect(
        updated.items.first.catalogName,
        'Baju',
      );

      expect(
        updated.items.first.quantity,
        2,
      );
    });
  });
}