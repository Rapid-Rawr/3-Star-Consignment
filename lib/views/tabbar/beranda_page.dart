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
import '../../widgets/catalog_image.dart';


class BerandaPage extends StatelessWidget {
  const BerandaPage({super.key});

  @override
  Widget build(BuildContext context) {
    final role = context.watch<AuthProvider>().role;
    final user = FirebaseAuth.instance.currentUser;

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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock_outline_rounded,
              size: 64,
              color: context.emptyIcon,
            ),
            const SizedBox(height: 16),
            Text(
              'Anda belum login',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: context.nameColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Silakan login terlebih dahulu untuk mengakses beranda.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: context.emptyText,
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.person_off_outlined,
              size: 64,
              color: context.emptyIcon,
            ),
            const SizedBox(height: 16),
            Text(
              'Anda tidak berafiliasi dengan kami',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: context.nameColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Akun Gmail Anda tidak terdaftar di sistem.\nHubungi Toko Seragam 3 Jaya Star untuk informasi lebih lanjut.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: context.emptyText,
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          flex: 1,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: _AdminRequestCard(
              requestsStream: _requestsStream,
              firestore: _firestore,
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 96),
            child: _AdminClientsCard(
              clientsStream: _clientsStream,
            ),
          ),
        ),
      ],
    );
  }
}

class _AdminRequestCard extends StatelessWidget {
  final Stream<QuerySnapshot> requestsStream;
  final FirebaseFirestore firestore;

  const _AdminRequestCard({
    required this.requestsStream,
    required this.firestore,
  });

  Future<void> _approveAllItems(String batchId) async {
    final docRef = firestore.collection('consignment_requests').doc(batchId);
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
    final docRef = firestore.collection('consignment_requests').doc(batchId);
    final snapshot = await docRef.get();
    final data = snapshot.data();
    if (data == null) return;

    final List items = data['items'] ?? [];
    final updatedItems = items.map((item) {
      return {...item, 'itemStatus': 'rejected'};
    }).toList();

    await docRef.update({'items': updatedItems, 'status': 'rejected'});
  }

