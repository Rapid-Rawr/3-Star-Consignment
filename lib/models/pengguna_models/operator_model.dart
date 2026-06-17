class OperatorModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? photoUrl;
  final bool pendingDelete;

  OperatorModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.photoUrl,
    this.pendingDelete = false,
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
      pendingDelete: map['pendingDelete'] == true,
    );
  }

  OperatorModel copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    String? photoUrl,
    bool? pendingDelete,
  }) {
    return OperatorModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      photoUrl: photoUrl ?? this.photoUrl,
      pendingDelete: pendingDelete ?? this.pendingDelete,
    );
  }
}