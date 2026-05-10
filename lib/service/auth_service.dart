import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../service/roles.dart';

class AuthService {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;

  Future<String?> getUserRole() async {
    final user = auth.currentUser;
    if (user == null) return null;

    final email = user.email;
    if (email == null) return null;

    // clients
    final clientQuery = await firestore
        .collection('clients')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    if (clientQuery.docs.isNotEmpty) {
      return Roles.client; // ✅ pakai constant
    }

    // users
    final userQuery = await firestore
        .collection('users')
        .where('gmail', isEqualTo: email)
        .limit(1)
        .get();

    if (userQuery.docs.isNotEmpty) {
      final role = userQuery.docs.first['Role'];

      // mapping biar aman
      if (role == 'Administrator') return Roles.admin;
      if (role == 'Karyawan') return Roles.karyawan;
    }

    return null;
  }
}
