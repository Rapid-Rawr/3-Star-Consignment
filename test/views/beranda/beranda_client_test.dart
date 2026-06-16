import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:star_consignment/views/tabbar/beranda_page.dart';

// ─── Mock ────────────────────────────────────────────────────────────────────
class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockUser extends Mock implements User {}

// ─── Helper ──────────────────────────────────────────────────────────────────
Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

Future<String> _addClient(
  FakeFirebaseFirestore firestore, {
  required String email,
}) async {
  final ref = await firestore.collection('clients').add({'email': email});
  return ref.id;
}

Future<void> _addRequest(
  FakeFirebaseFirestore firestore, {
  required String clientId,
  String status = 'pending',
  String clientName = 'Toko Makmur',
  List<Map<String, dynamic>>? items,
  Timestamp? createdAt,
}) async {
  await firestore.collection('consignment_requests').add({
    'clientId': clientId,
    'clientName': clientName,
    'status': status,
    'createdAt': createdAt ?? Timestamp.fromDate(DateTime(2024, 6, 1)),
    'items': items ?? [
      {'quantity': 3, 'catalogPrice': 15000},
      {'quantity': 2, 'catalogPrice': 25000},
    ],
  });
}

// ═════════════════════════════════════════════════════════════════════════════
void main() {
  group('Render dasar', () {
    testWidgets('render tanpa crash saat user null', (tester) async {
      final auth = MockFirebaseAuth();
      when(() => auth.currentUser).thenReturn(null);

      await tester.pumpWidget(
        _wrap(HomeClientPage(auth: auth, firestore: FakeFirebaseFirestore())),
      );
      await tester.pumpAndSettle();

      expect(find.byType(HomeClientPage), findsOneWidget);
    });

    testWidgets('tidak ada Scaffold ganda', (tester) async {
      final auth = MockFirebaseAuth();
      when(() => auth.currentUser).thenReturn(null);

      await tester.pumpWidget(
        _wrap(HomeClientPage(auth: auth, firestore: FakeFirebaseFirestore())),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Scaffold), findsOneWidget);
    });
  });

  group('User null / belum login', () {
    testWidgets('menampilkan pesan akun belum terdaftar', (tester) async {
      final auth = MockFirebaseAuth();
      when(() => auth.currentUser).thenReturn(null);

      await tester.pumpWidget(
        _wrap(HomeClientPage(auth: auth, firestore: FakeFirebaseFirestore())),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('belum terdaftar'), findsOneWidget);
    });

    testWidgets('menampilkan ikon info saat user null', (tester) async {
      final auth = MockFirebaseAuth();
      when(() => auth.currentUser).thenReturn(null);

      await tester.pumpWidget(
        _wrap(HomeClientPage(auth: auth, firestore: FakeFirebaseFirestore())),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });

    testWidgets('tidak ada footer Lebih Banyak saat user null', (tester) async {
      final auth = MockFirebaseAuth();
      when(() => auth.currentUser).thenReturn(null);

      await tester.pumpWidget(
        _wrap(HomeClientPage(auth: auth, firestore: FakeFirebaseFirestore())),
      );
      await tester.pumpAndSettle();

      expect(find.text('Lebih Banyak ...'), findsNothing);
    });
  });

  group('User login tapi tidak terdaftar sebagai klien', () {
    testWidgets('menampilkan pesan belum terdaftar sebagai klien', (tester) async {
      final auth = MockFirebaseAuth();
      final user = MockUser();
      when(() => auth.currentUser).thenReturn(user);
      when(() => user.email).thenReturn('bukan@klien.com');

      await tester.pumpWidget(
        _wrap(HomeClientPage(auth: auth, firestore: FakeFirebaseFirestore())),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('belum terdaftar'), findsOneWidget);
    });

    testWidgets('menampilkan header Request List walau tidak ada data', (tester) async {
      final auth = MockFirebaseAuth();
      final user = MockUser();
      when(() => auth.currentUser).thenReturn(user);
      when(() => user.email).thenReturn('bukan@klien.com');

      await tester.pumpWidget(
        _wrap(HomeClientPage(auth: auth, firestore: FakeFirebaseFirestore())),
      );
      await tester.pumpAndSettle();

      expect(find.text('Request List'), findsOneWidget);
    });
  });

  group('Klien terdaftar tapi belum ada pengajuan', () {
    testWidgets('menampilkan pesan belum ada pengajuan konsinyasi', (tester) async {
      final auth = MockFirebaseAuth();
      final user = MockUser();
      when(() => auth.currentUser).thenReturn(user);
      when(() => user.email).thenReturn('klien@example.com');

      final firestore = FakeFirebaseFirestore();
      await _addClient(firestore, email: 'klien@example.com');

      await tester.pumpWidget(
        _wrap(HomeClientPage(auth: auth, firestore: firestore)),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Belum ada pengajuan'), findsOneWidget);
    });

    testWidgets('tidak ada footer Lebih Banyak saat tidak ada request', (tester) async {
      final auth = MockFirebaseAuth();
      final user = MockUser();
      when(() => auth.currentUser).thenReturn(user);
      when(() => user.email).thenReturn('klien@example.com');

      final firestore = FakeFirebaseFirestore();
      await _addClient(firestore, email: 'klien@example.com');

      await tester.pumpWidget(
        _wrap(HomeClientPage(auth: auth, firestore: firestore)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Lebih Banyak ...'), findsNothing);
    });
  });

  group('Klien dengan request', () {
    testWidgets('menampilkan nama klien dari request', (tester) async {
      final auth = MockFirebaseAuth();
      final user = MockUser();
      when(() => auth.currentUser).thenReturn(user);
      when(() => user.email).thenReturn('klien@example.com');

      final firestore = FakeFirebaseFirestore();
      final clientId = await _addClient(firestore, email: 'klien@example.com');
      await _addRequest(firestore, clientId: clientId, clientName: 'Toko Makmur');

      await tester.pumpWidget(
        _wrap(HomeClientPage(auth: auth, firestore: firestore)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Toko Makmur'), findsOneWidget);
    });

    testWidgets('menampilkan footer Lebih Banyak saat ada request', (tester) async {
      final auth = MockFirebaseAuth();
      final user = MockUser();
      when(() => auth.currentUser).thenReturn(user);
      when(() => user.email).thenReturn('klien@example.com');

      final firestore = FakeFirebaseFirestore();
      final clientId = await _addClient(firestore, email: 'klien@example.com');
      await _addRequest(firestore, clientId: clientId);

      await tester.pumpWidget(
        _wrap(HomeClientPage(auth: auth, firestore: firestore)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Lebih Banyak ...'), findsOneWidget);
    });

    testWidgets('menampilkan tanggal format dd/mm/yyyy', (tester) async {
      final auth = MockFirebaseAuth();
      final user = MockUser();
      when(() => auth.currentUser).thenReturn(user);
      when(() => user.email).thenReturn('klien@example.com');

      final firestore = FakeFirebaseFirestore();
      final clientId = await _addClient(firestore, email: 'klien@example.com');
      await _addRequest(
        firestore,
        clientId: clientId,
        createdAt: Timestamp.fromDate(DateTime(2024, 6, 1)),
      );

      await tester.pumpWidget(
        _wrap(HomeClientPage(auth: auth, firestore: firestore)),
      );
      await tester.pumpAndSettle();

      expect(find.text('01/06/2024'), findsOneWidget);
    });
  });

  group('Badge status', () {
    Future<void> testStatus(WidgetTester tester, String status, String label) async {
      final auth = MockFirebaseAuth();
      final user = MockUser();
      when(() => auth.currentUser).thenReturn(user);
      when(() => user.email).thenReturn('klien@example.com');

      final firestore = FakeFirebaseFirestore();
      final clientId = await _addClient(firestore, email: 'klien@example.com');
      await _addRequest(firestore, clientId: clientId, status: status);

      await tester.pumpWidget(
        _wrap(HomeClientPage(auth: auth, firestore: firestore)),
      );
      await tester.pumpAndSettle();

      expect(find.text(label), findsOneWidget);
    }

    testWidgets('pending → Menunggu', (t) => testStatus(t, 'pending', 'Menunggu'));
    testWidgets('received → Diterima', (t) => testStatus(t, 'received', 'Diterima'));
    testWidgets('packed → Dikemas', (t) => testStatus(t, 'packed', 'Dikemas'));
    testWidgets('processing → Diproses', (t) => testStatus(t, 'processing', 'Diproses'));
    testWidgets('rejected → Ditolak', (t) => testStatus(t, 'rejected', 'Ditolak'));
  });

  group('Dark mode', () {
    testWidgets('render normal di dark mode', (tester) async {
      final auth = MockFirebaseAuth();
      when(() => auth.currentUser).thenReturn(null);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: HomeClientPage(auth: auth, firestore: FakeFirebaseFirestore()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(HomeClientPage), findsOneWidget);
    });
  });
}