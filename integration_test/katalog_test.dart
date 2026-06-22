import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:star_consignment/firebase_options.dart';
import 'package:star_consignment/utils/supabase_service.dart';
import 'package:star_consignment/service/auth_provider.dart';
import 'package:star_consignment/service/roles.dart';
import 'package:star_consignment/views/barang/katalog_page.dart';
import 'package:star_consignment/utils/theme_notifier.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late AuthProvider authProvider;
  late FirebaseFirestore firestore;

  // Nama barang khusus untuk test — mudah diidentifikasi dan dihapus
  const String testItemName = 'Barang Test Integrasi';
  const String testItemPrice = '15000';
  const String testItemCategory = 'Alat';

  setUpAll(() async {
    await dotenv.load(fileName: '.env');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    final supabaseUrl = dotenv.env['PROJECT_URL'];
    final supabaseAnonKey = dotenv.env['ANON_KEY'];
    if (supabaseUrl != null && supabaseAnonKey != null) {
      await SupabaseService.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
      );
    }

    firestore = FirebaseFirestore.instance;
    authProvider = AuthProvider();
    await authProvider.setRole(Roles.admin);
  });

  /// Hapus data test dari Firestore setelah selesai
  tearDownAll(() async {
    final snapshot = await firestore
        .collection('catalog')
        .where('name', isEqualTo: testItemName)
        .get();
    for (final doc in snapshot.docs) {
      await doc.reference.delete();
    }
  });

  Widget buildTestApp() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
      ],
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: themeNotifier,
        builder: (_, mode, __) => MaterialApp(
          debugShowCheckedModeBanner: false,
          themeMode: mode,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF1D1B20),
            ),
            useMaterial3: true,
            fontFamily: 'Poppins',
          ),
          home: const CatalogPage(),
        ),
      ),
    );
  }

  Future<void> waitForCatalog(WidgetTester tester) async {
    for (int i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 500));
      final hasLoading =
          find.byType(CircularProgressIndicator).evaluate().isNotEmpty;
      if (!hasLoading) break;
    }
  }

  Finder findFormFieldAt(int index) {
    return find.byType(TextFormField).at(index);
  }

  group('Katalog Barang - Black Box Integration Test', () {
    testWidgets('Halaman katalog berhasil ditampilkan', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('Manajemen Katalog'), findsOneWidget);
    });


    testWidgets('Search bar katalog berfungsi menerima input',
        (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      final searchField = find.byType(TextField).first;
      await tester.tap(searchField);
      await tester.pumpAndSettle();
      await tester.enterText(searchField, 'Seragam');
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.widgetWithText(TextField, 'Seragam'), findsOneWidget);
    });

    testWidgets('Search tidak ditemukan menampilkan pesan kosong',
        (tester) async {
      await tester.pumpWidget(buildTestApp());
      await waitForCatalog(tester);

      final searchField = find.byType(TextField).first;
      await tester.tap(searchField);
      await tester.pumpAndSettle();
      await tester.enterText(searchField, 'zzzznotfound999');
      await tester.pumpAndSettle(const Duration(seconds: 2));

      final hasEmptyText = find.textContaining('Tidak').evaluate().isNotEmpty ||
          find.textContaining('Belum').evaluate().isNotEmpty ||
          find.textContaining('ditemukan').evaluate().isNotEmpty;
      final hasNoCard = find.byType(Card).evaluate().isEmpty;

      expect(hasEmptyText || hasNoCard, isTrue);
    });

    testWidgets('Validasi form kosong — submit ditolak', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tambah'));
      await tester.pumpAndSettle();

      // Dialog masih tampil karena validasi gagal
      expect(find.text('Tambah Barang'), findsOneWidget);
    });

    testWidgets('Harga negatif menampilkan pesan error', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await tester.enterText(findFormFieldAt(0), 'Nama Valid');
      await tester.pump();
      await tester.enterText(findFormFieldAt(1), '-1');
      await tester.pump();

      await tester.tap(find.text('Tambah'));
      await tester.pumpAndSettle();

      expect(find.textContaining('tidak boleh negatif'), findsOneWidget);
    });

  });
}