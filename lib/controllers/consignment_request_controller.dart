import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/catalog_model.dart';
import '../models/consignment_request_model.dart';

class ConsignmentRequestController {
  final FirebaseFirestore firestore;
  final String collectionName = 'consignment_requests';

  ConsignmentRequestController({required this.firestore});

  Stream<QuerySnapshot> getRequestsStream() {
    return firestore
        .collection(collectionName)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  String? validateQuantity(String? value) {
    if (value == null || value.isEmpty) return 'Jumlah tidak boleh kosong';
    final parsed = int.tryParse(value);
    if (parsed == null) return 'Masukkan angka yang valid';
    if (parsed <= 0) return 'Jumlah minimal 1';
    return null;
  }

  Future<Map<String, dynamic>> createRequest({
    required CatalogModel catalog,
    required int quantity,
    String? notes,
  }) async {
    try {
      await firestore.collection(collectionName).add(
        ConsignmentRequestModel(
          id: '',
          catalogId: catalog.id,
          catalogName: catalog.name,
          catalogPrice: catalog.price,
          catalogCategory: catalog.category,
          catalogImagePath: catalog.imagePath,
          quantity: quantity,
          notes: notes?.trim().isEmpty == true ? null : notes?.trim(),
        ).toMap(),
      );
      return {'success': true};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updateStatus({
    required String id,
    required ConsignmentRequestStatus status,
  }) async {
    try {
      await firestore.collection(collectionName).doc(id).update({
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return {'success': true};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> deleteRequest(String id) async {
    try {
      await firestore.collection(collectionName).doc(id).delete();
      return {'success': true};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}
