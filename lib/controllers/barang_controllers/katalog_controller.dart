import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/barang_models/katalog_model.dart';
import '../../utils/supabase_service.dart';

class CatalogController {
  final FirebaseFirestore firestore;
  final String collectionName = 'catalog';

  String searchQuery = '';
  String? selectedCategory;

  CatalogController({required this.firestore});

  Stream<QuerySnapshot> getCatalogStream() {
    return firestore
        .collection(collectionName)
        .snapshots();
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
    XFile? imageFile,
  }) async {
    try {
      final docRef = await firestore.collection(collectionName).add({
        'name': name.trim(),
        'price': price,
        'category': category.trim(),
        'imagePath': null,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (imageFile != null) {
        final path = await SupabaseService.uploadCatalogImage(
          catalogId: docRef.id,
          imageFile: imageFile,
        );
        if (path != null) {
          await docRef.update({'imagePath': path});
        }
      }

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
    XFile? newImageFile,
    String? oldImagePath,
    bool removeImage = false,
  }) async {
    try {
      String? finalImagePath = oldImagePath;

      if (removeImage) {
        await SupabaseService.deleteCatalogImage(oldImagePath);
        finalImagePath = null;
      } else if (newImageFile != null) {
        final uploaded = await SupabaseService.uploadCatalogImage(
          catalogId: id,
          imageFile: newImageFile,
        );
        if (uploaded != null) {
          if (oldImagePath != null && oldImagePath.isNotEmpty) {
            await SupabaseService.deleteCatalogImage(oldImagePath);
          }
          finalImagePath = uploaded;
        }
      }

      await firestore.collection(collectionName).doc(id).update({
        'name': name.trim(),
        'price': price,
        'category': category.trim(),
        'imagePath': finalImagePath,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return {'success': true};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> deleteItem(String id) async {
    try {
      await SupabaseService.deleteCatalogFolder(id);
      await firestore.collection(collectionName).doc(id).delete();
      return {'success': true};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}
