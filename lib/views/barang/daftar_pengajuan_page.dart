import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../controllers/barang_controllers/konsinyasi_controller.dart';
import '../../models/barang_models/konsinyasi_model.dart';
import '../../widgets/search_filter_bar.dart';
import '../../widgets/catalog_image.dart';
import '../../widgets/gradient_button.dart';
import '../../utils/currency_format.dart';
import '../../widgets/app_dialog.dart';

class RequestListPage extends StatefulWidget {
  const RequestListPage({super.key});

  @override
  State<RequestListPage> createState() => _RequestListPageState();
}

class _RequestListPageState extends State<RequestListPage> {
  late final ConsignmentRequestController _controller;
  late final Stream<QuerySnapshot> _stream;

  // Map<clientId, photoUrl> — loaded once from clients collection
  Map<String, String> _clientPhotoMap = {};

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';
  ConsignmentBatchStatus? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _controller = ConsignmentRequestController(
      firestore: FirebaseFirestore.instance,
    );
    _stream = _controller.getRequestsStream();
    _loadClientPhotos();
  }

  Future<void> _loadClientPhotos() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('clients')
          .get();
      if (!mounted) return;
      setState(() {
        _clientPhotoMap = {
          for (final doc in snap.docs)
            if ((doc.data()['photoUrl'] as String?)?.isNotEmpty == true)
              doc.id: doc.data()['photoUrl'] as String,
        };
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Color _batchStatusBg(ConsignmentBatchStatus s, bool isDark) {
    switch (s) {
      case ConsignmentBatchStatus.pending:
        return isDark ? const Color(0xFF2A2A1A) : const Color(0xFFFFF8E1);
      case ConsignmentBatchStatus.processing:
        return isDark ? const Color(0xFF1A2A3A) : const Color(0xFFE3F2FD);
      case ConsignmentBatchStatus.packed:
        return isDark ? const Color(0xFF1A3A2A) : const Color(0xFFE6F4EA);
      case ConsignmentBatchStatus.received:
        return isDark ? const Color(0xFF1A3A3A) : const Color(0xFFE0F2F1);
      case ConsignmentBatchStatus.rejected:
        return isDark ? const Color(0xFF3A1A1A) : const Color(0xFFFCE8E8);
    }
  }

  Color _batchStatusFg(ConsignmentBatchStatus s, bool isDark) {
    switch (s) {
      case ConsignmentBatchStatus.pending:
        return isDark ? const Color(0xFFFFD54F) : const Color(0xFFF57F17);
      case ConsignmentBatchStatus.processing:
        return isDark ? const Color(0xFF90CAF9) : const Color(0xFF1565C0);
      case ConsignmentBatchStatus.packed:
        return isDark ? const Color(0xFF80CBC4) : const Color(0xFF2E7D32);
      case ConsignmentBatchStatus.received:
        return isDark ? const Color(0xFF4DB6AC) : const Color(0xFF00796B);
      case ConsignmentBatchStatus.rejected:
        return isDark ? const Color(0xFFFF8A8A) : Colors.red;
    }
  }

  IconData _batchStatusIcon(ConsignmentBatchStatus s) {
    switch (s) {
      case ConsignmentBatchStatus.pending:
        return Icons.hourglass_empty_rounded;
      case ConsignmentBatchStatus.processing:
        return Icons.pending_actions_rounded;
      case ConsignmentBatchStatus.packed:
        return Icons.inventory_2_rounded;
      case ConsignmentBatchStatus.received:
        return Icons.verified_outlined;
      case ConsignmentBatchStatus.rejected:
        return Icons.cancel_outlined;
    }
  }

  String _batchStatusLabel(ConsignmentBatchStatus s) {
    switch (s) {
      case ConsignmentBatchStatus.pending:
        return 'Menunggu';
      case ConsignmentBatchStatus.processing:
        return 'Diproses';
      case ConsignmentBatchStatus.packed:
        return 'Dikemas';
      case ConsignmentBatchStatus.received:
        return 'Diserahkan';
      case ConsignmentBatchStatus.rejected:
        return 'Ditolak';
    }
  }

  Color _itemStatusBg(ConsignmentItemStatus s, bool isDark) {
    switch (s) {
      case ConsignmentItemStatus.pending:
        return isDark ? const Color(0xFF2A2A1A) : const Color(0xFFFFF8E1);
      case ConsignmentItemStatus.approved:
        return isDark ? const Color(0xFF1A3A2A) : const Color(0xFFE6F4EA);
      case ConsignmentItemStatus.partial:
        return isDark ? const Color(0xFF1A2A3A) : const Color(0xFFE3F2FD);
      case ConsignmentItemStatus.rejected:
        return isDark ? const Color(0xFF3A1A1A) : const Color(0xFFFCE8E8);
    }
  }

  Color _itemStatusFg(ConsignmentItemStatus s, bool isDark) {
    switch (s) {
      case ConsignmentItemStatus.pending:
        return isDark ? const Color(0xFFFFD54F) : const Color(0xFFF57F17);
      case ConsignmentItemStatus.approved:
        return isDark ? const Color(0xFF80CBC4) : const Color(0xFF2E7D32);
      case ConsignmentItemStatus.partial:
        return isDark ? const Color(0xFF90CAF9) : const Color(0xFF1565C0);
      case ConsignmentItemStatus.rejected:
        return isDark ? const Color(0xFFFF8A8A) : Colors.red;
    }
  }

  IconData _itemStatusIcon(ConsignmentItemStatus s) {
    switch (s) {
      case ConsignmentItemStatus.pending:
        return Icons.hourglass_empty_rounded;
      case ConsignmentItemStatus.approved:
        return Icons.check_circle_outline_rounded;
      case ConsignmentItemStatus.partial:
        return Icons.rule_rounded;
      case ConsignmentItemStatus.rejected:
        return Icons.cancel_outlined;
    }
  }

  String _itemStatusLabel(ConsignmentItemStatus s) {
    switch (s) {
      case ConsignmentItemStatus.pending:
        return 'Menunggu';
      case ConsignmentItemStatus.approved:
        return 'Diterima';
      case ConsignmentItemStatus.partial:
        return 'Sebagian';
      case ConsignmentItemStatus.rejected:
        return 'Ditolak';
    }
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '-';
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${dt.day} ${months[dt.month]} ${dt.year}';
  }

  Future<void> _partialDialog(
    BuildContext context,
    ConsignmentRequestModel batch,
    int itemIndex,
    ConsignmentItemEntry item,
    bool isDark,
  ) async {
    final qtyCtrl = TextEditingController();
    int? result;

    await showAppDialog(
      context: context,
      title: 'Penuhi Sebagian',
      contentWidget: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Masukkan jumlah yang dipenuhi untuk "${item.catalogName}" (max ${item.quantity - 1}):',
            style: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: qtyCtrl,
            keyboardType: TextInputType.number,
            autofocus: true,
            cursorColor: isDark ? Colors.white : const Color(0xFF1D1B20),
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: isDark ? Colors.white : const Color(0xFF1D1B20),
                  width: 2,
                ),
              ),
              hintText: 'Jumlah',
            ),
          ),
        ],
      ),
      actions: [
        AppDialogAction(
          label: 'Batal',
          onPressed: () => Navigator.pop(context),
        ),
        AppDialogAction(
          label: 'Simpan',
          type: AppDialogActionType.gradient,
          onPressed: () {
            final val = int.tryParse(qtyCtrl.text.trim());
            if (val == null || val <= 0 || val >= item.quantity) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Masukkan angka antara 1 dan ${item.quantity - 1}',
                  ),
                ),
              );
              return;
            }
            result = val;
            Navigator.pop(context);
          },
        ),
      ],
    );
    if (result != null) {
      await _controller.updateItemStatus(
        batch.id,
        itemIndex,
        ConsignmentItemStatus.partial,
        approvedQty: result,
      );
    }
  }

  void _showDetail(
    BuildContext context,
    ConsignmentRequestModel batch,
    bool isDark,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _DetailSheet(
        batch: batch,
        isDark: isDark,
        itemStatusBg: _itemStatusBg,
        itemStatusFg: _itemStatusFg,
        itemStatusIcon: _itemStatusIcon,
        itemStatusLabel: _itemStatusLabel,
        batchStatusBg: _batchStatusBg,
        batchStatusFg: _batchStatusFg,
        batchStatusIcon: _batchStatusIcon,
        batchStatusLabel: _batchStatusLabel,
        formatDate: _formatDate,
        onApproveItem: (index) => _controller.updateItemStatus(
          batch.id,
          index,
          ConsignmentItemStatus.approved,
        ),
        onRejectItem: (index) => _controller.updateItemStatus(
          batch.id,
          index,
          ConsignmentItemStatus.rejected,
        ),
        onCancelItem: (index) => _controller.updateItemStatus(
          batch.id,
          index,
          ConsignmentItemStatus.pending,
        ),
        onPartialItem: (index) =>
            _partialDialog(context, batch, index, batch.items[index], isDark),
        onPack: () => _controller.packBatch(batch.id),
        onReceive: () => _controller.receiveBatch(batch.id),
        onRejectBatch: () => _controller.rejectBatch(batch.id),
        onCancelAll: () => _controller.cancelAllItems(batch.id),
      ),
    );
  }

  Future<void> _approveAllThenDetail(
    BuildContext context,
    ConsignmentRequestModel batch,
    bool isDark,
  ) async {
    final result = await _controller.approveAllPending(batch.id);
    if (!context.mounted) return;
    if (result['success'] == true) {
      _showDetail(context, batch, isDark);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['error'] ?? 'Terjadi kesalahan'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _rejectAllThenDetail(
    BuildContext context,
    ConsignmentRequestModel batch,
    bool isDark,
  ) async {
    final result = await _controller.rejectAllPending(batch.id);
    if (!context.mounted) return;
    if (result['success'] == true) {
      _showDetail(context, batch, isDark);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['error'] ?? 'Terjadi kesalahan'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color emptyIcon = isDark ? Colors.white24 : Colors.black26;
    final Color emptyText = isDark ? Colors.white38 : const Color(0xFF9E9E9E);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Daftar Pengajuan',
          style: TextStyle(fontFamily: 'Poppins'),
        ),
      ),
      body: Column(
        children: [
          SearchFilterBar<ConsignmentBatchStatus>(
            searchController: _searchController,
            searchFocusNode: _searchFocusNode,
            hintText: 'Cari nama atau institusi...',
            onSearchChanged: (val) {
              setState(() {
                _searchQuery = val.trim().toLowerCase();
              });
            },
            filters: const [
              FilterChipOption(label: 'Semua', value: null),
              FilterChipOption(
                label: 'Menunggu',
                value: ConsignmentBatchStatus.pending,
              ),
              FilterChipOption(
                label: 'Diproses',
                value: ConsignmentBatchStatus.processing,
              ),
              FilterChipOption(
                label: 'Dikemas',
                value: ConsignmentBatchStatus.packed,
              ),
            ],
            selectedFilter: _selectedStatus,
            onFilterSelected: (val) {
              setState(() {
                _selectedStatus = val;
              });
            },
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _stream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: const TextStyle(
                        color: Colors.red,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.assignment_outlined,
                          size: 64,
                          color: emptyIcon,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Belum Ada Pengajuan',
                          style: TextStyle(
                            fontSize: 16,
                            color: emptyText,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  );
                }

                var batches = snapshot.data!.docs
                    .map(
                      (d) => ConsignmentRequestModel.fromMap(
                        d.id,
                        d.data() as Map<String, dynamic>,
                      ),
                    )
                    .where(
                      (b) =>
                          b.status != ConsignmentBatchStatus.received &&
                          b.status != ConsignmentBatchStatus.rejected,
                    )
                    .toList();

                if (_selectedStatus != null) {
                  batches = batches
                      .where((b) => b.status == _selectedStatus)
                      .toList();
                }

                if (_searchQuery.isNotEmpty) {
                  batches = batches.where((b) {
                    final nameMatch = b.clientName.toLowerCase().contains(
                      _searchQuery,
                    );
                    final addrMatch = b.clientAddress.toLowerCase().contains(
                      _searchQuery,
                    );
                    return nameMatch || addrMatch;
                  }).toList();
                }

                if (batches.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 64,
                          color: emptyIcon,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Pengajuan Tidak Ditemukan',
                          style: TextStyle(
                            fontSize: 16,
                            color: emptyText,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: batches.length,
                  itemBuilder: (context, i) {
                    final batch = batches[i];
                    final pendingCount = batch.items
                        .where(
                          (it) =>
                              it.itemStatus == ConsignmentItemStatus.pending,
                        )
                        .length;
                    final categories = batch.items
                        .map((it) => it.catalogCategory)
                        .toSet()
                        .toList();

                    return _BatchCard(
                      batch: batch,
                      pendingCount: pendingCount,
                      categories: categories,
                      isDark: isDark,
                      clientPhotoMap: _clientPhotoMap,
                      batchStatusBg: _batchStatusBg,
                      batchStatusFg: _batchStatusFg,
                      batchStatusIcon: _batchStatusIcon,
                      batchStatusLabel: _batchStatusLabel,
                      formatDate: _formatDate,
                      onDetail: () => _showDetail(context, batch, isDark),
                      onApproveAll:
                          batch.status != ConsignmentBatchStatus.packed &&
                              pendingCount > 0
                          ? () => _approveAllThenDetail(context, batch, isDark)
                          : null,
                      onRejectAll:
                          batch.status != ConsignmentBatchStatus.packed &&
                              pendingCount > 0
                          ? () => _rejectAllThenDetail(context, batch, isDark)
                          : null,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BatchCard extends StatelessWidget {
  final ConsignmentRequestModel batch;
  final int pendingCount;
  final List<String> categories;
  final bool isDark;
  final Map<String, String> clientPhotoMap;
  final Color Function(ConsignmentBatchStatus, bool) batchStatusBg;
  final Color Function(ConsignmentBatchStatus, bool) batchStatusFg;
  final IconData Function(ConsignmentBatchStatus) batchStatusIcon;
  final String Function(ConsignmentBatchStatus) batchStatusLabel;
  final String Function(DateTime?) formatDate;
  final VoidCallback onDetail;
  final Future<void> Function()? onApproveAll;
  final Future<void> Function()? onRejectAll;

  const _BatchCard({
    required this.batch,
    required this.pendingCount,
    required this.categories,
    required this.isDark,
    required this.clientPhotoMap,
    required this.batchStatusBg,
    required this.batchStatusFg,
    required this.batchStatusIcon,
    required this.batchStatusLabel,
    required this.formatDate,
    required this.onDetail,
    required this.onApproveAll,
    required this.onRejectAll,
  });

  @override
  Widget build(BuildContext context) {
    final Color cardBg = isDark ? const Color(0xFF2B2930) : Colors.white;
    final Color cardBorder = isDark
        ? const Color(0xFF49454F)
        : const Color(0xFFE0E0E0);
    final Color nameColor = isDark ? Colors.white : const Color(0xFF1D1B20);
    final Color subColor = isDark ? Colors.white54 : const Color(0xFF757575);
    final Color accentGreen = isDark
        ? const Color(0xFF80CBC4)
        : const Color(0xFF2E7D32);
    final Color accentGreenBg = isDark
        ? const Color(0xFF1A3A2A)
        : const Color(0xFFE6F4EA);

    final statusBg = batchStatusBg(batch.status, isDark);
    final statusFg = batchStatusFg(batch.status, isDark);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black26
                : Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Builder(
                  builder: (context) {
                    final photoUrl = clientPhotoMap[batch.clientId];
                    return photoUrl != null && photoUrl.isNotEmpty
                        ? CircleAvatar(
                            radius: 22,
                            backgroundColor: accentGreenBg,
                            backgroundImage: NetworkImage(photoUrl),
                            onBackgroundImageError: (_, __) {},
                          )
                        : CircleAvatar(
                            radius: 22,
                            backgroundColor: accentGreenBg,
                            child: Icon(
                              Icons.store_outlined,
                              size: 22,
                              color: accentGreen,
                            ),
                          );
                  },
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        batch.clientName.isNotEmpty
                            ? batch.clientName
                            : 'Klien Tidak Dikenal',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: nameColor,
                        ),
                      ),
                      if (batch.clientAddress.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          batch.clientAddress,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            color: subColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: accentGreenBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${batch.items.length} barang',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: accentGreen,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Row(
              children: [
                Icon(Icons.calendar_today_outlined, size: 12, color: subColor),
                const SizedBox(width: 4),
                Text(
                  formatDate(batch.createdAt),
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    color: subColor,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        batchStatusIcon(batch.status),
                        size: 11,
                        color: statusFg,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        batchStatusLabel(batch.status),
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: statusFg,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: categories.take(5).map((cat) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF3A3540)
                        : const Color(0xFFF3EFF4),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.category_outlined, size: 11, color: subColor),
                      const SizedBox(width: 4),
                      Text(
                        cat,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: subColor,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onDetail,
                    icon: const Icon(Icons.visibility_outlined, size: 16),
                    label: const Text(
                      'Lihat Detail',
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: nameColor,
                      side: BorderSide(color: cardBorder),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                if (onApproveAll != null) ...[
                  const SizedBox(width: 8),
                  _IconActionButton(
                    icon: Icons.check_rounded,
                    color: const Color(0xFF2E7D32),
                    bgColor: isDark
                        ? const Color(0xFF1A3A2A)
                        : const Color(0xFFE6F4EA),
                    onTap: onApproveAll!,
                  ),
                ],
                if (onRejectAll != null) ...[
                  const SizedBox(width: 8),
                  _IconActionButton(
                    icon: Icons.close_rounded,
                    color: isDark ? const Color(0xFFFF8A8A) : Colors.red,
                    bgColor: isDark
                        ? const Color(0xFF3A1A1A)
                        : const Color(0xFFFCE8E8),
                    onTap: onRejectAll!,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _IconActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bgColor;
  final Future<void> Function() onTap;

  const _IconActionButton({
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}

class _DetailSheet extends StatefulWidget {
  final ConsignmentRequestModel batch;
  final bool isDark;
  final Color Function(ConsignmentItemStatus, bool) itemStatusBg;
  final Color Function(ConsignmentItemStatus, bool) itemStatusFg;
  final IconData Function(ConsignmentItemStatus) itemStatusIcon;
  final String Function(ConsignmentItemStatus) itemStatusLabel;
  final Color Function(ConsignmentBatchStatus, bool) batchStatusBg;
  final Color Function(ConsignmentBatchStatus, bool) batchStatusFg;
  final IconData Function(ConsignmentBatchStatus) batchStatusIcon;
  final String Function(ConsignmentBatchStatus) batchStatusLabel;
  final String Function(DateTime?) formatDate;
  final Future<Map<String, dynamic>> Function(int index) onApproveItem;
  final Future<Map<String, dynamic>> Function(int index) onRejectItem;
  final Future<Map<String, dynamic>> Function(int index) onCancelItem;
  final Future<void> Function(int index) onPartialItem;
  final Future<Map<String, dynamic>> Function() onPack;
  final Future<Map<String, dynamic>> Function() onReceive;
  final Future<Map<String, dynamic>> Function() onRejectBatch;
  final Future<Map<String, dynamic>> Function() onCancelAll;

  const _DetailSheet({
    required this.batch,
    required this.isDark,
    required this.itemStatusBg,
    required this.itemStatusFg,
    required this.itemStatusIcon,
    required this.itemStatusLabel,
    required this.batchStatusBg,
    required this.batchStatusFg,
    required this.batchStatusIcon,
    required this.batchStatusLabel,
    required this.formatDate,
    required this.onApproveItem,
    required this.onRejectItem,
    required this.onCancelItem,
    required this.onPartialItem,
    required this.onPack,
    required this.onReceive,
    required this.onRejectBatch,
    required this.onCancelAll,
  });

  @override
  State<_DetailSheet> createState() => _DetailSheetState();
}

class _DetailSheetState extends State<_DetailSheet> {
  late Stream<DocumentSnapshot> _docStream;

  @override
  void initState() {
    super.initState();
    _docStream = FirebaseFirestore.instance
        .collection('consignment_requests')
        .doc(widget.batch.id)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _docStream,
      builder: (context, snapshot) {
        final ConsignmentRequestModel batch;
        if (snapshot.hasData && snapshot.data!.exists) {
          batch = ConsignmentRequestModel.fromMap(
            snapshot.data!.id,
            snapshot.data!.data() as Map<String, dynamic>,
          );
        } else {
          batch = widget.batch;
        }

        return _DetailSheetBody(
          batch: batch,
          isDark: widget.isDark,
          itemStatusBg: widget.itemStatusBg,
          itemStatusFg: widget.itemStatusFg,
          itemStatusIcon: widget.itemStatusIcon,
          itemStatusLabel: widget.itemStatusLabel,
          batchStatusBg: widget.batchStatusBg,
          batchStatusFg: widget.batchStatusFg,
          batchStatusIcon: widget.batchStatusIcon,
          batchStatusLabel: widget.batchStatusLabel,
          formatDate: widget.formatDate,
          onApproveItem: widget.onApproveItem,
          onRejectItem: widget.onRejectItem,
          onCancelItem: widget.onCancelItem,
          onPartialItem: widget.onPartialItem,
          onPack: widget.onPack,
          onReceive: widget.onReceive,
          onRejectBatch: widget.onRejectBatch,
          onCancelAll: widget.onCancelAll,
        );
      },
    );
  }
}

class _DetailSheetBody extends StatelessWidget {
  final ConsignmentRequestModel batch;
  final bool isDark;
  final Color Function(ConsignmentItemStatus, bool) itemStatusBg;
  final Color Function(ConsignmentItemStatus, bool) itemStatusFg;
  final IconData Function(ConsignmentItemStatus) itemStatusIcon;
  final String Function(ConsignmentItemStatus) itemStatusLabel;
  final Color Function(ConsignmentBatchStatus, bool) batchStatusBg;
  final Color Function(ConsignmentBatchStatus, bool) batchStatusFg;
  final IconData Function(ConsignmentBatchStatus) batchStatusIcon;
  final String Function(ConsignmentBatchStatus) batchStatusLabel;
  final String Function(DateTime?) formatDate;
  final Future<Map<String, dynamic>> Function(int index) onApproveItem;
  final Future<Map<String, dynamic>> Function(int index) onRejectItem;
  final Future<Map<String, dynamic>> Function(int index) onCancelItem;
  final Future<void> Function(int index) onPartialItem;
  final Future<Map<String, dynamic>> Function() onPack;
  final Future<Map<String, dynamic>> Function() onReceive;
  final Future<Map<String, dynamic>> Function() onRejectBatch;
  final Future<Map<String, dynamic>> Function() onCancelAll;

  const _DetailSheetBody({
    required this.batch,
    required this.isDark,
    required this.itemStatusBg,
    required this.itemStatusFg,
    required this.itemStatusIcon,
    required this.itemStatusLabel,
    required this.batchStatusBg,
    required this.batchStatusFg,
    required this.batchStatusIcon,
    required this.batchStatusLabel,
    required this.formatDate,
    required this.onApproveItem,
    required this.onRejectItem,
    required this.onCancelItem,
    required this.onPartialItem,
    required this.onPack,
    required this.onReceive,
    required this.onRejectBatch,
    required this.onCancelAll,
  });

  @override
  Widget build(BuildContext context) {
    final Color sheetBg = isDark ? const Color(0xFF2B2930) : Colors.white;
    final Color nameColor = isDark ? Colors.white : const Color(0xFF1D1B20);
    final Color subColor = isDark ? Colors.white54 : const Color(0xFF757575);
    final Color divider = isDark
        ? const Color(0xFF49454F)
        : const Color(0xFFE0E0E0);

    final bool isLocked = batch.status == ConsignmentBatchStatus.packed;
    final bool hasPendingItems = batch.items.any(
      (it) => it.itemStatus == ConsignmentItemStatus.pending,
    );
    final bool hasNonPendingItems = batch.items.any(
      (it) => it.itemStatus != ConsignmentItemStatus.pending,
    );
    final bool allItemsRejected =
        batch.items.isNotEmpty &&
        batch.items.every(
          (it) => it.itemStatus == ConsignmentItemStatus.rejected,
        );
    final bool canRejectBatch =
        batch.status == ConsignmentBatchStatus.processing && allItemsRejected;
    final bool canPack =
        batch.status == ConsignmentBatchStatus.processing &&
        !hasPendingItems &&
        !allItemsRejected;
    final bool canReceive = batch.status == ConsignmentBatchStatus.packed;
    final bool canCancelAll = !isLocked && hasNonPendingItems;

    int getEffectiveQuantity(ConsignmentItemEntry item) {
      if (item.itemStatus == ConsignmentItemStatus.rejected) return 0;
      if (item.itemStatus == ConsignmentItemStatus.approved ||
          item.itemStatus == ConsignmentItemStatus.partial) {
        return item.approvedQty ?? item.quantity;
      }
      return item.quantity;
    }

    double overallTotal = 0;
    for (var item in batch.items) {
      if (item.itemStatus == ConsignmentItemStatus.approved ||
          item.itemStatus == ConsignmentItemStatus.partial) {
        overallTotal += item.catalogPrice * (item.approvedQty ?? item.quantity);
      }
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (ctx, scrollController) => DecoratedBox(
        decoration: BoxDecoration(
          color: sheetBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Row(
                children: [
                  Icon(Icons.person_outline, size: 16, color: subColor),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      batch.clientName.isNotEmpty
                          ? batch.clientName
                          : 'Klien Tidak Dikenal',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: nameColor,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: batchStatusBg(batch.status, isDark),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          batchStatusIcon(batch.status),
                          size: 11,
                          color: batchStatusFg(batch.status, isDark),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          batchStatusLabel(batch.status),
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: batchStatusFg(batch.status, isDark),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            if (batch.clientAddress.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 6),
                child: Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 13, color: subColor),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        batch.clientAddress,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: subColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 13,
                    color: subColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    formatDate(batch.createdAt),
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: subColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${batch.items.length} barang',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: subColor,
                    ),
                  ),
                  const Spacer(),
                  if (batch.status == ConsignmentBatchStatus.packed &&
                      batch.packedBy != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1D2F3C)
                            : const Color(0xFFE3F2FD),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.person_outline,
                            size: 11,
                            color: isDark
                                ? const Color(0xFF64B5F6)
                                : const Color(0xFF1976D2),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Oleh ${batch.packedBy}',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? const Color(0xFF64B5F6)
                                  : const Color(0xFF1976D2),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (canCancelAll) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () async {
                        bool confirm = false;
                        await showAppDialog(
                          context: context,
                          title: 'Batal Semua',
                          contentWidget: const Text(
                            'Reset semua item ke status Menunggu?',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                            ),
                          ),
                          actions: [
                            AppDialogAction(
                              label: 'Tidak',
                              onPressed: () => Navigator.pop(context),
                            ),
                            AppDialogAction(
                              label: 'Ya, Reset',
                              type: AppDialogActionType.gradient,
                              onPressed: () {
                                confirm = true;
                                Navigator.pop(context);
                              },
                            ),
                          ],
                        );
                        if (confirm) {
                          await onCancelAll();
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF3A2A2A)
                              : const Color(0xFFFCE8E8),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.restart_alt_rounded,
                              size: 12,
                              color: isDark
                                  ? const Color(0xFFFF8A8A)
                                  : Colors.red,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Batal Semua',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? const Color(0xFFFF8A8A)
                                    : Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            Divider(height: 1, color: divider),

            Expanded(
              child: ListView.separated(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                itemCount: batch.items.length,
                separatorBuilder: (_, __) => Divider(height: 1, color: divider),
                itemBuilder: (ctx, i) {
                  final item = batch.items[i];
                  final isPending =
                      item.itemStatus == ConsignmentItemStatus.pending;
                  final fg = itemStatusFg(item.itemStatus, isDark);
                  final bg = itemStatusBg(item.itemStatus, isDark);
                  final accentGreen = isDark
                      ? const Color(0xFF80CBC4)
                      : const Color(0xFF2E7D32);

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CatalogImage(
                              imagePath: item.catalogImagePath,
                              size: 56,
                              borderRadius: 10,
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
                                      fontSize: 14,
                                      color: nameColor,
                                    ),
                                  ),
                                  Text(
                                    item.catalogCategory,
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 11,
                                      color: subColor,
                                    ),
                                  ),
                                  Text(
                                    formatRupiah(item.catalogPrice),
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: accentGreen,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.layers_outlined,
                              size: 12,
                              color: subColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${item.quantity} pcs',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 11,
                                color: subColor,
                              ),
                            ),
                            if (item.approvedQty != null) ...[
                              const SizedBox(width: 8),
                              Icon(Icons.done_all, size: 12, color: fg),
                              const SizedBox(width: 4),
                              Text(
                                '${item.approvedQty} dipenuhi',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 11,
                                  color: fg,
                                ),
                              ),
                            ],
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: bg,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    itemStatusIcon(item.itemStatus),
                                    size: 11,
                                    color: fg,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    itemStatusLabel(item.itemStatus),
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: fg,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Subtotal: ${formatRupiah(item.catalogPrice * getEffectiveQuantity(item))}',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 10,
                            color: subColor,
                          ),
                        ),
                        if (!isLocked && isPending) ...[
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              _IconActionButton(
                                icon: Icons.check_rounded,
                                color: const Color(0xFF2E7D32),
                                bgColor: isDark
                                    ? const Color(0xFF1A3A2A)
                                    : const Color(0xFFE6F4EA),
                                onTap: () => onApproveItem(i),
                              ),
                              const SizedBox(width: 8),
                              _IconActionButton(
                                icon: Icons.rule_outlined,
                                color: const Color(0xFF1565C0),
                                bgColor: isDark
                                    ? const Color(0xFF1A2A3A)
                                    : const Color(0xFFE3F2FD),
                                onTap: () async {
                                  await onPartialItem(i);
                                },
                              ),
                              const SizedBox(width: 8),
                              _IconActionButton(
                                icon: Icons.close_rounded,
                                color: isDark
                                    ? const Color(0xFFFF8A8A)
                                    : Colors.red,
                                bgColor: isDark
                                    ? const Color(0xFF3A1A1A)
                                    : const Color(0xFFFCE8E8),
                                onTap: () => onRejectItem(i),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Terima · Sebagian · Tolak',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 10,
                                  color: subColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (!isLocked && !isPending) ...[
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              _IconActionButton(
                                icon: Icons.undo_rounded,
                                color: isDark ? Colors.white70 : Colors.black54,
                                bgColor: isDark
                                    ? const Color(0xFF333333)
                                    : const Color(0xFFE0E0E0),
                                onTap: () => onCancelItem(i),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Batal',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 10,
                                  color: subColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),

            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                color: sheetBg,
                border: Border(top: BorderSide(color: divider, width: 1)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Disetujui',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            color: subColor,
                          ),
                        ),
                        Text(
                          formatRupiah(overallTotal),
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: nameColor,
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (canRejectBatch) ...[
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: () async {
                        bool confirm = false;
                        await showAppDialog(
                          context: context,
                          title: 'Tolak Pengajuan',
                          contentWidget: const Text(
                            'Semua item ditolak. Yakin ingin menolak pengajuan ini secara keseluruhan? Pengajuan akan masuk ke riwayat.',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                            ),
                          ),
                          actions: [
                            AppDialogAction(
                              label: 'Batal',
                              onPressed: () => Navigator.pop(context),
                            ),
                            AppDialogAction(
                              label: 'Tolak',
                              type: AppDialogActionType.gradient,
                              onPressed: () {
                                confirm = true;
                                Navigator.pop(context);
                              },
                            ),
                          ],
                        );
                        if (confirm) {
                          final res = await onRejectBatch();
                          if (res['success'] == true && context.mounted) {
                            Navigator.pop(context);
                          }
                        }
                      },
                      icon: Icon(
                        Icons.cancel_outlined,
                        size: 18,
                        color: isDark ? const Color(0xFFFF8A8A) : Colors.red,
                      ),
                      label: Text(
                        'Tolak Pengajuan',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: isDark ? const Color(0xFFFF8A8A) : Colors.red,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: isDark ? const Color(0xFFFF8A8A) : Colors.red,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                  if (canPack) ...[
                    const SizedBox(width: 12),
                    GradientButton(
                      onPressed: () async {
                        bool confirm = false;
                        await showAppDialog(
                          context: context,
                          title: 'Kemas Pengajuan',
                          contentWidget: const Text(
                            'Apakah Anda yakin pengajuan ini sudah selesai diproses dan siap dikemas? Tindakan ini tidak dapat dibatalkan.',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                            ),
                          ),
                          actions: [
                            AppDialogAction(
                              label: 'Batal',
                              onPressed: () => Navigator.pop(context),
                            ),
                            AppDialogAction(
                              label: 'Kemas',
                              type: AppDialogActionType.gradient,
                              onPressed: () {
                                confirm = true;
                                Navigator.pop(context);
                              },
                            ),
                          ],
                        );

                        if (confirm) {
                          final res = await onPack();
                          if (res['success'] == true && context.mounted) {
                            Navigator.pop(context);
                          }
                        }
                      },
                      icon: Icon(
                        Icons.inventory_2_rounded,
                        size: 18,
                        color: isDark ? const Color(0xFF1D1B20) : Colors.white,
                      ),
                      label: 'Kemas Pengajuan',
                      textStyle: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFF1D1B20) : Colors.white,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      borderRadius: 12,
                    ),
                  ],
                  if (canReceive) ...[
                    const SizedBox(width: 12),
                    GradientButton(
                      onPressed: () async {
                        bool confirm = false;
                        await showAppDialog(
                          context: context,
                          title: 'Serahkan Pengajuan',
                          contentWidget: const Text(
                            'Apakah Anda yakin barang sudah diserahkan ke klien? Tindakan ini tidak dapat dibatalkan.',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                            ),
                          ),
                          actions: [
                            AppDialogAction(
                              label: 'Batal',
                              onPressed: () => Navigator.pop(context),
                            ),
                            AppDialogAction(
                              label: 'Serahkan',
                              type: AppDialogActionType.gradient,
                              onPressed: () {
                                confirm = true;
                                Navigator.pop(context);
                              },
                            ),
                          ],
                        );

                        if (confirm) {
                          final res = await onReceive();
                          if (res['success'] == true && context.mounted) {
                            Navigator.pop(context);
                          }
                        }
                      },
                      icon: Icon(
                        Icons.local_shipping_outlined,
                        size: 18,
                        color: isDark ? const Color(0xFF1D1B20) : Colors.white,
                      ),
                      label: 'Serahkan Pengajuan',
                      textStyle: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFF1D1B20) : Colors.white,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      borderRadius: 12,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
