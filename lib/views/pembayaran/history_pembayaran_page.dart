import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../controllers/pembayaran_controllers/pembayaran_controller.dart';
import '../../models/pembayaran_models/pembayaran_model.dart';
import '../../widgets/catalog_image.dart';
import '../../utils/currency_format.dart';

class HistoryPembayaranPage extends StatefulWidget {
  const HistoryPembayaranPage({super.key});

  @override
  State<HistoryPembayaranPage> createState() => _HistoryPembayaranPageState();
}

class _HistoryPembayaranPageState extends State<HistoryPembayaranPage> {
  late final PembayaranController _controller;
  late final Stream<QuerySnapshot> _stream;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';
  DateTime? _dateFrom;
  DateTime? _dateTo;

  @override
  void initState() {
    super.initState();
    _controller = PembayaranController(firestore: FirebaseFirestore.instance);
    _stream = _controller.getPaymentsStream();
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
      builder: (ctx, child) => Theme(data: _datePickerTheme(), child: child!),
    );
    if (picked != null) {
      setState(() {
        _dateFrom = picked;
        if (_dateTo != null && _dateTo!.isBefore(picked)) _dateTo = null;
      });
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateTo ?? (_dateFrom ?? DateTime.now()),
      firstDate: _dateFrom ?? DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(data: _datePickerTheme(), child: child!),
    );
    if (picked != null) {
      setState(() {
        _dateTo = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
      });
    }
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '-';
    const m = [
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
    return '${dt.day} ${m[dt.month]} ${dt.year}';
  }

  void _showDetail(BuildContext context, PembayaranModel payment, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PaymentDetailSheet(
        payment: payment,
        isDark: isDark,
        formatDate: _formatDate,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color emptyIcon = isDark ? Colors.white24 : Colors.black26;
    final Color emptyText = isDark ? Colors.white38 : const Color(0xFF9E9E9E);
    final Color borderActive = isDark
        ? const Color(0xFF4DB6AC)
        : const Color(0xFF00796B);
    final Color borderDim = isDark
        ? const Color(0xFF49454F)
        : const Color(0xFFE0E0E0);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'History Pembayaran',
          style: TextStyle(fontFamily: 'Poppins'),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              onChanged: (v) =>
                  setState(() => _searchQuery = v.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Cari nama klien...',
                hintStyle: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
                prefixIcon: const Icon(Icons.search, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: borderDim),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: borderDim),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: borderActive),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                isDense: true,
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
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
                          color: _dateFrom != null ? borderActive : borderDim,
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
                          color: _dateTo != null ? borderActive : borderDim,
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
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 64,
                          color: emptyIcon,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Belum Ada History Pembayaran',
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

                var payments = snapshot.data!.docs
                    .map(
                      (d) => PembayaranModel.fromMap(
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
                          color: emptyIcon,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'History Tidak Ditemukan',
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
                      isDark: isDark,
                      formatDate: _formatDate,
                      onDetail: () => _showDetail(context, payment, isDark),
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
  final PembayaranModel payment;
  final List<String> categories;
  final bool isDark;
  final String Function(DateTime?) formatDate;
  final VoidCallback onDetail;

  const _PaymentHistoryCard({
    required this.payment,
    required this.categories,
    required this.isDark,
    required this.formatDate,
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
    final Color cardBg = isDark ? const Color(0xFF2B2930) : Colors.white;
    final Color cardBorder = isDark
        ? const Color(0xFF49454F)
        : const Color(0xFFE0E0E0);
    final Color nameColor = isDark ? Colors.white : const Color(0xFF1D1B20);
    final Color subColor = isDark ? Colors.white54 : const Color(0xFF757575);
    final Color tealFg = isDark
        ? const Color(0xFF4DB6AC)
        : const Color(0xFF00796B);
    final Color tealBg = isDark
        ? const Color(0xFF1A3A3A)
        : const Color(0xFFE0F2F1);
    final Color cashBg = isDark
        ? const Color(0xFF1A2A3A)
        : const Color(0xFFE3F2FD);
    final Color cashFg = isDark
        ? const Color(0xFF90CAF9)
        : const Color(0xFF1565C0);

    final totalItems = payment.items.fold(0, (s, i) => s + i.quantity);

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
                          color: nameColor,
                        ),
                      ),
                      if (payment.clientAddress.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 12,
                              color: subColor,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                payment.clientAddress,
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: cashBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _methodIcon(payment.paymentMethod),
                            size: 12,
                            color: cashFg,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _methodLabel(payment.paymentMethod),
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: cashFg,
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
                        color: tealBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$totalItems barang',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: tealFg,
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
                Icon(Icons.calendar_month, size: 14, color: subColor),
                const SizedBox(width: 6),
                Text(
                  'Dibayar: ${formatDate(payment.paidAt)}',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: subColor,
                  ),
                ),
                const Spacer(),
                Text(
                  formatRupiah(payment.totalAmount),
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: tealFg,
                  ),
                ),
              ],
            ),

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
                      color: isDark
                          ? const Color(0xFF333138)
                          : Colors.grey[200],
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

class _PaymentDetailSheet extends StatelessWidget {
  final PembayaranModel payment;
  final bool isDark;
  final String Function(DateTime?) formatDate;

