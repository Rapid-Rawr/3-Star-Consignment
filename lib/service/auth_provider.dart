import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../service/roles.dart';

class AuthProvider extends ChangeNotifier {
  String? _role;

  String? get role => _role;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedRole = prefs.getString('user_role');

    if (savedRole != null &&
        [Roles.admin, Roles.karyawan, Roles.client].contains(savedRole)) {
      _role = savedRole;
      notifyListeners();
    } else {
      await _fetchAndSaveRole();
    }
  }

  Future<void> _fetchAndSaveRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _role = null;
      notifyListeners();
      return;
    }

    final email = user.email;
    if (email == null) {
      _role = null;
      notifyListeners();
      return;
    }

    try {
      final clientSnap = await FirebaseFirestore.instance
          .collection('clients')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (clientSnap.docs.isNotEmpty) {
        await setRole(Roles.client);
        return;
      }

      final userSnap = await FirebaseFirestore.instance
          .collection('users')
          .where('gmail', isEqualTo: email)
          .limit(1)
          .get();

      if (userSnap.docs.isNotEmpty) {
        final roleRaw = userSnap.docs.first['Role'] as String?;
        if (roleRaw == 'Administrator') {
          await setRole(Roles.admin);
        } else if (roleRaw == 'Karyawan') {
          await setRole(Roles.karyawan);
        } else {
          _role = null;
          notifyListeners();
        }
        return;
      }
    } catch (_) {}

    _role = null;
    notifyListeners();
  }

  Future<void> setRole(String? role) async {
    if (role == null) {
      _role = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_role');
      notifyListeners();
      return;
    }

    if (![Roles.admin, Roles.karyawan, Roles.client].contains(role)) return;

    _role = role;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_role', role);

    notifyListeners();
  }

  Future<void> clear() async {
    _role = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_role');

    notifyListeners();
  }

  void setRoleForTest(String role) {
      _role = role;
      notifyListeners();
    }
}
