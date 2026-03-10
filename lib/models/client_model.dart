class ClientModel {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String address;
  final double debt;

  ClientModel({
    required this.id,
    required this.name,
    required this.phone,
    this.email = '',
    required this.address,
    required this.debt,
  });

  Map<String, dynamic> toMap() {
    return {'name': name, 'phone': phone, 'email': email, 'address': address, 'debt': debt};
  }

  factory ClientModel.fromMap(String id, Map<String, dynamic> map) {
    return ClientModel(
      id: id,
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      address: map['address'] ?? '',
      debt: (map['debt'] as num?)?.toDouble() ?? 0.0,
    );
  }

  ClientModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? address,
    double? debt,
  }) {
    return ClientModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      debt: debt ?? this.debt,
    );
  }
}
