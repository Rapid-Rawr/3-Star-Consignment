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
  if (value == null || value.trim().isEmpty) return 'Nama tidak boleh kosong';
  if (value.trim().length < 2) return 'Nama minimal 2 karakter';
  return null;
}

  String? validatePrice(String? value) {
    if (value == null || value.isEmpty) return 'Harga tidak boleh kosong';
    final parsed = double.tryParse(
      value.replaceAll(',', '').replaceAll('.', ''),
    );
    if (parsed == null) return 'Masukkan angka yang valid';
    if (parsed <= 0) return 'Harga tidak boleh negatif';
    return null;
  }

  String? validateCategory(String? value) {
    if (value == null || value.isEmpty) return 'Kategori tidak boleh kosong';
    return null;
  }

  Future<bool> checkNameExists(String name, {String? excludeId}) async {
    final query = await firestore
        .collection(collectionName)
        .where('name', isEqualTo: name.trim())
        .get();

    if (excludeId != null) {
      return query.docs.any((doc) => doc.id != excludeId);
    }
    return query.docs.isNotEmpty;
  }

  Future<Map<String, dynamic>> createItem({
    required String name,
    required double price,
    required String category,
    XFile? imageFile,
  }) async {
    try {
      final nameExists = await checkNameExists(name);
      if (nameExists) return {'success': false, 'error': 'Nama barang sudah terdaftar'};

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
      final nameExists = await checkNameExists(name, excludeId: id);
      if (nameExists) return {'success': false, 'error': 'Nama barang sudah terdaftar'};

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

      if (finalImagePath != oldImagePath) {
        await _propagateImageUpdate(catalogId: id, newImagePath: finalImagePath);
      }

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

  Future<void> _propagateImageUpdate({
    required String catalogId,
    required String? newImagePath,
  }) async {
    try {
      final batch = firestore.batch();
      int operations = 0;
      const maxBatchSize = 500;

      final consignments = await firestore.collection('consignment_requests').get();
      for (final doc in consignments.docs) {
        if (operations >= maxBatchSize) break;
        
        final items = List<Map<String, dynamic>>.from(doc.data()['items'] ?? []);
        bool modified = false;

        for (int i = 0; i < items.length; i++) {
          if (items[i]['catalogId'] == catalogId) {
            items[i]['catalogImagePath'] = newImagePath;
            modified = true;
          }
        }

        if (modified) {
          batch.update(doc.reference, {'items': items});
          operations++;
        }
      }

      final clients = await firestore.collection('clients').get();
      for (final doc in clients.docs) {
        if (operations >= maxBatchSize) break;
        
        final borrowed = List<Map<String, dynamic>>.from(doc.data()['borrowedItems'] ?? []);
        bool modified = false;

        for (int i = 0; i < borrowed.length; i++) {
          if (borrowed[i]['catalogId'] == catalogId) {
            borrowed[i]['catalogImagePath'] = newImagePath;
            modified = true;
          }
        }

        if (modified) {
          batch.update(doc.reference, {'borrowedItems': borrowed});
          operations++;
        }
      }

      if (operations > 0) {
        await batch.commit();
      }
    } catch (e) {
      print('Error propagating image update: $e');
    }
  }
}
