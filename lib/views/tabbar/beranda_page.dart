import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../service/auth_provider.dart';
import '../../service/roles.dart';
import '../../models/barang_models/konsinyasi_model.dart';
import '../../models/pengguna_models/klien_model.dart';
import '../../views/barang/daftar_pengajuan_page.dart';
import '../barang/barang_konsinyasi_page.dart';
import '../../utils/currency_format.dart';

class BerandaPage extends StatelessWidget {
  const BerandaPage({super.key});

  @override
  Widget build(BuildContext context) {
    final role = context.watch<AuthProvider>().role;
    final user = FirebaseAuth.instance.currentUser;

    debugPrint('[BerandaPage] role=$role user=${user?.email}');

    if (user == null) {
      return const _NotLoggedInView();
    }
    if (role == null) {
      return const _UnregisteredView();
    }
    switch (role) {
      case Roles.admin:
        return const _AdminContent();
      case Roles.karyawan:
        return const _KaryawanContent();
      case Roles.client:
        return const _ClientContent();
      default:
        return const _UnregisteredView();
    }
  }
}

class _NotLoggedInView extends StatelessWidget {
  const _NotLoggedInView();

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock_outline_rounded,
              size: 64,
              color: isDark ? Colors.white24 : Colors.black26,
            ),
            const SizedBox(height: 16),
            Text(
              'Anda belum login',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : const Color(0xFF1D1B20),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Silakan login terlebih dahulu untuk mengakses beranda.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: isDark ? Colors.white38 : Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Scaffold.maybeOf(context)?.openEndDrawer();
              },
              icon: const Icon(Icons.login_rounded),
              label: const Text(
                'Login',
                style: TextStyle(fontFamily: 'Poppins'),
              ),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UnregisteredView extends StatelessWidget {
  const _UnregisteredView();

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.person_off_outlined,
              size: 64,
              color: isDark ? Colors.white24 : Colors.black26,
            ),
            const SizedBox(height: 16),
            Text(
              'Gmail tidak terdaftar',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : const Color(0xFF1D1B20),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Akun Anda belum terdaftar di sistem.\nHubungi admin untuk pendaftaran.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: isDark ? Colors.white38 : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminContent extends StatefulWidget {
  const _AdminContent();

  @override
  State<_AdminContent> createState() => _AdminContentState();
}

class _AdminContentState extends State<_AdminContent> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late final Stream<QuerySnapshot> _requestsStream;
  late final Stream<QuerySnapshot> _clientsStream;

  @override
  void initState() {
    super.initState();
    _requestsStream = _firestore
        .collection('consignment_requests')
        .where('status', isEqualTo: 'pending')
        .snapshots();
    _clientsStream = _firestore.collection('clients').snapshots();
  }

  Future<void> _approveAllItems(String batchId) async {
    final docRef = _firestore.collection('consignment_requests').doc(batchId);
    final snapshot = await docRef.get();
    final data = snapshot.data();
    if (data == null) return;

    final List items = data['items'] ?? [];
    final updatedItems = items.map((item) {
      return {...item, 'itemStatus': 'approved'};
    }).toList();

    await docRef.update({'items': updatedItems, 'status': 'processing'});
  }

  Future<void> _rejectAllItems(String batchId) async {
    final docRef = _firestore.collection('consignment_requests').doc(batchId);
    final snapshot = await docRef.get();
    final data = snapshot.data();
    if (data == null) return;

    final List items = data['items'] ?? [];
    final updatedItems = items.map((item) {
      return {...item, 'itemStatus': 'rejected'};
    }).toList();

    await docRef.update({'items': updatedItems, 'status': 'rejected'});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          flex: 1,
          child: StreamBuilder<QuerySnapshot>(
            stream: _requestsStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return _errorState(snapshot.error);
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text("Belum ada data"));
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

                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      title: Text(batch.clientName),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.assignment_outlined),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      RequestListPage(initialBatch: batch),
                                ),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.check_rounded,
                                color: Colors.green),
                            onPressed: () async {
                              await _approveAllItems(batch.id);
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('Request berhasil disetujui')),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.cancel_outlined,
                                color: Colors.red),
                            onPressed: () async {
                              await _rejectAllItems(batch.id);
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Request ditolak')),
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

        Expanded(
          flex: 1,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                    stream: _clientsStream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                            child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return _errorState(snapshot.error);
                      }
                      if (!snapshot.hasData) {
                        return const Center(
                            child: CircularProgressIndicator());
                      }

                      final clients = snapshot.data!.docs
                          .map(
                            (doc) => ClientModel.fromMap(
                              doc.id,
                              doc.data() as Map<String, dynamic>,
                            ),
                          )
                          .where(
                              (client) => client.borrowedItems.isNotEmpty)
                          .take(5)
                          .toList();

                      if (clients.isEmpty) {
                        return const Center(
                          child: Text("Belum ada barang konsinyasi"),
                        );
                      }

                      return ListView.builder(
                        itemCount: clients.length,
                        itemBuilder: (context, index) {
                          final client = clients[index];
                          final item = client.borrowedItems.first;

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
                                        Icons.inventory_2_outlined),
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
                                Text('Peminjam: ${client.name}'),
                                Text('Qty: ${item.quantity}'),
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
    );
  }

  Widget _errorState(Object? error) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 8),
          Text(
            'Gagal memuat data:\n$error',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _KaryawanContent extends StatelessWidget {
  const _KaryawanContent();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Beranda Karyawan'));
  }
}

