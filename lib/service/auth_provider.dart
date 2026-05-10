import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../service/roles.dart';

class AuthProvider extends ChangeNotifier {
  String? _role;

  String? get role => _role;

  /// init saat app start
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedRole = prefs.getString('user_role');

    // mapping ke Roles
    if (savedRole == Roles.admin) {
      _role = Roles.admin;
    } else if (savedRole == Roles.karyawan) {
      _role = Roles.karyawan;
    } else if (savedRole == Roles.client) {
      _role = Roles.client;
    } else {
      _role = null;
    }

    notifyListeners();
  }

  /// set role setelah login
  Future<void> setRole(String? role) async {
    if (role == null) return;

    // validasi supaya hanya role resmi
    if (![Roles.admin, Roles.karyawan, Roles.client].contains(role)) {
      return;
    }

    _role = role;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_role', role);

    notifyListeners();
  }

  /// logout
  Future<void> clear() async {
    _role = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_role');

    notifyListeners();
  }
}
