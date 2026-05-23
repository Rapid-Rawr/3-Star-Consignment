import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../views/barang/daftar_pengajuan_page.dart';
import '../../models/barang_models/konsinyasi_model.dart';
import '../barang/barang_konsinyasi_page.dart';
import '../../models/barang_models/katalog_model.dart';

class HomeAdminPage extends StatelessWidget {
  const HomeAdminPage({super.key});

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

Stream<QuerySnapshot> getBarangPreview() {
  return FirebaseFirestore.instance
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
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  /// =========================
                  /// HEADER
                  /// =========================
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
                              builder: (_) =>
                                  ConsignmentPage(),
                            ),
                          );
                        },

                        child: const Text("Lihat Semua"),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  /// =========================
                  /// LIST PREVIEW
                  /// =========================
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('consignment_requests')
                          .orderBy(
                            'createdAt',
                            descending: true,
                          )
                          .limit(5)
                          .snapshots(),

                      builder: (context, snapshot) {

                        if (!snapshot.hasData ||
                            snapshot.data!.docs.isEmpty) {
                          return const Center(
                            child: Text(
                              "Belum ada barang konsinyasi",
                            ),
                          );
                        }

                        final docs = snapshot.data!.docs;

                        return ListView.builder(
                          itemCount: docs.length,

                          itemBuilder: (context, index) {

                            final batch =
                                ConsignmentRequestModel.fromMap(
                              docs[index].id,
                              docs[index].data()
                                  as Map<String, dynamic>,
                            );

                            final firstItem =
                                batch.items.isNotEmpty
                                    ? batch.items.first
                                    : null;

                            return Padding(
                              padding:
                                  const EdgeInsets.only(bottom: 14),

                              child: Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,

                                children: [

                                  /// IMAGE / ICON
                                  Container(
                                    width: 54,
                                    height: 54,

                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade100,
                                      borderRadius:
                                          BorderRadius.circular(12),
                                    ),

                                    child: firstItem?.catalogImagePath !=
                                                null &&
                                            firstItem!
                                                .catalogImagePath!
                                                .isNotEmpty
                                        ? ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(
                                                    12),

                                            child: Image.network(
                                              firstItem
                                                  .catalogImagePath!,
                                              fit: BoxFit.cover,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.inventory_2_outlined,
                                          ),
                                  ),

                                  const SizedBox(width: 12),

                                  /// CONTENT
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,

                                      children: [

                                        /// CLIENT NAME
                                        Text(
                                          batch.clientName,
                                          style: const TextStyle(
                                            fontWeight:
                                                FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),

                                        const SizedBox(height: 4),

                                        /// ITEM NAME
                                        Text(
                                          firstItem?.catalogName ??
                                              "Tanpa Barang",

                                          maxLines: 1,
                                          overflow:
                                              TextOverflow.ellipsis,

                                          style: TextStyle(
                                            color:
                                                Colors.grey.shade700,
                                          ),
                                        ),

                                        const SizedBox(height: 4),

                                        /// PRICE
                                        Text(
                                          'Rp ${firstItem?.catalogPrice.toStringAsFixed(0) ?? '0'}',

                                          style: TextStyle(
                                            color:
                                                Colors.grey.shade600,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
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