import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';

// Sesuaikan path import di bawah ini dengan struktur project Anda
import 'package:star_consignment/service/roles.dart'; // Import class Roles Anda
import 'package:star_consignment/service/auth_provider.dart';
import 'package:star_consignment/views/pengguna/klien_page.dart';
import 'package:star_consignment/utils/theme_notifier.dart';



/// FakeAuthProvider menimpa (override) fungsi AuthProvider asli
/// agar tidak memanggil Firebase dan SharedPreferences saat ditest.
class FakeAuthProvider extends AuthProvider {
  // Kita set default role ke Admin agar test memiliki akses penuh ke fitur CRUD
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

  setUpAll(() async {
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
      await tester.enterText(searchField, 'Toko');
      await tester.pumpAndSettle();

      expect(find.widgetWithText(TextField, 'Toko'), findsOneWidget);
    });

    // testWidgets('TC-MK-04: Tombol FAB tambah klien tampil untuk Admin', (tester) async {
    //   await loadApp(tester);
    //   // Memastikan FAB ada karena Role = Admin (dari FakeAuthProvider)
    //   expect(find.byType(FloatingActionButton), findsOneWidget);
    // });

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

    // =================================================================
    // CATATAN: Test Edit (TC 09-12) dan Hapus (TC 13-15) akan berhasil
    // secara konsisten JIKA Anda juga sudah mem-bypass pemanggilan data
    // Klien (Client) dengan Fake Data seperti Toko Abadi.
    // =================================================================
  });
}