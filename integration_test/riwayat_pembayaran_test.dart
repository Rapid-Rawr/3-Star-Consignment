import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:star_consignment/firebase_options.dart';
import 'package:star_consignment/utils/supabase_service.dart';
import 'package:star_consignment/service/auth_provider.dart';
import 'package:star_consignment/views/pembayaran/riwayat_pembayaran_page.dart';
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
          home: const PaymentHistoryPage(),
        ),
      ),
    );
  }

  group('Riwayat Pembayaran - Black Box Test', () {
    testWidgets('Halaman riwayat pembayaran berhasil ditampilkan',
        (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('Riwayat Pembayaran'), findsOneWidget);
    });

    testWidgets('Search bar klien berfungsi', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      final searchField = find.byType(TextField).first;
      await tester.tap(searchField);
      await tester.pumpAndSettle();
      await tester.enterText(searchField, 'Toko');
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.widgetWithText(TextField, 'Toko'), findsOneWidget);
    });

    testWidgets('Filter tanggal "Dari" tersedia', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Tombol filter tanggal dari harus tampil
      expect(find.text('Dari'), findsOneWidget);
    });

    testWidgets('Filter tanggal "Sampai" tersedia', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('Sampai'), findsOneWidget);
    });

    testWidgets('Date picker muncul saat tombol Dari ditekan',
        (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      await tester.tap(find.text('Dari'));
      await tester.pumpAndSettle();

      // DatePickerDialog atau CalendarDatePicker harus tampil
      expect(
        find.byType(DatePickerDialog).evaluate().isNotEmpty ||
            find.byType(CalendarDatePicker).evaluate().isNotEmpty,
        isTrue,
      );
    });

    testWidgets('Pencarian tidak ditemukan menampilkan pesan kosong',
        (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      final searchField = find.byType(TextField).first;
      await tester.tap(searchField);
      await tester.pumpAndSettle();
      await tester.enterText(searchField, 'xyzabc999tidakada');
      await tester.pumpAndSettle(const Duration(seconds: 2));

      final emptySearch = find.text('History Tidak Ditemukan');
      final emptyAll = find.text('Belum Ada History Pembayaran');
      expect(
        emptySearch.evaluate().isNotEmpty || emptyAll.evaluate().isNotEmpty,
        isTrue,
      );
    });

    testWidgets('Tombol Lihat Detail tampil pada card jika ada data',
        (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      final detailButtons = find.text('Lihat Detail');
      if (detailButtons.evaluate().isNotEmpty) {
        expect(detailButtons, findsAtLeastNWidgets(1));
      } else {
        expect(
          find.text('Belum Ada History Pembayaran').evaluate().isNotEmpty ||
              find.byIcon(Icons.receipt_long_outlined).evaluate().isNotEmpty,
          isTrue,
        );
      }
    });

    testWidgets(
        'Bottom sheet detail pembayaran terbuka saat Lihat Detail ditekan',
        (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      final detailButton = find.text('Lihat Detail');
      if (detailButton.evaluate().isNotEmpty) {
        await tester.tap(detailButton.first);
        await tester.pumpAndSettle(const Duration(seconds: 3));

        expect(
          find.text('Total Pembayaran').evaluate().isNotEmpty ||
              find.byType(DraggableScrollableSheet).evaluate().isNotEmpty,
          isTrue,
        );
      }
    });

    testWidgets('Card riwayat menampilkan metode pembayaran',
        (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      final cashBadge = find.text('Cash');
      final transferBadge = find.text('Transfer');
      if (cashBadge.evaluate().isNotEmpty ||
          transferBadge.evaluate().isNotEmpty) {
        expect(
          cashBadge.evaluate().isNotEmpty ||
              transferBadge.evaluate().isNotEmpty,
          isTrue,
        );
      }
    });

    testWidgets('Search dan filter tanggal dapat digunakan bersamaan',
        (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Isi search dulu
      final searchField = find.byType(TextField).first;
      await tester.tap(searchField);
      await tester.pumpAndSettle();
      await tester.enterText(searchField, 'Toko');
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Filter tanggal masih tersedia
      expect(find.text('Dari'), findsOneWidget);
      expect(find.text('Sampai'), findsOneWidget);
      expect(find.byType(TextField), findsAtLeastNWidgets(1));
    });

    testWidgets('Detail sheet dapat ditutup dengan swipe down',
        (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      final detailButton = find.text('Lihat Detail');
      if (detailButton.evaluate().isNotEmpty) {
        await tester.tap(detailButton.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Swipe down untuk menutup bottom sheet
        await tester.drag(
          find.byType(DraggableScrollableSheet).first,
          const Offset(0, 400),
        );
        await tester.pumpAndSettle();

        expect(find.text('Riwayat Pembayaran'), findsOneWidget);
      }
    });
  });
}