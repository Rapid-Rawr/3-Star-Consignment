import 'dart:async';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../widgets/app_dialog.dart';

class AuthController {
  AuthController._();
  static final AuthController instance = AuthController._();

  Stream<User?> get authStateChanges =>
      FirebaseAuth.instance.authStateChanges();

  User? get currentUser => FirebaseAuth.instance.currentUser;

  Future<void> init() async {
    try {
      await GoogleSignIn.instance.initialize();
    } catch (_) {}
  }

  Future<void> signInWithGoogle(BuildContext context) async {
    try {
      final result = await InternetAddress.lookup(
        'google.com',
      ).timeout(const Duration(seconds: 4));
      if (result.isEmpty || result[0].rawAddress.isEmpty) {
        if (context.mounted) _showNoInternetDialog(context);
        return;
      }
    } catch (_) {
      if (context.mounted) _showNoInternetDialog(context);
      return;
    }

    try {
      final GoogleSignInAccount account = await GoogleSignIn.instance
          .authenticate();
      final GoogleSignInAuthentication auth = account.authentication;
      final credential = GoogleAuthProvider.credential(idToken: auth.idToken);
      await FirebaseAuth.instance.signInWithCredential(credential);
    } catch (e) {
      if (e is PlatformException && e.code == 'sign_in_cancelled') return;
      final errStr = e.toString().toLowerCase();
      if (errStr.contains('sign_in_cancelled') ||
          errStr.contains('canceled') ||
          errStr.contains('cancelled')) {
        return;
      }

      if (!context.mounted) return;

      final isNetworkError =
          e is SocketException ||
          (e is FirebaseAuthException && e.code == 'network-request-failed') ||
          errStr.contains('network') ||
          errStr.contains('socket') ||
          errStr.contains('failed host lookup');

      if (isNetworkError) {
        showAppDialog(
          context: context,
          title: 'Tidak Ada Koneksi',
          titleIcon: const Icon(Icons.wifi_off_rounded),
          content: 'Periksa koneksi internet Anda lalu coba lagi.',
          actions: [
            AppDialogAction(
              label: 'OK',
              onPressed: () => Navigator.pop(context),
            ),
          ],
        );
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal masuk: $e')));
    }
  }

  void _showNoInternetDialog(BuildContext context) {
    showAppDialog(
      context: context,
      title: 'Tidak Ada Koneksi',
      titleIcon: const Icon(Icons.wifi_off_rounded),
      content: 'Periksa koneksi internet Anda lalu coba lagi.',
      actions: [
        AppDialogAction(label: 'OK', onPressed: () => Navigator.pop(context)),
      ],
    );
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    await GoogleSignIn.instance.signOut();
  }
}
