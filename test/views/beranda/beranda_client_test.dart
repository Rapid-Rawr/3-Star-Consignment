import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mocktail/mocktail.dart';

import 'package:star_consignment/views/beranda/beranda_client.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

void main() {
  testWidgets(
    'HomeClientPage render test',
    (WidgetTester tester) async {
      final firestore = FakeFirebaseFirestore();

      final auth = MockFirebaseAuth();

      when(() => auth.currentUser).thenReturn(null);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HomeClientPage(
              auth: auth,
              firestore: firestore,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(HomeClientPage), findsOneWidget);
    },
  );
}