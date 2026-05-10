import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../controllers/barang_controllers/konsinyasi_controller.dart';
import '../../models/barang_models/konsinyasi_model.dart';
import '../../widgets/search_filter_bar.dart';
import '../../widgets/date_range_filter.dart';
import '../../widgets/detail_sheet_widgets.dart';
import '../../utils/app_colors.dart';
import '../../utils/currency_format.dart';
import '../../utils/konsinyasi_status_helpers.dart';

class RequestHistoryPage extends StatefulWidget {
  const RequestHistoryPage({super.key});

  @override
  State<RequestHistoryPage> createState() => _RequestHistoryPageState();
}

class _RequestHistoryPageState extends State<RequestHistoryPage> {
  late final ConsignmentRequestController _controller;
  late final Stream<QuerySnapshot> _stream;
  Map<String, String> _clientPhotoMap = {};

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
    _loadClientPhotos();
  }

  Future<void> _loadClientPhotos() async {
    try {
      final snap = await FirebaseFirestore.instance.collection('clients').get();
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

  Future<void> _selectFromDate() => selectFromDate(
    context: context,
    current: _dateFrom,
    dateTo: _dateTo,
    onPicked: (picked) => setState(() {
      _dateFrom = picked;
      if (_dateTo != null && _dateTo!.isBefore(picked)) _dateTo = null;
    }),
  );

  Future<void> _selectEndDate() => selectToDate(
    context: context,
    current: _dateTo,
    dateFrom: _dateFrom,
    onPicked: (picked) => setState(() => _dateTo = picked),
  );

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
        clientPhotoUrl: _clientPhotoMap[batch.clientId],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          DateRangeFilter(
            dateFrom: _dateFrom,
            dateTo: _dateTo,
            onFromTap: _selectFromDate,
            onToTap: _selectEndDate,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            onClear: () => setState(() {
              _dateFrom = null;
              _dateTo = null;
            }),
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
                          Icons.history_rounded,
                          size: 64,
                          color: context.emptyIcon,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Belum Ada Riwayat',
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
                    final nameMatch = b.clientName.toLowerCase().contains(
                      _searchQuery,
                    );
                    final addrMatch = b.clientAddress.toLowerCase().contains(
                      _searchQuery,
                    );
                    return nameMatch || addrMatch;
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
                          color: context.emptyIcon,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Riwayat Tidak Ditemukan',
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
                      isDark: context.isDark,
                      onDetail: () =>
                          _showDetail(context, batch, context.isDark),
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
  final VoidCallback onDetail;

  const _BatchHistoryCard({
    required this.batch,
    required this.categories,
    required this.isDark,
    required this.onDetail,
  });

  @override
  Widget build(BuildContext context) {
    final Color cardBg = context.cardBg;
    final Color cardBorder = context.cardBorder;
    final Color nameColor = context.nameColor;
    final Color subColor = context.subColor;
    final Color accentGreenBg = context.successBg;

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
                  'Diajukan: ${formatDateShort(batch.createdAt)}',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: subColor,
                  ),
                ),
                const Spacer(),
                if (batch.receivedAt != null) ...[
                  Text(
                    'Diserahkan: ${formatDateShort(batch.receivedAt)}',
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
                    color: context.chipBg,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    cat,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 10,
                      color: context.chipText,
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
  final String? clientPhotoUrl;

  const _DetailSheet({
    required this.batch,
    required this.isDark,
    this.clientPhotoUrl,
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
          clientPhotoUrl: widget.clientPhotoUrl,
        );
      },
    );
  }
}

class _DetailSheetBody extends StatelessWidget {
  final ConsignmentRequestModel batch;
  final bool isDark;
  final String? clientPhotoUrl;

  const _DetailSheetBody({
    required this.batch,
    required this.isDark,
    this.clientPhotoUrl,
  });

  @override
  Widget build(BuildContext context) {
    final Color sheetBg = context.cardBg;
    final Color divider  = context.cardBorder;

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
    final int totalUnits = batch.items.fold(
      0,
      (sum, item) => sum + getEffectiveQuantity(item),
    );

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.97,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: sheetBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SheetDragHandle(),

              SheetClientHeader(
                clientName: batch.clientName,
                clientAddress: batch.clientAddress,
                photoUrl: clientPhotoUrl,
                countBadgeText: '$totalUnits unit',
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
                                batch.receivedAt != null
                                    ? Icons.calendar_month
                                    : batchStatusIcon(batch.status),
                                size: 12,
                                color: batchStatusFg(batch.status, isDark),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                batch.receivedAt != null
                                    ? '${batchStatusLabel(batch.status)}: ${formatDateShort(batch.receivedAt)}'
                                    : batchStatusLabel(batch.status),
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
                              color: context.successBg,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.person_outline,
                                  size: 11,
                                  color: context.successFg,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Dikemas: ${batch.packedBy}',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: context.successFg,
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
                    SheetSectionHeader(
                      title: 'Daftar Barang',
                      countBadgeText: '${batch.items.length} barang',
                    ),
                    const SizedBox(height: 12),

                    ...batch.items.map((item) {
                      final effectiveQty = getEffectiveQuantity(item);
                      return SheetItemCard(
                        imagePath: item.catalogImagePath,
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: itemStatusBg(item.itemStatus, isDark),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                itemStatusIcon(item.itemStatus),
                                size: 10,
                                color: itemStatusFg(item.itemStatus, isDark),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                itemStatusLabel(item.itemStatus),
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: itemStatusFg(item.itemStatus, isDark),
                                ),
                              ),
                            ],
                          ),
                        ),
                        contentChildren: [
                          Text(
                            item.catalogName,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: context.nameColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Harga: ${formatRupiah(item.catalogPrice)}',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              color: context.subColor,
                            ),
                          ),
                          Text(
                            item.itemStatus == ConsignmentItemStatus.partial
                                ? 'Pengajuan awal: ${item.quantity}  •  Disetujui: $effectiveQty'
                                : 'Jumlah Disetujui: $effectiveQty',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              color: context.subColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Subtotal: ${formatRupiah(item.catalogPrice * effectiveQty)}',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 10,
                              color: context.subColor,
                            ),
                          ),
                        ],
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
                child: SheetTotalFooter(
                  label: 'Total Keseluruhan',
                  amount: formatRupiah(overallTotal),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
