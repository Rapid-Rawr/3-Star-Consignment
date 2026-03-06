// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:google_sign_in/google_sign_in.dart';

// class SignInPage extends StatefulWidget {
//   const SignInPage({super.key});

//   @override
//   State<SignInPage> createState() => _SignInPageState();
// }

// class _SignInPageState extends State<SignInPage> {
//   bool _isLoading = false;
//   bool _initialized = false;

//   @override
//   void initState() {
//     super.initState();
//     _initGoogleSignIn();
//     // Auto-close page if user already signed in
//     FirebaseAuth.instance.authStateChanges().listen((User? user) {
//       if (user != null && mounted) {
//         Navigator.of(context).pop(true);
//       }
//     });
//   }

//   Future<void> _initGoogleSignIn() async {
//     try {
//       await GoogleSignIn.instance.initialize();
//       if (mounted) setState(() => _initialized = true);
//     } catch (_) {
//       if (mounted) setState(() => _initialized = true);
//     }
//   }

//   Future<void> _signInWithGoogle() async {
//     if (!_initialized) return;
//     setState(() => _isLoading = true);
//     try {
//       final GoogleSignInAccount account = await GoogleSignIn.instance
//           .authenticate();
//       final GoogleSignInAuthentication auth = await account.authentication;
//       final credential = GoogleAuthProvider.credential(idToken: auth.idToken);
//       await FirebaseAuth.instance.signInWithCredential(credential);
//       // authStateChanges listener will pop the page
//     } catch (e) {
//       if (mounted) {
//         setState(() => _isLoading = false);
//         ScaffoldMessenger.of(
//           context,
//         ).showSnackBar(SnackBar(content: Text('Sign in failed: $e')));
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Sign In'),
//         backgroundColor: Colors.deepPurple,
//         foregroundColor: Colors.white,
//       ),
//       body: Center(
//         child: Padding(
//           padding: const EdgeInsets.all(32.0),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               const Icon(
//                 Icons.account_circle,
//                 size: 100,
//                 color: Colors.deepPurple,
//               ),
//               const SizedBox(height: 24),
//               const Text(
//                 'Welcome to Star Consignment',
//                 style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
//                 textAlign: TextAlign.center,
//               ),
//               const SizedBox(height: 8),
//               const Text(
//                 'Please sign in to continue',
//                 style: TextStyle(fontSize: 16, color: Colors.grey),
//                 textAlign: TextAlign.center,
//               ),
//               const SizedBox(height: 40),
//               if (_isLoading || !_initialized)
//                 const CircularProgressIndicator()
//               else
//                 ElevatedButton.icon(
//                   onPressed: _signInWithGoogle,
//                   icon: const Icon(Icons.login, size: 24),
//                   label: const Text(
//                     'Sign in with Google',
//                     style: TextStyle(fontSize: 16),
//                   ),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.white,
//                     foregroundColor: Colors.black87,
//                     elevation: 2,
//                     minimumSize: const Size(double.infinity, 52),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(8),
//                       side: const BorderSide(color: Colors.grey),
//                     ),
//                   ),
//                 ),
//               const SizedBox(height: 24),
//               const Text(
//                 'By signing in, you agree to our terms and conditions.',
//                 style: TextStyle(color: Colors.grey, fontSize: 12),
//                 textAlign: TextAlign.center,
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
