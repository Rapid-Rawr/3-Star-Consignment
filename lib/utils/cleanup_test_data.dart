import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> cleanupTestData() async {
  const targetClientId = 'test_client_001';
  const collection = 'consignment_requests';

  print('[cleanup] Mencari document dengan clientId = "$targetClientId"...');

  final snapshot = await FirebaseFirestore.instance
      .collection(collection)
      .where('clientId', isEqualTo: targetClientId)
      .get();

  if (snapshot.docs.isEmpty) {
    print('[cleanup] Tidak ada document sampah. Firestore sudah bersih!');
    return;
  }

  print('[cleanup] Ditemukan ${snapshot.docs.length} document sampah. Menghapus...');

  final batch = FirebaseFirestore.instance.batch();
  for (final doc in snapshot.docs) {
    batch.delete(doc.reference);
    print('[cleanup]   - ${doc.id}');
  }
  await batch.commit();

  print('[cleanup] Selesai! ${snapshot.docs.length} document berhasil dihapus.');
}