  const _PaymentDetailSheet({
    required this.payment,
    required this.isDark,
    required this.formatDate,
  });

  @override
  Widget build(BuildContext context) {
    final Color sheetBg = isDark ? const Color(0xFF2B2930) : Colors.white;
    final Color divider = isDark
        ? const Color(0xFF49454F)
        : const Color(0xFFE0E0E0);
    final Color nameColor = isDark ? Colors.white : const Color(0xFF1D1B20);
    final Color subColor = isDark ? Colors.white54 : const Color(0xFF757575);
    final Color tealFg = isDark
        ? const Color(0xFF4DB6AC)
        : const Color(0xFF00796B);
    final Color tealBg = isDark
        ? const Color(0xFF1A3A3A)
        : const Color(0xFFE0F2F1);
    final Color cashBg = isDark
        ? const Color(0xFF1A2A3A)
        : const Color(0xFFE3F2FD);
    final Color cashFg = isDark
        ? const Color(0xFF90CAF9)
        : const Color(0xFF1565C0);
    final Color priceColor = isDark
        ? const Color(0xFF80CBC4)
        : const Color(0xFF2E7D32);

    final totalItems = payment.items.fold(0, (s, i) => s + i.quantity);

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.97,
      builder: (context, sc) => Container(
        decoration: BoxDecoration(
          color: sheetBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 6),
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
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: tealBg,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.store_outlined, color: tealFg, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          payment.clientName,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: nameColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (payment.clientAddress.isNotEmpty)
                          Text(
                            payment.clientAddress,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              color: subColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: cashBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.payments_outlined, size: 12, color: cashFg),
                        const SizedBox(width: 4),
                        Text(
                          payment.paymentMethod == 'cash'
                              ? 'Cash'
                              : payment.paymentMethod,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: cashFg,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: tealBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$totalItems unit',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: tealFg,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            Divider(height: 1, color: divider),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
              child: Row(
                children: [
                  Icon(Icons.calendar_month, size: 14, color: subColor),
                  const SizedBox(width: 6),
                  Text(
                    'Dibayar: ${formatDate(payment.paidAt)}',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: subColor,
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 6),
              child: Row(
                children: [
                  Text(
                    'Barang Dibayar',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: nameColor,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: tealBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${payment.items.length} item',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: tealFg,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: divider),

            Expanded(
              child: ListView.separated(
                controller: sc,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                itemCount: payment.items.length,
                separatorBuilder: (_, __) => Divider(height: 1, color: divider),
                itemBuilder: (_, i) {
                  final item = payment.items[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CatalogImage(
                          imagePath: item.catalogImagePath,
                          size: 52,
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
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: nameColor,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item.catalogCategory,
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 11,
                                  color: subColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${item.quantity}× ${formatRupiah(item.catalogPrice)}',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12,
                                  color: priceColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          formatRupiah(item.catalogPrice * item.quantity),
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: tealFg,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
              decoration: BoxDecoration(
                color: sheetBg,
                border: Border(top: BorderSide(color: divider)),
              ),
              child: Row(
                children: [
                  Text(
                    'Total Pembayaran',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: subColor,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    formatRupiah(payment.totalAmount),
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: tealFg,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
