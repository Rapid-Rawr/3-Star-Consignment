import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/client_model.dart';

class ClientController {
  final FirebaseFirestore firestore;
  final String collectionName = 'clients';

  String searchQuery = '';

  ClientController({required this.firestore});

  Stream<QuerySnapshot> getClientsStream() {
    return firestore
        .collection(collectionName)
        .snapshots(includeMetadataChanges: true);
  }

  void setSearchQuery(String query) {
    searchQuery = query;
  }

  List<ClientModel> filteredClients(List<ClientModel> clients) {
    if (searchQuery.isEmpty) return clients;
    final query = searchQuery.toLowerCase();
    return clients.where((c) {
      return c.name.toLowerCase().contains(query) ||
          c.phone.toLowerCase().contains(query) ||
          c.address.toLowerCase().contains(query);
    }).toList();
  }

  String? validateName(String? value) {
    if (value == null || value.isEmpty) return 'Nama tidak boleh kosong';
    if (value.length < 2) return 'Nama minimal 2 karakter';
    if (value.length > 100) return 'Nama maksimal 100 karakter';
    return null;
  }

  String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Nomor telepon tidak boleh kosong';
    }
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 8) return 'Nomor telepon minimal 8 digit';
    if (digits.length > 15) return 'Nomor telepon maksimal 15 digit';
    return null;
  }

  String? validateAddress(String? value) {
    if (value == null || value.isEmpty) return 'Alamat tidak boleh kosong';
    return null;
  }

  String? validateDebt(String? value) {
    if (value == null || value.isEmpty) return null; // debt boleh 0
    final parsed = double.tryParse(
      value.replaceAll(',', '').replaceAll('.', ''),
    );
    if (parsed == null) return 'Masukkan angka yang valid';
    if (parsed < 0) return 'Hutang tidak boleh negatif';
    return null;
  }

  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Email tidak boleh kosong';
    final emailRegex = RegExp(r'^[\w._%+\-]+@[\w.\-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value)) return 'Format email tidak valid';
    return null;
  }

  Future<Map<String, dynamic>> createClient({
    required String name,
    required String phone,
    required String email,
    required String address,
  }) async {
    try {
      await firestore.collection(collectionName).add({
        'name': name.trim(),
        'phone': phone.trim(),
        'email': email.trim(),
        'address': address.trim(),
        'debt': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return {'success': true};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updateClient({
    required String id,
    required String name,
    required String phone,
    required String email,
    required String address,
  }) async {
    try {
      await firestore.collection(collectionName).doc(id).update({
        'name': name.trim(),
        'phone': phone.trim(),
        'email': email.trim(),
        'address': address.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return {'success': true};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> deleteClient(String id) async {
    try {
      await firestore.collection(collectionName).doc(id).delete();
      return {'success': true};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}
