import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/pembayaran_models/pembayaran_model.dart';

/// Handles delivery history records in the [delivery_history] Firestore collection.
/// Reuses [PembayaranModel] and [PaidItem] as the data shape is identical.
class PenyerahanController {
  final FirebaseFirestore firestore;
  final String collectionName = 'delivery_history';

  PenyerahanController({required this.firestore});

  Stream<QuerySnapshot> getDeliveriesStream() {
    return firestore
        .collection(collectionName)
        .orderBy('deliveredAt', descending: true)
        .snapshots();
  }

  Future<Map<String, dynamic>> createDelivery({
    required String clientId,
    required String clientName,
    required String clientAddress,
    required List<PaidItem> items,
    required double totalAmount,
  }) async {
    try {
      await firestore.collection(collectionName).add({
        'clientId': clientId,
        'clientName': clientName,
        'clientAddress': clientAddress,
        'items': items.map((i) => i.toMap()).toList(),
        'totalAmount': totalAmount,
        'deliveredAt': FieldValue.serverTimestamp(),
      });
      return {'success': true};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}
