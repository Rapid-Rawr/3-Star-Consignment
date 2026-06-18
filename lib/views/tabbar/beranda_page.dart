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
import '../../utils/app_colors.dart';
import '../../widgets/gradient_button.dart';


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
        return const HomeAdminPage();
      case Roles.karyawan:
        return const _KaryawanContent();
      case Roles.client:
        return const HomeClientPage();
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
            GradientButton(
              label: 'Login',
              icon: const Icon(Icons.login_rounded, color: Colors.white, size: 18),
              onPressed: () {
                Scaffold.maybeOf(context)?.openEndDrawer();
              },
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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

class HomeAdminPage extends StatefulWidget {
  final FirebaseFirestore? firestore;

  const HomeAdminPage({super.key, this.firestore});

  @override
  State<HomeAdminPage> createState() => _HomeAdminPageState();
}

class _HomeAdminPageState extends State<HomeAdminPage> {
  FirebaseFirestore get _firestore =>
      widget.firestore ?? FirebaseFirestore.instance;

  late final Stream<QuerySnapshot> _requestsStream;
  late final Stream<QuerySnapshot> _clientsStream;

  @override
  void initState() {
    super.initState();
    _requestsStream = _firestore
        .collection('consignment_requests')
        .where('status', whereIn: ['pending', 'processing', 'packed'])
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
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            children: [
              const Text(
                'Daftar Pengajuan',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        ),
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
                      leading: _ClientAvatar(
                        clientId: batch.clientId,
                        name: batch.clientName,
                      ),
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
                            icon: const Icon(
                              Icons.check_rounded,
                              color: Colors.green,
                            ),
                            onPressed: () async {
                              await _approveAllItems(batch.id);
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Request berhasil disetujui'),
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
                              await _rejectAllItems(batch.id);
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Request ditolak'),
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

        Expanded(
          flex: 1,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                          MaterialPageRoute(builder: (_) => ConsignmentPage()),
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
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return _errorState(snapshot.error);
                      }
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final clients = snapshot.data!.docs
                          .map(
                            (doc) => ClientModel.fromMap(
                              doc.id,
                              doc.data() as Map<String, dynamic>,
                            ),
                          )
                          .where((client) => client.borrowedItems.isNotEmpty)
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
                            leading:
                                item.catalogImagePath != null &&
                                    item.catalogImagePath!.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      item.catalogImagePath!,
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : const CircleAvatar(
                                    child: Icon(Icons.inventory_2_outlined),
                                  ),
                            title: Text(
                              item.catalogName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
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

class _KaryawanContent extends StatefulWidget {
  const _KaryawanContent();

  @override
  State<_KaryawanContent> createState() => _KaryawanContentState();
}

class _KaryawanContentState extends State<_KaryawanContent> {
  late final Stream<QuerySnapshot> _requestsStream;

  @override
  void initState() {
    super.initState();
    _requestsStream = FirebaseFirestore.instance
        .collection('consignment_requests')
        .where('status', whereIn: ['pending', 'processing', 'packed'])
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'Daftar Pengajuan',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _requestsStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 8),
                      Text(
                        'Gagal memuat data:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                ),
              ],
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.inbox_outlined,
                  size: 64,
                  color: context.emptyIcon,
                ),
                const SizedBox(height: 16),
                Text(
                  'Belum ada pengajuan masuk',
                  style: TextStyle(
                    fontSize: 16,
                    color: context.emptyText,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          );
        }

        final docs = snapshot.data!.docs;
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final batch = ConsignmentRequestModel.fromMap(
              docs[index].id,
              docs[index].data() as Map<String, dynamic>,
            );
            return _RequestItem(batch: batch, isDark: isDark);
          },
            );
          },
        ),
        ),
      ],
    );
  }
}

class _ClientAvatar extends StatelessWidget {
  final String clientId;
  final String name;

  const _ClientAvatar({required this.clientId, required this.name});

  @override
  Widget build(BuildContext context) {
    if (clientId.isEmpty) {
      return CircleAvatar(
        radius: 21,
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      );
    }
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('clients')
          .doc(clientId)
          .get(),
      builder: (context, snap) {
        String? photoUrl;
        if (snap.hasData && snap.data!.exists) {
          final data = snap.data!.data() as Map<String, dynamic>?;
          photoUrl = data?['photoUrl'] as String?;
        }
        if (photoUrl != null && photoUrl.isNotEmpty) {
          return CircleAvatar(
            radius: 21,
            backgroundImage: NetworkImage(photoUrl),
          );
        }
        return CircleAvatar(
          radius: 21,
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        );
      },
    );
  }
}

