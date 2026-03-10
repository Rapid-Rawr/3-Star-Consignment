import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../utils/internet_check.dart';
import '../widgets/app_dialog.dart';

class AuthController {
  AuthController._();
  static final AuthController instance = AuthController._();

  Stream<User?> get authStateChanges =>
      FirebaseAuth.instance.authStateChanges();

  User? get currentUser => FirebaseAuth.instance.currentUser;

  Future<void> init() async {
    if (kIsWeb) return;
    try {
      await GoogleSignIn.instance.initialize();
    } catch (_) {}
  }

  /// Sync Google photoURL ke dokumen Firestore user yang emailnya cocok.
  Future<void> syncPhotoUrl(User user) async {
    final photoUrl = user.photoURL;
    final email = user.email?.toLowerCase();
    if (photoUrl == null || email == null) return;

    try {
      final query = await FirebaseFirestore.instance
          .collection('users')
          .where('gmail', isEqualTo: email)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        await query.docs.first.reference.update({'photoUrl': photoUrl});
      }
    } catch (_) {}
  }

  Future<void> signInWithGoogle(BuildContext context) async {
    if (!kIsWeb) {
      final hasInternet = await checkInternetConnection();
      if (!hasInternet) {
        if (context.mounted) _showNoInternetDialog(context);
        return;
      }
    }

    try {
      if (kIsWeb) {
        final provider = GoogleAuthProvider();
        await FirebaseAuth.instance.signInWithPopup(provider);
      } else {
        final GoogleSignInAccount account = await GoogleSignIn.instance
            .authenticate();
        final GoogleSignInAuthentication auth = account.authentication;
        final credential = GoogleAuthProvider.credential(idToken: auth.idToken);
        await FirebaseAuth.instance.signInWithCredential(credential);
      }

      // Sync photo URL setelah berhasil login
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) await syncPhotoUrl(user);
    } catch (e) {
      if (e is PlatformException && e.code == 'sign_in_cancelled') return;
      final errStr = e.toString().toLowerCase();
      if (errStr.contains('sign_in_cancelled') ||
          errStr.contains('canceled') ||
          errStr.contains('cancelled') ||
          errStr.contains('popup_closed')) {
        return;
      }

      if (!context.mounted) return;

      final isNetworkError =
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
    if (!kIsWeb) {
      await GoogleSignIn.instance.signOut();
    }
  }
}
