import 'package:cloud_firestore/cloud_firestore.dart';
import '../../service/email_validator_service.dart';
import '../../service/roles.dart';

class ClientController {
  final FirebaseFirestore firestore;
  final String collectionName = 'clients';

  final EmailValidatorService emailValidator;

  ClientController({required this.firestore})
    : emailValidator = EmailValidatorService(firestore: firestore);

  Stream<QuerySnapshot> getClientsStream() {
    return firestore.collection(collectionName).snapshots();
  }

  Stream<QuerySnapshot> getClientsStreamForUser(String email) {
    return firestore
        .collection(collectionName)
        .where('email', isEqualTo: email)
        .snapshots();
  }

  Stream<QuerySnapshot> getClientsByRole({
    required String role,
    required String email,
  }) {
    if (role == Roles.admin || role == Roles.karyawan) {
      return getClientsStream();
    }
    return getClientsStreamForUser(email);
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
    if (value == null || value.isEmpty) return null;
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

  Future<bool> checkEmailExists(String email, {String? excludeId}) async {
    return await emailValidator.isEmailUsedAnywhere(
      email,
      excludeId: excludeId,
      collection: 'clients',
    );
  }

  Future<Map<String, dynamic>> createClient({
    required String name,
    required String phone,
    required String email,
    required String address,
  }) async {
    try {
      final emailExists = await checkEmailExists(email);
      if (emailExists) {
        return {'success': false, 'error': 'Email sudah terdaftar'};
      }

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
      final emailExists = await checkEmailExists(email, excludeId: id);
      if (emailExists) {
        return {'success': false, 'error': 'Email sudah terdaftar'};
      }

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

  Future<Map<String, dynamic>> deductBorrowedItems({
    required String clientId,
    required List<Map<String, dynamic>> currentItems,
    required Map<int, int> deductions,
  }) async {
    try {
      final updated = <Map<String, dynamic>>[];
      for (int i = 0; i < currentItems.length; i++) {
        final item = Map<String, dynamic>.from(currentItems[i]);
        final deduct = deductions[i] ?? 0;
        final currentQty = (item['quantity'] as num?)?.toInt() ?? 0;
        final newQty = currentQty - deduct;
        if (newQty > 0) {
          item['quantity'] = newQty;
          updated.add(item);
        }
      }

      await firestore.collection(collectionName).doc(clientId).update({
        'borrowedItems': updated,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return {'success': true};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> addBorrowedItemsDirect({
    required String clientId,
    required List<Map<String, dynamic>> newItems,
  }) async {
    try {
      final clientRef = firestore.collection(collectionName).doc(clientId);
      final now = Timestamp.now();

      await firestore.runTransaction((tx) async {
        final snap = await tx.get(clientRef);
        final data = snap.data();
        final rawBorrowed = (data?['borrowedItems'] as List<dynamic>?) ?? [];

        String mergeKey(Map<String, dynamic> raw) {
          final id = raw['catalogId'] as String? ?? '';
          final price = (raw['catalogPrice'] as num?)?.toDouble() ?? 0.0;
          return '${id}_$price';
        }

        final Map<String, Map<String, dynamic>> mergedMap = {
          for (final raw in rawBorrowed.whereType<Map<String, dynamic>>())
            mergeKey(raw): Map<String, dynamic>.from(raw),
        };

        for (final item in newItems) {
          final key = mergeKey(item);
          final qty = (item['quantity'] as num?)?.toInt() ?? 1;
          if (mergedMap.containsKey(key)) {
            final existing = mergedMap[key]!;
            mergedMap[key] = {
              ...existing,
              'quantity': ((existing['quantity'] as num?)?.toInt() ?? 0) + qty,
              'lastReceivedAt': now,
            };
          } else {
            mergedMap[key] = {...item, 'lastReceivedAt': now};
          }
        }

        tx.update(clientRef, {
          'borrowedItems': mergedMap.values.toList(),
          'updatedAt': now,
        });
      });

      return {'success': true};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}
