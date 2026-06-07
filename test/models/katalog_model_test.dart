import 'package:flutter_test/flutter_test.dart';
import 'package:star_consignment/models/barang_models/katalog_model.dart';

void main() {
  group('CatalogModel', () {
    //Apakah data Firestore/Map berhasil diubah menjadi CatalogModel dengan benar
    test('fromMap creates object correctly', () {
      final catalog = CatalogModel.fromMap(
        'item1',
        {
          'name': 'Baju Seragam',
          'price': 150000,
          'category': 'Seragam',
          'imagePath': 'test.jpg',
        },
      );

      expect(catalog.id, 'item1');
      expect(catalog.name, 'Baju Seragam');
      expect(catalog.price, 150000);
      expect(catalog.category, 'Seragam');
      expect(catalog.imagePath, 'test.jpg');
    });

    //Apakah fallback imageUrl bekerja jika imagePath tidak ada
    test('fromMap uses imageUrl when imagePath is missing', () {
      final catalog = CatalogModel.fromMap(
        'item1',
        {
          'name': 'Baju Seragam',
          'price': 150000,
          'category': 'Seragam',
          'imageUrl': 'fallback.jpg',
        },
      );

      expect(catalog.imagePath, 'fallback.jpg');
    });

    //Apakah nilai default digunakan jika field kosong/hilang
    test('fromMap returns default values when fields are missing', () {
      final catalog = CatalogModel.fromMap(
        'item1',
        {},
      );

      expect(catalog.id, 'item1');
      expect(catalog.name, '');
      expect(catalog.price, 0.0);
      expect(catalog.category, '');
      expect(catalog.imagePath, null);
    });

    //Apakah object bisa diubah kembali menjadi Map untuk disimpan ke Firestore
    test('toMap converts object correctly', () {
      final catalog = CatalogModel(
        id: 'item1',
        name: 'Baju Seragam',
        price: 150000,
        category: 'Seragam',
        imagePath: 'test.jpg',
      );

      final map = catalog.toMap();

      expect(map['name'], 'Baju Seragam');
      expect(map['price'], 150000);
      expect(map['category'], 'Seragam');
      expect(map['imagePath'], 'test.jpg');
    });

    //Apakah hanya field tertentu yang berubah
    test('copyWith updates selected fields', () {
      final catalog = CatalogModel(
        id: 'item1',
        name: 'Baju Seragam',
        price: 150000,
        category: 'Seragam',
        imagePath: 'old.jpg',
      );

      final updated = catalog.copyWith(
        name: 'Celana Seragam',
        price: 200000,
      );

      expect(updated.id, 'item1');
      expect(updated.name, 'Celana Seragam');
      expect(updated.price, 200000);
      expect(updated.category, 'Seragam');
      expect(updated.imagePath, 'old.jpg');
    });

    //Apakah gambar bisa diganti
    test('copyWith can replace imagePath', () {
      final catalog = CatalogModel(
        id: 'item1',
        name: 'Baju Seragam',
        price: 150000,
        category: 'Seragam',
        imagePath: 'old.jpg',
      );

      final updated = catalog.copyWith(
        imagePath: 'new.jpg',
      );

      expect(updated.imagePath, 'new.jpg');
    });

    //Apakah gambar bisa dihapus menggunakan clearImage
    test('copyWith can clear imagePath', () {
      final catalog = CatalogModel(
        id: 'item1',
        name: 'Baju Seragam',
        price: 150000,
        category: 'Seragam',
        imagePath: 'old.jpg',
      );

      final updated = catalog.copyWith(
        clearImage: true,
      );

      expect(updated.imagePath, null);
    });
  });
}