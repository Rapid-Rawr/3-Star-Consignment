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
import 'package:star_consignment/views/tabbar/beranda_page.dart';
import 'package:star_consignment/utils/theme_notifier.dart';
import 'package:star_consignment/views/tabbar/beranda_page.dart';


void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  late AuthProvider authProvider;

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

    authProvider = AuthProvider();
    await authProvider.setRole(Roles.admin);
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
          home: const HomeAdminPage(),
        ),
      ),
    );
  }

  group('Beranda Admin - Black Box Test', () {
    testWidgets(
        'Tombol approve (✓) tampil pada card pengajuan',
        (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 8));

      final approveButtons = find.byIcon(Icons.check_rounded);
      if (approveButtons.evaluate().isNotEmpty) {
        expect(approveButtons, findsAtLeastNWidgets(1));
      } else {
        // Tidak ada data pengajuan aktif
        expect(find.text('Belum ada data'), findsOneWidget);
      }
    });

    testWidgets(
        'Tombol reject (✗) tampil pada card pengajuan',
        (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 8));

      final rejectButtons = find.byIcon(Icons.cancel_outlined);
      if (rejectButtons.evaluate().isNotEmpty) {
        expect(rejectButtons, findsAtLeastNWidgets(1));
      } else {
        expect(find.text('Belum ada data'), findsOneWidget);
      }
    });

    testWidgets(
        'Approve request - tap tombol approve dan snackbar sukses muncul',
        (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 8));

      final approveButton = find.byIcon(Icons.check_rounded);
      if (approveButton.evaluate().isEmpty) {
        // Skip jika tidak ada data pengajuan aktif
        return;
      }

      // Tap tombol approve pada card pertama
      await tester.tap(approveButton.first);

      // Tunggu proses Firestore selesai (call real network)
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Snackbar sukses harus muncul
      expect(find.text('Request berhasil disetujui'), findsOneWidget);
    });

    testWidgets(
        'Reject request - tap tombol reject dan snackbar muncul',
        (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 8));

      final rejectButton = find.byIcon(Icons.cancel_outlined);
      if (rejectButton.evaluate().isEmpty) {
        // Skip jika tidak ada data pengajuan aktif
        return;
      }

      // Tap tombol reject pada card pertama
      await tester.tap(rejectButton.first);

      // Tunggu proses Firestore selesai
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Snackbar harus muncul
      expect(find.text('Request ditolak'), findsOneWidget);
    });
  });
}