  Color _statusColor(BuildContext context, ConsignmentBatchStatus s) {
    switch (s) {
      case ConsignmentBatchStatus.received:
        return context.receivedFg;
      case ConsignmentBatchStatus.packed:
        return context.packedFg;
      case ConsignmentBatchStatus.processing:
        return context.processingFg;
      case ConsignmentBatchStatus.rejected:
        return context.rejectedFg;
      case ConsignmentBatchStatus.pending:
        return context.pendingFg;
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
            context: context,
            icon: Icons.error_outline,
            message: 'Gagal memuat data:\n${snapshot.error}',
          );
        } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          content = _emptyState(
            context: context,
            icon: Icons.inbox_outlined,
            message: 'Belum ada pengajuan masuk',
          );
        } else {
          showFooter = true;
          final docs = snapshot.data!.docs;
          final batches = docs.map((doc) {
            return ConsignmentRequestModel.fromMap(
              doc.id,
              doc.data() as Map<String, dynamic>,
            );
          }).toList();

          batches.sort((a, b) {
            const statusOrder = {
              ConsignmentBatchStatus.pending: 0,
              ConsignmentBatchStatus.processing: 1,
              ConsignmentBatchStatus.packed: 2,
              ConsignmentBatchStatus.received: 3,
              ConsignmentBatchStatus.rejected: 4,
            };
            final statusCompare = (statusOrder[a.status] ?? 999).compareTo(statusOrder[b.status] ?? 999);
            if (statusCompare != 0) return statusCompare;
            final aDate = a.createdAt ?? DateTime(1970);
            final bDate = b.createdAt ?? DateTime(1970);
            return bDate.compareTo(aDate);
          });

          content = ListView.separated(
            padding: const EdgeInsets.only(top: 8),
            itemCount: batches.length,
            separatorBuilder: (_, __) => Divider(height: 1, color: context.cardBorder),
            itemBuilder: (context, i) {
              final batch = batches[i];
              final showActions = batch.status == ConsignmentBatchStatus.pending ||
                  batch.status == ConsignmentBatchStatus.processing;
              return _AdminRequestItem(
                batch: batch,
                statusColor: _statusColor(context, batch.status),
                statusIcon: _statusIcon(batch.status),
                statusLabel: _statusLabel(batch.status),
                showActions: showActions,
                onDetail: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RequestListPage(initialBatch: batch),
                    ),
                  );
                },
                onApprove: () async {
                  await _approveAllItems(batch.id);
                  if (context.mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RequestListPage(initialBatch: batch),
                      ),
                    );
                  }
                },
                onReject: () async {
                  await _rejectAllItems(batch.id);
                  if (context.mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RequestListPage(initialBatch: batch),
                      ),
                    );
                  }
                },
              );
            },
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.cardBorder),
            boxShadow: [
              BoxShadow(
                color: context.cardShadow,
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
                  color: context.headerBg,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Text(
                  'Daftar Pengajuan',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: context.subColor,
                  ),
                ),
              ),
              Expanded(child: content),
              if (showFooter)
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => RequestListPage()),
                    );
                  },
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
                        color: context.subColor,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _emptyState({required BuildContext context, required IconData icon, required String message}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 48,
              color: context.emptyIcon,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: context.emptyText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminRequestItem extends StatelessWidget {
  final ConsignmentRequestModel batch;
  final Color statusColor;
  final IconData statusIcon;
  final String statusLabel;
  final bool showActions;
  final VoidCallback onDetail;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _AdminRequestItem({
    required this.batch,
    required this.statusColor,
    required this.statusIcon,
    required this.statusLabel,
    required this.showActions,
    required this.onDetail,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    int totalQty = 0;
    double totalPrice = 0;
    for (final item in batch.items) {
      totalQty += item.quantity;
      totalPrice += item.quantity * item.catalogPrice;
    }

    String dateLabel = '';
    if (batch.createdAt != null) {
      final dt = batch.createdAt!;
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
                  batch.clientName,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: context.nameColor,
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
                    color: context.subColor,
                  ),
                ),
                if (dateLabel.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    dateLabel,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      color: context.subColor,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        statusIcon,
                        size: 12,
                        color: statusColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        statusLabel,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (showActions)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ActionButton(
                  icon: Icons.list_alt_rounded,
                  color: context.primaryFg,
                  onTap: onDetail,
                ),
                const SizedBox(width: 6),
                _ActionButton(
                  icon: Icons.check_rounded,
                  color: Colors.green,
                  onTap: onApprove,
                ),
                const SizedBox(width: 6),
                _ActionButton(
                  icon: Icons.close_rounded,
                  color: Colors.red,
                  onTap: onReject,
                ),
              ],
            ),
          if (!showActions)
            _ActionButton(
              icon: Icons.list_alt_rounded,
              color: context.primaryFg,
              onTap: onDetail,
            ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }
}

class _AdminClientsCard extends StatelessWidget {
  final Stream<QuerySnapshot> clientsStream;

  const _AdminClientsCard({
    required this.clientsStream,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: clientsStream,
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
            context: context,
            icon: Icons.error_outline,
            message: 'Gagal memuat data:\n${snapshot.error}',
          );
        } else if (!snapshot.hasData) {
          content = _emptyState(
            context: context,
            icon: Icons.inventory_2_outlined,
            message: 'Belum ada barang konsinyasi',
          );
        } else {
          final clients = snapshot.data!.docs
              .map(
                (doc) => ClientModel.fromMap(
                  doc.id,
                  doc.data() as Map<String, dynamic>,
                ),
              )
              .where((client) => client.borrowedItems.isNotEmpty)
              .toList();

          showFooter = clients.isNotEmpty;

          if (clients.isEmpty) {
            content = _emptyState(
              context: context,
              icon: Icons.inventory_2_outlined,
              message: 'Belum ada barang konsinyasi',
            );
          } else {
            content = ListView.separated(
              padding: const EdgeInsets.only(top: 8),
              itemCount: clients.length,
              separatorBuilder: (_, __) => Divider(height: 1, color: context.cardBorder),
              itemBuilder: (context, i) {
                final client = clients[i];
                final item = client.borrowedItems.first;
                return _AdminClientItem(
                  client: client,
                  item: item,
                );
              },
            );
          }
        }

        return Container(
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.cardBorder),
            boxShadow: [
              BoxShadow(
                color: context.cardShadow,
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
                  color: context.headerBg,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Text(
                  'Barang Konsinyasi',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: context.subColor,
                  ),
                ),
              ),
              Expanded(child: content),
              if (showFooter)
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ConsignmentPage()),
                    );
                  },
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
                        color: context.subColor,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _emptyState({required BuildContext context, required IconData icon, required String message}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 48,
              color: context.emptyIcon,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: context.emptyText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminClientItem extends StatelessWidget {
  final ClientModel client;
  final BorrowedItem item;

  const _AdminClientItem({
    required this.client,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          CatalogImage(
            imagePath: item.catalogImagePath,
            size: 44,
            borderRadius: 8,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.catalogName,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: context.nameColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Peminjam: ${client.name}',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    color: context.subColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Qty: ${item.quantity}',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    color: context.subColor,
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      child: _KaryawanRequestCard(
        requestsStream: _requestsStream,
      ),
    );
  }
}

class _KaryawanRequestCard extends StatelessWidget {
  final Stream<QuerySnapshot> requestsStream;

  const _KaryawanRequestCard({
    required this.requestsStream,
  });

  @override
  Widget build(BuildContext context) {
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
            context: context,
            icon: Icons.error_outline,
            message: 'Gagal memuat data:\n${snapshot.error}',
          );
        } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          content = _emptyState(
            context: context,
            icon: Icons.inbox_outlined,
            message: 'Belum ada pengajuan masuk',
          );
        } else {
          showFooter = true;
          final docs = snapshot.data!.docs;
          final batches = docs.map((doc) {
            return ConsignmentRequestModel.fromMap(
              doc.id,
              doc.data() as Map<String, dynamic>,
            );
          }).toList();

          batches.sort((a, b) {
            const statusOrder = {
              ConsignmentBatchStatus.pending: 0,
              ConsignmentBatchStatus.processing: 1,
              ConsignmentBatchStatus.packed: 2,
              ConsignmentBatchStatus.received: 3,
              ConsignmentBatchStatus.rejected: 4,
            };
            final statusCompare = (statusOrder[a.status] ?? 999).compareTo(statusOrder[b.status] ?? 999);
            if (statusCompare != 0) return statusCompare;
            final aDate = a.createdAt ?? DateTime(1970);
            final bDate = b.createdAt ?? DateTime(1970);
            return bDate.compareTo(aDate);
          });

          content = ListView.separated(
            padding: const EdgeInsets.only(top: 8),
            itemCount: batches.length,
            separatorBuilder: (_, __) => Divider(height: 1, color: context.cardBorder),
            itemBuilder: (context, i) {
              final batch = batches[i];
              return _RequestItem(
                batch: batch,
                onDetail: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RequestListPage(initialBatch: batch),
                  ),
                ),
              );
            },
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.cardBorder),
            boxShadow: [
              BoxShadow(
                color: context.cardShadow,
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
                  color: context.headerBg,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Text(
                  'Daftar Pengajuan',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: context.subColor,
                  ),
                ),
              ),
              Expanded(child: content),
              if (showFooter)
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => RequestListPage()),
                    );
                  },
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
                        color: context.subColor,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _emptyState({required BuildContext context, required IconData icon, required String message}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 48,
              color: context.emptyIcon,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: context.emptyText,
              ),
            ),
          ],
        ),
      ),
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
      if (!mounted) return;
      setState(() => _loadingClient = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingClient) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Expanded(
          flex: 1,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: _ClientRequestCard(
              clientId: _clientId,
              requestsStream: _requestsStream,
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 96),
            child: _ClientBorrowedItemsCard(
              clientId: _clientId,
              firestore: _firestore,
            ),
          ),
        ),
      ],
    );
  }
}

