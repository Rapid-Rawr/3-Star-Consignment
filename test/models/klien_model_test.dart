import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:star_consignment/models/pengguna_models/klien_model.dart';

void main() {
  // ══════════════════════════════════════════════════════════════════
  // BorrowedItem
  // ══════════════════════════════════════════════════════════════════
  group('BorrowedItem', () {
    final tDate = DateTime(2024, 6, 1);

    final tItem = BorrowedItem(
      catalogId: 'cat-001',
      catalogName: 'Kursi Plastik',
      catalogPrice: 15000,
      catalogCategory: 'Furniture',
      catalogImagePath: 'images/kursi.png',
      quantity: 3,
      lastReceivedAt: tDate,
    );

    // ── toMap ────────────────────────────────────────────────────────
    group('toMap()', () {
      test('menyertakan semua field dengan benar', () {
        final map = tItem.toMap();

        expect(map['catalogId'], 'cat-001');
        expect(map['catalogName'], 'Kursi Plastik');
        expect(map['catalogPrice'], 15000.0);
        expect(map['catalogCategory'], 'Furniture');
        expect(map['catalogImagePath'], 'images/kursi.png');
        expect(map['quantity'], 3);
        expect(map['lastReceivedAt'], isA<Timestamp>());
        expect(
          (map['lastReceivedAt'] as Timestamp).toDate(),
          tDate,
        );
      });

      test('lastReceivedAt null jika tidak diset', () {
        final item = BorrowedItem(
          catalogId: 'cat-002',
          catalogName: 'Meja',
          catalogPrice: 25000,
          catalogCategory: 'Furniture',
          quantity: 1,
        );
        expect(item.toMap()['lastReceivedAt'], isNull);
      });
    });

    // ── fromMap ──────────────────────────────────────────────────────
    group('fromMap()', () {
      test('membuat objek dari map lengkap', () {
        final map = {
          'catalogId': 'cat-001',
          'catalogName': 'Kursi Plastik',
          'catalogPrice': 15000,
          'catalogCategory': 'Furniture',
          'catalogImagePath': 'images/kursi.png',
          'quantity': 3,
          'lastReceivedAt': Timestamp.fromDate(tDate),
        };

        final item = BorrowedItem.fromMap(map);

        expect(item.catalogId, 'cat-001');
        expect(item.catalogName, 'Kursi Plastik');
        expect(item.catalogPrice, 15000.0);
        expect(item.catalogCategory, 'Furniture');
        expect(item.catalogImagePath, 'images/kursi.png');
        expect(item.quantity, 3);
        expect(item.lastReceivedAt, tDate);
      });

      test('nilai default jika field kosong / null', () {
        final item = BorrowedItem.fromMap({});

        expect(item.catalogId, '');
        expect(item.catalogName, '');
        expect(item.catalogPrice, 0.0);
        expect(item.catalogCategory, '');
        expect(item.catalogImagePath, isNull);
        expect(item.quantity, 1); // default quantity = 1
        expect(item.lastReceivedAt, isNull);
      });

      test('catalogPrice dikonversi ke double dari int', () {
        final item = BorrowedItem.fromMap({'catalogPrice': 20000});
        expect(item.catalogPrice, isA<double>());
        expect(item.catalogPrice, 20000.0);
      });
    });

    // ── accumulate ───────────────────────────────────────────────────
    group('accumulate()', () {
      test('menambah quantity dan memperbarui lastReceivedAt', () {
        final newDate = DateTime(2024, 7, 15);
        final accumulated = tItem.accumulate(2, newDate);

        expect(accumulated.quantity, 5); // 3 + 2
        expect(accumulated.lastReceivedAt, newDate);
      });

      test('field lain tidak berubah setelah accumulate', () {
        final newDate = DateTime(2024, 8, 1);
        final accumulated = tItem.accumulate(1, newDate);

        expect(accumulated.catalogId, tItem.catalogId);
        expect(accumulated.catalogName, tItem.catalogName);
        expect(accumulated.catalogPrice, tItem.catalogPrice);
        expect(accumulated.catalogCategory, tItem.catalogCategory);
        expect(accumulated.catalogImagePath, tItem.catalogImagePath);
      });

      test('accumulate dengan qty 0 tidak mengubah quantity', () {
        final accumulated = tItem.accumulate(0, DateTime.now());
        expect(accumulated.quantity, tItem.quantity);
      });
    });

    // ── roundtrip ────────────────────────────────────────────────────
    test('roundtrip toMap → fromMap menghasilkan objek yang sama', () {
      final restored = BorrowedItem.fromMap(tItem.toMap());

      expect(restored.catalogId, tItem.catalogId);
      expect(restored.catalogName, tItem.catalogName);
      expect(restored.catalogPrice, tItem.catalogPrice);
      expect(restored.catalogCategory, tItem.catalogCategory);
      expect(restored.catalogImagePath, tItem.catalogImagePath);
      expect(restored.quantity, tItem.quantity);
      expect(restored.lastReceivedAt, tItem.lastReceivedAt);
    });
  });

  // ══════════════════════════════════════════════════════════════════
  // ClientModel
  // ══════════════════════════════════════════════════════════════════
  group('ClientModel', () {
    final tItems = [
      BorrowedItem(
        catalogId: 'cat-001',
        catalogName: 'Kursi Plastik',
        catalogPrice: 15000,
        catalogCategory: 'Furniture',
        quantity: 2,
      ),
      BorrowedItem(
        catalogId: 'cat-002',
        catalogName: 'Meja Lipat',
        catalogPrice: 50000,
        catalogCategory: 'Furniture',
        quantity: 1,
      ),
    ];

    final tClient = ClientModel(
      id: 'client-001',
      name: 'Budi Santoso',
      phone: '08123456789',
      email: 'budi@example.com',
      address: 'Jl. Merdeka No. 1, Surabaya',
      photoUrl: 'https://example.com/photo.jpg',
      debt: 80000,
      borrowedItems: tItems,
    );

    // ── toMap ────────────────────────────────────────────────────────
    group('toMap()', () {
      test('mengandung semua field dengan benar', () {
        final map = tClient.toMap();

        expect(map['name'], 'Budi Santoso');
        expect(map['phone'], '08123456789');
        expect(map['email'], 'budi@example.com');
        expect(map['address'], 'Jl. Merdeka No. 1, Surabaya');
        expect(map['photoUrl'], 'https://example.com/photo.jpg');
        expect(map['debt'], 80000.0);
        expect(map['borrowedItems'], isA<List>());
        expect((map['borrowedItems'] as List).length, 2);
      });

      test('photoUrl tidak ada di map jika null', () {
        final clientTanpaFoto = tClient.copyWith(photoUrl: null);
        // copyWith tidak bisa clear photoUrl karena pakai ??
        // buat ulang langsung:
        final c = ClientModel(
          id: 'x',
          name: 'Test',
          phone: '0',
          address: 'Addr',
          debt: 0,
          photoUrl: null,
        );
        expect(c.toMap().containsKey('photoUrl'), isFalse);
      });

      test('id tidak disertakan dalam toMap', () {
        expect(tClient.toMap().containsKey('id'), isFalse);
      });
    });

    // ── fromMap ──────────────────────────────────────────────────────
    group('fromMap()', () {
      test('membuat objek dari map lengkap', () {
        final map = tClient.toMap();
        final restored = ClientModel.fromMap('client-001', map);

        expect(restored.id, 'client-001');
        expect(restored.name, 'Budi Santoso');
        expect(restored.phone, '08123456789');
        expect(restored.email, 'budi@example.com');
        expect(restored.address, 'Jl. Merdeka No. 1, Surabaya');
        expect(restored.photoUrl, 'https://example.com/photo.jpg');
        expect(restored.debt, 80000.0);
        expect(restored.borrowedItems.length, 2);
      });

      test('nilai default jika map kosong', () {
        final client = ClientModel.fromMap('id-x', {});

        expect(client.id, 'id-x');
        expect(client.name, '');
        expect(client.phone, '');
        expect(client.email, '');
        expect(client.address, '');
        expect(client.photoUrl, isNull);
        expect(client.debt, 0.0);
        expect(client.borrowedItems, isEmpty);
      });

      test('borrowedItems yang bukan Map diabaikan', () {
        final map = {
          'borrowedItems': ['invalid', 123, null],
        };
        final client = ClientModel.fromMap('id-x', map);
        expect(client.borrowedItems, isEmpty);
      });

      test('debt dikonversi ke double dari int', () {
        final client = ClientModel.fromMap('id-x', {'debt': 100000});
        expect(client.debt, isA<double>());
        expect(client.debt, 100000.0);
      });
    });

    // ── copyWith ─────────────────────────────────────────────────────
    group('copyWith()', () {
      test('mengubah field yang diberikan', () {
        final updated = tClient.copyWith(name: 'Siti', debt: 999);

        expect(updated.name, 'Siti');
        expect(updated.debt, 999.0);
      });

      test('mempertahankan field yang tidak diberikan', () {
        final updated = tClient.copyWith(name: 'Siti');

        expect(updated.id, tClient.id);
        expect(updated.phone, tClient.phone);
        expect(updated.email, tClient.email);
        expect(updated.address, tClient.address);
        expect(updated.photoUrl, tClient.photoUrl);
        expect(updated.borrowedItems, tClient.borrowedItems);
      });

      test('mengubah borrowedItems', () {
        final newItems = [
          BorrowedItem(
            catalogId: 'cat-999',
            catalogName: 'Tenda',
            catalogPrice: 200000,
            catalogCategory: 'Outdoor',
            quantity: 1,
          ),
        ];
        final updated = tClient.copyWith(borrowedItems: newItems);
        expect(updated.borrowedItems.length, 1);
        expect(updated.borrowedItems.first.catalogName, 'Tenda');
      });
    });

    // ── computedDebt ─────────────────────────────────────────────────
    group('computedDebt', () {
      test('menghitung total hutang dari borrowedItems', () {
        // (15000 × 2) + (50000 × 1) = 80000
        expect(tClient.computedDebt, 80000.0);
      });

      test('computedDebt = 0 jika borrowedItems kosong', () {
        final client = ClientModel(
          id: 'x',
          name: 'Empty',
          phone: '0',
          address: 'Addr',
          debt: 0,
        );
        expect(client.computedDebt, 0.0);
      });

      test('computedDebt akurat dengan banyak item', () {
        final items = List.generate(
          5,
          (i) => BorrowedItem(
            catalogId: 'cat-$i',
            catalogName: 'Item $i',
            catalogPrice: 10000,
            catalogCategory: 'Misc',
            quantity: i + 1, // 1,2,3,4,5
          ),
        );
        final client = ClientModel(
          id: 'x',
          name: 'Multi',
          phone: '0',
          address: 'Addr',
          debt: 0,
          borrowedItems: items,
        );
        // 10000*(1+2+3+4+5) = 150000
        expect(client.computedDebt, 150000.0);
      });
    });

    // ── roundtrip ────────────────────────────────────────────────────
    test('roundtrip toMap → fromMap menghasilkan objek yang ekuivalen', () {
      final map = tClient.toMap();
      final restored = ClientModel.fromMap(tClient.id, map);

      expect(restored.id, tClient.id);
      expect(restored.name, tClient.name);
      expect(restored.phone, tClient.phone);
      expect(restored.email, tClient.email);
      expect(restored.address, tClient.address);
      expect(restored.photoUrl, tClient.photoUrl);
      expect(restored.debt, tClient.debt);
      expect(restored.borrowedItems.length, tClient.borrowedItems.length);
      expect(restored.computedDebt, tClient.computedDebt);
    });
  });
}
