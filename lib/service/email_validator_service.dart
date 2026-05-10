import 'package:cloud_firestore/cloud_firestore.dart';

class EmailValidatorService {
  final FirebaseFirestore firestore;

  EmailValidatorService({required this.firestore});

  Future<bool> isEmailUsedAnywhere(
    String email, {
    String? excludeId,
    String? collection,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();

    // cek di users
    final usersQuery = await firestore
        .collection('users')
        .where('gmail', isEqualTo: normalizedEmail)
        .get();

    // cek di clients
    final clientsQuery = await firestore
        .collection('clients')
        .where('email', isEqualTo: normalizedEmail)
        .get();

    bool existsInUsers = usersQuery.docs.any((doc) {
      if (collection == 'users' && excludeId != null) {
        return doc.id != excludeId;
      }
      return true;
    });

    bool existsInClients = clientsQuery.docs.any((doc) {
      if (collection == 'clients' && excludeId != null) {
        return doc.id != excludeId;
      }
      return true;
    });

    return existsInUsers || existsInClients;
  }
}
