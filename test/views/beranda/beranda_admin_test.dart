import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:star_consignment/views/beranda/beranda_admin.dart';

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
      'createdAt': DateTime.now(),

      'items': [
        {
          'catalogId': 'item1',
          'catalogName': 'Baju Seragam',
          'catalogPrice': 150000,
          'catalogCategory': 'Seragam',
          'catalogImagePath': '',
          'quantity': 2,
          'itemStatus': 'pending',
        }
      ]
    });
  }

  Widget buildWidget() {
    return MaterialApp(
      home: HomeAdminPage(
        firestore: firestore,
      ),
    );
  }

  group('HomeAdminPage Widget Tests', () {
    testWidgets(
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
      'shows request from firestore',
      (tester) async {
        await createSampleRequest();

        await tester.pumpWidget(buildWidget());

        await tester.pumpAndSettle();

        expect(
          find.text('John Doe'),
          findsNWidgets(2),
        );
      },
    );

    testWidgets(
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
      'shows preview item information',
      (tester) async {
        await createSampleRequest();

        await tester.pumpWidget(buildWidget());

        await tester.pumpAndSettle();

        expect(
          find.text('Barang Konsinyasi'),
          findsOneWidget,
        );

        expect(
          find.text('Baju Seragam'),
          findsOneWidget,
        );

        expect(
          find.textContaining('Rp'),
          findsWidgets,
        );
      },
    );

    testWidgets(
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