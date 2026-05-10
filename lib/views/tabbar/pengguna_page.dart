import 'package:flutter/material.dart';
import '../pengguna/operator_page.dart';
import '../pengguna/klien_page.dart';
import '../../widgets/menu_button.dart';
import '../../utils/app_colors.dart';
import 'package:provider/provider.dart';
import '../../service/auth_provider.dart';
import '../../service/roles.dart';

bool hasAccess(String? role, List<String> allowedRoles) {
  if (role == null) return false;
  return allowedRoles.contains(role);
}

class UserPage extends StatelessWidget {
  const UserPage({super.key});

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
                constraints: const BoxConstraints(maxWidth: 360),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (hasAccess(role, [Roles.admin, Roles.karyawan]))
                        MenuButton(
                          svgPath: 'assets/icons/Operator.svg',
                          label: 'Operator',
                          borderColor: context.borderColor,
                          iconSize: 96,
                          verticalPadding: 32,
                          iconLabelSpacing: 6,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const OperatorPage(),
                              ),
                            );
                          },
                        ),
                      if (hasAccess(role, [Roles.admin, Roles.karyawan]))
                        const SizedBox(height: 16),
                      MenuButton(
                        svgPath: 'assets/icons/Client.svg',
                        label: 'Klien',
                        borderColor: context.borderColor,
                        iconSize: 96,
                        verticalPadding: 32,
                        iconLabelSpacing: 6,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ClientPage(),
                            ),
                          );
                        },
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
