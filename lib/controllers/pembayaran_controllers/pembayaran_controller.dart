import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/pembayaran_models/pembayaran_model.dart';
import '../../service/roles.dart';

class PaymentController {
  final FirebaseFirestore firestore;
  final String collectionName = 'payment_history';

  PaymentController({required this.firestore});

  Stream<QuerySnapshot> getPaymentsStream() {
    return firestore
        .collection(collectionName)
        .orderBy('paidAt', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> getPaymentsStreamForUser(String email) {
    return firestore
        .collection(collectionName)
        .where('clientEmail', isEqualTo: email)
        .orderBy('paidAt', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> getPaymentsByRole({
    required String role,
    required String email,
  }) {
    if (role == Roles.admin || role == Roles.karyawan) {
      return getPaymentsStream();
    }
    return getPaymentsStreamForUser(email);
  }

  Future<Map<String, dynamic>> createPayment({
    required String clientId,
    required String clientName,
    required String clientAddress,
    required String clientEmail,
    required String paymentMethod,
    required List<PaidItem> items,
    required double totalAmount,
    String? confirmedBy,
  }) async {
    try {
      await firestore.collection(collectionName).add({
        'clientId': clientId,
        'clientName': clientName,
        'clientAddress': clientAddress,
        'clientEmail': clientEmail,
        'paymentMethod': paymentMethod,
        'items': items.map((i) => i.toMap()).toList(),
        'totalAmount': totalAmount,
        'paidAt': FieldValue.serverTimestamp(),
        if (confirmedBy != null && confirmedBy.isNotEmpty)
          'confirmedBy': confirmedBy,
      });
      return {'success': true};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}
