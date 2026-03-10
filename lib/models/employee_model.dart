class EmployeeModel {
  final String id;
  final String name;
  final String email;
  final String role;

  EmployeeModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });

  Map<String, dynamic> toMap() {
    return {'username': name, 'gmail': email, 'Role': role};
  }

  factory EmployeeModel.fromMap(String id, Map<String, dynamic> map) {
    return EmployeeModel(
      id: id,
      name: map['username'] ?? '',
      email: map['gmail'] ?? '',
      role: map['Role'] ?? '',
    );
  }

  EmployeeModel copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
  }) {
    return EmployeeModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
    );
  }
}
