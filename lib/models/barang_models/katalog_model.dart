class CatalogModel {
  final String id;
  final String name;
  final double price;
  final String category;
  final String? imagePath;

  CatalogModel({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    this.imagePath,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'category': category,
      'imagePath': imagePath,
    };
  }

  factory CatalogModel.fromMap(String id, Map<String, dynamic> map) {
    return CatalogModel(
      id: id,
      name: map['name'] ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      category: map['category'] ?? '',
      imagePath: (map['imagePath'] ?? map['imageUrl']) as String?,
    );
  }

  CatalogModel copyWith({
    String? id,
    String? name,
    double? price,
    String? category,
    String? imagePath,
    bool clearImage = false,
  }) {
    return CatalogModel(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      category: category ?? this.category,
      imagePath: clearImage ? null : (imagePath ?? this.imagePath),
    );
  }
}
