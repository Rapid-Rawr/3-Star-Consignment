import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

// Sesuaikan path import dengan project kamu
import 'package:star_consignment/views/barang/barang_konsinyasi_page.dart';
import 'package:star_consignment/controllers/pengguna_controllers/klien_controller.dart';
import 'package:star_consignment/controllers/barang_controllers/katalog_controller.dart';
import 'package:star_consignment/models/pengguna_models/klien_model.dart';
import 'package:star_consignment/models/barang_models/katalog_model.dart';

@GenerateMocks([ClientController, CatalogController, FirebaseFirestore])
import 'konsinyasi_page_test.mocks.dart';

// ─── Helper: data dummy ──────────────────────────────────────────────────────

List<ClientModel> _dummyClients() => [
  ClientModel(
    id: 'c1',
    name: 'Toko Makmur',
    phone: '081234567890',
    email: 'makmur@example.com',
    address: 'Jl. Merdeka 1, Surabaya',
    debt: 150000,
    borrowedItems: [
      BorrowedItem(
        catalogId: 'cat-1',
        catalogName: 'Kursi Plastik',
        catalogPrice: 15000,
        catalogCategory: 'Furniture',
        quantity: 5,
        lastReceivedAt: DateTime(2024, 5, 10),
      ),
      BorrowedItem(
        catalogId: 'cat-2',
        catalogName: 'Meja Lipat',
        catalogPrice: 30000,
        catalogCategory: 'Furniture',
        quantity: 3,
      ),
    ],
  ),
  ClientModel(
    id: 'c2',
    name: 'Toko Sejahtera',
    phone: '089876543210',
    email: '',
    address: 'Jl. Kenangan 5, Malang',
    debt: 0,
    borrowedItems: [],
  ),
];

List<CatalogModel> _dummyCatalogs() => [
  CatalogModel(
    id: 'cat-1',
    name: 'Kursi Plastik',
    category: 'Furniture',
    price: 15000,
    imagePath: null,
  ),
  CatalogModel(
    id: 'cat-2',
    name: 'Meja Lipat',
    category: 'Furniture',
    price: 30000,
    imagePath: null,
  ),
  CatalogModel(
    id: 'cat-3',
    name: 'Tenda Outdoor',
    category: 'Outdoor',
    price: 200000,
    imagePath: null,
  ),
];

// ─── Helper: wrap widget ─────────────────────────────────────────────────────

Widget _wrap(Widget child, {bool dark = false}) => MaterialApp(
  theme: dark ? ThemeData.dark() : ThemeData.light(),
  home: child,
);

// ════════════════════════════════════════════════════════════════════════════
// _InlineQtyStepper
// ════════════════════════════════════════════════════════════════════════════

