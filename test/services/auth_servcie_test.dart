import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:star_consignment/service/auth_service.dart';

// 1. BIKIN MOCK MANUAL MENGGUNAKAN IMPLEMENTS (Tanpa package tambahan)
class MockFirebaseAuthUnauthenticated implements FirebaseAuth {
  @override
  User? get currentUser => null; // Simulasikan tidak ada user login

  // Karena kita menggunakan 'implements', Dart memaksa kita menulis noSuchMethod 
  // agar kita tidak perlu menulis ulang ratusan fungsi Firebase lainnya.
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockFirebaseFirestoreEmpty implements FirebaseFirestore {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('Harus mengembalikan null jika tidak ada user yang login', () async {
    // 2. Instansiasi Class Palsu yang kita buat di atas
    final mockAuth = MockFirebaseAuthUnauthenticated();
    final mockFirestore = MockFirebaseFirestoreEmpty();

    // 3. Masukkan ke AuthService
    final authService = AuthService(auth: mockAuth, firestore: mockFirestore);

    // 4. Jalankan fungsi dan cek hasilnya
    final result = await authService.getUserRole();
    expect(result, isNull);
  });
}