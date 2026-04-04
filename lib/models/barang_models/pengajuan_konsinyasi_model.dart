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
  final String userId;
  final String userName;
  final String userEmail;
  final String userSchool;
  final ConsignmentBatchStatus status;
  final List<ConsignmentItemEntry> items;
  final String? packedBy;
  final String? receivedBy;
  final DateTime? receivedAt;
  final DateTime? createdAt;

  const ConsignmentRequestModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    this.userSchool = '',
    this.status = ConsignmentBatchStatus.pending,
    required this.items,
    this.packedBy,
    this.receivedBy,
    this.receivedAt,
    this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'userName': userName,
    'userEmail': userEmail,
    'userSchool': userSchool,
    'status': status.name,
    'items': items.map((e) => e.toMap()).toList(),
    'packedBy': packedBy,
    'receivedBy': receivedBy,
    'receivedAt': receivedAt != null ? Timestamp.fromDate(receivedAt!) : null,
    'createdAt': FieldValue.serverTimestamp(),
  };

  factory ConsignmentRequestModel.fromMap(String id, Map<String, dynamic> map) {
    final batchStatus =
        ConsignmentBatchStatus.values.asNameMap()[map['status'] as String?] ??
        ConsignmentBatchStatus.pending;

    final rawItems = map['items'] as List<dynamic>? ?? [];
    final items = rawItems
        .whereType<Map<String, dynamic>>()
        .map(ConsignmentItemEntry.fromMap)
        .toList();

    return ConsignmentRequestModel(
      id: id,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userEmail: map['userEmail'] ?? '',
      userSchool: map['userSchool'] ?? '',
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
      userId: userId,
      userName: userName,
      userEmail: userEmail,
      userSchool: userSchool,
      status: status,
      items: newItems,
      packedBy: packedBy,
      createdAt: createdAt,
    );
  }
}
