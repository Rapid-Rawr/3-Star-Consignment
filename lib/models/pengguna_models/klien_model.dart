import 'package:cloud_firestore/cloud_firestore.dart';

class ClientModel {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String address;
  final String? photoUrl;
  final double debt;
  final List<BorrowedItem> borrowedItems;

  ClientModel({
    required this.id,
    required this.name,
    required this.phone,
    this.email = '',
    required this.address,
    this.photoUrl,
    required this.debt,
    this.borrowedItems = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      if (photoUrl != null) 'photoUrl': photoUrl,
      'debt': debt,
      'borrowedItems': borrowedItems.map((b) => b.toMap()).toList(),
    };
  }

  factory ClientModel.fromMap(String id, Map<String, dynamic> map) {
    final rawBorrowed = map['borrowedItems'] as List<dynamic>? ?? [];
    final borrowed = rawBorrowed
        .whereType<Map<String, dynamic>>()
        .map(BorrowedItem.fromMap)
        .toList();
    return ClientModel(
      id: id,
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      address: map['address'] ?? '',
      photoUrl: map['photoUrl'] as String?,
      debt: (map['debt'] as num?)?.toDouble() ?? 0.0,
      borrowedItems: borrowed,
    );
  }

  ClientModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? address,
    String? photoUrl,
    double? debt,
    List<BorrowedItem>? borrowedItems,
  }) {
    return ClientModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      photoUrl: photoUrl ?? this.photoUrl,
      debt: debt ?? this.debt,
      borrowedItems: borrowedItems ?? this.borrowedItems,
    );
  }

  double get computedDebt => borrowedItems.fold(
    0.0,
    (sum, item) => sum + item.catalogPrice * item.quantity,
  );
}

class BorrowedItem {
  final String catalogId;
  final String catalogName;
  final double catalogPrice;
  final String catalogCategory;
  final String? catalogImagePath;
  final int quantity;
  final DateTime? lastReceivedAt;

  const BorrowedItem({
    required this.catalogId,
    required this.catalogName,
    required this.catalogPrice,
    required this.catalogCategory,
    this.catalogImagePath,
    required this.quantity,
    this.lastReceivedAt,
  });

  Map<String, dynamic> toMap() => {
    'catalogId': catalogId,
    'catalogName': catalogName,
    'catalogPrice': catalogPrice,
    'catalogCategory': catalogCategory,
    'catalogImagePath': catalogImagePath,
    'quantity': quantity,
    'lastReceivedAt': lastReceivedAt != null
        ? Timestamp.fromDate(lastReceivedAt!)
        : null,
  };

  factory BorrowedItem.fromMap(Map<String, dynamic> map) => BorrowedItem(
    catalogId: map['catalogId'] ?? '',
    catalogName: map['catalogName'] ?? '',
    catalogPrice: (map['catalogPrice'] as num?)?.toDouble() ?? 0.0,
    catalogCategory: map['catalogCategory'] ?? '',
    catalogImagePath: map['catalogImagePath'] as String?,
    quantity: (map['quantity'] as num?)?.toInt() ?? 1,
    lastReceivedAt: (map['lastReceivedAt'] as Timestamp?)?.toDate(),
  );

  BorrowedItem accumulate(int addQty, DateTime receivedAt) => BorrowedItem(
    catalogId: catalogId,
    catalogName: catalogName,
    catalogPrice: catalogPrice,
    catalogCategory: catalogCategory,
    catalogImagePath: catalogImagePath,
    quantity: quantity + addQty,
    lastReceivedAt: receivedAt,
  );
}
