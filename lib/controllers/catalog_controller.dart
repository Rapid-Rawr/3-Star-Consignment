import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/catalog_model.dart';

class CatalogController {
  final FirebaseFirestore firestore;
  final String collectionName = 'catalog';

  String searchQuery = '';
  String? selectedCategory;

  CatalogController({required this.firestore});

  Stream<QuerySnapshot> getCatalogStream() {
    return firestore
        .collection(collectionName)
        .snapshots(includeMetadataChanges: true);
  }

  void setSearchQuery(String query) => searchQuery = query;
  void setCategory(String? category) => selectedCategory = category;

  List<CatalogModel> filteredCatalog(List<CatalogModel> items) {
    var result = items;
    if (selectedCategory != null) {
      result = result.where((i) => i.category == selectedCategory).toList();
    }
    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      result = result.where((i) {
        return i.name.toLowerCase().contains(q) ||
            i.category.toLowerCase().contains(q);
      }).toList();
    }
    return result;
  }

  List<String> uniqueCategories(List<CatalogModel> items) {
    return items.map((i) => i.category).toSet().toList()..sort();
  }

  String? validateName(String? value) {
    if (value == null || value.isEmpty) return 'Nama tidak boleh kosong';
    if (value.length < 2) return 'Nama minimal 2 karakter';
    return null;
  }

  String? validatePrice(String? value) {
    if (value == null || value.isEmpty) return 'Harga tidak boleh kosong';
    final parsed = double.tryParse(
      value.replaceAll(',', '').replaceAll('.', ''),
    );
    if (parsed == null) return 'Masukkan angka yang valid';
    if (parsed < 0) return 'Harga tidak boleh negatif';
    return null;
  }

  String? validateCategory(String? value) {
    if (value == null || value.isEmpty) return 'Kategori tidak boleh kosong';
    return null;
  }

  Future<Map<String, dynamic>> createItem({
    required String name,
    required double price,
    required String category,
  }) async {
    try {
      await firestore.collection(collectionName).add({
        'name': name.trim(),
        'price': price,
        'category': category.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      return {'success': true};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updateItem({
    required String id,
    required String name,
    required double price,
    required String category,
  }) async {
    try {
      await firestore.collection(collectionName).doc(id).update({
        'name': name.trim(),
        'price': price,
        'category': category.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return {'success': true};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> deleteItem(String id) async {
    try {
      await firestore.collection(collectionName).doc(id).delete();
      return {'success': true};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}
