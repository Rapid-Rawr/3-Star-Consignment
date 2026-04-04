import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../controllers/barang_controllers/pengajuan_konsinyasi_controller.dart';
import '../../models/barang_models/pengajuan_konsinyasi_model.dart';
import '../../widgets/search_filter_bar.dart';
import '../../widgets/catalog_image.dart';
import '../../utils/currency_format.dart';

class RiwayatPengajuanPage extends StatefulWidget {
  const RiwayatPengajuanPage({super.key});

  @override
  State<RiwayatPengajuanPage> createState() => _RiwayatPengajuanPageState();
}

class _RiwayatPengajuanPageState extends State<RiwayatPengajuanPage> {
  late final ConsignmentRequestController _controller;
  late final Stream<QuerySnapshot> _stream;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';
  DateTime? _dateFrom;
  DateTime? _dateTo;

  @override
  void initState() {
    super.initState();
    _controller = ConsignmentRequestController(
      firestore: FirebaseFirestore.instance,
    );
    _stream = _controller.getRequestsStream();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  ThemeData _datePickerTheme() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Theme.of(context).copyWith(
      colorScheme: isDark
          ? const ColorScheme.dark(
              primary: Color(0xFF4DB6AC),
              onPrimary: Colors.black,
              surface: Color(0xFF2B2930),
              onSurface: Colors.white,
            )
          : const ColorScheme.light(
              primary: Color(0xFF00796B),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF1D1B20),
            ),
    );
  }

  Future<void> _selectFromDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateFrom ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) =>
          Theme(data: _datePickerTheme(), child: child!),
    );
    if (picked != null) {
      setState(() {
        _dateFrom = picked;
        if (_dateTo != null && _dateTo!.isBefore(picked)) {
          _dateTo = null;
        }
      });
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateTo ?? (_dateFrom ?? DateTime.now()),
      firstDate: _dateFrom ?? DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) =>
          Theme(data: _datePickerTheme(), child: child!),
    );
    if (picked != null) {
      setState(() {
        _dateTo = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
      });
    }
  }

  Color _batchStatusBg(ConsignmentBatchStatus s, bool isDark) {
    if (s == ConsignmentBatchStatus.rejected) {
      return isDark ? const Color(0xFF3A1A1A) : const Color(0xFFFCE8E8);
    }
    return isDark ? const Color(0xFF1A3A3A) : const Color(0xFFE0F2F1);
  }

  Color _batchStatusFg(ConsignmentBatchStatus s, bool isDark) {
    if (s == ConsignmentBatchStatus.rejected) {
      return isDark ? const Color(0xFFFF8A8A) : Colors.red;
    }
    return isDark ? const Color(0xFF4DB6AC) : const Color(0xFF00796B);
  }

  IconData _batchStatusIcon(ConsignmentBatchStatus s) {
    if (s == ConsignmentBatchStatus.rejected) return Icons.cancel_outlined;
    return Icons.verified_outlined;
  }

  String _batchStatusLabel(ConsignmentBatchStatus s) {
    if (s == ConsignmentBatchStatus.rejected) return 'Ditolak';
    return 'Diserahkan';
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color emptyIcon = isDark ? Colors.white24 : Colors.black26;
    final Color emptyText = isDark ? Colors.white38 : const Color(0xFF9E9E9E);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Riwayat Pengajuan',
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
            filters: const [],
            selectedFilter: null,
            onFilterSelected: (_) {},
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _selectFromDate,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _dateFrom != null
                              ? (isDark
                                    ? const Color(0xFF4DB6AC)
                                    : const Color(0xFF00796B))
                              : (isDark
                                    ? const Color(0xFF49454F)
                                    : const Color(0xFFE0E0E0)),
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: isDark ? Colors.white54 : Colors.black54,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _dateFrom == null
                                ? 'Dari Tanggal'
                                : _formatDate(_dateFrom),
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              color: _dateFrom != null
                                  ? (isDark
                                        ? Colors.white
                                        : const Color(0xFF1D1B20))
                                  : (isDark ? Colors.white38 : Colors.black38),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    onTap: _selectEndDate,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _dateTo != null
                              ? (isDark
                                    ? const Color(0xFF4DB6AC)
                                    : const Color(0xFF00796B))
                              : (isDark
                                    ? const Color(0xFF49454F)
                                    : const Color(0xFFE0E0E0)),
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: isDark ? Colors.white54 : Colors.black54,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _dateTo == null
                                  ? 'Sampai Tanggal'
                                  : _formatDate(_dateTo),
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                color: _dateTo != null
                                    ? (isDark
                                          ? Colors.white
                                          : const Color(0xFF1D1B20))
                                    : (isDark
                                          ? Colors.white38
                                          : Colors.black38),
                              ),
                            ),
                          ),
                          if (_dateFrom != null || _dateTo != null)
                            GestureDetector(
                              onTap: () => setState(() {
                                _dateFrom = null;
                                _dateTo = null;
                              }),
                              child: Icon(
                                Icons.close_rounded,
                                size: 16,
                                color: isDark ? Colors.white38 : Colors.black38,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
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
                        Icon(Icons.history_rounded, size: 64, color: emptyIcon),
                        const SizedBox(height: 16),
                        Text(
                          'Belum Ada Riwayat',
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
                          b.status == ConsignmentBatchStatus.received ||
                          b.status == ConsignmentBatchStatus.rejected,
                    )
                    .toList();

                if (_searchQuery.isNotEmpty) {
                  batches = batches.where((b) {
                    final nameMatch = b.userName.toLowerCase().contains(
                      _searchQuery,
                    );
                    final schoolMatch = b.userSchool.toLowerCase().contains(
                      _searchQuery,
                    );
                    return nameMatch || schoolMatch;
                  }).toList();
                }

                if (_dateFrom != null && _dateTo != null) {
                  batches = batches.where((b) {
                    final date = b.receivedAt ?? b.createdAt;
                    if (date == null) return false;
                    return !date.isBefore(_dateFrom!) &&
                        !date.isAfter(_dateTo!);
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
                          'Riwayat Tidak Ditemukan',
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
                    final categories = batch.items
                        .map((it) => it.catalogCategory)
                        .toSet()
                        .toList();

                    return _BatchHistoryCard(
                      batch: batch,
                      categories: categories,
                      isDark: isDark,
                      batchStatusBg: _batchStatusBg,
                      batchStatusFg: _batchStatusFg,
                      batchStatusIcon: _batchStatusIcon,
                      batchStatusLabel: _batchStatusLabel,
                      formatDate: _formatDate,
                      onDetail: () => _showDetail(context, batch, isDark),
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

class _BatchHistoryCard extends StatelessWidget {
  final ConsignmentRequestModel batch;
  final List<String> categories;
  final bool isDark;
  final Color Function(ConsignmentBatchStatus, bool) batchStatusBg;
  final Color Function(ConsignmentBatchStatus, bool) batchStatusFg;
  final IconData Function(ConsignmentBatchStatus) batchStatusIcon;
  final String Function(ConsignmentBatchStatus) batchStatusLabel;
  final String Function(DateTime?) formatDate;
  final VoidCallback onDetail;

  const _BatchHistoryCard({
    required this.batch,
    required this.categories,
    required this.isDark,
    required this.batchStatusBg,
    required this.batchStatusFg,
    required this.batchStatusIcon,
    required this.batchStatusLabel,
    required this.formatDate,
    required this.onDetail,
  });

  @override
  Widget build(BuildContext context) {
    final Color cardBg = isDark ? const Color(0xFF2B2930) : Colors.white;
    final Color cardBorder = isDark
        ? const Color(0xFF49454F)
        : const Color(0xFFE0E0E0);
    final Color nameColor = isDark ? Colors.white : const Color(0xFF1D1B20);
    final Color subColor = isDark ? Colors.white54 : const Color(0xFF757575);
    final Color accentGreenBg = isDark
        ? const Color(0xFF1A3A2A)
        : const Color(0xFFE6F4EA);

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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        batch.userName.isNotEmpty
                            ? batch.userName
                            : 'Pengguna Tidak Dikenal',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: nameColor,
                        ),
                      ),
                      if (batch.userSchool.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.school_outlined,
                              size: 12,
                              color: subColor,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                batch.userSchool,
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12,
                                  color: subColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
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
                      color: isDark
                          ? const Color(0xFF80CBC4)
                          : const Color(0xFF2E7D32),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_month, size: 14, color: subColor),
                const SizedBox(width: 6),
                Text(
                  'Diajukan: ${formatDate(batch.createdAt)}',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: subColor,
                  ),
                ),
                const Spacer(),
                if (batch.receivedAt != null) ...[
                  Text(
                    'Diserahkan: ${formatDate(batch.receivedAt)}',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: subColor,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: categories.map((cat) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF333138) : Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    cat,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 10,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onDetail,
              icon: const Icon(Icons.visibility_outlined, size: 16),
              label: const Text(
                'Lihat Riwayat',
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
          ],
        ),
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
  });

  @override
  Widget build(BuildContext context) {
    final Color sheetBg = isDark ? const Color(0xFF2B2930) : Colors.white;
    final Color nameColor = isDark ? Colors.white : const Color(0xFF1D1B20);
    final Color subColor = isDark ? Colors.white54 : const Color(0xFF757575);
    final Color divider = isDark
        ? const Color(0xFF49454F)
        : const Color(0xFFE0E0E0);

    int getEffectiveQuantity(ConsignmentItemEntry item) {
      if (item.itemStatus == ConsignmentItemStatus.rejected) return 0;
      if (item.itemStatus == ConsignmentItemStatus.approved ||
          item.itemStatus == ConsignmentItemStatus.partial) {
        return item.approvedQty ?? item.quantity;
      }
      return item.quantity;
    }

    final double overallTotal = batch.items.fold(
      0.0,
      (sum, item) => sum + (item.catalogPrice * getEffectiveQuantity(item)),
    );

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: sheetBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Detail Riwayat: ${batch.userName}',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: nameColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: divider),

              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
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
                                size: 12,
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
                        if (batch.packedBy != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF1A3A2A)
                                  : const Color(0xFFE6F4EA),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.person_outline,
                                  size: 11,
                                  color: isDark
                                      ? const Color(0xFF80CBC4)
                                      : const Color(0xFF2E7D32),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Dikemas: ${batch.packedBy}',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? const Color(0xFF80CBC4)
                                        : const Color(0xFF2E7D32),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (batch.receivedBy != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  batch.status ==
                                      ConsignmentBatchStatus.rejected
                                  ? (isDark
                                        ? const Color(0xFF3A1A1A)
                                        : const Color(0xFFFCE8E8))
                                  : (isDark
                                        ? const Color(0xFF1E3A5F)
                                        : const Color(0xFFE8F4FD)),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  batch.status ==
                                          ConsignmentBatchStatus.rejected
                                      ? Icons.cancel_outlined
                                      : Icons.verified_user_outlined,
                                  size: 11,
                                  color:
                                      batch.status ==
                                          ConsignmentBatchStatus.rejected
                                      ? (isDark
                                            ? const Color(0xFFFF8A8A)
                                            : Colors.red)
                                      : (isDark
                                            ? const Color(0xFF64B5F6)
                                            : const Color(0xFF1976D2)),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  batch.status ==
                                          ConsignmentBatchStatus.rejected
                                      ? 'Ditolak: ${batch.receivedBy}'
                                      : 'Diserahkan: ${batch.receivedBy}',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color:
                                        batch.status ==
                                            ConsignmentBatchStatus.rejected
                                        ? (isDark
                                              ? const Color(0xFFFF8A8A)
                                              : Colors.red)
                                        : (isDark
                                              ? const Color(0xFF64B5F6)
                                              : const Color(0xFF1976D2)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Daftar Barang',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: nameColor,
                      ),
                    ),
                    const SizedBox(height: 12),

                    ...batch.items.map((item) {
                      final effectiveQty = getEffectiveQuantity(item);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF333138)
                              : Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: divider, width: 1),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CatalogImage(
                              imagePath: item.catalogImagePath,
                              size: 50,
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
                                      color: nameColor,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Harga: ${formatRupiah(item.catalogPrice)}',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 11,
                                      color: subColor,
                                    ),
                                  ),
                                  Text(
                                    item.itemStatus ==
                                            ConsignmentItemStatus.partial
                                        ? 'Pengajuan awal: ${item.quantity}  •  Disetujui: $effectiveQty'
                                        : 'Jumlah Disetujui: $effectiveQty',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 11,
                                      color: subColor,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Subtotal: ${formatRupiah(item.catalogPrice * effectiveQty)}',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 10,
                                      color: subColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: itemStatusBg(
                                      item.itemStatus,
                                      isDark,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        itemStatusIcon(item.itemStatus),
                                        size: 10,
                                        color: itemStatusFg(
                                          item.itemStatus,
                                          isDark,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        itemStatusLabel(item.itemStatus),
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 9,
                                          fontWeight: FontWeight.w600,
                                          color: itemStatusFg(
                                            item.itemStatus,
                                            isDark,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
                            'Total Keseluruhan',
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
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
