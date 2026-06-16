import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:star_consignment/views/tabbar/beranda_page.dart';

void main() {
  late FakeFirebaseFirestore firestore;

  setUp(() {
    firestore = FakeFirebaseFirestore();
  });

  Future<void> createSampleRequest() async {
    await firestore
        .collection('consignment_requests')
        .doc('batch1')
        .set({
      'clientId': 'client1',
      'clientName': 'John Doe',
      'clientAddress': 'Test Address',
      'clientEmail': 'john@test.com',
      'status': 'pending',
      'createdAt': Timestamp.now(),

      'items': [
        {
          'catalogId': 'item1',
          'catalogName': 'Baju',
          'catalogPrice': 150000,
          'catalogCategory': 'Seragam',
          'catalogImagePath': '',
          'quantity': 2,
          'itemStatus': 'pending',
        }
      ]
    });
  }

  Future<void> createSampleClient() async {
    await firestore
        .collection('clients')
        .doc('client1')
        .set({
      'name': 'John Doe',
      'phone': '08123456789',
      'email': 'john@test.com',
      'address': 'Test Address',
      'debt': 300000,

      'borrowedItems': [
        {
          'catalogId': 'item1',
          'catalogName': 'Baju',
          'catalogPrice': 150000,
          'catalogCategory': 'Seragam',
          'catalogImagePath': '',
          'quantity': 2,
        }
      ]
    });
  }

  Widget buildWidget() {
    return MaterialApp(
      home: Scaffold(
        body: HomeAdminPage(
          firestore: firestore,
        ),
      ),
    );
  }
  
  group('HomeAdminPage Widget Tests', () {
    testWidgets(
      //Apakah menampilkan state kosong jida request tidak ada
      'shows empty state when no requests exist',
      (tester) async {
        await tester.pumpWidget(buildWidget());

        await tester.pumpAndSettle();

        expect(
          find.text('Belum ada data'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      //Apakah menampilkan request dari firestore
      'shows request from firestore',
      (tester) async {
        await createSampleRequest();

        await tester.pumpWidget(buildWidget());

        await tester.pumpAndSettle();

        expect(
          find.text('John Doe'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      //Apakah tombol approve bekerja untuk approve status
      'approve button updates status',
      (tester) async {
        await createSampleRequest();

        await tester.pumpWidget(buildWidget());

        await tester.pumpAndSettle();

        await tester.tap(
          find.byIcon(Icons.check_rounded),
        );

        await tester.pumpAndSettle();

        final doc = await firestore
            .collection('consignment_requests')
            .doc('batch1')
            .get();

        expect(
          doc.data()?['status'],
          equals('processing'),
        );

        final items =
            doc.data()?['items'] as List<dynamic>;

        expect(
          items.first['itemStatus'],
          equals('approved'),
        );

        expect(
          find.text('Request berhasil disetujui'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      //Apakah tombol reject bekerja untuk reject status
      'reject button updates status',
      (tester) async {
        await createSampleRequest();

        await tester.pumpWidget(buildWidget());

        await tester.pumpAndSettle();

        await tester.tap(
          find.byIcon(Icons.cancel_outlined),
        );

        await tester.pumpAndSettle();

        final doc = await firestore
            .collection('consignment_requests')
            .doc('batch1')
            .get();

        expect(
          doc.data()?['status'],
          equals('rejected'),
        );

        final items =
            doc.data()?['items'] as List<dynamic>;

        expect(
          items.first['itemStatus'],
          equals('rejected'),
        );

        expect(
          find.text('Request ditolak'),
          findsOneWidget,
        );
      },
    );

  testWidgets(
    //Apakah menampilkan preview untuk barang konsinyasi
    'shows preview item information',
    (tester) async {
      await createSampleClient();

      await tester.pumpWidget(buildWidget());

      await tester.pumpAndSettle();

      expect(
        find.text('Barang Konsinyasi'),
        findsOneWidget,
      );

      expect(
        find.text('Baju'),
        findsOneWidget,
      );

      expect(
        find.text('Peminjam: John Doe'),
        findsOneWidget,
      );

      expect(
        find.text('Qty: 2'),
        findsOneWidget,
      );
    },
  );

    testWidgets(
      //Apakah tombol lihat semua ada
      'lihat semua button exists',
      (tester) async {
        await createSampleRequest();

        await tester.pumpWidget(buildWidget());

        await tester.pumpAndSettle();

        expect(
          find.text('Lihat Semua'),
          findsOneWidget,
        );
      },
    );
  });
}
