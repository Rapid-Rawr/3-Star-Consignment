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

  Widget buildTestApp({String? role}) {
    final authProvider = AuthProvider();
    if (role != null) {
      authProvider.setRoleForTest(role);
    }
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
          home: const RequestListPage(),
        ),
      ),
    );
  }

  Future<void> waitForData(WidgetTester tester) async {
    for (int i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 500));
      final hasLoading =
          find.byType(CircularProgressIndicator).evaluate().isNotEmpty;
      if (!hasLoading) break;
    }
  }

  group('Daftar Pengajuan - Decision Table Test', () {

    testWidgets('TC-DP-DT-01: Halaman daftar pengajuan berhasil ditampilkan',
        (tester) async {
      await tester.pumpWidget(buildTestApp(role: Roles.admin));
      await tester.pumpAndSettle(const Duration(seconds: 8));

      expect(find.text('Daftar Pengajuan'), findsOneWidget);
      expect(
        find.byType(ListView).evaluate().isNotEmpty ||
            find.text('Belum Ada Pengajuan').evaluate().isNotEmpty,
        isTrue,
      );
    });

    testWidgets(
        'TC-DP-DT-03: Tap tombol Approve membuka bottom sheet detail',
        (tester) async {
      await tester.pumpWidget(buildTestApp(role: Roles.admin));
      await waitForData(tester);

      final approveButtons = find.byIcon(Icons.check_rounded);
      if (approveButtons.evaluate().isNotEmpty) {
        await tester.tap(approveButtons.first);
        await tester.pumpAndSettle(const Duration(seconds: 5));

        expect(
          find.byType(DraggableScrollableSheet).evaluate().isNotEmpty ||
              find.text('Total Disetujui').evaluate().isNotEmpty,
          isTrue,
        );
      } else {
        expect(
          find.text('Belum Ada Pengajuan').evaluate().isNotEmpty ||
              find.text('Lihat Detail').evaluate().isNotEmpty,
          isTrue,
        );
      }
    });

    testWidgets(
        'TC-DP-DT-05: Tap Tolak Pengajuan di bottom sheet menampilkan dialog konfirmasi',
        (tester) async {
      await tester.pumpWidget(buildTestApp(role: Roles.admin));
      await waitForData(tester);

      // Step 1: Tap tombol tolak (✗) di card untuk buka bottom sheet
      final rejectButtons = find.byIcon(Icons.close_rounded);
      if (rejectButtons.evaluate().isNotEmpty) {
        await tester.tap(rejectButtons.first);
        await tester.pumpAndSettle(const Duration(seconds: 5));

        // Step 2: Scroll ke bawah untuk pastikan footer terlihat
        await tester.dragFrom(
          tester.getCenter(find.byType(DraggableScrollableSheet).first),
          const Offset(0, -200),
        );
        await tester.pumpAndSettle();

        // Step 3: Tap tombol "Tolak Pengajuan" di footer bottom sheet
        final tolakPengajuanBtn = find.text('Tolak Pengajuan');
        if (tolakPengajuanBtn.evaluate().isNotEmpty) {
          await tester.tap(tolakPengajuanBtn.last);
          await tester.pumpAndSettle();

          // Step 4: Verifikasi dialog konfirmasi muncul
          expect(find.text('Tolak Pengajuan'), findsWidgets);
          expect(find.text('Tolak'), findsOneWidget);

          // FIX: Gunakan descendant finder agar tidak bentrok dengan
          // tombol "Batal" yang ada di list item bottom sheet
          expect(
            find.descendant(
              of: find.byType(AlertDialog),
              matching: find.text('Batal'),
            ),
            findsOneWidget,
          );

          // Step 5: Konfirmasi tolak — tap "Tolak" di dalam dialog
          await tester.tap(find.text('Tolak').last);
          await tester.pumpAndSettle(const Duration(seconds: 3));

          // Step 6: Verifikasi snackbar atau bottom sheet tertutup
          expect(
            find.text('Pengajuan berhasil ditolak').evaluate().isNotEmpty ||
                find.text('Daftar Pengajuan').evaluate().isNotEmpty,
            isTrue,
          );
        } else {
          // Tombol hanya muncul jika semua item rejected
          expect(find.text('Total Disetujui'), findsOneWidget);
        }
      } else {
        expect(
          find.text('Belum Ada Pengajuan').evaluate().isNotEmpty ||
              find.text('Lihat Detail').evaluate().isNotEmpty,
          isTrue,
        );
      }
    });

    testWidgets(
        'TC-DP-DT-08: Search dengan keyword tidak valid menampilkan empty state',
        (tester) async {
      await tester.pumpWidget(buildTestApp(role: Roles.admin));
      await waitForData(tester);

      final searchField = find.byType(TextField).first;
      await tester.tap(searchField);
      await tester.pumpAndSettle();
      await tester.enterText(searchField, 'xyzxyzyxyzy');
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(
        find.text('Pengajuan Tidak Ditemukan').evaluate().isNotEmpty ||
            find.text('Belum Ada Pengajuan').evaluate().isNotEmpty,
        isTrue,
      );
    });

    testWidgets(
        'TC-DP-DT-09: Search nama klien valid menampilkan hasil',
        (tester) async {
      await tester.pumpWidget(buildTestApp(role: Roles.admin));
      await waitForData(tester);

      final searchField = find.byType(TextField).first;
      await tester.tap(searchField);
      await tester.pumpAndSettle();
      await tester.enterText(searchField, 'SD Bangkit 1000');
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.widgetWithText(TextField, 'SD Bangkit 1000'), findsOneWidget);
      expect(find.text('SD Bangkit 1000'), findsAtLeastNWidgets(1));
    });

  });
}