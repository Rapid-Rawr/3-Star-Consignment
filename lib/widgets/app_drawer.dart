import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../utils/theme_notifier.dart';

class AppDrawer extends StatelessWidget {
  final User? currentUser;
  final bool isSigningIn;
  final VoidCallback onSignIn;
  final VoidCallback onSignOut;

  const AppDrawer({
    super.key,
    required this.currentUser,
    required this.isSigningIn,
    required this.onSignIn,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
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
                              ? const Icon(
                                  Icons.person,
                                  size: 30,
                                  color: Color(0xFF49454F),
                                )
                              : null,
                        ),
                        const SizedBox(height: 5),
                        Text(
                          currentUser!.displayName ?? 'User',
                          style: const TextStyle(
                            color: Color(0xFF49454F),
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          currentUser!.email ?? '',
                          style: const TextStyle(
                            color: Color(0xFF49454F),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  // ===== BELUM LOGIN =====
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 40, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.account_circle,
                          size: 40,
                          color: Color(0xFF49454F),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Guest',
                          style: TextStyle(
                            color: Color(0xFF49454F),
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'You\'re not signed in',
                          style: TextStyle(
                            color: Color(0xFF49454F),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                // ── Settings ──
                ListTile(
                  leading: const Icon(Icons.settings),
                  iconColor: const Color(0xFF49454F),
                  title: const Text(
                    'Settings',
                    style: TextStyle(
                      color: Color(0xFF49454F),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // ── Dark Mode toggle ──
          Container(
            color: Colors.white,
            child: ValueListenableBuilder<ThemeMode>(
              valueListenable: themeNotifier,
              builder: (_, mode, __) => ListTile(
                leading: const Icon(Icons.dark_mode, color: Color(0xFF49454F)),
                title: const Text(
                  'Dark Mode',
                  style: TextStyle(
                    color: Color(0xFF49454F),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                trailing: Switch(
                  value: mode == ThemeMode.dark,
                  activeThumbColor: const Color(0xFF49454F),
                  onChanged: (val) {
                    themeNotifier.value = val
                        ? ThemeMode.dark
                        : ThemeMode.light;
                  },
                ),
              ),
            ),
          ),

          // ── Sign In / Sign Out ──
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomLeft,
                end: Alignment.topRight,
                colors: [Color(0xFF67636D), Color(0xFF1D1B20)],
              ),
            ),
            child: Column(
              children: [
                if (currentUser != null)
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.white),
                    title: const Text(
                      'Sign Out',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      onSignOut();
                    },
                  )
                else
                  isSigningIn
                      ? const ListTile(
                          leading: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                          title: Text(
                            'Signing in...',
                            style: TextStyle(color: Colors.white),
                          ),
                        )
                      : ListTile(
                          leading: const Icon(Icons.login, color: Colors.white),
                          title: const Text(
                            'Sign In',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            onSignIn();
                          },
                        ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
