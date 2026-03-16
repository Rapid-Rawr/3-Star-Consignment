import 'package:cloud_firestore/cloud_firestore.dart';

enum ConsignmentRequestStatus { pending, approved, rejected }

class ConsignmentRequestModel {
  final String id;
  final String catalogId;
  final String catalogName;
  final double catalogPrice;
  final String catalogCategory;
  final String? catalogImagePath;
  final int quantity;
  final String? notes;
  final ConsignmentRequestStatus status;
  final DateTime? createdAt;

  ConsignmentRequestModel({
    required this.id,
    required this.catalogId,
    required this.catalogName,
    required this.catalogPrice,
    required this.catalogCategory,
    this.catalogImagePath,
    required this.quantity,
    this.notes,
    this.status = ConsignmentRequestStatus.pending,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'catalogId': catalogId,
      'catalogName': catalogName,
      'catalogPrice': catalogPrice,
      'catalogCategory': catalogCategory,
      'catalogImagePath': catalogImagePath,
      'quantity': quantity,
      'notes': notes,
      'status': status.name,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory ConsignmentRequestModel.fromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    ConsignmentRequestStatus status;
    switch (map['status'] as String?) {
      case 'approved':
        status = ConsignmentRequestStatus.approved;
        break;
      case 'rejected':
        status = ConsignmentRequestStatus.rejected;
        break;
      default:
        status = ConsignmentRequestStatus.pending;
    }

    return ConsignmentRequestModel(
      id: id,
      catalogId: map['catalogId'] ?? '',
      catalogName: map['catalogName'] ?? '',
      catalogPrice: (map['catalogPrice'] as num?)?.toDouble() ?? 0.0,
      catalogCategory: map['catalogCategory'] ?? '',
      catalogImagePath: map['catalogImagePath'] as String?,
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
      notes: map['notes'] as String?,
      status: status,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
