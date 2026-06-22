import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:provider/provider.dart';
import '../../controllers/pembayaran_controllers/pembayaran_controller.dart';
import '../../models/pembayaran_models/pembayaran_model.dart';
import '../../service/auth_provider.dart';
import '../../widgets/date_range_filter.dart';
import '../../widgets/search_filter_bar.dart';
import '../../widgets/detail_sheet_widgets.dart';
import '../../utils/currency_format.dart';
import '../../utils/app_colors.dart';

class PaymentHistoryPage extends StatefulWidget {
  const PaymentHistoryPage({super.key});

  @override
  State<PaymentHistoryPage> createState() => _PaymentHistoryPageState();
}

class _PaymentHistoryPageState extends State<PaymentHistoryPage> {
  late final PaymentController _controller;

  // Map<clientId, photoUrl> — loaded once from clients collection
  Map<String, String> _clientPhotoMap = {};

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';
  DateTime? _dateFrom;
  DateTime? _dateTo;

  @override
  void initState() {
    super.initState();
    _controller = PaymentController(firestore: FirebaseFirestore.instance);
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

  void _showDetail(BuildContext context, PaymentModel payment, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PaymentDetailSheet(
        payment: payment,
        isDark: isDark,
        clientPhotoUrl: _clientPhotoMap[payment.clientId],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final role = context.watch<AuthProvider>().role;
    final user = FirebaseAuth.instance.currentUser;

    final stream = _controller.getPaymentsByRole(
      role: role ?? '',
      email: user?.email ?? '',
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Riwayat Pembayaran',
          style: TextStyle(fontFamily: 'Poppins'),
        ),
      ),
      body: Column(
        children: [
          SearchFilterBar<Never>(
            searchController: _searchController,
            searchFocusNode: _searchFocusNode,
            hintText: 'Cari nama klien...',
            onSearchChanged: (v) =>
                setState(() => _searchQuery = v.trim().toLowerCase()),
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
              stream: stream,
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
                          Icons.receipt_long_outlined,
                          size: 64,
                          color: context.emptyIcon,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Belum Ada History Pembayaran',
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

                var payments = snapshot.data!.docs
                    .map(
                      (d) => PaymentModel.fromMap(
                        d.id,
                        d.data() as Map<String, dynamic>,
                      ),
                    )
                    .toList();

                if (_searchQuery.isNotEmpty) {
                  payments = payments
                      .where(
                        (p) =>
                            p.clientName.toLowerCase().contains(_searchQuery) ||
                            p.clientAddress.toLowerCase().contains(
                              _searchQuery,
                            ),
                      )
                      .toList();
                }

                if (_dateFrom != null && _dateTo != null) {
                  payments = payments.where((p) {
                    final date = p.paidAt;
                    if (date == null) return false;
                    return !date.isBefore(_dateFrom!) &&
                        !date.isAfter(_dateTo!);
                  }).toList();
                }

                if (payments.isEmpty) {
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
                          'History Tidak Ditemukan',
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
                  itemCount: payments.length,
                  itemBuilder: (context, i) {
                    final payment = payments[i];
                    final categories = payment.items
                        .map((it) => it.catalogCategory)
                        .toSet()
                        .toList();
                    return _PaymentHistoryCard(
                      payment: payment,
                      categories: categories,
                      isDark: context.isDark,
                      onDetail: () =>
                          _showDetail(context, payment, context.isDark),
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

class _PaymentHistoryCard extends StatelessWidget {
  final PaymentModel payment;
  final List<String> categories;
  final bool isDark;
  final VoidCallback onDetail;

  const _PaymentHistoryCard({
    required this.payment,
    required this.categories,
    required this.isDark,
    required this.onDetail,
  });

  String _methodLabel(String method) {
    switch (method.toLowerCase()) {
      case 'cash':
        return 'Cash';
      case 'transfer':
        return 'Transfer';
      default:
        return method;
    }
  }

  IconData _methodIcon(String method) {
    switch (method.toLowerCase()) {
      case 'cash':
        return Icons.payments_outlined;
      case 'transfer':
        return Icons.account_balance_outlined;
      default:
        return Icons.payment_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color cardBg = context.cardBg;
    final Color cardBorder = context.cardBorder;
    final totalItems = payment.items.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: context.cardShadow,
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        payment.clientName.isNotEmpty
                            ? payment.clientName
                            : 'Klien Tidak Dikenal',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: context.nameColor,
                        ),
                      ),
                      if (payment.clientAddress.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 12,
                              color: context.subColor,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                payment.clientAddress,
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12,
                                  color: context.subColor,
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: context.infoBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _methodIcon(payment.paymentMethod),
                            size: 12,
                            color: context.infoFg,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _methodLabel(payment.paymentMethod),
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: context.infoFg,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: context.primaryBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$totalItems barang',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: context.primaryFg,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Icon(Icons.calendar_month, size: 14, color: context.subColor),
                const SizedBox(width: 6),
                Text(
                  'Dibayar: ${formatDateShort(payment.paidAt)}',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: context.subColor,
                  ),
                ),
                const Spacer(),
                Text(
                  formatRupiah(payment.totalAmount),
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: context.primaryFg,
                  ),
                ),
              ],
            ),

            if (payment.confirmedBy != null &&
                payment.confirmedBy!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.person_outline, size: 14, color: context.subColor),
                  const SizedBox(width: 6),
                  Text(
                    'Dikonfirmasi oleh: ${payment.confirmedBy}',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: context.subColor,
                    ),
                  ),
                ],
              ),
            ],

            if (categories.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 4,
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
            ],

            const SizedBox(height: 12),

            OutlinedButton.icon(
              onPressed: onDetail,
              icon: const Icon(Icons.visibility_outlined, size: 16),
              label: const Text(
                'Lihat Detail',
                style: TextStyle(fontFamily: 'Poppins', fontSize: 12),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: context.nameColor,
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

class _PaymentDetailSheet extends StatelessWidget {
  final PaymentModel payment;
  final bool isDark;
  final String? clientPhotoUrl;

  const _PaymentDetailSheet({
    required this.payment,
    required this.isDark,
    this.clientPhotoUrl,
  });

  @override
  Widget build(BuildContext context) {
    final Color sheetBg = context.cardBg;
    final Color divider = context.cardBorder;
    final totalItems = payment.items.fold(0, (s, i) => s + i.quantity);

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.97,
      builder: (context, sc) => SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            color: sheetBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SheetDragHandle(),

              SheetClientHeader(
                clientName: payment.clientName,
                clientAddress: payment.clientAddress,
                photoUrl: clientPhotoUrl,
                countBadgeText: '$totalItems unit',
                extraBadge: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: context.infoBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.payments_outlined,
                        size: 12,
                        color: context.infoFg,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        payment.paymentMethod == 'cash'
                            ? 'Cash'
                            : payment.paymentMethod,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: context.infoFg,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Divider(height: 1, color: divider),

              Expanded(
                child: ListView(
                  controller: sc,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  children: [
                    // Badge chips: tanggal + dikonfirmasi oleh
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
                            color: context.infoBg,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.calendar_month,
                                size: 11,
                                color: context.infoFg,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Dibayar: ${formatDateShort(payment.paidAt)}',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: context.infoFg,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (payment.confirmedBy != null &&
                            payment.confirmedBy!.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: context.primaryBg,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.person_outline,
                                  size: 11,
                                  color: context.primaryFg,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Dikonfirmasi: ${payment.confirmedBy}',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: context.primaryFg,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    SheetSectionHeader(
                      title: 'Barang Dibayar',
                      countBadgeText: '${payment.items.length} item',
                    ),
                    const SizedBox(height: 12),
                    // List item barang
                    ...payment.items.map((item) {
                      return SheetItemCard(
                        imagePath: item.catalogImagePath,
                        imageSize: 52,
                        imageBorderRadius: 10,
                        trailing: Text(
                          formatRupiah(item.catalogPrice * item.quantity),
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: context.primaryFg,
                          ),
                        ),
                        contentChildren: [
                          Text(
                            item.catalogName,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: context.nameColor,
                            ),
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
                          const SizedBox(height: 4),
                          Text(
                            '${item.quantity}× ${formatRupiah(item.catalogPrice)}',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              color: context.successFg,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                decoration: BoxDecoration(
                  color: sheetBg,
                  border: Border(top: BorderSide(color: divider)),
                ),
                child: SheetTotalFooter(
                  label: 'Total Pembayaran',
                  amount: formatRupiah(payment.totalAmount),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
