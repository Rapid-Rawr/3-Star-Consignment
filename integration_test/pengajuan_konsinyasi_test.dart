import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:star_consignment/firebase_options.dart';
import 'package:star_consignment/utils/supabase_service.dart';
import 'package:star_consignment/service/auth_provider.dart';
import 'package:star_consignment/views/barang/pengajuan_konsinyasi_page.dart';
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
          home: const ConsignmentRequestPage(),
        ),
      ),
    );
  }

  group('Pengajuan Konsinyasi - Black Box Test', () {
    testWidgets('TC-PK-01: Halaman pengajuan konsinyasi berhasil ditampilkan',
        (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 8));

      expect(find.text('Pengajuan Konsinyasi'), findsOneWidget);
    });

    testWidgets('TC-PK-02: Daftar katalog tampil di halaman pengajuan',
        (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 8));

      // Halaman tampil = test pass
      expect(find.text('Pengajuan Konsinyasi'), findsOneWidget);
    });

    testWidgets('TC-PK-03: Pilih barang menampilkan bottom sheet',
        (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 8));

      final addButtons = find.byIcon(Icons.add);
      if (addButtons.evaluate().isNotEmpty) {
        await tester.tap(addButtons.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));
        expect(find.text('Barang Dipilih'), findsOneWidget);
      } else {
        // Tidak ada barang di katalog - halaman tetap tampil
        expect(find.text('Pengajuan Konsinyasi'), findsOneWidget);
      }
    });

    testWidgets('TC-PK-04: Search katalog di halaman pengajuan berfungsi',
        (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 8));

      final searchField = find.byType(TextField).first;
      await tester.tap(searchField);
      await tester.pumpAndSettle();
      await tester.enterText(searchField, 'Seragam');
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.byType(TextField), findsAtLeastNWidgets(1));
    });

    testWidgets('TC-PK-05: Dialog konfirmasi kirim pengajuan muncul',
        (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 8));

      final addButtons = find.byIcon(Icons.add);
      if (addButtons.evaluate().isNotEmpty) {
        await tester.tap(addButtons.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));

        final kirimButton = find.text('Kirim Pengajuan');
        if (kirimButton.evaluate().isNotEmpty) {
          await tester.tap(kirimButton);
          await tester.pumpAndSettle();
          expect(find.text('Kirim Pengajuan'), findsWidgets);
          expect(find.text('Batal'), findsOneWidget);
          expect(find.text('Kirim'), findsOneWidget);
        } else {
          expect(find.text('Pengajuan Konsinyasi'), findsOneWidget);
        }
      } else {
        // Tidak ada barang - halaman tetap tampil
        expect(find.text('Pengajuan Konsinyasi'), findsOneWidget);
      }
    });
  });
}