class _ClientRequestCard extends StatelessWidget {
  final String? clientId;
  final Stream<QuerySnapshot>? requestsStream;

  const _ClientRequestCard({
    required this.clientId,
    required this.requestsStream,
  });

  @override
  Widget build(BuildContext context) {
    if (clientId == null) {
      return _shell(
        context: context,
        showFooter: false,
        child: _emptyState(
          context: context,
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
            context: context,
            icon: Icons.error_outline,
            message: 'Gagal memuat data:\n${snapshot.error}',
          );
        } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          content = _emptyState(
            context: context,
            icon: Icons.inventory_2_outlined,
            message: 'Belum ada pengajuan konsinyasi',
          );
        } else {
          showFooter = true;
          final docs = snapshot.data!.docs;
          final batches = docs.map((doc) {
            return ConsignmentRequestModel.fromMap(
              doc.id,
              doc.data() as Map<String, dynamic>,
            );
          }).toList();

          batches.sort((a, b) {
            const statusOrder = {
              ConsignmentBatchStatus.pending: 0,
              ConsignmentBatchStatus.processing: 1,
              ConsignmentBatchStatus.packed: 2,
              ConsignmentBatchStatus.received: 3,
              ConsignmentBatchStatus.rejected: 4,
            };
            final statusCompare = (statusOrder[a.status] ?? 999).compareTo(statusOrder[b.status] ?? 999);
            if (statusCompare != 0) return statusCompare;
            final aDate = a.createdAt ?? DateTime(1970);
            final bDate = b.createdAt ?? DateTime(1970);
            return bDate.compareTo(aDate);
          });

          content = ListView.separated(
            padding: const EdgeInsets.only(top: 8),
            itemCount: batches.length,
            separatorBuilder: (_, __) => Divider(height: 1, color: context.cardBorder),
            itemBuilder: (context, i) {
              final batch = batches[i];
              return _RequestItem(
                batch: batch,
                onDetail: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RequestListPage(initialBatch: batch),
                  ),
                ),
              );
            },
          );
        }

        return _shell(
          context: context,
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
    required BuildContext context,
    required bool showFooter,
    required Widget child,
    VoidCallback? onMoreTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.cardBorder),
        boxShadow: [
          BoxShadow(
            color: context.cardShadow,
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
              color: context.headerBg,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Text(
              'Daftar Pengajuan',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: context.subColor,
              ),
            ),
          ),
          Expanded(child: child),
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
                  color: context.subColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState({required BuildContext context, required IconData icon, required String message}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 48,
              color: context.emptyIcon,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: context.emptyText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClientBorrowedItemsCard extends StatelessWidget {
  final String? clientId;
  final FirebaseFirestore firestore;

  const _ClientBorrowedItemsCard({
    required this.clientId,
    required this.firestore,
  });

  @override
  Widget build(BuildContext context) {
    if (clientId == null) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: firestore.collection('clients').doc(clientId).snapshots(),
      builder: (context, snapshot) {
        Widget content;
        bool showFooter = false;
        List<BorrowedItem> borrowedItems = [];

        if (snapshot.connectionState == ConnectionState.waiting) {
          content = const Padding(
            padding: EdgeInsets.symmetric(vertical: 36),
            child: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError) {
          content = _emptyState(
            context: context,
            icon: Icons.error_outline,
            message: 'Gagal memuat data:\n${snapshot.error}',
          );
        } else if (!snapshot.hasData || !snapshot.data!.exists) {
          content = _emptyState(
            context: context,
            icon: Icons.inventory_2_outlined,
            message: 'Data klien tidak ditemukan',
          );
        } else {
          final client = ClientModel.fromMap(
            snapshot.data!.id,
            snapshot.data!.data() as Map<String, dynamic>,
          );
          borrowedItems = client.borrowedItems;
          showFooter = borrowedItems.isNotEmpty;

          if (borrowedItems.isEmpty) {
            content = _emptyState(
              context: context,
              icon: Icons.inventory_2_outlined,
              message: 'Belum ada barang konsinyasi',
            );
          } else {
            content = ListView.separated(
              padding: const EdgeInsets.only(top: 8),
              itemCount: borrowedItems.length,
              separatorBuilder: (_, __) => Divider(height: 1, color: context.cardBorder),
              itemBuilder: (context, i) {
                final item = borrowedItems[i];
                return _BorrowedItemTile(item: item);
              },
            );
          }
        }

        return Container(
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.cardBorder),
            boxShadow: [
              BoxShadow(
                color: context.cardShadow,
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
                  color: context.headerBg,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Text(
                  'Barang Konsinyasi',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: context.subColor,
                  ),
                ),
              ),
              Expanded(child: content),
              if (showFooter)
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ConsignmentPage()),
                    );
                  },
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
                        color: context.subColor,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _emptyState({required BuildContext context, required IconData icon, required String message}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 48,
              color: context.emptyIcon,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: context.emptyText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BorrowedItemTile extends StatelessWidget {
  final BorrowedItem item;

  const _BorrowedItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          CatalogImage(
            imagePath: item.catalogImagePath,
            size: 44,
            borderRadius: 8,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.catalogName,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: context.nameColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  item.catalogCategory,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    color: context.subColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.quantity}x ${formatRupiah(item.catalogPrice)}',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    color: context.subColor,
                  ),
                ),
              ],
            ),
          ),
          Text(
            formatRupiah(item.catalogPrice * item.quantity),
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: context.primaryFg,
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestItem extends StatelessWidget {
  final ConsignmentRequestModel batch;
  final VoidCallback? onDetail;

  const _RequestItem({
    required this.batch,
    this.onDetail,
  });

  Color _statusColor(BuildContext context, ConsignmentBatchStatus s) {
    switch (s) {
      case ConsignmentBatchStatus.received:
        return context.receivedFg;
      case ConsignmentBatchStatus.packed:
        return context.packedFg;
      case ConsignmentBatchStatus.processing:
        return context.processingFg;
      case ConsignmentBatchStatus.rejected:
        return context.rejectedFg;
      case ConsignmentBatchStatus.pending:
        return context.pendingFg;
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

    final sColor = _statusColor(context, status);

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
                    color: context.nameColor,
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
                    color: context.subColor,
                  ),
                ),
                if (dateLabel.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    dateLabel,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      color: context.subColor,
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
          if (onDetail != null) ...[
            const SizedBox(width: 8),
            _ActionButton(
              icon: Icons.list_alt_rounded,
              color: context.primaryFg,
              onTap: onDetail!,
            ),
          ],
        ],
      ),
    );
  }
}
