import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/pengguna_models/operator_model.dart';

class OperatorController {
  final FirebaseFirestore firestore;
  final String collectionName = 'users';

  String searchQuery = '';
  String? selectedRoleFilter;

  OperatorController({required this.firestore});

  Stream<QuerySnapshot> getOperatorsStream() {
    return firestore
        .collection(collectionName)
        .snapshots(includeMetadataChanges: true);
  }

  void setRoleFilter(String? role) {
    selectedRoleFilter = role;
  }

  void setSearchQuery(String query) {
    searchQuery = query;
  }

  List<OperatorModel> filteredOperators(List<OperatorModel> operators) {
    var filtered = operators;

    if (selectedRoleFilter != null && selectedRoleFilter!.isNotEmpty) {
      filtered = filtered
          .where((operator) => operator.role == selectedRoleFilter)
          .toList();
    }

    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      filtered = filtered.where((operator) {
        return operator.name.toLowerCase().contains(query) ||
            operator.email.toLowerCase().contains(query) ||
            operator.role.toLowerCase().contains(query);
      }).toList();
    }

    return filtered;
  }

  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email tidak boleh kosong';
    }
    if (!value.contains('@')) {
      return 'Email harus mengandung @';
    }
    if (!value.endsWith('@gmail.com')) {
      return 'Email harus menggunakan @gmail.com';
    }
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@gmail\.com$');
    if (!emailRegex.hasMatch(value)) {
      return 'Format email tidak valid';
    }
    return null;
  }

  String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Nama tidak boleh kosong';
    }
    if (value.length < 2) {
      return 'Nama minimal 2 karakter';
    }
    if (value.length > 50) {
      return 'Nama maksimal 50 karakter';
    }
    return null;
  }

  String? validateRole(String? value) {
    if (value == null || value.isEmpty) {
      return 'Role harus dipilih';
    }
    return null;
  }

  String formatDisplayName(String name) {
    if (name.length <= 12) {
      return name;
    }
    return '${name.substring(0, 9)}...';
  }

  Future<bool> checkEmailExists(String email, {String? excludeId}) async {
    final emailQuery = await firestore
        .collection(collectionName)
        .where('gmail', isEqualTo: email.toLowerCase())
        .get();

    if (excludeId != null) {
      return emailQuery.docs.any((doc) => doc.id != excludeId);
    }

    return emailQuery.docs.isNotEmpty;
  }

  Future<Map<String, dynamic>> createOperator({
    required String name,
    required String email,
    required String role,
  }) async {
    try {
      final emailExists = await checkEmailExists(email);
      if (emailExists) {
        return {'success': false, 'error': 'Email sudah terdaftar'};
      }

      await firestore.collection(collectionName).add({
        'username': name.trim(),
        'gmail': email.trim().toLowerCase(),
        'Role': role,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return {'success': true};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updateOperator({
    required String id,
    required String name,
    required String email,
    required String role,
  }) async {
    try {
      final emailExists = await checkEmailExists(email, excludeId: id);
      if (emailExists) {
        return {'success': false, 'error': 'Email sudah terdaftar'};
      }

      await firestore.collection(collectionName).doc(id).update({
        'username': name.trim(),
        'gmail': email.trim().toLowerCase(),
        'Role': role,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return {'success': true};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> deleteOperator(String id) async {
    try {
      await firestore.collection(collectionName).doc(id).delete();
      return {'success': true};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}
