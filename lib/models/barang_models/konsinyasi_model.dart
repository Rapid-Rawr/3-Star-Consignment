import 'package:cloud_firestore/cloud_firestore.dart';

enum ConsignmentItemStatus { pending, approved, partial, rejected }

enum ConsignmentBatchStatus { pending, processing, packed, received, rejected }

class ConsignmentItemEntry {
  final String catalogId;
  final String catalogName;
  final double catalogPrice;
  final String catalogCategory;
  final String? catalogImagePath;
  final int quantity;
  final int? approvedQty;
  final ConsignmentItemStatus itemStatus;

  const ConsignmentItemEntry({
    required this.catalogId,
    required this.catalogName,
    required this.catalogPrice,
    required this.catalogCategory,
    this.catalogImagePath,
    required this.quantity,
    this.approvedQty,
    this.itemStatus = ConsignmentItemStatus.pending,
  });

  Map<String, dynamic> toMap() => {
    'catalogId': catalogId,
    'catalogName': catalogName,
    'catalogPrice': catalogPrice,
    'catalogCategory': catalogCategory,
    'catalogImagePath': catalogImagePath,
    'quantity': quantity,
    'approvedQty': approvedQty,
    'itemStatus': itemStatus.name,
  };

  factory ConsignmentItemEntry.fromMap(Map<String, dynamic> map) {
    final status =
        ConsignmentItemStatus.values.asNameMap()[map['itemStatus'] as String?] ??
        ConsignmentItemStatus.pending;
    return ConsignmentItemEntry(
      catalogId: map['catalogId'] ?? '',
      catalogName: map['catalogName'] ?? '',
      catalogPrice: (map['catalogPrice'] as num?)?.toDouble() ?? 0.0,
      catalogCategory: map['catalogCategory'] ?? '',
      catalogImagePath: map['catalogImagePath'] as String?,
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
      approvedQty: (map['approvedQty'] as num?)?.toInt(),
      itemStatus: status,
    );
  }

  ConsignmentItemEntry copyWith({
    ConsignmentItemStatus? itemStatus,
    Object? approvedQty = _unset,
  }) {
    return ConsignmentItemEntry(
      catalogId: catalogId,
      catalogName: catalogName,
      catalogPrice: catalogPrice,
      catalogCategory: catalogCategory,
      catalogImagePath: catalogImagePath,
      quantity: quantity,
      approvedQty: approvedQty == _unset
          ? this.approvedQty
          : approvedQty as int?,
      itemStatus: itemStatus ?? this.itemStatus,
    );
  }
}

const Object _unset = Object();

class ConsignmentRequestModel {
  final String id;

  // Client fields (denormalized — same pattern as payment_history)
  final String clientId;
  final String clientName;
  final String clientAddress;
  final String clientEmail;

  // Legacy field — kept for backward compatibility with old Firestore documents
  // Used as fallback in receiveBatch when clientId is not yet stored
  final String? userEmail;

  final ConsignmentBatchStatus status;
  final List<ConsignmentItemEntry> items;
  final String? packedBy;
  final String? receivedBy;
  final DateTime? receivedAt;
  final DateTime? createdAt;

  const ConsignmentRequestModel({
    required this.id,
    required this.clientId,
    required this.clientName,
    this.clientAddress = '',
    required this.clientEmail,
    this.userEmail,
    this.status = ConsignmentBatchStatus.pending,
    required this.items,
    this.packedBy,
    this.receivedBy,
    this.receivedAt,
    this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'clientId': clientId,
    'clientName': clientName,
    'clientAddress': clientAddress,
    'clientEmail': clientEmail,
    'status': status.name,
    'items': items.map((e) => e.toMap()).toList(),
    'packedBy': packedBy,
    'receivedBy': receivedBy,
    'receivedAt': receivedAt != null ? Timestamp.fromDate(receivedAt!) : null,
    'createdAt': FieldValue.serverTimestamp(),
  };

  factory ConsignmentRequestModel.fromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    final batchStatus =
        ConsignmentBatchStatus.values.asNameMap()[map['status'] as String?] ??
        ConsignmentBatchStatus.pending;

    final rawItems = map['items'] as List<dynamic>? ?? [];
    final items = rawItems
        .whereType<Map<String, dynamic>>()
        .map(ConsignmentItemEntry.fromMap)
        .toList();

    // Backward compatibility: read new fields with fallback to old field names
    final clientId =
        (map['clientId'] as String?)?.isNotEmpty == true
            ? map['clientId'] as String
            : (map['userId'] as String? ?? '');

    final clientName =
        (map['clientName'] as String?)?.isNotEmpty == true
            ? map['clientName'] as String
            : (map['userName'] as String? ?? '');

    final clientAddress =
        (map['clientAddress'] as String?)?.isNotEmpty == true
            ? map['clientAddress'] as String
            : (map['userSchool'] as String? ?? '');

    final clientEmail =
        (map['clientEmail'] as String?)?.isNotEmpty == true
            ? map['clientEmail'] as String
            : (map['userEmail'] as String? ?? '');

    // Keep userEmail for legacy receiveBatch fallback
    final userEmail = map['userEmail'] as String?;
    // clientPhotoUrl is now stored in clients collection, not in request documents

    return ConsignmentRequestModel(
      id: id,
      clientId: clientId,
      clientName: clientName,
      clientAddress: clientAddress,
      clientEmail: clientEmail,
      userEmail: userEmail,
      status: batchStatus,
      items: items,
      packedBy: map['packedBy'] as String?,
      receivedBy: map['receivedBy'] as String?,
      receivedAt: (map['receivedAt'] as Timestamp?)?.toDate(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  ConsignmentRequestModel copyWithItems(List<ConsignmentItemEntry> newItems) {
    return ConsignmentRequestModel(
      id: id,
      clientId: clientId,
      clientName: clientName,
      clientAddress: clientAddress,
      clientEmail: clientEmail,
      userEmail: userEmail,
      status: status,
      items: newItems,
      packedBy: packedBy,
      createdAt: createdAt,
    );
  }
}
