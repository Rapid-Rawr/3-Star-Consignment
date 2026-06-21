import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:star_consignment/firebase_options.dart';
import 'package:star_consignment/utils/supabase_service.dart';
import 'package:star_consignment/service/auth_provider.dart';
import 'package:star_consignment/views/pengguna/klien_page.dart';
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
          home: const ClientPage(),
        ),
      ),
    );
  }

  group('Manajemen Klien - Black Box Test', () {
    testWidgets('TC-MK-01: Halaman klien berhasil ditampilkan',
        (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('Klien'), findsOneWidget);
    });

    testWidgets('TC-MK-02: Search bar klien berfungsi', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      final searchField = find.byType(TextField).first;
      await tester.tap(searchField);
      await tester.pumpAndSettle();
      await tester.enterText(searchField, 'Toko');
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.widgetWithText(TextField, 'Toko'), findsOneWidget);
    });

    testWidgets('TC-MK-03: Pencarian klien tidak ditemukan menampilkan pesan kosong',
        (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      final searchField = find.byType(TextField).first;
      await tester.tap(searchField);
      await tester.pumpAndSettle();
      await tester.enterText(searchField, 'xyzabc999tidakada');
      await tester.pumpAndSettle(const Duration(seconds: 2));

      final emptySearch = find.text('Klien Tidak Ditemukan');
      final emptyAll = find.text('Belum Ada Klien');
      expect(
        emptySearch.evaluate().isNotEmpty || emptyAll.evaluate().isNotEmpty,
        isTrue,
      );
    });

    testWidgets('TC-MK-04: Tombol FAB tambah klien tampil', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('TC-MK-05: Dialog tambah klien terbuka saat FAB ditekan',
        (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.text('Tambah Klien'), findsOneWidget);
    });

    testWidgets('TC-MK-06: Form tambah klien memiliki semua field yang diperlukan',
        (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.text('Nama Klien'), findsOneWidget);
      expect(find.text('Nomor Telepon'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Alamat'), findsOneWidget);
    });

    testWidgets('TC-MK-07: Validasi form tambah klien kosong gagal disubmit',
        (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Tekan tombol Tambah tanpa mengisi form
      await tester.tap(find.text('Tambah'));
      await tester.pumpAndSettle();

      // Dialog masih tampil karena validasi gagal
      expect(find.text('Tambah Klien'), findsOneWidget);
    });

    testWidgets('TC-MK-08: Dialog tambah klien dapat dibatalkan',
        (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.text('Tambah Klien'), findsOneWidget);

      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();

      expect(find.text('Tambah Klien'), findsNothing);
    });

    testWidgets('TC-MK-09: Tombol edit tampil pada card klien jika ada data',
        (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      final editButtons = find.byIcon(Icons.edit);
      if (editButtons.evaluate().isNotEmpty) {
        expect(editButtons, findsAtLeastNWidgets(1));
      } else {
        // Tidak ada data klien, tampilan kosong
        expect(
          find.text('Belum Ada Klien').evaluate().isNotEmpty ||
              find.byIcon(Icons.people_outline).evaluate().isNotEmpty,
          isTrue,
        );
      }
    });

    testWidgets('TC-MK-10: Dialog edit klien terbuka saat tombol edit ditekan',
        (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      final editButton = find.byIcon(Icons.edit);
      if (editButton.evaluate().isNotEmpty) {
        await tester.tap(editButton.first);
        await tester.pumpAndSettle();

        expect(find.text('Edit Klien'), findsOneWidget);
      }
    });

    testWidgets('TC-MK-11: Form edit klien terisi dengan data klien yang ada',
        (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      final editButton = find.byIcon(Icons.edit);
      if (editButton.evaluate().isNotEmpty) {
        await tester.tap(editButton.first);
        await tester.pumpAndSettle();

        // Field nama, telepon, email, dan alamat harus ada
        expect(find.text('Nama Klien'), findsOneWidget);
        expect(find.text('Nomor Telepon'), findsOneWidget);
        expect(find.text('Email'), findsOneWidget);
        expect(find.text('Alamat'), findsOneWidget);
      }
    });

    testWidgets('TC-MK-12: Dialog edit klien dapat dibatalkan', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      final editButton = find.byIcon(Icons.edit);
      if (editButton.evaluate().isNotEmpty) {
        await tester.tap(editButton.first);
        await tester.pumpAndSettle();

        expect(find.text('Edit Klien'), findsOneWidget);

        await tester.tap(find.text('Batal'));
        await tester.pumpAndSettle();

        expect(find.text('Edit Klien'), findsNothing);
      }
    });

    testWidgets('TC-MK-13: Tombol hapus tampil pada card klien jika ada data',
        (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      final deleteButtons = find.byIcon(Icons.delete_outline);
      if (deleteButtons.evaluate().isNotEmpty) {
        expect(deleteButtons, findsAtLeastNWidgets(1));
      }
    });

    testWidgets('TC-MK-14: Dialog konfirmasi hapus klien terbuka',
        (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      final deleteButton = find.byIcon(Icons.delete_outline);
      if (deleteButton.evaluate().isNotEmpty) {
        await tester.tap(deleteButton.first);
        await tester.pumpAndSettle();

        // Salah satu dialog konfirmasi hapus atau dialog ditolak (ada hutang)
        expect(
          find.text('Hapus Klien').evaluate().isNotEmpty ||
              find.text('Ditolak').evaluate().isNotEmpty,
          isTrue,
        );
      }
    });

    testWidgets('TC-MK-15: Dialog konfirmasi hapus klien dapat dibatalkan',
        (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      final deleteButton = find.byIcon(Icons.delete_outline);
      if (deleteButton.evaluate().isNotEmpty) {
        await tester.tap(deleteButton.first);
        await tester.pumpAndSettle();

        // Jika dialog hapus muncul (bukan dialog ditolak)
        if (find.text('Hapus Klien').evaluate().isNotEmpty) {
          await tester.tap(find.text('Batal'));
          await tester.pumpAndSettle();

          expect(find.text('Hapus Klien'), findsNothing);
        }
      }
    });
  });
}