class _ClientContent extends StatefulWidget {
  const _ClientContent();

  @override
  State<_ClientContent> createState() => _ClientContentState();
}

class _ClientContentState extends State<_ClientContent> {
  static const int _previewLimit = 5;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _clientId;
  bool _loadingClient = true;
  Stream<QuerySnapshot>? _requestsStream;

  @override
  void initState() {
    super.initState();
    _resolveClientId();
  }

  Future<void> _resolveClientId() async {
    final user = _auth.currentUser;
    if (user == null) {
      if (!mounted) return;
      setState(() => _loadingClient = false);
      return;
    }
    try {
      final snap = await _firestore
          .collection('clients')
          .where('email', isEqualTo: user.email)
          .limit(1)
          .get();

      if (!mounted) return;

      final clientId = snap.docs.isNotEmpty ? snap.docs.first.id : null;

      if (clientId != null) {
        _requestsStream = _firestore
            .collection('consignment_requests')
            .where('clientId', isEqualTo: clientId)
            .orderBy('createdAt', descending: true)
            .limit(_previewLimit)
            .snapshots();
      }

      setState(() {
        _clientId = clientId;
        _loadingClient = false;
      });
    } catch (e) {
      debugPrint('[BerandaClient] _resolveClientId error: $e');
      if (!mounted) return;
      setState(() => _loadingClient = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    if (_loadingClient) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: _ClientRequestCard(
        clientId: _clientId,
        requestsStream: _requestsStream,
        isDark: isDark,
      ),
    );
  }
}

class _ClientRequestCard extends StatelessWidget {
  final String? clientId;
  final Stream<QuerySnapshot>? requestsStream;
  final bool isDark;

