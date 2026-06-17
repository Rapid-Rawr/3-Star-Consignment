// cleanup_test_data.dart
// Jalankan sekali untuk menghapus semua document di consignment_requests
// dengan clientId = "test_client_001"
//
// Cara jalankan:
//   dart run bin/cleanup_test_data.dart

import 'dart:convert';
import 'dart:io';

const String _projectId = 'test-4d7e0';
const String _apiKey = 'AIzaSyDMguzq1QuA7ejN6SmIr47gYG9X3CAkGaU';
const String _collection = 'consignment_requests';
const String _targetClientId = 'test_client_001';

Future<void> main() async {
  print('=== Cleanup Test Data ===');
  print('Project: $_projectId');
  print('Collection: $_collection');
  print('Target clientId: $_targetClientId');
  print('');

  // Step 1: Authenticate anonymously
  print('[1/3] Authenticating...');
  final idToken = await _signInAnonymously();
  if (idToken == null) {
    print('ERROR: Gagal autentikasi. Pastikan Anonymous Auth aktif di Firebase Console.');
    print('       Buka: https://console.firebase.google.com/project/$_projectId/authentication/providers');
    print('       Aktifkan "Anonymous" provider.');
    exit(1);
  }
  print('       OK (authenticated)');

  // Step 2: Query matching documents
  print('[2/3] Mencari document dengan clientId = "$_targetClientId"...');
  final docNames = await _queryDocuments(idToken);
  print('       Ditemukan ${docNames.length} document');

  if (docNames.isEmpty) {
    print('');
    print('Tidak ada document yang perlu dihapus. Firestore sudah bersih!');
    exit(0);
  }

  // Step 3: Delete each document
  print('[3/3] Menghapus document...');
  int success = 0;
  int failed = 0;
  for (final docName in docNames) {
    final docId = docName.split('/').last;
    final ok = await _deleteDocument(idToken, docId);
    if (ok) {
      print('       ✓ $docId');
      success++;
    } else {
      print('       ✗ $docId (gagal)');
      failed++;
    }
  }

  print('');
  print('=== Selesai ===');
  print('Berhasil dihapus: $success');
  if (failed > 0) print('Gagal: $failed');
}

Future<String?> _signInAnonymously() async {
  try {
    final client = HttpClient();
    final url = Uri.parse(
      'https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$_apiKey',
    );
    final request = await client.postUrl(url);
    request.headers.contentType = ContentType.json;
    request.write(jsonEncode({'returnSecureToken': true}));
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();
    final data = jsonDecode(body) as Map<String, dynamic>;
    return data['idToken'] as String?;
  } catch (e) {
    print('       Auth error: $e');
    return null;
  }
}

Future<List<String>> _queryDocuments(String idToken) async {
  final client = HttpClient();
  final url = Uri.parse(
    'https://firestore.googleapis.com/v1/projects/$_projectId/databases/(default)/documents:runQuery',
  );
  final request = await client.postUrl(url);
  request.headers.contentType = ContentType.json;
  request.headers.set('Authorization', 'Bearer $idToken');
  request.write(jsonEncode({
    'structuredQuery': {
      'from': [
        {'collectionId': _collection}
      ],
      'where': {
        'fieldFilter': {
          'field': {'fieldPath': 'clientId'},
          'op': 'EQUAL',
          'value': {'stringValue': _targetClientId},
        }
      }
    }
  }));
  final response = await request.close();
  final body = await response.transform(utf8.decoder).join();
  final results = jsonDecode(body) as List;

  final docNames = <String>[];
  for (final result in results) {
    if (result['document'] != null) {
      docNames.add(result['document']['name'] as String);
    }
  }
  return docNames;
}

Future<bool> _deleteDocument(String idToken, String docId) async {
  try {
    final client = HttpClient();
    final url = Uri.parse(
      'https://firestore.googleapis.com/v1/projects/$_projectId/databases/(default)/documents/$_collection/$docId',
    );
    final request = await client.deleteUrl(url);
    request.headers.set('Authorization', 'Bearer $idToken');
    final response = await request.close();
    await response.drain();
    return response.statusCode == 200;
  } catch (_) {
    return false;
  }
}
