import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../controllers/pembayaran_controllers/penyerahan_controller.dart';
import '../../models/pembayaran_models/pembayaran_model.dart';
import '../../widgets/catalog_image.dart';
import '../../utils/currency_format.dart';

class HistoryPenyerahanPage extends StatefulWidget {
  const HistoryPenyerahanPage({super.key});

  @override
  State<HistoryPenyerahanPage> createState() => _HistoryPenyerahanPageState();
}

class _HistoryPenyerahanPageState extends State<HistoryPenyerahanPage> {
  late final PenyerahanController _controller;
  late final Stream<QuerySnapshot> _stream;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';
  DateTime? _dateFrom;
  DateTime? _dateTo;

  @override
  void initState() {
    super.initState();
    _controller = PenyerahanController(firestore: FirebaseFirestore.instance);
    _stream = _controller.getDeliveriesStream();
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

  PembayaranModel _fromDeliveryDoc(String id, Map<String, dynamic> m) {
    final rawItems = m['items'] as List<dynamic>? ?? [];
    return PembayaranModel(
      id: id,
      clientId: m['clientId'] ?? '',
      clientName: m['clientName'] ?? '',
      clientAddress: m['clientAddress'] ?? '',
      paymentMethod: 'serahkan',
      items: rawItems
          .whereType<Map<String, dynamic>>()
          .map(PaidItem.fromMap)
          .toList(),
      totalAmount: (m['totalAmount'] as num?)?.toDouble() ?? 0.0,
      paidAt: (m['deliveredAt'] as dynamic)?.toDate() as DateTime?,
    );
  }

  void _showDetail(BuildContext context, PembayaranModel record, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DeliveryDetailSheet(
        record: record,
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
          'Riwayat Penyerahan',
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
                          Icons.local_shipping_outlined,
                          size: 64,
                          color: emptyIcon,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Belum Ada Riwayat Penyerahan',
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

                var records = snapshot.data!.docs
                    .map(
                      (d) => _fromDeliveryDoc(
                        d.id,
                        d.data() as Map<String, dynamic>,
                      ),
                    )
                    .toList();

                if (_searchQuery.isNotEmpty) {
                  records = records
                      .where(
                        (r) =>
                            r.clientName.toLowerCase().contains(_searchQuery) ||
                            r.clientAddress.toLowerCase().contains(
                              _searchQuery,
                            ),
                      )
                      .toList();
                }

                if (_dateFrom != null && _dateTo != null) {
                  records = records.where((r) {
                    final date = r.paidAt;
                    if (date == null) return false;
                    return !date.isBefore(_dateFrom!) &&
                        !date.isAfter(_dateTo!);
                  }).toList();
                }

                if (records.isEmpty) {
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
                  itemCount: records.length,
                  itemBuilder: (context, i) {
                    final record = records[i];
                    final categories = record.items
                        .map((it) => it.catalogCategory)
                        .toSet()
                        .toList();
                    return _DeliveryCard(
                      record: record,
                      categories: categories,
                      isDark: isDark,
                      formatDate: _formatDate,
                      onDetail: () => _showDetail(context, record, isDark),
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

class _DeliveryCard extends StatelessWidget {
  final PembayaranModel record;
  final List<String> categories;
  final bool isDark;
  final String Function(DateTime?) formatDate;
  final VoidCallback onDetail;

  const _DeliveryCard({
    required this.record,
    required this.categories,
    required this.isDark,
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
    final Color tealFg = isDark
        ? const Color(0xFF4DB6AC)
        : const Color(0xFF00796B);
    final Color tealBg = isDark
        ? const Color(0xFF1A3A3A)
        : const Color(0xFFE0F2F1);
    final Color shipBg = isDark
        ? const Color(0xFF1A3020)
        : const Color(0xFFE8F5E9);
    final Color shipFg = isDark
        ? const Color(0xFF80CBC4)
        : const Color(0xFF2E7D32);

    final totalItems = record.items.fold(0, (s, i) => s + i.quantity);

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
                        record.clientName.isNotEmpty
                            ? record.clientName
                            : 'Klien Tidak Dikenal',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: nameColor,
                        ),
                      ),
                      if (record.clientAddress.isNotEmpty) ...[
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
                                record.clientAddress,
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
                        color: shipBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.local_shipping_outlined,
                            size: 12,
                            color: shipFg,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Diserahkan',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: shipFg,
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
                  'Diserahkan: ${formatDate(record.paidAt)}',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: subColor,
                  ),
                ),
                const Spacer(),
                Text(
                  formatRupiah(record.totalAmount),
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

class _DeliveryDetailSheet extends StatelessWidget {
  final PembayaranModel record;
  final bool isDark;
  final String Function(DateTime?) formatDate;

  const _DeliveryDetailSheet({
    required this.record,
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
    final Color shipBg = isDark
        ? const Color(0xFF1A3020)
        : const Color(0xFFE8F5E9);
    final Color shipFg = isDark
        ? const Color(0xFF80CBC4)
        : const Color(0xFF2E7D32);
    final Color priceColor = isDark
        ? const Color(0xFF80CBC4)
        : const Color(0xFF2E7D32);

    final totalItems = record.items.fold(0, (s, i) => s + i.quantity);

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
                          record.clientName,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: nameColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (record.clientAddress.isNotEmpty)
                          Text(
                            record.clientAddress,
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
                      color: shipBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.local_shipping_outlined,
                          size: 12,
                          color: shipFg,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Diserahkan',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: shipFg,
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
                    'Diserahkan: ${formatDate(record.paidAt)}',
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
                    'Barang Diserahkan',
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
                      '${record.items.length} item',
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
                itemCount: record.items.length,
                separatorBuilder: (_, __) => Divider(height: 1, color: divider),
                itemBuilder: (_, i) {
                  final item = record.items[i];
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
                    'Total Estimasi',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: subColor,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    formatRupiah(record.totalAmount),
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
