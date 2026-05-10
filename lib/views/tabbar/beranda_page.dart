import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../views/barang/daftar_pengajuan_page.dart';
import '../../models/barang_models/konsinyasi_model.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  /// ==========================================================
  /// ✅ NEW: APPROVE ALL ITEMS + UPDATE BATCH STATUS
  /// (REPLACED old updateRequestStatus)
  /// ==========================================================
  Future<void> approveAllItems(String batchId) async {
    final docRef = FirebaseFirestore.instance
        .collection('consignment_requests')
        .doc(batchId);

    final snapshot = await docRef.get();
    final data = snapshot.data();

    if (data == null) return;

    final List items = data['items'] ?? [];

    /// ✅ CHANGE: update every item's status
    final updatedItems = items.map((item) {
      return {
        ...item,
        'itemStatus': 'approved',
      };
    }).toList();

    /// ✅ CHANGE: update items + batch status together
    await docRef.update({
      'items': updatedItems,
      'status': 'processing',
    });
  }

  /// ==========================================================
  /// ✅ NEW: REJECT ALL ITEMS
  /// ==========================================================
  Future<void> rejectAllItems(String batchId) async {
    final docRef = FirebaseFirestore.instance
        .collection('consignment_requests')
        .doc(batchId);

    final snapshot = await docRef.get();
    final data = snapshot.data();

    if (data == null) return;

    final List items = data['items'] ?? [];

    /// ✅ CHANGE: reject all items
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

  /// ==========================================================
  /// ✅ STREAM ONLY PENDING REQUESTS (UNCHANGED)
  /// ==========================================================
  Stream<QuerySnapshot> getRequests() {
    return FirebaseFirestore.instance
        .collection('consignment_requests')
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark =
        Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Column(
        children: [

          /// ======================
          /// TOP HALF (REQUEST LIST)
          /// ======================
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

                            /// =================================================
                            /// DETAIL BUTTON (UNCHANGED)
                            /// =================================================
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

                            /// =================================================
                            /// ✅ ACCEPT BUTTON (UPDATED)
                            /// =================================================
                            IconButton(
                              icon: const Icon(
                                Icons.check_rounded,
                                color: Colors.green,
                              ),
                              onPressed: () async {

                                /// ✅ CHANGE:
                                /// update ALL item status + batch status
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

                            /// =================================================
                            /// ✅ DECLINE BUTTON (UPDATED)
                            /// =================================================
                            IconButton(
                              icon: const Icon(
                                Icons.cancel_outlined,
                                color: Colors.red,
                              ),
                              onPressed: () async {

                                /// ✅ CHANGE:
                                /// reject ALL items
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

          /// ======================
          /// BOTTOM HALF
          /// ======================
          Expanded(
            flex: 1,
            child: Container(
              color: Colors.grey.shade100,
              child: const Center(
                child: Text("Future Content Here"),
              ),
            ),
          ),
        ],
      ),
    );
  }
}