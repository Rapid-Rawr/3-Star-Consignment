import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../views/barang/daftar_pengajuan_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

Stream<QuerySnapshot> getRequests() {
  return FirebaseFirestore.instance
      .collection('consignment_requests')
      .where('status', isEqualTo: 'pendingR')
      .snapshots();
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: Column(
        children: [

          /// ======================
          /// TOP HALF (LIST)
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

                    final data =
                        docs[index].data() as Map<String, dynamic>;

                    final name =
                        data['clientName'] ?? "Tanpa Nama";

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        title: Text(name),

                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [

                            /// Detail
                            IconButton(
                              icon: const Icon(Icons.assignment_outlined),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => RequestListPage(),
                                  ),
                                );
                              },
                            ),

                            /// APPROVE
                            IconButton(
                              icon: const Icon(
                                Icons.check_rounded,
                                color: Colors.green,
                              ),
                              onPressed: () {},
                            ),

                            /// DECLINE
                            IconButton(
                              icon: const Icon(
                                Icons.cancel_outlined,
                                color: Colors.red,
                              ),
                              onPressed: () {},
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
          /// BOTTOM HALF (EMPTY NOW)
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