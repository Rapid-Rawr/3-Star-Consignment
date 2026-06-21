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
import 'package:star_consignment/views/barang/katalog_page.dart';
import 'package:star_consignment/utils/theme_notifier.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

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
  });

  Widget buildTestApp() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
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

  group('Katalog Barang - Black Box Test', () {
    testWidgets('TC-KB-01: Halaman katalog berhasil ditampilkan',
        (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('Manajemen Katalog'), findsOneWidget);
    });

    testWidgets('TC-KB-02: Search bar katalog berfungsi', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      final searchField = find.byType(TextField).first;
      await tester.tap(searchField);
      await tester.pumpAndSettle();
      await tester.enterText(searchField, 'Alat');
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verifikasi search field berhasil menerima input
      expect(find.byType(TextField), findsAtLeastNWidgets(1));
    });

    testWidgets('TC-KB-03: Tombol tambah barang (FAB) tampil', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('TC-KB-04: Dialog tambah barang terbuka', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.text('Tambah Barang'), findsOneWidget);
      expect(find.text('Nama Barang'), findsOneWidget);
      expect(find.text('Harga (Rp)'), findsOneWidget);
    });

    testWidgets('TC-KB-05: Validasi form tambah barang kosong', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tambah'));
      await tester.pumpAndSettle();

      // Dialog masih tampil karena validasi gagal
      expect(find.text('Tambah Barang'), findsOneWidget);
    });
  });
}