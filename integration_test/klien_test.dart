import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:star_consignment/service/roles.dart';
import 'package:star_consignment/service/auth_provider.dart';
import 'package:star_consignment/views/pengguna/klien_page.dart';
import 'package:star_consignment/utils/theme_notifier.dart';


/// FakeAuthProvider menimpa (override) fungsi AuthProvider asli
/// agar tidak memanggil Firebase dan SharedPreferences saat ditest.
class FakeAuthProvider extends AuthProvider {
  // set default role ke Admin agar test memiliki akses penuh ke fitur CRUD
  String? _fakeRole = Roles.admin;

  @override
  String? get role => _fakeRole;

  @override
  Future<void> init() async {
    notifyListeners();
  }

  @override
  Future<void> setRole(String? role) async {
    _fakeRole = role;
    notifyListeners();
  }

  @override
  Future<void> clear() async {
    _fakeRole = null;
    notifyListeners();
  }
}

class FakeClientProvider extends ChangeNotifier {
  final List<Map<String, dynamic>> mockClients = [
    {
      'id': '1',
      'nama': 'Toko Abadi',
      'telepon': '08123456789',
      'email': 'toko@abadi.com',
      'alamat': 'Jl. Mawar No. 1'
    }
  ];

  List<Map<String, dynamic>> get clients => mockClients;
}

// ===================================================================
// [TESTING SECTION]
// ===================================================================

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Tambahkan inisialisasi Firebase di sini agar tidak crash saat ClientPage dipanggil
  setUpAll(() async {
    await Firebase.initializeApp();
  });

  Widget buildTestApp() {
    return MultiProvider(
      providers: [
        // Inject FakeAuthProvider menggantikan AuthProvider asli
        ChangeNotifierProvider<AuthProvider>(create: (_) {
          final auth = FakeAuthProvider();
          auth.init(); // Panggil init mock
          return auth;
        }),
        // Inject FakeClientProvider yang sebelumnya terlupakan
        ChangeNotifierProvider<FakeClientProvider>(create: (_) => FakeClientProvider()),
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

  group('Manajemen Klien - Mocked UI Test', () {
    Future<void> loadApp(WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp());
      // pumpAndSettle digunakan agar menunggu semua animasi/loading UI selesai
      await tester.pumpAndSettle(const Duration(seconds: 2));
    }

    testWidgets('TC-MK-01: Halaman klien berhasil ditampilkan', (tester) async {
      await loadApp(tester);
      expect(find.text('Klien'), findsOneWidget);
    });

    testWidgets('TC-MK-02: Search bar klien berfungsi menerima input', (tester) async {
      await loadApp(tester);

      final searchField = find.byType(TextField).first;
      await tester.enterText(searchField, 'Eiger');
      await tester.pumpAndSettle();

      expect(find.widgetWithText(TextField, 'Eiger'), findsOneWidget);
    });

//     testWidgets('TC-MK-02: Search bar klien berfungsi menerima input', (tester) async {
//           await loadApp(tester);
//
//           final searchField = find.byType(TextField).first;
//           await tester.enterText(searchField, '');
//           await tester.pumpAndSettle();
//
//           expect(find.empty);
//         });


    testWidgets('TC-MK-03: Tombol FAB tambah klien tampil untuk Admin', (tester) async {
      await loadApp(tester);
      // Memastikan FAB ada karena Role = Admin (dari FakeAuthProvider)
          await tester.tap(find.byType(FloatingActionButton));
          await tester.pumpAndSettle();
        // Mencari kolom input berdasarkan labelnya
        final namaKlienField = find.widgetWithText(TextFormField, 'Nama Klien');
        final nomorKlienField = find.widgetWithText(TextFormField, 'Nomor Telepon');
        final emailKlienField = find.widgetWithText(TextFormField, 'Email');
        final alamatKlienField = find.widgetWithText(TextFormField, 'Alamat');


        // Menyuruh tester mengetik di kolom tersebut
        await tester.enterText(namaKlienField, 'Eiger');
        await tester.enterText(nomorKlienField, '008123456789');
        await tester.enterText(emailKlienField, 'bintang@gmail.com');
        await tester.enterText(alamatKlienField, 'Eiger');

        final tombolTambah = find.text('Tambah');
        await tester.tap(tombolTambah);
        await tester.pumpAndSettle();

    });

 testWidgets('TC-MK-03: Tombol FAB tambah klien tampil untuk Admin', (tester) async {
      await loadApp(tester);
      // Memastikan FAB ada karena Role = Admin (dari FakeAuthProvider)
          await tester.tap(find.byType(FloatingActionButton));
          await tester.pumpAndSettle();
        // Mencari kolom input berdasarkan labelnya
        final namaKlienField = find.widgetWithText(TextFormField, 'Nama Klien');
        final nomorKlienField = find.widgetWithText(TextFormField, 'Nomor Telepon');
        final emailKlienField = find.widgetWithText(TextFormField, 'Email');
        final alamatKlienField = find.widgetWithText(TextFormField, 'Alamat');


        // Menyuruh tester mengetik di kolom tersebut
        await tester.enterText(namaKlienField, 'Eiger');
        await tester.enterText(nomorKlienField, '9');
        await tester.enterText(emailKlienField, 'bintang');
        await tester.enterText(alamatKlienField, 'Eiger');

        final tombolTambah = find.text('Tambah');
        await tester.tap(tombolTambah);
        await tester.pumpAndSettle();

      expect(find.widgetWithText(TextField, 'eror'), findsOneWidget);


    });

testWidgets('TC-MK-04: edit klien  untuk Admin', (tester) async {
      await loadApp(tester);
      // Memastikan FAB ada karena Role = Admin (dari FakeAuthProvider)
      final searchField = find.byType(TextField).first;
            await tester.enterText(searchField, 'Eiger');
            await tester.pumpAndSettle();

            expect(find.widgetWithText(TextField, 'Eiger'), findsOneWidget);
          await tester.tap(find.byIcon(Icons.edit));
          await tester.pumpAndSettle();
        // Mencari kolom input berdasarkan labelnya
        final namaKlienField = find.widgetWithText(TextFormField, 'Nama Klien');
        final nomorKlienField = find.widgetWithText(TextFormField, 'Nomor Telepon');
        final emailKlienField = find.widgetWithText(TextFormField, 'Email');
        final alamatKlienField = find.widgetWithText(TextFormField, 'Alamat');


        // Menyuruh tester mengetik di kolom tersebut
        await tester.enterText(namaKlienField, 'edit ');
        await tester.enterText(nomorKlienField, '008123456789');
        await tester.enterText(emailKlienField, 'edit@gmail.com');
        await tester.enterText(alamatKlienField, 'edit');

        final tombolTambah = find.text('Simpan');
        await tester.tap(tombolTambah);
        await tester.pumpAndSettle();

    });
    // testWidgets('TC-MK-05: Dialog tambah klien terbuka saat FAB ditekan', (tester) async {
    //   await loadApp(tester);
    //   await tester.tap(find.byType(FloatingActionButton));
    //   await tester.pumpAndSettle();

    //   expect(find.text('Tambah Klien'), findsOneWidget);
    // });

    // testWidgets('TC-MK-08: Dialog tambah klien dapat dibatalkan', (tester) async {
    //   await loadApp(tester);
    //   await tester.tap(find.byType(FloatingActionButton));
    //   await tester.pumpAndSettle();

    //   await tester.tap(find.text('Batal'));
    //   await tester.pumpAndSettle();

    //   // Memastikan dialog hilang (findsNothing)
    //   expect(find.text('Tambah Klien'), findsNothing);
    // });
  });
}