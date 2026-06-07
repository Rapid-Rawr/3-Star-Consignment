import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:star_consignment/views/beranda/beranda_client.dart';

// ─── Mock ────────────────────────────────────────────────────────────────────
class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUser extends Mock implements User {}

// ─── Helper ──────────────────────────────────────────────────────────────────
Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

/// Tambahkan dokumen ke koleksi clients
Future<String> _addClient(
  FakeFirebaseFirestore firestore, {
  required String email,
}) async {
  final ref = await firestore.collection('clients').add({'email': email});
  return ref.id;
}

/// Tambahkan dokumen ke koleksi consignment_requests
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
    'items':
        items ??
        [
          {'quantity': 3, 'catalogPrice': 15000},
          {'quantity': 2, 'catalogPrice': 25000},
        ],
  });
}

// ═════════════════════════════════════════════════════════════════════════════
void main() {
  // ── 1. Render dasar ────────────────────────────────────────────────────────
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

    testWidgets(
      'tidak ada Scaffold ganda (widget tidak punya AppBar sendiri)',
      (tester) async {
        final auth = MockFirebaseAuth();
        when(() => auth.currentUser).thenReturn(null);

        await tester.pumpWidget(
          _wrap(HomeClientPage(auth: auth, firestore: FakeFirebaseFirestore())),
        );
        await tester.pumpAndSettle();

        // Hanya 1 Scaffold dari wrapper
        expect(find.byType(Scaffold), findsOneWidget);
      },
    );
  });

  // ── 2. User null (belum login) ─────────────────────────────────────────────
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

    testWidgets('tidak ada footer "Lebih Banyak" saat user null', (
      tester,
    ) async {
      final auth = MockFirebaseAuth();
      when(() => auth.currentUser).thenReturn(null);

      await tester.pumpWidget(
        _wrap(HomeClientPage(auth: auth, firestore: FakeFirebaseFirestore())),
      );
      await tester.pumpAndSettle();

      expect(find.text('Lebih Banyak ...'), findsNothing);
    });
  });

  // ── 3. User login tapi email tidak ada di clients ──────────────────────────
  group('User login tapi tidak terdaftar sebagai klien', () {
    testWidgets('menampilkan pesan belum terdaftar sebagai klien', (
      tester,
    ) async {
      final auth = MockFirebaseAuth();
      final user = MockUser();
      when(() => auth.currentUser).thenReturn(user);
      when(() => user.email).thenReturn('bukan@klien.com');

      final firestore = FakeFirebaseFirestore();

      await tester.pumpWidget(
        _wrap(HomeClientPage(auth: auth, firestore: firestore)),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('belum terdaftar'), findsOneWidget);
    });

    testWidgets('menampilkan header Request List walau tidak ada data', (
      tester,
    ) async {
      final auth = MockFirebaseAuth();
      final user = MockUser();
      when(() => auth.currentUser).thenReturn(user);
      when(() => user.email).thenReturn('bukan@klien.com');

      await tester.pumpWidget(
        _wrap(HomeClientPage(auth: auth, firestore: FakeFirebaseFirestore())),
      );
      await tester.pumpAndSettle();

      // Header "Request List" tetap muncul
      expect(find.text('Request List'), findsOneWidget);
    });
  });

  // ── 4. User terdaftar sebagai klien, tanpa request ─────────────────────────
  group('Klien terdaftar tapi belum ada pengajuan', () {
    testWidgets('menampilkan pesan belum ada pengajuan konsinyasi', (
      tester,
    ) async {
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

    testWidgets('menampilkan ikon inventory saat belum ada request', (
      tester,
    ) async {
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

      expect(find.byIcon(Icons.inventory_2_outlined), findsOneWidget);
    });

    testWidgets('tidak ada footer "Lebih Banyak" saat tidak ada request', (
      tester,
    ) async {
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

  // ── 5. Klien dengan request ────────────────────────────────────────────────
  group('Klien dengan request', () {
    testWidgets('menampilkan nama klien dari request', (tester) async {
      final auth = MockFirebaseAuth();
      final user = MockUser();
      when(() => auth.currentUser).thenReturn(user);
      when(() => user.email).thenReturn('klien@example.com');

      final firestore = FakeFirebaseFirestore();
      final clientId = await _addClient(firestore, email: 'klien@example.com');
      await _addRequest(
        firestore,
        clientId: clientId,
        clientName: 'Toko Makmur',
      );

      await tester.pumpWidget(
        _wrap(HomeClientPage(auth: auth, firestore: firestore)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Toko Makmur'), findsOneWidget);
    });

    testWidgets('menampilkan header Request List', (tester) async {
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

      expect(find.text('Request List'), findsOneWidget);
    });

    testWidgets('menampilkan footer "Lebih Banyak" saat ada request', (
      tester,
    ) async {
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

    testWidgets('menampilkan tanggal request dengan format dd/mm/yyyy', (
      tester,
    ) async {
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

    testWidgets('menampilkan total qty dan harga dari items', (tester) async {
      final auth = MockFirebaseAuth();
      final user = MockUser();
      when(() => auth.currentUser).thenReturn(user);
      when(() => user.email).thenReturn('klien@example.com');

      final firestore = FakeFirebaseFirestore();
      final clientId = await _addClient(firestore, email: 'klien@example.com');
      await _addRequest(
        firestore,
        clientId: clientId,
        items: [
          {'quantity': 2, 'catalogPrice': 50000}, // 100.000
          {'quantity': 1, 'catalogPrice': 30000}, // 30.000 → total 130.000
        ],
      );

      await tester.pumpWidget(
        _wrap(HomeClientPage(auth: auth, firestore: firestore)),
      );
      await tester.pumpAndSettle();

      // total qty = 3
      expect(find.textContaining('3 item'), findsOneWidget);
    });

    testWidgets('menampilkan ikon assignment di setiap request item', (
      tester,
    ) async {
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

      expect(find.byIcon(Icons.assignment_outlined), findsWidgets);
    });
  });

  // ── 6. Badge status ────────────────────────────────────────────────────────
  group('Badge status', () {
    Future<void> _testStatus(
      WidgetTester tester,
      String status,
      String expectedLabel,
    ) async {
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

      expect(find.text(expectedLabel), findsOneWidget);
    }

    testWidgets('status pending → label Menunggu', (tester) async {
      await _testStatus(tester, 'pending', 'Menunggu');
    });

    testWidgets('status received → label Diterima', (tester) async {
      await _testStatus(tester, 'received', 'Diterima');
    });

    testWidgets('status packed → label Dikemas', (tester) async {
      await _testStatus(tester, 'packed', 'Dikemas');
    });

    testWidgets('status processing → label Diproses', (tester) async {
      await _testStatus(tester, 'processing', 'Diproses');
    });

    testWidgets('status rejected → label Ditolak', (tester) async {
      await _testStatus(tester, 'rejected', 'Ditolak');
    });

    testWidgets('status tidak dikenal → default label Menunggu', (
      tester,
    ) async {
      await _testStatus(tester, 'unknown_status', 'Menunggu');
    });
  });

  // ── 7. Multiple request ────────────────────────────────────────────────────
  group('Multiple request', () {
    testWidgets('menampilkan semua request hingga batas previewLimit', (
      tester,
    ) async {
      final auth = MockFirebaseAuth();
      final user = MockUser();
      when(() => auth.currentUser).thenReturn(user);
      when(() => user.email).thenReturn('klien@example.com');

      final firestore = FakeFirebaseFirestore();
      final clientId = await _addClient(firestore, email: 'klien@example.com');

      // Tambah 3 request dengan nama berbeda
      for (int i = 1; i <= 3; i++) {
        await _addRequest(firestore, clientId: clientId, clientName: 'Toko $i');
      }

      await tester.pumpWidget(
        _wrap(HomeClientPage(auth: auth, firestore: firestore)),
      );
      await tester.pumpAndSettle();

      // Semua 3 nama muncul
      expect(find.text('Toko 1'), findsOneWidget);
      expect(find.text('Toko 2'), findsOneWidget);
      expect(find.text('Toko 3'), findsOneWidget);
    });

    testWidgets('request dari klien lain tidak ditampilkan', (tester) async {
      final auth = MockFirebaseAuth();
      final user = MockUser();
      when(() => auth.currentUser).thenReturn(user);
      when(() => user.email).thenReturn('klien@example.com');

      final firestore = FakeFirebaseFirestore();
      final clientId = await _addClient(firestore, email: 'klien@example.com');

      // Request milik klien ini
      await _addRequest(firestore, clientId: clientId, clientName: 'Toko Saya');

      // Request milik klien lain
      await _addRequest(
        firestore,
        clientId: 'other-client-id',
        clientName: 'Toko Orang Lain',
      );

      await tester.pumpWidget(
        _wrap(HomeClientPage(auth: auth, firestore: firestore)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Toko Saya'), findsOneWidget);
      expect(find.text('Toko Orang Lain'), findsNothing);
    });
  });

  // ── 8. Items tanpa data / edge case ───────────────────────────────────────
  group('Edge case items', () {
    testWidgets('items kosong tidak menyebabkan crash', (tester) async {
      final auth = MockFirebaseAuth();
      final user = MockUser();
      when(() => auth.currentUser).thenReturn(user);
      when(() => user.email).thenReturn('klien@example.com');

      final firestore = FakeFirebaseFirestore();
      final clientId = await _addClient(firestore, email: 'klien@example.com');
      await _addRequest(firestore, clientId: clientId, items: []);

      await tester.pumpWidget(
        _wrap(HomeClientPage(auth: auth, firestore: firestore)),
      );
      await tester.pumpAndSettle();

      // 0 item tampil
      expect(find.textContaining('0 item'), findsOneWidget);
    });

    testWidgets('items null tidak menyebabkan crash', (tester) async {
      final auth = MockFirebaseAuth();
      final user = MockUser();
      when(() => auth.currentUser).thenReturn(user);
      when(() => user.email).thenReturn('klien@example.com');

      final firestore = FakeFirebaseFirestore();
      final clientId = await _addClient(firestore, email: 'klien@example.com');

      // Tambah request tanpa field items
      await firestore.collection('consignment_requests').add({
        'clientId': clientId,
        'clientName': 'Test',
        'status': 'pending',
        'createdAt': Timestamp.now(),
      });

      await tester.pumpWidget(
        _wrap(HomeClientPage(auth: auth, firestore: firestore)),
      );
      await tester.pumpAndSettle();

      expect(find.byType(HomeClientPage), findsOneWidget);
    });

    testWidgets('createdAt null tidak menampilkan tanggal', (tester) async {
      final auth = MockFirebaseAuth();
      final user = MockUser();
      when(() => auth.currentUser).thenReturn(user);
      when(() => user.email).thenReturn('klien@example.com');

      final firestore = FakeFirebaseFirestore();
      final clientId = await _addClient(firestore, email: 'klien@example.com');

      await firestore.collection('consignment_requests').add({
        'clientId': clientId,
        'clientName': 'Test Tanpa Tanggal',
        'status': 'pending',
        'items': [],
      });

      await tester.pumpWidget(
        _wrap(HomeClientPage(auth: auth, firestore: firestore)),
      );
      await tester.pumpAndSettle();

      // Tidak ada format tanggal xx/xx/xxxx
      expect(find.textContaining('/202'), findsNothing);
    });

    testWidgets('clientName null menampilkan -', (tester) async {
      final auth = MockFirebaseAuth();
      final user = MockUser();
      when(() => auth.currentUser).thenReturn(user);
      when(() => user.email).thenReturn('klien@example.com');

      final firestore = FakeFirebaseFirestore();
      final clientId = await _addClient(firestore, email: 'klien@example.com');

      await firestore.collection('consignment_requests').add({
        'clientId': clientId,
        'status': 'pending',
        'createdAt': Timestamp.now(),
        'items': [],
      });

      await tester.pumpWidget(
        _wrap(HomeClientPage(auth: auth, firestore: firestore)),
      );
      await tester.pumpAndSettle();

      expect(find.text('-'), findsOneWidget);
    });
  });

  // ── 9. Dark mode ──────────────────────────────────────────────────────────
  group('Dark mode', () {
    testWidgets('render normal di dark mode', (tester) async {
      final auth = MockFirebaseAuth();
      when(() => auth.currentUser).thenReturn(null);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: HomeClientPage(
              auth: auth,
              firestore: FakeFirebaseFirestore(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(HomeClientPage), findsOneWidget);
    });

    testWidgets('menampilkan pesan belum terdaftar di dark mode', (
      tester,
    ) async {
      final auth = MockFirebaseAuth();
      when(() => auth.currentUser).thenReturn(null);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: HomeClientPage(
              auth: auth,
              firestore: FakeFirebaseFirestore(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('belum terdaftar'), findsOneWidget);
    });
  });
}
