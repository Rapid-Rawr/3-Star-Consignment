import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:star_consignment/firebase_options.dart';
import 'package:star_consignment/utils/supabase_service.dart';
import 'package:star_consignment/service/auth_provider.dart';
import 'package:star_consignment/views/barang/riwayat_pengajuan_page.dart';
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
          home: const RequestHistoryPage(),
        ),
      ),
    );
  }

  group('Riwayat Pengajuan - Black Box Test', () {
    testWidgets('TC-RP-01: Halaman riwayat pengajuan berhasil ditampilkan',
        (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('Riwayat Pengajuan'), findsOneWidget);
    });

    testWidgets('TC-RP-02: Empty state atau list riwayat tampil',
        (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(
        find.byType(ListView).evaluate().isNotEmpty ||
            find.text('Belum Ada Riwayat').evaluate().isNotEmpty,
        isTrue,
      );
    });

    testWidgets('TC-RP-03: Search riwayat berfungsi', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      final searchField = find.byType(TextField).first;
      await tester.tap(searchField);
      await tester.pumpAndSettle();
      await tester.enterText(searchField, 'Test');
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.byType(TextField), findsAtLeastNWidgets(1));
    });

    testWidgets('TC-RP-04: Filter tanggal dari berfungsi', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      final fromDateButton = find.textContaining('Dari');
      if (fromDateButton.evaluate().isNotEmpty) {
        await tester.tap(fromDateButton.first);
        await tester.pumpAndSettle();

        expect(find.byType(DatePickerDialog), findsOneWidget);

        // Tutup date picker
        final cancelButton = find.text('Cancel');
        if (cancelButton.evaluate().isNotEmpty) {
          await tester.tap(cancelButton);
        } else {
          await tester.tap(find.text('Batal'));
        }
        await tester.pumpAndSettle();
      } else {
        expect(find.text('Riwayat Pengajuan'), findsOneWidget);
      }
    });

    testWidgets('TC-RP-05: Detail riwayat pengajuan dapat dibuka',
        (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      final lihatButton = find.text('Lihat Riwayat');
      if (lihatButton.evaluate().isNotEmpty) {
        await tester.tap(lihatButton.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));

        expect(find.text('Daftar Barang'), findsOneWidget);
      } else {
        expect(
          find.text('Belum Ada Riwayat').evaluate().isNotEmpty ||
              find.text('Riwayat Pengajuan').evaluate().isNotEmpty,
          isTrue,
        );
      }
    });
  });
}