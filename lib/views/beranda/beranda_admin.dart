import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../views/barang/daftar_pengajuan_page.dart';
import '../../models/barang_models/konsinyasi_model.dart';
import '../barang/barang_konsinyasi_page.dart';
import '../../models/barang_models/katalog_model.dart';
import '../../models/pengguna_models/klien_model.dart';

class HomeAdminPage extends StatelessWidget {
  final FirebaseFirestore firestore;
  const HomeAdminPage({
    super.key,
    FirebaseFirestore? firestore,
  }) : firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> approveAllItems(String batchId) async {
    final docRef = firestore
        .collection('consignment_requests')
        .doc(batchId);

    final snapshot = await docRef.get();
    final data = snapshot.data();

    if (data == null) return;

    final List items = data['items'] ?? [];

    final updatedItems = items.map((item) {
      return {
        ...item,
        'itemStatus': 'approved',
      };
    }).toList();

    await docRef.update({
      'items': updatedItems,
      'status': 'processing',
    });
  }

  Future<void> rejectAllItems(String batchId) async {
    final docRef = firestore
        .collection('consignment_requests')
        .doc(batchId);

    final snapshot = await docRef.get();
    final data = snapshot.data();

    if (data == null) return;

    final List items = data['items'] ?? [];

    final updatedItems = items.map((item) {
      return {
        ...item,
        'itemStatus': 'rejected',
      };
    }).toList();

    await docRef.update({
      'items': updatedItems,
      'status': 'rejected',
    });
  }

  Stream<QuerySnapshot> getRequests() {
    return firestore
        .collection('consignment_requests')
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

Stream<QuerySnapshot> getBarangPreview() {
  return firestore
      .collection('catalog')
      .limit(3)
      .snapshots();
}

  @override
  Widget build(BuildContext context) {
    final bool isDark =
        Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Column(
        children: [
          //TOP HALF
          Expanded(
            flex: 1,
            child: StreamBuilder<QuerySnapshot>(
              stream: getRequests(),
              builder: (context, snapshot) {

                if (!snapshot.hasData ||
                    snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text("Belum ada data"),
                  );
                }

                final docs = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {

                    final doc = docs[index];

                    final batch = ConsignmentRequestModel.fromMap(
                      doc.id,
                      doc.data() as Map<String, dynamic>,
                    );

                    final name = batch.clientName;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        title: Text(name),

                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.assignment_outlined),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        RequestListPage(
                                      initialBatch: batch,
                                    ),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.check_rounded,
                                color: Colors.green,
                              ),
                              onPressed: () async {
                                await approveAllItems(batch.id);

                                ScaffoldMessenger.of(context)
                                    .showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Request berhasil disetujui',
                                    ),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.cancel_outlined,
                                color: Colors.red,
                              ),
                              onPressed: () async {

                                await rejectAllItems(batch.id);

                                ScaffoldMessenger.of(context)
                                    .showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Request ditolak',
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          //BOTTOM HALF
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        "Barang Konsinyasi",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const Spacer(),

                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ConsignmentPage(),
                            ),
                          );
                        },
                        child: const Text("Lihat Semua"),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: firestore
                          .collection('clients')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final clients = snapshot.data!.docs
                            .map(
                              (doc) => ClientModel.fromMap(
                                doc.id,
                                doc.data() as Map<String, dynamic>,
                              ),
                            )
                            .where(
                              (client) =>
                                  client.borrowedItems.isNotEmpty,
                            )
                            .take(5)
                            .toList();

                        if (clients.isEmpty) {
                          return const Center(
                            child: Text(
                              "Belum ada barang konsinyasi",
                            ),
                          );
                        }

                        return ListView.builder(
                          itemCount: clients.length,
                          itemBuilder: (context, index) {
                            final client = clients[index];
                            final item =
                                client.borrowedItems.first;

                            return ListTile(
                              contentPadding: EdgeInsets.zero,

                              leading: item.catalogImagePath != null &&
                                      item.catalogImagePath!.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius:
                                          BorderRadius.circular(8),
                                      child: Image.network(
                                        item.catalogImagePath!,
                                        width: 50,
                                        height: 50,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : const CircleAvatar(
                                      child: Icon(
                                        Icons.inventory_2_outlined,
                                      ),
                                    ),

                              title: Text(
                                item.catalogName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              subtitle: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Peminjam: ${client.name}',
                                  ),
                                  Text(
                                    'Qty: ${item.quantity}',
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}