  const _ClientRequestCard({
    required this.clientId,
    required this.requestsStream,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final Color cardBg =
        isDark ? const Color(0xFF2B2930) : Colors.white;
    final Color headerBg =
        isDark ? const Color(0xFF3A3540) : Colors.grey.shade100;
    final Color borderColor =
        isDark ? const Color(0xFF49454F) : Colors.grey.shade200;

    if (clientId == null) {
      return _shell(
        cardBg: cardBg,
        headerBg: headerBg,
        borderColor: borderColor,
        showFooter: false,
        child: _emptyState(
          icon: Icons.info_outline,
          message:
              'Akun belum terdaftar sebagai klien.\nHubungi admin untuk pendaftaran.',
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: requestsStream,
      builder: (context, snapshot) {
        Widget content;
        bool showFooter = false;

        if (snapshot.connectionState == ConnectionState.waiting) {
          content = const Padding(
            padding: EdgeInsets.symmetric(vertical: 36),
            child: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError) {
          content = _emptyState(
            icon: Icons.error_outline,
            message: 'Gagal memuat data:\n${snapshot.error}',
          );
        } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          content = _emptyState(
            icon: Icons.inventory_2_outlined,
            message: 'Belum ada pengajuan konsinyasi',
          );
        } else {
          showFooter = true;
          final docs = snapshot.data!.docs;
          content = ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: docs.length,
            separatorBuilder: (_, __) =>
                Divider(height: 1, color: borderColor),
            itemBuilder: (context, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              return _RequestItem(data: data, isDark: isDark);
            },
          );
        }

        return _shell(
          cardBg: cardBg,
          headerBg: headerBg,
          borderColor: borderColor,
          showFooter: showFooter,
          child: content,
        );
      },
    );
  }

  Widget _shell({
    required Color cardBg,
    required Color headerBg,
    required Color borderColor,
    required bool showFooter,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black26
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: headerBg,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Text(
              'Request List',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
            ),
          ),
          child,
          if (showFooter)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              alignment: Alignment.center,
              child: Text(
                'Lebih Banyak ...',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: isDark ? Colors.white38 : Colors.black54,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _emptyState({required IconData icon, required String message}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 48,
                color: isDark ? Colors.white24 : Colors.black26),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: isDark ? Colors.white38 : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RequestItem extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isDark;

  const _RequestItem({required this.data, required this.isDark});

  Color _statusColor(String s) {
    switch (s.toLowerCase()) {
      case 'received':
        return const Color(0xFF1565C0);
      case 'packed':
        return const Color(0xFF6A1B9A);
      case 'processing':
        return const Color(0xFF0277BD);
      case 'rejected':
        return const Color(0xFFC62828);
      case 'pending':
      default:
        return const Color(0xFFF57F17);
    }
  }

  String _statusLabel(String s) {
    switch (s.toLowerCase()) {
      case 'received':
        return 'Diterima';
      case 'packed':
        return 'Dikemas';
      case 'processing':
        return 'Diproses';
      case 'rejected':
        return 'Ditolak';
      case 'pending':
      default:
        return 'Menunggu';
    }
  }

  @override
  Widget build(BuildContext context) {
    final String status = (data['status'] as String?) ?? 'pending';
    final String clientName = (data['clientName'] as String?) ?? '-';
    final Timestamp? createdAt = data['createdAt'] as Timestamp?;

    final List rawItems = (data['items'] as List?) ?? [];
    int totalQty = 0;
    double totalPrice = 0;
    for (final e in rawItems) {
      if (e is Map) {
        final qty = (e['quantity'] as num?)?.toInt() ?? 0;
        final price = (e['catalogPrice'] as num?)?.toDouble() ?? 0.0;
        totalQty += qty;
        totalPrice += qty * price;
      }
    }

    final Color nameColor =
        isDark ? Colors.white : const Color(0xFF1D1B20);
    final Color subColor =
        isDark ? Colors.white54 : const Color(0xFF757575);
    final Color sColor = _statusColor(status);

    String dateLabel = '';
    if (createdAt != null) {
      final dt = createdAt.toDate();
      dateLabel =
          '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1A3A2A)
                  : const Color(0xFFE6F4EA),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.assignment_outlined,
              size: 20,
              color: isDark
                  ? const Color(0xFF80CBC4)
                  : const Color(0xFF2E7D32),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  clientName,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: nameColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '$totalQty item  •  ${formatRupiah(totalPrice)}',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    color: subColor,
                  ),
                ),
                if (dateLabel.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    dateLabel,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      color: subColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: sColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _statusLabel(status),
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: sColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