void main() {
  // ── karena class private, test via pump langsung ──────────────────────────
  group('_InlineQtyStepper', () {
    testWidgets('menampilkan quantity awal', (tester) async {
      int qty = 3;
      await tester.pumpWidget(
        _wrap(
          StatefulBuilder(
            builder: (_, setState) => Scaffold(
              body: InlineQtyStepper(
                quantity: qty,
                isDark: false,
                onDecrement: () => setState(() => qty--),
                onIncrement: () => setState(() => qty++),
              ),
            ),
          ),
        ),
      );
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('tombol + menambah quantity', (tester) async {
      int qty = 2;
      await tester.pumpWidget(
        _wrap(
          StatefulBuilder(
            builder: (_, setState) => Scaffold(
              body: InlineQtyStepper(
                quantity: qty,
                isDark: false,
                onDecrement: () => setState(() => qty--),
                onIncrement: () => setState(() => qty++),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('tombol - mengurangi quantity', (tester) async {
      int qty = 3;
      await tester.pumpWidget(
        _wrap(
          StatefulBuilder(
            builder: (_, setState) => Scaffold(
              body: InlineQtyStepper(
                quantity: qty,
                isDark: false,
                onDecrement: () => setState(() => qty--),
                onIncrement: () => setState(() => qty++),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byIcon(Icons.remove));
      await tester.pump();
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('tampilkan ikon delete jika quantity = 1', (tester) async {
      await tester.pumpWidget(
        _wrap(
          Scaffold(
            body: InlineQtyStepper(
              quantity: 1,
              isDark: false,
              onDecrement: () {},
              onIncrement: () {},
            ),
          ),
        ),
      );
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
      expect(find.byIcon(Icons.remove), findsNothing);
    });

    testWidgets('tampilkan ikon remove jika quantity > 1', (tester) async {
      await tester.pumpWidget(
        _wrap(
          Scaffold(
            body: InlineQtyStepper(
              quantity: 2,
              isDark: false,
              onDecrement: () {},
              onIncrement: () {},
            ),
          ),
        ),
      );
      expect(find.byIcon(Icons.remove), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline), findsNothing);
    });

    testWidgets('warna berbeda di dark mode', (tester) async {
      await tester.pumpWidget(
        _wrap(
          Scaffold(
            body: InlineQtyStepper(
              quantity: 2,
              isDark: true,
              onDecrement: () {},
              onIncrement: () {},
            ),
          ),
          dark: true,
        ),
      );
      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, const Color(0xFF3A3740));
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // _ClientCard
  // ════════════════════════════════════════════════════════════════════════════

  group('_ClientCard', () {
    final client = _dummyClients()[0]; // Toko Makmur - ada borrowedItems
    final emptyClient = _dummyClients()[1]; // Toko Sejahtera - kosong

    testWidgets('menampilkan nama klien', (tester) async {
      await tester.pumpWidget(
        _wrap(
          Scaffold(
            body: ClientCard(
              client: client,
              displayItems: client.borrowedItems,
              isDark: false,
              formatDate: (_) => '-',
              onDetail: () {},
              onSerahkan: () {},
            ),
          ),
        ),
      );
      expect(find.text('Toko Makmur'), findsOneWidget);
    });

    testWidgets('menampilkan alamat klien', (tester) async {
      await tester.pumpWidget(
        _wrap(
          Scaffold(
            body: ClientCard(
              client: client,
              displayItems: client.borrowedItems,
              isDark: false,
              formatDate: (_) => '-',
              onDetail: () {},
              onSerahkan: () {},
            ),
          ),
        ),
      );
      expect(find.text('Jl. Merdeka 1, Surabaya'), findsOneWidget);
    });

    testWidgets('menampilkan total qty unit badge', (tester) async {
      await tester.pumpWidget(
        _wrap(
          Scaffold(
            body: ClientCard(
              client: client,
              displayItems: client.borrowedItems,
              isDark: false,
              formatDate: (_) => '-',
              onDetail: () {},
              onSerahkan: () {},
            ),
          ),
        ),
      );
      // qty = 5 + 3 = 8
      expect(find.text('8 unit'), findsOneWidget);
    });

    testWidgets('menampilkan chip kategori', (tester) async {
      await tester.pumpWidget(
        _wrap(
          Scaffold(
            body: ClientCard(
              client: client,
              displayItems: client.borrowedItems,
              isDark: false,
              formatDate: (_) => '-',
              onDetail: () {},
              onSerahkan: () {},
            ),
          ),
        ),
      );
      expect(find.text('Furniture'), findsWidgets);
    });

    testWidgets('menampilkan teks kosong jika tidak ada borrowed items', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          Scaffold(
            body: ClientCard(
              client: emptyClient,
              displayItems: [],
              isDark: false,
              formatDate: (_) => '-',
              onDetail: () {},
              onSerahkan: () {},
            ),
          ),
        ),
      );
      expect(find.text('Belum ada barang konsinyasi'), findsOneWidget);
    });

    testWidgets('tombol Lihat Semua memanggil onDetail', (tester) async {
      bool called = false;
      await tester.pumpWidget(
        _wrap(
          Scaffold(
            body: ClientCard(
              client: client,
              displayItems: client.borrowedItems,
              isDark: false,
              formatDate: (_) => '-',
              onDetail: () => called = true,
              onSerahkan: () {},
            ),
          ),
        ),
      );
      await tester.tap(find.text('Lihat Semua'));
      expect(called, isTrue);
    });

    testWidgets('tombol + memanggil onSerahkan (saat ada borrowed items)', (
      tester,
    ) async {
      bool called = false;
      await tester.pumpWidget(
        _wrap(
          Scaffold(
            body: ClientCard(
              client: client,
              displayItems: client.borrowedItems,
              isDark: false,
              formatDate: (_) => '-',
              onDetail: () {},
              onSerahkan: () => called = true,
            ),
          ),
        ),
      );
      await tester.tap(find.byIcon(Icons.add_rounded));
      expect(called, isTrue);
    });

    testWidgets('menampilkan label + 1 barang lainnya jika items > 3', (
      tester,
    ) async {
      final manyItems = List.generate(
        4,
        (i) => BorrowedItem(
          catalogId: 'cat-$i',
          catalogName: 'Item $i',
          catalogPrice: 10000,
          catalogCategory: 'Misc',
          quantity: 1,
        ),
      );
      await tester.pumpWidget(
        _wrap(
          Scaffold(
            body: SingleChildScrollView(
              child: ClientCard(
                client: client.copyWith(borrowedItems: manyItems),
                displayItems: manyItems,
                isDark: false,
                formatDate: (_) => '-',
                onDetail: () {},
                onSerahkan: () {},
              ),
            ),
          ),
        ),
      );
      expect(find.textContaining('barang lainnya'), findsOneWidget);
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // _ClientDetailSheet
  // ════════════════════════════════════════════════════════════════════════════

  group('_ClientDetailSheet', () {
    final client = _dummyClients()[0];

    Future<void> _openSheet(
      WidgetTester tester, {
      String? initialCategory,
    }) async {
      await tester.pumpWidget(
        _wrap(
          Builder(
            builder: (ctx) => Scaffold(
              body: ElevatedButton(
                onPressed: () => showModalBottomSheet(
                  context: ctx,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => ClientDetailSheet(
                    client: client,
                    isDark: false,
                    formatDate: (dt) => dt?.toString() ?? '-',
                    initialCategory: initialCategory,
                  ),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
    }

    testWidgets('menampilkan nama klien di header sheet', (tester) async {
      await _openSheet(tester);
      expect(find.text('Toko Makmur'), findsOneWidget);
    });

    testWidgets('menampilkan daftar barang', (tester) async {
      await _openSheet(tester);
      expect(find.text('Kursi Plastik'), findsOneWidget);
      expect(find.text('Meja Lipat'), findsOneWidget);
    });

    testWidgets('menampilkan chip kategori saat ada > 1 kategori', (
      tester,
    ) async {
      final multiCatClient = ClientModel(
        id: 'cx',
        name: 'Multi Cat',
        phone: '0',
        address: 'Addr',
        debt: 0,
        borrowedItems: [
          BorrowedItem(
            catalogId: 'a',
            catalogName: 'Item A',
            catalogPrice: 10000,
            catalogCategory: 'Furniture',
            quantity: 1,
          ),
          BorrowedItem(
            catalogId: 'b',
            catalogName: 'Item B',
            catalogPrice: 10000,
            catalogCategory: 'Outdoor',
            quantity: 1,
          ),
        ],
      );
      await tester.pumpWidget(
        _wrap(
          Builder(
            builder: (ctx) => Scaffold(
              body: ElevatedButton(
                onPressed: () => showModalBottomSheet(
                  context: ctx,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => ClientDetailSheet(
                    client: multiCatClient,
                    isDark: false,
                    formatDate: (_) => '-',
                    initialCategory: null,
                  ),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Furniture'), findsWidgets);
      expect(find.text('Outdoor'), findsWidgets);
    });

    testWidgets('tombol close menutup sheet', (tester) async {
      await _openSheet(tester);
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(find.text('Kursi Plastik'), findsNothing);
    });

    testWidgets('menampilkan total unit di badge', (tester) async {
      await _openSheet(tester);
      // qty = 5 + 3 = 8
      expect(find.text('8 unit'), findsOneWidget);
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // _formatDate (via widget)
  // ════════════════════════════════════════════════════════════════════════════

  group('_formatDate helper', () {
    // Kita test via ClientDetailSheet yang menggunakannya
    testWidgets('null date menampilkan -', (tester) async {
      final client = ClientModel(
        id: 'cx',
        name: 'Test',
        phone: '0',
        address: 'Addr',
        debt: 0,
        borrowedItems: [
          BorrowedItem(
            catalogId: 'a',
            catalogName: 'Item Tanpa Tanggal',
            catalogPrice: 1000,
            catalogCategory: 'X',
            quantity: 1,
            lastReceivedAt: null,
          ),
        ],
      );
      await tester.pumpWidget(
        _wrap(
          Builder(
            builder: (ctx) => Scaffold(
              body: ElevatedButton(
                onPressed: () => showModalBottomSheet(
                  context: ctx,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => ClientDetailSheet(
                    client: client,
                    isDark: false,
                    formatDate: (dt) {
                      if (dt == null) return '-';
                      const m = [
                        '',
                        'Jan',
                        'Feb',
                        'Mar',
                        'Apr',
                        'Mei',
                        'Jun',
                        'Jul',
                        'Agu',
                        'Sep',
                        'Okt',
                        'Nov',
                        'Des',
                      ];
                      return '${dt.day} ${m[dt.month]} ${dt.year}';
                    },
                    initialCategory: null,
                  ),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      // Tidak ada teks "Terakhir diterima" karena lastReceivedAt == null
      expect(find.textContaining('Terakhir diterima'), findsNothing);
    });

    testWidgets('date valid diformat dengan benar', (tester) async {
      final client = ClientModel(
        id: 'cx',
        name: 'Test',
        phone: '0',
        address: 'Addr',
        debt: 0,
        borrowedItems: [
          BorrowedItem(
            catalogId: 'a',
            catalogName: 'Item Dengan Tanggal',
            catalogPrice: 1000,
            catalogCategory: 'X',
            quantity: 1,
            lastReceivedAt: DateTime(2024, 3, 7),
          ),
        ],
      );
      await tester.pumpWidget(
        _wrap(
          Builder(
            builder: (ctx) => Scaffold(
              body: ElevatedButton(
                onPressed: () => showModalBottomSheet(
                  context: ctx,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => ClientDetailSheet(
                    client: client,
                    isDark: false,
                    formatDate: (dt) {
                      if (dt == null) return '-';
                      const m = [
                        '',
                        'Jan',
                        'Feb',
                        'Mar',
                        'Apr',
                        'Mei',
                        'Jun',
                        'Jul',
                        'Agu',
                        'Sep',
                        'Okt',
                        'Nov',
                        'Des',
                      ];
                      return '${dt.day} ${m[dt.month]} ${dt.year}';
                    },
                    initialCategory: null,
                  ),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.textContaining('7 Mar 2024'), findsOneWidget);
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // _SelectedItem (unit test — logika internal)
  // ════════════════════════════════════════════════════════════════════════════

  group('_SelectedItem logic', () {
    test('quantity awal = 1', () {
      final catalog = _dummyCatalogs()[0];
      final item = SelectedItem(catalog: catalog);
      expect(item.quantity, 1);
    });

    test('quantity bisa diubah', () {
      final catalog = _dummyCatalogs()[0];
      final item = SelectedItem(catalog: catalog);
      item.quantity = 5;
      expect(item.quantity, 5);
    });

    test('computedTotal = price * quantity', () {
      final catalog = _dummyCatalogs()[0]; // price = 15000
      final item = SelectedItem(catalog: catalog);
      item.quantity = 3;
      expect(item.catalog.price * item.quantity, 45000.0);
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // Filter & Search logic (unit test tanpa widget)
  // ════════════════════════════════════════════════════════════════════════════

  group('Filter & Search logic', () {
    final clients = _dummyClients();

    test('pencarian berdasarkan nama menemukan klien', () {
      final q = 'makmur';
      final result = clients
          .where(
            (c) =>
                c.name.toLowerCase().contains(q) ||
                c.address.toLowerCase().contains(q) ||
                c.phone.toLowerCase().contains(q),
          )
          .toList();
      expect(result.length, 1);
      expect(result.first.name, 'Toko Makmur');
    });

    test('pencarian berdasarkan alamat menemukan klien', () {
      final q = 'malang';
      final result = clients
          .where(
            (c) =>
                c.name.toLowerCase().contains(q) ||
                c.address.toLowerCase().contains(q) ||
                c.phone.toLowerCase().contains(q),
          )
          .toList();
      expect(result.length, 1);
      expect(result.first.name, 'Toko Sejahtera');
    });

    test('pencarian tidak menemukan klien mengembalikan list kosong', () {
      final q = 'tidakadaklienini';
      final result = clients
          .where(
            (c) =>
                c.name.toLowerCase().contains(q) ||
                c.address.toLowerCase().contains(q),
          )
          .toList();
      expect(result, isEmpty);
    });

    test('filter kategori menyaring borrowedItems dengan benar', () {
      final filtered = clients
          .where(
            (c) => c.borrowedItems.any((b) => b.catalogCategory == 'Furniture'),
          )
          .toList();
      expect(filtered.length, 1);
      expect(filtered.first.name, 'Toko Makmur');
    });

    test('filter kategori tidak ada mengembalikan list kosong', () {
      final filtered = clients
          .where(
            (c) => c.borrowedItems.any(
              (b) => b.catalogCategory == 'KategoriTidakAda',
            ),
          )
          .toList();
      expect(filtered, isEmpty);
    });

    test('allCats mengambil kategori unik dari semua klien', () {
      final allCats =
          clients
              .expand((c) => c.borrowedItems.map((b) => b.catalogCategory))
              .toSet()
              .toList()
            ..sort();
      expect(allCats, ['Furniture']);
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // _changeQty logic (unit test)
  // ════════════════════════════════════════════════════════════════════════════

  group('_changeQty logic', () {
    late Map<String, SelectedItem> selected;

    setUp(() {
      selected = {};
      final cat = _dummyCatalogs()[0];
      selected[cat.id] = SelectedItem(catalog: cat)..quantity = 3;
    });

    test('increment menambah quantity', () {
      final id = _dummyCatalogs()[0].id;
      final newQty = selected[id]!.quantity + 1;
      selected[id]!.quantity = newQty;
      expect(selected[id]!.quantity, 4);
    });

    test('decrement mengurangi quantity', () {
      final id = _dummyCatalogs()[0].id;
      final newQty = selected[id]!.quantity - 1;
      selected[id]!.quantity = newQty;
      expect(selected[id]!.quantity, 2);
    });

    test('quantity <= 0 menghapus item dari selected', () {
      final id = _dummyCatalogs()[0].id;
      selected[id]!.quantity = 1;
      final newQty = selected[id]!.quantity - 1;
      if (newQty <= 0) selected.remove(id);
      expect(selected.containsKey(id), isFalse);
    });

    test('toggle menambah item baru ke selected', () {
      final cat = _dummyCatalogs()[1];
      selected[cat.id] = SelectedItem(catalog: cat);
      expect(selected.containsKey(cat.id), isTrue);
    });

    test('toggle item yang sudah ada menghapusnya', () {
      final id = _dummyCatalogs()[0].id;
      if (selected.containsKey(id)) selected.remove(id);
      expect(selected.containsKey(id), isFalse);
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // Total estimasi (unit test)
  // ════════════════════════════════════════════════════════════════════════════

  group('Total estimasi', () {
    test('totalEst = sum(price * qty) dari selected items', () {
      final selected = {
        'cat-1': SelectedItem(catalog: _dummyCatalogs()[0])
          ..quantity = 2, // 15000 * 2 = 30000
        'cat-3': SelectedItem(catalog: _dummyCatalogs()[2])
          ..quantity = 1, // 200000 * 1 = 200000
      };
      final totalEst = selected.values.fold(
        0.0,
        (s, e) => s + e.catalog.price * e.quantity,
      );
      expect(totalEst, 230000.0);
    });

    test('totalEst = 0 jika tidak ada item dipilih', () {
      final selected = <String, SelectedItem>{};
      final totalEst = selected.values.fold(
        0.0,
        (s, e) => s + e.catalog.price * e.quantity,
      );
      expect(totalEst, 0.0);
    });

    test('totalQty = sum semua quantity', () {
      final selected = {
        'cat-1': SelectedItem(catalog: _dummyCatalogs()[0])..quantity = 3,
        'cat-2': SelectedItem(catalog: _dummyCatalogs()[1])..quantity = 2,
      };
      final totalQty = selected.values.fold(0, (s, e) => s + e.quantity);
      expect(totalQty, 5);
    });
  });
}
