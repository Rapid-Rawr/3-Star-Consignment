class OperatorModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? photoUrl;

  OperatorModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.photoUrl,
  });

  Map<String, dynamic> toMap() {
    return {'username': name, 'gmail': email, 'Role': role};
  }

  factory OperatorModel.fromMap(String id, Map<String, dynamic> map) {
    return OperatorModel(
      id: id,
      name: map['username'] ?? '',
      email: map['gmail'] ?? '',
      role: map['Role'] ?? '',
      photoUrl: map['photoUrl'] as String?,
    );
  }

  OperatorModel copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    String? photoUrl,
  }) {
    return OperatorModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }
}
