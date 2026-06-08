import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:star_consignment/controllers/barang_controllers/katalog_controller.dart';
import 'package:star_consignment/models/barang_models/katalog_model.dart';

// ─── Helper: buat CatalogModel dummy ─────────────────────────────────────────
CatalogModel _makeItem({
  String id = 'cat-001',
  String name = 'Kursi Plastik',
  String category = 'Furniture',
  double price = 15000,
  String? imagePath,
}) =>
    CatalogModel(
      id: id,
      name: name,
      category: category,
      price: price,
      imagePath: imagePath,
    );

/// Tambahkan item ke FakeFirestore dan return id-nya
Future<String> _addItem(
  FakeFirebaseFirestore firestore, {
  String name = 'Kursi Plastik',
  double price = 15000,
  String category = 'Furniture',
  String? imagePath,
}) async {
  final ref = await firestore.collection('catalog').add({
    'name': name,
    'price': price,
    'category': category,
    'imagePath': imagePath,
  });
  return ref.id;
}

// ═════════════════════════════════════════════════════════════════════════════
void main() {
  // ── 1. validateName ────────────────────────────────────────────────────────
  group('validateName', () {
    late CatalogController controller;

    setUp(() {
      controller = CatalogController(firestore: FakeFirebaseFirestore());
    });

    test('null → error tidak boleh kosong', () {
      expect(controller.validateName(null), isNotNull);
    });

    test('string kosong → error tidak boleh kosong', () {
      expect(controller.validateName(''), isNotNull);
    });

    test('1 karakter → error minimal 2 karakter', () {
      expect(controller.validateName('A'), isNotNull);
    });

    test('2 karakter → valid', () {
      expect(controller.validateName('AB'), isNull);
    });

    test('nama panjang → valid', () {
      expect(controller.validateName('Kursi Plastik Premium'), isNull);
    });
  });

  // ── 2. validatePrice ───────────────────────────────────────────────────────
  group('validatePrice', () {
    late CatalogController controller;

    setUp(() {
      controller = CatalogController(firestore: FakeFirebaseFirestore());
    });

    test('null → error tidak boleh kosong', () {
      expect(controller.validatePrice(null), isNotNull);
    });

    test('string kosong → error tidak boleh kosong', () {
      expect(controller.validatePrice(''), isNotNull);
    });

    test('bukan angka → error angka valid', () {
      expect(controller.validatePrice('abc'), isNotNull);
    });

    test('angka negatif → error tidak boleh negatif', () {
      expect(controller.validatePrice('-1000'), isNotNull);
    });

    test('0 → valid', () {
      expect(controller.validatePrice('0'), isNull);
    });

    test('angka positif → valid', () {
      expect(controller.validatePrice('15000'), isNull);
    });

    test('angka dengan koma → valid (strip koma)', () {
      expect(controller.validatePrice('15,000'), isNull);
    });

    test('angka dengan titik → valid (strip titik)', () {
      expect(controller.validatePrice('15.000'), isNull);
    });
  });

  // ── 3. validateCategory ────────────────────────────────────────────────────
  group('validateCategory', () {
    late CatalogController controller;

    setUp(() {
      controller = CatalogController(firestore: FakeFirebaseFirestore());
    });

    test('null → error tidak boleh kosong', () {
      expect(controller.validateCategory(null), isNotNull);
    });

    test('string kosong → error tidak boleh kosong', () {
      expect(controller.validateCategory(''), isNotNull);
    });

    test('kategori valid → null', () {
      expect(controller.validateCategory('Furniture'), isNull);
    });
  });

  // ── 4. filteredCatalog ─────────────────────────────────────────────────────
  group('filteredCatalog', () {
    late CatalogController controller;
    late List<CatalogModel> items;

    setUp(() {
      controller = CatalogController(firestore: FakeFirebaseFirestore());
      items = [
        _makeItem(id: '1', name: 'Kursi Plastik', category: 'Furniture'),
        _makeItem(id: '2', name: 'Meja Lipat', category: 'Furniture'),
        _makeItem(id: '3', name: 'Tenda Outdoor', category: 'Outdoor'),
        _makeItem(id: '4', name: 'Lampu LED', category: 'Elektronik'),
      ];
    });

    test('tanpa filter → semua item dikembalikan', () {
      final result = controller.filteredCatalog(items);
      expect(result.length, 4);
    });

    test('filter kategori Furniture → 2 item', () {
      controller.setCategory('Furniture');
      final result = controller.filteredCatalog(items);
      expect(result.length, 2);
      expect(result.every((i) => i.category == 'Furniture'), isTrue);
    });

    test('filter kategori Outdoor → 1 item', () {
      controller.setCategory('Outdoor');
      final result = controller.filteredCatalog(items);
      expect(result.length, 1);
      expect(result.first.name, 'Tenda Outdoor');
    });

    test('search nama → menemukan item yang cocok', () {
      controller.setSearchQuery('kursi');
      final result = controller.filteredCatalog(items);
      expect(result.length, 1);
      expect(result.first.name, 'Kursi Plastik');
    });

    test('search kategori → menemukan item berdasar kategori', () {
      controller.setSearchQuery('outdoor');
      final result = controller.filteredCatalog(items);
      expect(result.length, 1);
      expect(result.first.name, 'Tenda Outdoor');
    });

    test('search tidak cocok → hasil kosong', () {
      controller.setSearchQuery('tidakada');
      final result = controller.filteredCatalog(items);
      expect(result, isEmpty);
    });

    test('search + filter kategori → irisan keduanya', () {
      controller.setCategory('Furniture');
      controller.setSearchQuery('meja');
      final result = controller.filteredCatalog(items);
      expect(result.length, 1);
      expect(result.first.name, 'Meja Lipat');
    });

    test('search case-insensitive', () {
      controller.setSearchQuery('KURSI');
      final result = controller.filteredCatalog(items);
      expect(result.length, 1);
    });

    test('list kosong → hasil kosong', () {
      final result = controller.filteredCatalog([]);
      expect(result, isEmpty);
    });
  });

  // ── 5. uniqueCategories ────────────────────────────────────────────────────
  group('uniqueCategories', () {
    late CatalogController controller;

    setUp(() {
      controller = CatalogController(firestore: FakeFirebaseFirestore());
    });

    test('mengembalikan kategori unik', () {
      final items = [
        _makeItem(category: 'Furniture'),
        _makeItem(category: 'Furniture'),
        _makeItem(category: 'Outdoor'),
      ];
      final cats = controller.uniqueCategories(items);
      expect(cats.length, 2);
      expect(cats.toSet(), {'Furniture', 'Outdoor'});
    });

    test('hasil terurut secara alfabetis', () {
      final items = [
        _makeItem(category: 'Outdoor'),
        _makeItem(category: 'Elektronik'),
        _makeItem(category: 'Furniture'),
      ];
      final cats = controller.uniqueCategories(items);
      expect(cats, ['Elektronik', 'Furniture', 'Outdoor']);
    });

    test('list kosong → hasil kosong', () {
      expect(controller.uniqueCategories([]), isEmpty);
    });

    test('1 item → 1 kategori', () {
      expect(controller.uniqueCategories([_makeItem()]).length, 1);
    });
  });

  // ── 6. setSearchQuery & setCategory ───────────────────────────────────────
  group('setSearchQuery dan setCategory', () {
    late CatalogController controller;

    setUp(() {
      controller = CatalogController(firestore: FakeFirebaseFirestore());
    });

    test('setSearchQuery menyimpan query', () {
      controller.setSearchQuery('test');
      expect(controller.searchQuery, 'test');
    });

    test('setCategory menyimpan kategori', () {
      controller.setCategory('Furniture');
      expect(controller.selectedCategory, 'Furniture');
    });

    test('setCategory null → selectedCategory null', () {
      controller.setCategory('Furniture');
      controller.setCategory(null);
      expect(controller.selectedCategory, isNull);
    });
  });

  // ── 7. checkNameExists ─────────────────────────────────────────────────────
  group('checkNameExists', () {
    test('nama belum ada → false', () async {
      final firestore = FakeFirebaseFirestore();
      final controller = CatalogController(firestore: firestore);

      final exists = await controller.checkNameExists('Nama Baru');
      expect(exists, isFalse);
    });

    test('nama sudah ada → true', () async {
      final firestore = FakeFirebaseFirestore();
      await _addItem(firestore, name: 'Kursi Plastik');
      final controller = CatalogController(firestore: firestore);

      final exists = await controller.checkNameExists('Kursi Plastik');
      expect(exists, isTrue);
    });

    test('nama sama tapi excludeId cocok → false (update diri sendiri)', () async {
      final firestore = FakeFirebaseFirestore();
      final id = await _addItem(firestore, name: 'Kursi Plastik');
      final controller = CatalogController(firestore: firestore);

      final exists =
          await controller.checkNameExists('Kursi Plastik', excludeId: id);
      expect(exists, isFalse);
    });

    test('nama sama tapi excludeId berbeda → true (duplikat)', () async {
      final firestore = FakeFirebaseFirestore();
      await _addItem(firestore, name: 'Kursi Plastik');
      final controller = CatalogController(firestore: firestore);

      final exists = await controller.checkNameExists(
        'Kursi Plastik',
        excludeId: 'id-lain',
      );
      expect(exists, isTrue);
    });
  });

  // ── 8. createItem ──────────────────────────────────────────────────────────
  group('createItem', () {
    test('berhasil membuat item baru', () async {
      final firestore = FakeFirebaseFirestore();
      final controller = CatalogController(firestore: firestore);

      final result = await controller.createItem(
        name: 'Meja Baru',
        price: 50000,
        category: 'Furniture',
      );

      expect(result['success'], isTrue);

      final snap = await firestore.collection('catalog').get();
      expect(snap.docs.length, 1);
      expect(snap.docs.first['name'], 'Meja Baru');
    });

    test('nama duplikat → gagal', () async {
      final firestore = FakeFirebaseFirestore();
      await _addItem(firestore, name: 'Kursi Plastik');
      final controller = CatalogController(firestore: firestore);

      final result = await controller.createItem(
        name: 'Kursi Plastik',
        price: 15000,
        category: 'Furniture',
      );

      expect(result['success'], isFalse);
      expect(result['error'], contains('sudah terdaftar'));
    });

    test('item tersimpan dengan data yang benar', () async {
      final firestore = FakeFirebaseFirestore();
      final controller = CatalogController(firestore: firestore);

      await controller.createItem(
        name: 'Lampu LED',
        price: 75000,
        category: 'Elektronik',
      );

      final snap = await firestore.collection('catalog').get();
      final data = snap.docs.first.data();
      expect(data['name'], 'Lampu LED');
      expect(data['price'], 75000.0);
      expect(data['category'], 'Elektronik');
    });

    test('nama di-trim sebelum disimpan', () async {
      final firestore = FakeFirebaseFirestore();
      final controller = CatalogController(firestore: firestore);

      await controller.createItem(
        name: '  Kursi Baru  ',
        price: 10000,
        category: 'Furniture',
      );

      final snap = await firestore.collection('catalog').get();
      expect(snap.docs.first['name'], 'Kursi Baru');
    });
  });

  // ── 9. updateItem ──────────────────────────────────────────────────────────
  group('updateItem', () {
    test('berhasil update item', () async {
      final firestore = FakeFirebaseFirestore();
      final id = await _addItem(firestore, name: 'Kursi Lama', price: 10000);
      final controller = CatalogController(firestore: firestore);

      final result = await controller.updateItem(
        id: id,
        name: 'Kursi Baru',
        price: 20000,
        category: 'Furniture',
      );

      expect(result['success'], isTrue);

      final doc = await firestore.collection('catalog').doc(id).get();
      expect(doc['name'], 'Kursi Baru');
      expect(doc['price'], 20000.0);
    });

    test('nama duplikat (bukan diri sendiri) → gagal', () async {
      final firestore = FakeFirebaseFirestore();
      await _addItem(firestore, name: 'Meja Lipat');
      final id = await _addItem(firestore, name: 'Kursi Plastik');
      final controller = CatalogController(firestore: firestore);

      final result = await controller.updateItem(
        id: id,
        name: 'Meja Lipat', // nama milik item lain
        price: 15000,
        category: 'Furniture',
      );

      expect(result['success'], isFalse);
      expect(result['error'], contains('sudah terdaftar'));
    });

    test('update dengan nama yang sama (diri sendiri) → berhasil', () async {
      final firestore = FakeFirebaseFirestore();
      final id = await _addItem(firestore, name: 'Kursi Plastik', price: 10000);
      final controller = CatalogController(firestore: firestore);

      final result = await controller.updateItem(
        id: id,
        name: 'Kursi Plastik',
        price: 20000, // hanya ubah harga
        category: 'Furniture',
      );

      expect(result['success'], isTrue);
    });
  });

  // ── 10. deleteItem ─────────────────────────────────────────────────────────
  group('deleteItem', () {
    test('berhasil menghapus item dari firestore', () async {
      final firestore = FakeFirebaseFirestore();
      final id = await _addItem(firestore);
      final controller = CatalogController(firestore: firestore);

      final result = await controller.deleteItem(id);

      expect(result['success'], isTrue);

      final doc = await firestore.collection('catalog').doc(id).get();
      expect(doc.exists, isFalse);
    });
  });

  // ── 11. getCatalogStream ───────────────────────────────────────────────────
  group('getCatalogStream', () {
    test('stream mengembalikan data yang ada di firestore', () async {
      final firestore = FakeFirebaseFirestore();
      await _addItem(firestore, name: 'Kursi Plastik');
      final controller = CatalogController(firestore: firestore);

      final snap = await controller.getCatalogStream().first;
      expect(snap.docs.length, 1);
      expect(snap.docs.first['name'], 'Kursi Plastik');
    });

    test('stream kosong jika tidak ada data', () async {
      final firestore = FakeFirebaseFirestore();
      final controller = CatalogController(firestore: firestore);

      final snap = await controller.getCatalogStream().first;
      expect(snap.docs, isEmpty);
    });

    test('stream update saat item baru ditambahkan', () async {
      final firestore = FakeFirebaseFirestore();
      final controller = CatalogController(firestore: firestore);

      final stream = controller.getCatalogStream();

      await _addItem(firestore, name: 'Item Baru');

      final snap = await stream.first;
      expect(snap.docs.length, 1);
    });
  });
}