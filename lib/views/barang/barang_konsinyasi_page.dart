import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../controllers/pengguna_controllers/klien_controller.dart';
import '../../models/pengguna_models/klien_model.dart';
import '../../widgets/search_filter_bar.dart';
import '../../widgets/catalog_image.dart';
import '../../utils/currency_format.dart';

class BarangKonsinyasiPage extends StatefulWidget {
  const BarangKonsinyasiPage({super.key});

  @override
  State<BarangKonsinyasiPage> createState() => _BarangKonsinyasiPageState();
}

class _BarangKonsinyasiPageState extends State<BarangKonsinyasiPage> {
  late final ClientController _controller;
  late final Stream<QuerySnapshot> _stream;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _controller = ClientController(firestore: FirebaseFirestore.instance);
    _stream = _controller.getClientsStream();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
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

  void _showDetail(BuildContext context, ClientModel client, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ClientDetailSheet(
        client: client,
        isDark: isDark,
        formatDate: _formatDate,
        initialCategory: _selectedCategory,
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
          'Barang Konsinyasi',
          style: TextStyle(fontFamily: 'Poppins'),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _stream,
        builder: (context, snap) {
          final allClients = (snap.data?.docs ?? [])
              .map(
                (d) =>
                    ClientModel.fromMap(d.id, d.data() as Map<String, dynamic>),
              )
              .toList();

          final allCats =
              allClients
                  .expand((c) => c.borrowedItems.map((b) => b.catalogCategory))
                  .toSet()
                  .toList()
                ..sort();

          var clients = List<ClientModel>.from(allClients);
          if (_searchQuery.isNotEmpty) {
            clients = clients
                .where(
                  (c) =>
                      c.name.toLowerCase().contains(_searchQuery) ||
                      c.address.toLowerCase().contains(_searchQuery) ||
                      c.phone.toLowerCase().contains(_searchQuery),
                )
                .toList();
          }
          if (_selectedCategory != null) {
            clients = clients
                .where(
                  (c) => c.borrowedItems.any(
                    (b) => b.catalogCategory == _selectedCategory,
                  ),
                )
                .toList();
          }

          final filterOptions = <FilterChipOption<String>>[
            const FilterChipOption(label: 'Semua', value: null),
            ...allCats.map((c) => FilterChipOption(label: c, value: c)),
          ];

          return Column(
            children: [
              SearchFilterBar<String>(
                searchController: _searchController,
                searchFocusNode: _searchFocusNode,
                hintText: 'Cari nama klien atau alamat...',
                onSearchChanged: (val) =>
                    setState(() => _searchQuery = val.trim().toLowerCase()),
                filters: filterOptions,
                selectedFilter: _selectedCategory,
                onFilterSelected: (val) =>
                    setState(() => _selectedCategory = val),
              ),
              Expanded(
                child: Builder(
                  builder: (_) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snap.hasError) {
                      return Center(
                        child: Text(
                          'Error: ${snap.error}',
                          style: const TextStyle(
                            color: Colors.red,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      );
                    }
                    if (clients.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline_rounded,
                              size: 64,
                              color: emptyIcon,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isNotEmpty ||
                                      _selectedCategory != null
                                  ? 'Klien Tidak Ditemukan'
                                  : 'Belum Ada Klien',
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
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      itemCount: clients.length,
                      itemBuilder: (context, i) {
                        final client = clients[i];
                        final displayItems = _selectedCategory != null
                            ? client.borrowedItems
                                  .where(
                                    (b) =>
                                        b.catalogCategory == _selectedCategory,
                                  )
                                  .toList()
                            : client.borrowedItems;
                        return _ClientCard(
                          client: client,
                          displayItems: displayItems,
                          isDark: isDark,
                          formatDate: _formatDate,
                          onDetail: () => _showDetail(context, client, isDark),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ClientCard extends StatelessWidget {
  final ClientModel client;
  final List<BorrowedItem> displayItems;
  final bool isDark;
  final String Function(DateTime?) formatDate;
  final VoidCallback onDetail;

  const _ClientCard({
    required this.client,
    required this.displayItems,
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

    final bool hasBorrowed = displayItems.isNotEmpty;
    final int totalQty = displayItems.fold(0, (s, b) => s + b.quantity);
    final double totalVal = displayItems.fold(
      0.0,
      (s, b) => s + b.catalogPrice * b.quantity,
    );
    final cats = displayItems.map((b) => b.catalogCategory).toSet().toList()
      ..sort();

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
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: hasBorrowed
                        ? tealBg
                        : (isDark
                              ? const Color(0xFF3A3740)
                              : Colors.grey[100]!),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    hasBorrowed ? Icons.store_outlined : Icons.person_outline,
                    color: hasBorrowed ? tealFg : subColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        client.name.isNotEmpty
                            ? client.name
                            : 'Klien Tanpa Nama',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: nameColor,
                        ),
                      ),
                      if (client.address.isNotEmpty)
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
                                client.address,
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
                  ),
                ),
                if (hasBorrowed)
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
                      '$totalQty unit',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: tealFg,
                      ),
                    ),
                  ),
              ],
            ),

            if (hasBorrowed) ...[
              if (cats.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: cats
                      .map(
                        (c) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF3A3740)
                                : Colors.grey[100],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            c,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 10,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
              const SizedBox(height: 12),

              ...displayItems
                  .take(3)
                  .map(
                    (b) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          CatalogImage(
                            imagePath: b.catalogImagePath,
                            size: 36,
                            borderRadius: 8,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  b.catalogName,
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: nameColor,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '${b.quantity}x  •  ${formatRupiah(b.catalogPrice * b.quantity)}',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 11,
                                    color: subColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

              if (displayItems.length > 3)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '+ ${displayItems.length - 3} barang lainnya...',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: tealFg,
                    ),
                  ),
                ),

              Divider(height: 20, color: cardBorder),

              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Nilai',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10,
                          color: subColor,
                        ),
                      ),
                      Text(
                        formatRupiah(totalVal),
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: tealFg,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  OutlinedButton.icon(
                    onPressed: onDetail,
                    icon: const Icon(Icons.list_alt_rounded, size: 15),
                    label: const Text(
                      'Lihat Semua',
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: nameColor,
                      side: BorderSide(color: cardBorder),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF3A3740) : Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    'Belum ada barang konsinyasi',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: subColor,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ClientDetailSheet extends StatefulWidget {
  final ClientModel client;
  final bool isDark;
  final String Function(DateTime?) formatDate;
  final String? initialCategory;

  const _ClientDetailSheet({
    required this.client,
    required this.isDark,
    required this.formatDate,
    required this.initialCategory,
  });

  @override
  State<_ClientDetailSheet> createState() => _ClientDetailSheetState();
}

class _ClientDetailSheetState extends State<_ClientDetailSheet> {
  String? _catFilter;

  @override
  void initState() {
    super.initState();
    _catFilter = widget.initialCategory;
  }

  @override
  Widget build(BuildContext context) {
    final Color sheetBg = widget.isDark
        ? const Color(0xFF2B2930)
        : Colors.white;
    final Color nameColor = widget.isDark
        ? Colors.white
        : const Color(0xFF1D1B20);
    final Color subColor = widget.isDark
        ? Colors.white54
        : const Color(0xFF757575);
    final Color divider = widget.isDark
        ? const Color(0xFF49454F)
        : const Color(0xFFE0E0E0);
    final Color tealFg = widget.isDark
        ? const Color(0xFF4DB6AC)
        : const Color(0xFF00796B);
    final Color tealBg = widget.isDark
        ? const Color(0xFF1A3A3A)
        : const Color(0xFFE0F2F1);

    final allCats =
        widget.client.borrowedItems
            .map((b) => b.catalogCategory)
            .toSet()
            .toList()
          ..sort();

    final items = _catFilter != null
        ? widget.client.borrowedItems
              .where((b) => b.catalogCategory == _catFilter)
              .toList()
        : widget.client.borrowedItems;

    final double grandTotal = items.fold(
      0.0,
      (s, b) => s + b.catalogPrice * b.quantity,
    );
    final int totalQty = items.fold(0, (s, b) => s + b.quantity);

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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                          widget.client.name,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: nameColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (widget.client.address.isNotEmpty)
                          Text(
                            widget.client.address,
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
                      color: tealBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$totalQty unit',
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

            if (allCats.length > 1)
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  children: [
                    _chip('Semua', null),
                    ...allCats.map((c) => _chip(c, c)),
                  ],
                ),
              ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Row(
                children: [
                  Text(
                    'Barang yang Dipinjam',
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
                      '${items.length} item',
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
              child: items.isEmpty
                  ? Center(
                      child: Text(
                        'Tidak ada barang di kategori ini',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          color: subColor,
                        ),
                      ),
                    )
                  : ListView.separated(
                      controller: sc,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      itemCount: items.length,
                      separatorBuilder: (_, __) =>
                          Divider(height: 1, color: divider),
                      itemBuilder: (_, i) {
                        final b = items[i];

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CatalogImage(
                                imagePath: b.catalogImagePath,
                                size: 52,
                                borderRadius: 10,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            b.catalogName,
                                            style: TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: nameColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      b.catalogCategory,
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 11,
                                        color: subColor,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${b.quantity}× ${formatRupiah(b.catalogPrice)}',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 12,
                                        color: subColor,
                                      ),
                                    ),
                                    if (b.lastReceivedAt != null)
                                      Text(
                                        'Terakhir diterima: ${widget.formatDate(b.lastReceivedAt)}',
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
                              Text(
                                formatRupiah(b.catalogPrice * b.quantity),
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
                    'Total Nilai Konsinyasi',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: subColor,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    formatRupiah(grandTotal),
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

  Widget _chip(String label, String? value) {
    final bool isSelected = _catFilter == value;
    final Color tealFg = widget.isDark
        ? const Color(0xFF4DB6AC)
        : const Color(0xFF00796B);
    final Color chipBg = widget.isDark
        ? const Color(0xFF3A3740)
        : const Color(0xFFECECEC);
    final Color chipBorder = widget.isDark
        ? const Color(0xFF49454F)
        : const Color(0xFFE0E0E0);

    return GestureDetector(
      onTap: () => setState(() => _catFilter = isSelected ? null : value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? tealFg : chipBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? tealFg : chipBorder),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isSelected
                ? Colors.white
                : (widget.isDark ? Colors.white70 : Colors.black87),
          ),
        ),
      ),
    );
  }
}
