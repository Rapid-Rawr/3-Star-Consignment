import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/pembayaran_models/pembayaran_model.dart';

class PembayaranController {
  final FirebaseFirestore firestore;
  final String collectionName = 'payment_history';

  PembayaranController({required this.firestore});

  Stream<QuerySnapshot> getPaymentsStream() {
    return firestore
        .collection(collectionName)
        .orderBy('paidAt', descending: true)
        .snapshots();
  }

  Future<Map<String, dynamic>> createPayment({
    required String clientId,
    required String clientName,
    required String clientAddress,
    required String paymentMethod,
    required List<PaidItem> items,
    required double totalAmount,
  }) async {
    try {
      await firestore.collection(collectionName).add({
        'clientId': clientId,
        'clientName': clientName,
        'clientAddress': clientAddress,
        'paymentMethod': paymentMethod,
        'items': items.map((i) => i.toMap()).toList(),
        'totalAmount': totalAmount,
        'paidAt': FieldValue.serverTimestamp(),
      });
      return {'success': true};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}
