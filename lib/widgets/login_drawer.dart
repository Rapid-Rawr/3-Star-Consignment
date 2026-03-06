import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../utils/theme_notifier.dart';

class LoginDrawer extends StatelessWidget {
  final User? currentUser;
  final bool isSigningIn;
  final VoidCallback onSignIn;
  final VoidCallback onSignOut;

  const LoginDrawer({
    super.key,
    required this.currentUser,
    required this.isSigningIn,
    required this.onSignIn,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    // Baca mode tema sekali di sini → dipakai di seluruh widget
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor = isDark ? const Color(0xFF1D1B20) : Colors.white;
    final Color contentColor = isDark ? Colors.white : const Color(0xFF49454F);

    return Drawer(
      backgroundColor: bgColor,
      surfaceTintColor: Colors.transparent,
      child: Column(
        children: <Widget>[
          // ── Profile section ──
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[
                if (currentUser != null)
                  // ===== SUDAH LOGIN =====
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundImage: currentUser!.photoURL != null
                              ? NetworkImage(currentUser!.photoURL!)
                              : null,
                          child: currentUser!.photoURL == null
                              ? Icon(
                                  Icons.person,
                                  size: 30,
                                  color: contentColor,
                                )
                              : null,
                        ),
                        const SizedBox(height: 5),
                        Text(
                          currentUser!.displayName ?? 'User',
                          style: TextStyle(
                            color: contentColor,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          currentUser!.email ?? '',
                          style: TextStyle(
                            color: contentColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  // ===== BELUM LOGIN =====
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.account_circle,
                          size: 40,
                          color: contentColor,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Guest',
                          style: TextStyle(
                            color: contentColor,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'You\'re not signed in',
                          style: TextStyle(
                            color: contentColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ListTile(
                  leading: Icon(Icons.settings, color: contentColor),
                  title: Text(
                    'Pengaturan',
                    style: TextStyle(
                      color: contentColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Container(
            color: bgColor,
            child: ValueListenableBuilder<ThemeMode>(
              valueListenable: themeNotifier,
              builder: (_, mode, __) => ListTile(
                leading: Icon(Icons.dark_mode, color: contentColor),
                title: Text(
                  'Mode Gelap',
                  style: TextStyle(
                    color: contentColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                trailing: Switch(
                  value: mode == ThemeMode.dark,
                  activeThumbColor: contentColor,
                  onChanged: (val) {
                    themeNotifier.value = val
                        ? ThemeMode.dark
                        : ThemeMode.light;
                  },
                ),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomLeft,
                end: Alignment.topRight,
                colors: isDark
                    ? [const Color(0xFFA3A3A3), const Color(0xFFFFFFFF)]
                    : [const Color(0xFF67636D), const Color(0xFF1D1B20)],
              ),
            ),
            child: Theme(
              data: Theme.of(context).copyWith(
                splashColor: isDark
                    ? const Color(0xFF1D1B20).withValues(alpha: 0.25)
                    : Colors.white.withValues(alpha: 0.2),
                highlightColor: isDark
                    ? const Color(0xFF1D1B20).withValues(alpha: 0.15)
                    : Colors.white.withValues(alpha: 0.1),
              ),
              child: Material(
                type: MaterialType.transparency,
                child: Column(
                  children: [
                    if (currentUser != null)
                      ListTile(
                        leading: Icon(
                          Icons.logout,
                          color: isDark
                              ? const Color(0xFF1D1B20)
                              : Colors.white,
                        ),
                        title: Text(
                          'Keluar',
                          style: TextStyle(
                            color: isDark
                                ? const Color(0xFF1D1B20)
                                : Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        onTap: () async {
                          // Navigator.pop(context);
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) {
                              final bool dIsDark =
                                  Theme.of(ctx).brightness == Brightness.dark;
                              final Color dialogTextColor = dIsDark
                                  ? Colors.white
                                  : const Color(0xFF1D1B20);
                              // Warna button "Keluar" = kebalikan gradient container
                              final Color btnTextColor = dIsDark
                                  ? const Color(0xFF1D1B20)
                                  : Colors.white;
                              return AlertDialog(
                                title: Row(
                                  children: [
                                    Icon(
                                      Icons.warning_amber_rounded,
                                      color: dialogTextColor,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Keluar',
                                      style: TextStyle(color: dialogTextColor),
                                    ),
                                  ],
                                ),
                                content: Text(
                                  'Apakah anda yakin ingin keluar?',
                                  style: TextStyle(color: dialogTextColor),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: Text(
                                      'Batal',
                                      style: TextStyle(color: dialogTextColor),
                                    ),
                                  ),
                                  // Keluar button: gradient background
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      overlayColor: dIsDark
                                          ? const Color(0xFF1D1B20)
                                          : Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                    child: Ink(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.bottomLeft,
                                          end: Alignment.topRight,
                                          colors: dIsDark
                                              ? [
                                                  const Color(0xFFA3A3A3),
                                                  const Color(0xFFFFFFFF),
                                                ]
                                              : [
                                                  const Color(0xFF67636D),
                                                  const Color(0xFF1D1B20),
                                                ],
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                        child: Text(
                                          'Keluar',
                                          style: TextStyle(
                                            color: btnTextColor,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          );
                          if (confirm == true && context.mounted) {
                            onSignOut();
                          }
                        },
                      )
                    else
                      isSigningIn
                          ? ListTile(
                              leading: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: isDark
                                      ? const Color(0xFF1D1B20)
                                      : Colors.white,
                                ),
                              ),
                              title: Text(
                                'Masuk...',
                                style: TextStyle(
                                  color: isDark
                                      ? const Color(0xFF1D1B20)
                                      : Colors.white,
                                ),
                              ),
                            )
                          : ListTile(
                              leading: Icon(
                                Icons.login,
                                color: isDark
                                    ? const Color(0xFF1D1B20)
                                    : Colors.white,
                              ),
                              title: Text(
                                'Masuk',
                                style: TextStyle(
                                  color: isDark
                                      ? const Color(0xFF1D1B20)
                                      : Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              onTap: () {
                                // Navigator.pop(context);
                                onSignIn();
                              },
                            ),
                  ],
                ), // close Column
              ), // close Material
            ), // close Theme
          ), // close Container
        ],
      ),
    );
  }
}
