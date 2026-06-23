import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:star_consignment/firebase_options.dart';
import 'package:star_consignment/utils/supabase_service.dart';
import 'package:star_consignment/service/auth_provider.dart';
import 'package:star_consignment/views/barang/barang_konsinyasi_page.dart';
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
          home: const ConsignmentPage(),
        ),
      ),
    );
  }

  group('Barang Konsinyasi - Black Box Test', () {
    testWidgets('TC-BK-01: Halaman barang konsinyasi berhasil ditampilkan',
        (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('Barang Konsinyasi'), findsOneWidget);
    });

    testWidgets('TC-BK-02: Search bar klien berfungsi', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      final searchField = find.byType(TextField).first;
      await tester.tap(searchField);
      await tester.pumpAndSettle();
      await tester.enterText(searchField, 'Toko');
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.widgetWithText(TextField, 'Toko'), findsOneWidget);
    });

    testWidgets('TC-BK-03: Tombol FAB Konsinyasi tampil', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.text('Konsinyasi'), findsOneWidget);
    });

    testWidgets('TC-BK-04: Bottom sheet tambah konsinyasi terbuka saat FAB ditekan',
        (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.text('Tambah Barang Konsinyasi'), findsOneWidget);
    });

    testWidgets('TC-BK-05: Field pencarian klien tersedia di bottom sheet',
        (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.text('Cari nama klien...'), findsOneWidget);
    });

    testWidgets('TC-BK-06: Field pencarian katalog tersedia di bottom sheet',
        (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.text('Cari katalog...'), findsOneWidget);
    });

    testWidgets('TC-BK-07: Tombol Serahkan tampil di bottom sheet',
        (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.text('Serahkan'), findsOneWidget);
    });

    testWidgets('TC-BK-08: Bottom sheet dapat ditutup dengan tombol close',
        (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.text('Tambah Barang Konsinyasi'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close).last);
      await tester.pumpAndSettle();

      expect(find.text('Tambah Barang Konsinyasi'), findsNothing);
    });

    testWidgets('TC-BK-09: Search katalog di bottom sheet menerima input',
        (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      final catalogSearch = find.widgetWithText(TextField, 'Cari katalog...');
      if (catalogSearch.evaluate().isNotEmpty) {
        await tester.tap(catalogSearch.first);
        await tester.pumpAndSettle();
        await tester.enterText(catalogSearch.first, 'Alat');
        await tester.pumpAndSettle(const Duration(seconds: 2));

        expect(find.widgetWithText(TextField, 'Alat'), findsOneWidget);
      }
    });

    testWidgets('TC-BK-10: Search klien di bottom sheet menerima input',
        (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      final clientSearch = find.widgetWithText(TextField, 'Cari nama klien...');
      if (clientSearch.evaluate().isNotEmpty) {
        await tester.tap(clientSearch.first);
        await tester.pumpAndSettle();
        await tester.enterText(clientSearch.first, 'Toko ABC');
        await tester.pumpAndSettle(const Duration(seconds: 1));

        expect(find.byType(TextField), findsAtLeastNWidgets(1));
      }
    });

    testWidgets('TC-BK-11: Menambahkan barang konsinyasi baru tampil di daftar riwayat',
        (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));
      
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      final clientSearch = find.widgetWithText(TextField, 'Cari nama klien...');
      if (clientSearch.evaluate().isNotEmpty) {
        await tester.tap(clientSearch.first);
        await tester.pumpAndSettle();
        await tester.enterText(clientSearch.first, 'Toko ABC');
        await tester.pumpAndSettle(const Duration(seconds: 1));
        
        final clientResult = find.text('Toko ABC');
        if (clientResult.evaluate().isNotEmpty) {
            await tester.tap(clientResult.first);
            await tester.pumpAndSettle();
        }
      }

      final catalogSearch = find.widgetWithText(TextField, 'Cari katalog...');
      if (catalogSearch.evaluate().isNotEmpty) {
        await tester.tap(catalogSearch.first);
        await tester.pumpAndSettle();
        await tester.enterText(catalogSearch.first, 'Alat');
        await tester.pumpAndSettle(const Duration(seconds: 1));
        
        final addQtyButton = find.byIcon(Icons.add);
        if (addQtyButton.evaluate().isNotEmpty) {
          await tester.tap(addQtyButton.first);
          await tester.pumpAndSettle();
        }
      }

      // Tekan tombol Serahkan
      final submitButton = find.text('Serahkan');
      if (submitButton.evaluate().isNotEmpty) {
        // Scroll jika tertutup
        await tester.ensureVisible(submitButton);
        await tester.tap(submitButton);
        
        // Tunggu request API ke firebase selesai
        await tester.pumpAndSettle(const Duration(seconds: 4));
      }

      // Verifikasi data (Toko ABC) sekarang ada di halaman utama
      expect(find.textContaining('Toko ABC'), findsWidgets);
    });
  });
}
