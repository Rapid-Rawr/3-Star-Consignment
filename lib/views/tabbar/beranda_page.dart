import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import '../../service/auth_provider.dart';
import '../../service/roles.dart';
import '../beranda/beranda_admin.dart';
import '../beranda/beranda_karyawan.dart';
import '../beranda/beranda_client.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final role = context.watch<AuthProvider>().role;

    switch (role) {
      case Roles.admin:
        return HomeAdminPage();

      case Roles.karyawan:
        return const HomeKaryawanPage();

      case Roles.client:
        return const HomeClientPage();

      default:
        return const Center(child: CircularProgressIndicator());
    }
  }
}
