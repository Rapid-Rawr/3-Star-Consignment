import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:star_consignment/firebase_options.dart';
import 'package:star_consignment/utils/supabase_service.dart';
import 'package:star_consignment/service/auth_provider.dart';
import 'package:star_consignment/service/roles.dart';
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
    final authProvider = AuthProvider();
    authProvider.setRoleForTest(Roles.admin);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
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

  group('Barang Konsinyasi - Admin Test', () {
    testWidgets('TC-BK-01: Halaman barang konsinyasi berhasil ditampilkan',
        (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('Barang Konsinyasi'), findsOneWidget);
    });

    testWidgets('TC-BK-02: Tombol FAB Konsinyasi tampil', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.text('Konsinyasi'), findsOneWidget);
    });

    testWidgets('TC-BK-03: Detail sheet bisa dibuka', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      final lihatSemuaButton = find.widgetWithText(OutlinedButton, 'Lihat Semua');

      if (lihatSemuaButton.evaluate().isNotEmpty) {
        await tester.tap(lihatSemuaButton.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));

        final sheetTitle = find.text('Barang yang Dipinjam');
        expect(sheetTitle, findsOneWidget);
      } else {
        expect(find.text('Belum Ada Klien'), findsOneWidget);
      }
    });

    testWidgets('TC-BK-04: FAB bisa dipencet dan memunculkan bottom sheet',
        (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.text('Tambah Barang Konsinyasi'), findsOneWidget);
      expect(find.text('Cari nama klien...'), findsOneWidget);
    });

    testWidgets('TC-BK-05: Pencarian dengan filter kategori', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      final searchField = find.byType(TextField).first;
      await tester.tap(searchField);
      await tester.pumpAndSettle();
      await tester.enterText(searchField, 'sd');
      await tester.pumpAndSettle(const Duration(seconds: 1));

      final seragamChip = find.widgetWithText(FilterChip, 'Seragam');
      if (seragamChip.evaluate().isNotEmpty) {
        await tester.tap(seragamChip);
        await tester.pumpAndSettle(const Duration(seconds: 1));
      }

      expect(find.byType(TextField), findsWidgets);
    });

    testWidgets('TC-BK-06: Pencarian invalid - data tidak ada', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      final searchField = find.byType(TextField).first;
      await tester.tap(searchField);
      await tester.pumpAndSettle();
      await tester.enterText(searchField, '#####');
      await tester.pumpAndSettle(const Duration(seconds: 1));

      final semuaChip = find.widgetWithText(FilterChip, 'Semua');
      if (semuaChip.evaluate().isNotEmpty) {
        await tester.tap(semuaChip);
        await tester.pumpAndSettle(const Duration(seconds: 1));
      }

      expect(
        find.text('Klien Tidak Ditemukan'),
        findsOneWidget,
      );
    });

    testWidgets('TC-BK-07: Serahkan dengan klien dan barang dipilih', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      final clientSearch = find.widgetWithText(TextField, 'Cari nama klien...');
      await tester.tap(clientSearch);
      await tester.pumpAndSettle();

      await tester.enterText(clientSearch, '');
      await tester.pumpAndSettle(const Duration(seconds: 2));

      final dropdownItems = find.byIcon(Icons.store_outlined);
      if (dropdownItems.evaluate().isNotEmpty) {
        await tester.tapAt(tester.getCenter(dropdownItems.first) + const Offset(50, 0));
        await tester.pumpAndSettle();
      }

      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      
      final checkboxes = find.byWidgetPredicate((widget) =>
          widget is GestureDetector && 
          widget.child is AnimatedContainer);
      
      if (checkboxes.evaluate().isNotEmpty) {
        await tester.tap(checkboxes.first, warnIfMissed: false);
        await tester.pumpAndSettle();
      }

      final serahkanButton = find.text('Serahkan');
      await tester.tap(serahkanButton);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      expect(
        find.textContaining('berhasil'),
        findsWidgets,
      );
    });

    testWidgets('TC-BK-08: Serahkan dengan klien dipilih, barang tidak dipilih',
        (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      final clientSearch = find.widgetWithText(TextField, 'Cari nama klien...');
      await tester.tap(clientSearch);
      await tester.pumpAndSettle();

      await tester.enterText(clientSearch, '');
      await tester.pumpAndSettle(const Duration(seconds: 2));

      final dropdownItems = find.byIcon(Icons.store_outlined);
      if (dropdownItems.evaluate().isNotEmpty) {
        await tester.tapAt(tester.getCenter(dropdownItems.first) + const Offset(50, 0));
        await tester.pumpAndSettle();
      }

      final serahkanButton = find.text('Serahkan');
      await tester.tap(serahkanButton);
      await tester.pumpAndSettle();

      expect(find.text('Peringatan'), findsOneWidget);
      expect(find.text('Silakan pilih minimal satu barang.'), findsOneWidget);
    });

    testWidgets('TC-BK-09: Serahkan dengan klien tidak dipilih, barang dipilih',
        (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await tester.pump(const Duration(seconds: 1));
      final checkboxes = find.byIcon(Icons.check_box_outline_blank);
      if (checkboxes.evaluate().isNotEmpty) {
        await tester.tap(checkboxes.first);
        await tester.pumpAndSettle();
      }

      final serahkanButton = find.text('Serahkan');
      await tester.tap(serahkanButton);
      await tester.pumpAndSettle();

      expect(find.text('Peringatan'), findsOneWidget);
      expect(
          find.text('Silakan pilih klien terlebih dahulu.'), findsOneWidget);
    });

    testWidgets('TC-BK-10: Serahkan tanpa memilih semua', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      final serahkanButton = find.text('Serahkan');
      await tester.tap(serahkanButton);
      await tester.pumpAndSettle();

      expect(find.text('Peringatan'), findsOneWidget);
      expect(
          find.text('Silakan pilih klien terlebih dahulu.'), findsOneWidget);
    });
  });
}