class HomeClientPage extends StatefulWidget {

  final FirebaseAuth? auth;
  final FirebaseFirestore? firestore;

  const HomeClientPage({super.key, this.auth, this.firestore});


  @override
  State<HomeClientPage> createState() => HomeClientPageState();
}

class HomeClientPageState extends State<HomeClientPage> {
  static const int _previewLimit = 5;

  FirebaseAuth get _auth => widget.auth ?? FirebaseAuth.instance;
  FirebaseFirestore get _firestore => widget.firestore ?? FirebaseFirestore.instance;

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
    final Color cardBg = isDark ? const Color(0xFF2B2930) : Colors.white;
    final Color headerBg = isDark
        ? const Color(0xFF3A3540)
        : Colors.grey.shade100;
    final Color borderColor = isDark
        ? const Color(0xFF49454F)
        : Colors.grey.shade200;

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
            separatorBuilder: (_, __) => Divider(height: 1, color: borderColor),
            itemBuilder: (context, i) {
              final batch = ConsignmentRequestModel.fromMap(
                docs[i].id,
                docs[i].data() as Map<String, dynamic>,
              );
              return _RequestItem(batch: batch, isDark: isDark);
            },
          );
        }

        return _shell(
          cardBg: cardBg,
          headerBg: headerBg,
          borderColor: borderColor,
          showFooter: showFooter,
          onMoreTap: showFooter
              ? () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => RequestListPage()),
                )
              : null,
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
    VoidCallback? onMoreTap,
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
          InkWell(
            onTap: onMoreTap,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
            child: Container(
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
            Icon(
              icon,
              size: 48,
              color: isDark ? Colors.white24 : Colors.black26,
            ),
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
  final ConsignmentRequestModel batch;
  final bool isDark;

  const _RequestItem({required this.batch, required this.isDark});

  Color _statusColor(ConsignmentBatchStatus s) {
    switch (s) {
      case ConsignmentBatchStatus.received:
        return const Color(0xFF1565C0);
      case ConsignmentBatchStatus.packed:
        return const Color(0xFF6A1B9A);
      case ConsignmentBatchStatus.processing:
        return const Color(0xFF0277BD);
      case ConsignmentBatchStatus.rejected:
        return const Color(0xFFC62828);
      case ConsignmentBatchStatus.pending:
        return const Color(0xFFF57F17);
    }
  }

  IconData _statusIcon(ConsignmentBatchStatus s) {
    switch (s) {
      case ConsignmentBatchStatus.received:
        return Icons.verified_outlined;
      case ConsignmentBatchStatus.packed:
        return Icons.inventory_2_rounded;
      case ConsignmentBatchStatus.processing:
        return Icons.pending_actions_rounded;
      case ConsignmentBatchStatus.rejected:
        return Icons.cancel_outlined;
      case ConsignmentBatchStatus.pending:
        return Icons.hourglass_empty_rounded;
    }
  }

  String _statusLabel(ConsignmentBatchStatus s) {
    switch (s) {
      case ConsignmentBatchStatus.received:
        return 'Diserahkan';
      case ConsignmentBatchStatus.packed:
        return 'Dikemas';
      case ConsignmentBatchStatus.processing:
        return 'Diproses';
      case ConsignmentBatchStatus.rejected:
        return 'Ditolak';
      case ConsignmentBatchStatus.pending:
        return 'Menunggu';
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = batch.status;
        final clientName = batch.clientName;
    final createdAt = batch.createdAt != null ? Timestamp.fromDate(batch.createdAt!) : null;

    int totalQty = 0;
    double totalPrice = 0;
    for (final item in batch.items) {
      totalQty += item.quantity;
      totalPrice += item.quantity * item.catalogPrice;
    }

    final Color nameColor = isDark ? Colors.white : const Color(0xFF1D1B20);
    final Color subColor = isDark ? Colors.white54 : const Color(0xFF757575);
    final sColor = _statusColor(status);

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
          _ClientAvatar(
            clientId: batch.clientId,
            name: batch.clientName,
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
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: sColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _statusIcon(status),
                  size: 12,
                  color: sColor,
                ),
                const SizedBox(width: 4),
                Text(
                  _statusLabel(status),
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: sColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
