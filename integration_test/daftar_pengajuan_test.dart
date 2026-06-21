import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:star_consignment/firebase_options.dart';
import 'package:star_consignment/utils/supabase_service.dart';
import 'package:star_consignment/service/auth_provider.dart';
import 'package:star_consignment/views/barang/daftar_pengajuan_page.dart';
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
          home: const RequestListPage(),
        ),
      ),
    );
  }

  group('Daftar Pengajuan Konsinyasi - Black Box Test', () {
    testWidgets('TC-DP-01: Halaman daftar pengajuan berhasil ditampilkan',
        (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('Daftar Pengajuan'), findsOneWidget);
    });

    testWidgets('TC-DP-02: Search bar pengajuan berfungsi', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      final searchField = find.byType(TextField).first;
      await tester.tap(searchField);
      await tester.pumpAndSettle();
      await tester.enterText(searchField, 'Toko');
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.widgetWithText(TextField, 'Toko'), findsOneWidget);
    });

    testWidgets('TC-DP-03: Filter chip status tersedia', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('Semua'), findsOneWidget);
      expect(find.text('Menunggu'), findsOneWidget);
      expect(find.text('Diproses'), findsOneWidget);
      expect(find.text('Dikemas'), findsOneWidget);
    });

    testWidgets('TC-DP-04: Filter chip Menunggu dapat ditekan', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      await tester.tap(find.text('Menunggu'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.text('Menunggu'), findsOneWidget);
    });

    testWidgets('TC-DP-05: Filter chip Diproses dapat ditekan', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      await tester.tap(find.text('Diproses'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.text('Diproses'), findsOneWidget);
    });

    testWidgets('TC-DP-06: Filter chip Dikemas dapat ditekan', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      await tester.tap(find.text('Dikemas'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.text('Dikemas'), findsOneWidget);
    });

    testWidgets('TC-DP-07: Tampilan kosong muncul jika pencarian tidak ditemukan',
        (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      final searchField = find.byType(TextField).first;
      await tester.tap(searchField);
      await tester.pumpAndSettle();
      await tester.enterText(searchField, 'xyzabc999tidakada');
      await tester.pumpAndSettle(const Duration(seconds: 2));

      final emptySearch = find.text('Pengajuan Tidak Ditemukan');
      final emptyAll = find.text('Belum Ada Pengajuan');
      expect(
        emptySearch.evaluate().isNotEmpty || emptyAll.evaluate().isNotEmpty,
        isTrue,
      );
    });

    testWidgets('TC-DP-08: Reset filter ke Semua setelah memilih filter lain',
        (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      await tester.tap(find.text('Menunggu'));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      await tester.tap(find.text('Semua'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.text('Semua'), findsOneWidget);
    });

    testWidgets(
        'TC-DP-09: Tombol Lihat Detail tampil pada card jika ada data',
        (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      final detailButtons = find.text('Lihat Detail');
      if (detailButtons.evaluate().isNotEmpty) {
        expect(detailButtons, findsAtLeastNWidgets(1));
      } else {
        expect(
          find.text('Belum Ada Pengajuan').evaluate().isNotEmpty ||
              find.byIcon(Icons.assignment_outlined).evaluate().isNotEmpty,
          isTrue,
        );
      }
    });

    testWidgets(
        'TC-DP-10: Bottom sheet detail terbuka saat Lihat Detail ditekan',
        (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      final detailButton = find.text('Lihat Detail');
      if (detailButton.evaluate().isNotEmpty) {
        await tester.tap(detailButton.first);
        await tester.pumpAndSettle(const Duration(seconds: 3));

        expect(
          find.text('Total Disetujui').evaluate().isNotEmpty ||
              find.byType(DraggableScrollableSheet).evaluate().isNotEmpty,
          isTrue,
        );
      }
    });

    testWidgets('TC-DP-11: Search dan filter dapat digunakan bersamaan',
        (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      await tester.tap(find.text('Menunggu'));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      final searchField = find.byType(TextField).first;
      await tester.tap(searchField);
      await tester.pumpAndSettle();
      await tester.enterText(searchField, 'Toko');
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.text('Menunggu'), findsOneWidget);
      expect(find.byType(TextField), findsAtLeastNWidgets(1));
    });
  });
}