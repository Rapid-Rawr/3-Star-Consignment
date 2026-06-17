import 'package:flutter/material.dart';
import '../barang/katalog_page.dart';
import '../barang/pengajuan_konsinyasi_page.dart';
import '../barang/daftar_pengajuan_page.dart';
import '../barang/riwayat_pengajuan_page.dart';
import '../barang/barang_konsinyasi_page.dart';
import '../../widgets/menu_button.dart';
import '../../utils/app_colors.dart';
import 'package:provider/provider.dart';
import '../../service/auth_provider.dart';
import '../../service/roles.dart';

bool hasAccess(String? role, List<String> allowedRoles) {
  if (role == null) return false;
  return allowedRoles.contains(role);
}

class ItemPage extends StatelessWidget {
  const ItemPage({super.key});

  @override
  Widget build(BuildContext context) {
    final role = context.watch<AuthProvider>().role;

    return CustomScrollView(
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (hasAccess(role, [Roles.admin]))
                        MenuButton(
                          svgPath: 'assets/icons/ConsignmentItem.svg',
                          label: 'Barang Konsinyasi',
                          borderColor: context.borderColor,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ConsignmentPage(),
                            ),
                          ),
                        ),
                      if (hasAccess(role, [Roles.admin]))
                        const SizedBox(height: 16),
                      MenuButton(
                        svgPath: 'assets/icons/ConsignmentHistory.svg',
                        label: 'Riwayat Pengajuan',
                        borderColor: context.borderColor,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RequestHistoryPage(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      MenuButton(
                        svgPath: 'assets/icons/RequestList.svg',
                        label: 'Daftar Pengajuan',
                        borderColor: context.borderColor,
                        imageOffset: const Offset(8, 0),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RequestListPage(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (hasAccess(role, [Roles.client]))
                        MenuButton(
                          svgPath: 'assets/icons/Request Consignment.svg',
                          label: 'Pengajuan Konsinyasi',
                          borderColor: context.borderColor,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ConsignmentRequestPage(),
                            ),
                          ),
                        ),
                      if (hasAccess(role, [Roles.client]))
                        const SizedBox(height: 16),
                      if (hasAccess(role, [Roles.admin]))
                        MenuButton(
                          svgPath: 'assets/icons/Catalog.svg',
                          label: 'Manajemen Katalog',
                          borderColor: context.borderColor,
                          imageOffset: const Offset(8, 0),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CatalogPage(),
                            ),
                          ),
                        ),

                      if (hasAccess(role, [Roles.karyawan]))
                        MenuButton(
                          svgPath: 'assets/icons/Catalog.svg',
                          label: 'Katalog',
                          borderColor: context.borderColor,
                          imageOffset: const Offset(8, 0),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const CatalogPage(isReadOnly: true),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
