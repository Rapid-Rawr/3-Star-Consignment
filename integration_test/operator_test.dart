import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:star_consignment/firebase_options.dart';
import 'package:star_consignment/utils/supabase_service.dart';
import 'package:star_consignment/service/auth_provider.dart';
import 'package:star_consignment/views/pengguna/operator_page.dart';
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
          home: const OperatorPage(),
        ),
      ),
    );
  }

  group('Manajemen Operator - Black Box Test', () {
    testWidgets('TC-MO-01: Halaman operator berhasil ditampilkan',
        (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('Operator'), findsOneWidget);
    });

    testWidgets('TC-MO-02: Search bar operator berfungsi', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      final searchField = find.byType(TextField).first;
      await tester.tap(searchField);
      await tester.pumpAndSettle();
      await tester.enterText(searchField, 'Admin');
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.widgetWithText(TextField, 'Admin'), findsOneWidget);
    });

    testWidgets('TC-MO-03: Filter chip role tersedia', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('Semua'), findsOneWidget);
      expect(find.text('Administrator'), findsOneWidget);
      expect(find.text('Karyawan'), findsOneWidget);
    });

    testWidgets('TC-MO-04: Filter chip Administrator dapat ditekan',
        (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      await tester.tap(find.text('Administrator').first);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.text('Administrator'), findsOneWidget);
    });

    testWidgets('TC-MO-05: Filter chip Karyawan dapat ditekan', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      await tester.tap(find.text('Karyawan').first);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.text('Karyawan'), findsOneWidget);
    });

    testWidgets('TC-MO-06: Pencarian tidak ditemukan menampilkan pesan kosong',
        (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      final searchField = find.byType(TextField).first;
      await tester.tap(searchField);
      await tester.pumpAndSettle();
      await tester.enterText(searchField, 'xyzabc999tidakada');
      await tester.pumpAndSettle(const Duration(seconds: 2));

      final emptySearch = find.text('Operator Tidak Ditemukan');
      final emptyAll = find.text('Belum Ada Operator');
      expect(
        emptySearch.evaluate().isNotEmpty || emptyAll.evaluate().isNotEmpty,
        isTrue,
      );
    });

    testWidgets('TC-MO-07: Tombol FAB tambah operator tampil', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('TC-MO-08: Dialog tambah operator terbuka saat FAB ditekan',
        (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.text('Tambah Operator'), findsOneWidget);
    });

    testWidgets('TC-MO-09: Form tambah operator memiliki semua field',
        (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.text('Nama'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Role'), findsOneWidget);
    });

    testWidgets('TC-MO-10: Dropdown role memiliki pilihan Administrator dan Karyawan',
        (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Tap dropdown Role untuk membuka pilihan
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();

      expect(find.text('Administrator'), findsAtLeastNWidgets(1));
      expect(find.text('Karyawan'), findsAtLeastNWidgets(1));
    });

    testWidgets('TC-MO-11: Validasi form tambah operator kosong gagal disubmit',
        (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Tekan Tambah tanpa mengisi field apapun
      await tester.tap(find.text('Tambah'));
      await tester.pumpAndSettle();

      // Dialog masih tampil karena validasi gagal
      expect(find.text('Tambah Operator'), findsOneWidget);
    });

    testWidgets('TC-MO-12: Dialog tambah operator dapat dibatalkan',
        (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.text('Tambah Operator'), findsOneWidget);

      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();

      expect(find.text('Tambah Operator'), findsNothing);
    });

    testWidgets('TC-MO-13: Tombol edit tampil pada card operator jika ada data',
        (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      final editButtons = find.byIcon(Icons.edit_outlined);
      if (editButtons.evaluate().isNotEmpty) {
        expect(editButtons, findsAtLeastNWidgets(1));
      } else {
        expect(
          find.text('Belum Ada Operator').evaluate().isNotEmpty ||
              find.byIcon(Icons.people_outline).evaluate().isNotEmpty,
          isTrue,
        );
      }
    });

    testWidgets('TC-MO-14: Dialog edit operator terbuka saat tombol edit ditekan',
        (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      final editButton = find.byIcon(Icons.edit_outlined);
      if (editButton.evaluate().isNotEmpty) {
        await tester.tap(editButton.first);
        await tester.pumpAndSettle();

        expect(find.text('Edit Operator'), findsOneWidget);
      }
    });

    testWidgets('TC-MO-15: Form edit operator terisi dengan data yang ada',
        (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      final editButton = find.byIcon(Icons.edit_outlined);
      if (editButton.evaluate().isNotEmpty) {
        await tester.tap(editButton.first);
        await tester.pumpAndSettle();

        expect(find.text('Nama'), findsOneWidget);
        expect(find.text('Email'), findsOneWidget);
        expect(find.text('Role'), findsOneWidget);
      }
    });

    testWidgets('TC-MO-16: Dialog edit operator dapat dibatalkan',
        (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      final editButton = find.byIcon(Icons.edit_outlined);
      if (editButton.evaluate().isNotEmpty) {
        await tester.tap(editButton.first);
        await tester.pumpAndSettle();

        expect(find.text('Edit Operator'), findsOneWidget);

        await tester.tap(find.text('Batal'));
        await tester.pumpAndSettle();

        expect(find.text('Edit Operator'), findsNothing);
      }
    });

    testWidgets('TC-MO-17: Tombol hapus tampil pada card operator jika ada data',
        (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      final deleteButtons = find.byIcon(Icons.delete_outline);
      if (deleteButtons.evaluate().isNotEmpty) {
        expect(deleteButtons, findsAtLeastNWidgets(1));
      }
    });

    testWidgets('TC-MO-18: Dialog konfirmasi hapus operator terbuka',
        (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      final deleteButton = find.byIcon(Icons.delete_outline);
      if (deleteButton.evaluate().isNotEmpty) {
        await tester.tap(deleteButton.first);
        await tester.pumpAndSettle();

        expect(find.text('Hapus Operator'), findsOneWidget);
      }
    });

    testWidgets('TC-MO-19: Dialog konfirmasi hapus operator dapat dibatalkan',
        (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      final deleteButton = find.byIcon(Icons.delete_outline);
      if (deleteButton.evaluate().isNotEmpty) {
        await tester.tap(deleteButton.first);
        await tester.pumpAndSettle();

        if (find.text('Hapus Operator').evaluate().isNotEmpty) {
          await tester.tap(find.text('Batal'));
          await tester.pumpAndSettle();

          expect(find.text('Hapus Operator'), findsNothing);
        }
      }
    });

    testWidgets('TC-MO-20: Search dan filter role dapat digunakan bersamaan',
        (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Pilih filter Administrator
      await tester.tap(find.text('Administrator').first);
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Lalu isi search
      final searchField = find.byType(TextField).first;
      await tester.tap(searchField);
      await tester.pumpAndSettle();
      await tester.enterText(searchField, 'Budi');
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Filter chip dan search tetap tampil
      expect(find.text('Administrator'), findsOneWidget);
      expect(find.byType(TextField), findsAtLeastNWidgets(1));
    });
  });
}