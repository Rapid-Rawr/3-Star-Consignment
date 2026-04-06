import 'package:cloud_firestore/cloud_firestore.dart';

class PaidItem {
  final String catalogName;
  final String catalogCategory;
  final String? catalogImagePath;
  final double catalogPrice;
  final int quantity;

  const PaidItem({
    required this.catalogName,
    required this.catalogCategory,
    this.catalogImagePath,
    required this.catalogPrice,
    required this.quantity,
  });

  Map<String, dynamic> toMap() => {
    'catalogName': catalogName,
    'catalogCategory': catalogCategory,
    'catalogImagePath': catalogImagePath,
    'catalogPrice': catalogPrice,
    'quantity': quantity,
  };

  factory PaidItem.fromMap(Map<String, dynamic> m) => PaidItem(
    catalogName: m['catalogName'] ?? '',
    catalogCategory: m['catalogCategory'] ?? '',
    catalogImagePath: m['catalogImagePath'] as String?,
    catalogPrice: (m['catalogPrice'] as num?)?.toDouble() ?? 0.0,
    quantity: (m['quantity'] as num?)?.toInt() ?? 0,
  );
}

class PembayaranModel {
  final String id;
  final String clientId;
  final String clientName;
  final String clientAddress;
  final String paymentMethod; // 'cash', 'transfer', dll
  final List<PaidItem> items;
  final double totalAmount;
  final DateTime? paidAt;

  const PembayaranModel({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.clientAddress,
    required this.paymentMethod,
    required this.items,
    required this.totalAmount,
    this.paidAt,
  });

  Map<String, dynamic> toMap() => {
    'clientId': clientId,
    'clientName': clientName,
    'clientAddress': clientAddress,
    'paymentMethod': paymentMethod,
    'items': items.map((i) => i.toMap()).toList(),
    'totalAmount': totalAmount,
    'paidAt': paidAt != null ? Timestamp.fromDate(paidAt!) : null,
  };

  factory PembayaranModel.fromMap(String id, Map<String, dynamic> m) {
    final rawItems = m['items'] as List<dynamic>? ?? [];
    return PembayaranModel(
      id: id,
      clientId: m['clientId'] ?? '',
      clientName: m['clientName'] ?? '',
      clientAddress: m['clientAddress'] ?? '',
      paymentMethod: m['paymentMethod'] ?? 'cash',
      items: rawItems
          .whereType<Map<String, dynamic>>()
          .map(PaidItem.fromMap)
          .toList(),
      totalAmount: (m['totalAmount'] as num?)?.toDouble() ?? 0.0,
      paidAt: (m['paidAt'] as Timestamp?)?.toDate(),
    );
  }
}
