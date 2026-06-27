import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:provider/provider.dart';
import '../../controllers/pengguna_controllers/klien_controller.dart';
import '../../controllers/pembayaran_controllers/pembayaran_controller.dart';
import '../../models/pengguna_models/klien_model.dart';
import '../../models/pembayaran_models/pembayaran_model.dart';
import '../../service/auth_provider.dart';
import '../../widgets/search_filter_bar.dart';
import '../../widgets/catalog_image.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/quantity_stepper.dart';
import '../../utils/currency_format.dart';
import '../../utils/app_colors.dart';

class _PayItem {
  final BorrowedItem item;
  int qty;
  _PayItem({required this.item, required this.qty});
}

class ManualPaymentPage extends StatefulWidget {
  const ManualPaymentPage({super.key});

  @override
  State<ManualPaymentPage> createState() => _ManualPaymentPageState();
}

class _ManualPaymentPageState extends State<ManualPaymentPage> {
  late final ClientController _controller;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _controller = ClientController(firestore: FirebaseFirestore.instance);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _showPaymentSheet(BuildContext context, ClientModel client) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PaymentBottomSheet(client: client),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color emptyIcon = isDark ? Colors.white24 : Colors.black26;
    final Color emptyText = isDark ? Colors.white38 : const Color(0xFF9E9E9E);

    final role = context.watch<AuthProvider>().role;
    final user = FirebaseAuth.instance.currentUser;

    final stream = _controller.getClientsByRole(
      role: role ?? '',
      email: user?.email ?? '',
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Pembayaran Manual',
          style: TextStyle(fontFamily: 'Poppins'),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: stream,
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

          // Sort: clients with debt first
          clients.sort((a, b) {
            final aHasDebt = a.computedDebt > 0;
            final bHasDebt = b.computedDebt > 0;
            if (aHasDebt != bHasDebt) {
              return aHasDebt ? -1 : 1;
            }
            return 0;
          });

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
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
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
                        return _ClientPayCard(
                          client: client,
                          displayItems: displayItems,
                          onPay: () => _showPaymentSheet(context, client),
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

class _ClientPayCard extends StatelessWidget {
  final ClientModel client;
  final List<BorrowedItem> displayItems;
  final VoidCallback onPay;

  const _ClientPayCard({
    required this.client,
    required this.displayItems,
    required this.onPay,
  });

  @override
  Widget build(BuildContext context) {
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
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.cardBorder, width: 1),
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
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: hasBorrowed
                        ? context.primaryBg
                        : (context.isDark
                              ? const Color(0xFF3A3740)
                              : Colors.grey[100]!),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    hasBorrowed ? Icons.store_outlined : Icons.person_outline,
                    color: hasBorrowed ? context.primaryFg : context.subColor,
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
                          color: context.nameColor,
                        ),
                      ),
                      if (client.address.isNotEmpty)
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
                                client.address,
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
                  ),
                ),
                if (hasBorrowed)
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
                      '$totalQty unit',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: context.primaryFg,
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
                            color: context.isDark
                                ? const Color(0xFF3A3740)
                                : Colors.grey[100],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            c,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 10,
                              color: context.isDark
                                  ? Colors.white70
                                  : Colors.black87,
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
                                    color: context.nameColor,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '${b.quantity}x  •  ${formatRupiah(b.catalogPrice * b.quantity)}',
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
                      color: context.primaryFg,
                    ),
                  ),
                ),

              Divider(height: 20, color: context.cardBorder),
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
                          color: context.subColor,
                        ),
                      ),
                      Text(
                        formatRupiah(totalVal),
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: context.primaryFg,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  OutlinedButton.icon(
                    onPressed: onPay,
                    icon: const Icon(Icons.payments_outlined, size: 15),
                    label: const Text(
                      'Bayar',
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: context.primaryFg,
                      side: BorderSide(color: context.primaryFg),
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
                  color: context.isDark
                      ? const Color(0xFF3A3740)
                      : Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    'Belum ada barang konsinyasi',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: context.subColor,
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

class _PaymentBottomSheet extends StatefulWidget {
  final ClientModel client;

  const _PaymentBottomSheet({required this.client});

  @override
  State<_PaymentBottomSheet> createState() => _PaymentBottomSheetState();
}

class _PaymentBottomSheetState extends State<_PaymentBottomSheet> {
  late final Map<int, _PayItem> _selected;
  late final ClientController _controller;
  late final PaymentController _payController;
  bool _isPaying = false;

  final DraggableScrollableController _dragController =
      DraggableScrollableController();

  @override
  void initState() {
    super.initState();
    _controller = ClientController(firestore: FirebaseFirestore.instance);
    _payController = PaymentController(firestore: FirebaseFirestore.instance);
    _selected = {};
  }

  @override
  void dispose() {
    _dragController.dispose();
    super.dispose();
  }

  void _toggle(BorrowedItem item, int index) {
    setState(() {
      if (_selected.containsKey(index)) {
        _selected.remove(index);
      } else {
        _selected[index] = _PayItem(item: item, qty: item.quantity);
      }
    });
  }

  void _changeQty(int key, int delta) {
    setState(() {
      if (!_selected.containsKey(key)) return;
      final newQty = _selected[key]!.qty + delta;
      if (newQty <= 0) {
        _selected.remove(key);
      } else {
        _selected[key]!.qty = newQty;
      }
    });
  }

  void _setQty(int key, int qty) {
    setState(() {
      if (!_selected.containsKey(key)) return;
      if (qty <= 0) {
        _selected.remove(key);
      } else {
        _selected[key]!.qty = qty;
      }
    });
  }

  Future<void> _pay() async {
    if (_selected.isEmpty || _isPaying) return;
    setState(() => _isPaying = true);

    final currentItems = widget.client.borrowedItems
        .map((b) => b.toMap())
        .toList();

    final deductions = _selected.map(
      (index, payItem) => MapEntry(index, payItem.qty),
    );

    final result = await _controller.deductBorrowedItems(
      clientId: widget.client.id,
      currentItems: currentItems,
      deductions: deductions,
    );

    if (result['success'] == true) {
      final paidItems = _selected.values
          .map(
            (p) => PaidItem(
              catalogName: p.item.catalogName,
              catalogCategory: p.item.catalogCategory,
              catalogImagePath: p.item.catalogImagePath,
              catalogPrice: p.item.catalogPrice,
              quantity: p.qty,
            ),
          )
          .toList();

      final totalAmount = paidItems.fold(
        0.0,
        (s, i) => s + i.catalogPrice * i.quantity,
      );

      await _payController.createPayment(
        clientId: widget.client.id,
        clientName: widget.client.name,
        clientAddress: widget.client.address,
        clientEmail: widget.client.email,
        paymentMethod: 'cash',
        items: paidItems,
        totalAmount: totalAmount,
        confirmedBy:
            FirebaseAuth.instance.currentUser?.displayName ??
            FirebaseAuth.instance.currentUser?.email,
      );
    }

    setState(() => _isPaying = false);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['success'] == true
                ? 'Pembayaran manual berhasil dicatat'
                : 'Gagal: ${result['error'] ?? 'Terjadi kesalahan'}',
          ),
          backgroundColor: result['success'] == true
              ? Colors.green
              : Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final allItems = widget.client.borrowedItems;
    final selectedList = _selected.values.toList();

    final double totalPrice = selectedList.fold(
      0.0,
      (s, e) => s + e.item.catalogPrice * e.qty,
    );
    final int totalItems = selectedList.fold(0, (s, e) => s + e.qty);

    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: context.cardBorder, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: context.isDark ? 0.35 : 0.10),
            blurRadius: 16,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: DraggableScrollableSheet(
        controller: _dragController,
        initialChildSize: 0.88,
        minChildSize: 0.5,
        maxChildSize: 0.97,
        expand: false,
        builder: (context, sc) => SafeArea(
          top: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 6),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.cardBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: context.primaryBg,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.store_outlined,
                        color: context.primaryFg,
                        size: 20,
                      ),
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
                              color: context.nameColor,
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
                                color: context.subColor,
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
                        color: context.primaryBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$totalItems unit dipilih',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: context.primaryFg,
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

              Divider(height: 1, color: context.cardBorder),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                child: Row(
                  children: [
                    Text(
                      'Pilih Barang yang Akan Dibayar',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: context.nameColor,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: context.primaryBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_selected.length}/${allItems.length} item',
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
              ),
              Divider(height: 1, color: context.cardBorder),
              Expanded(
                child: allItems.isEmpty
                    ? Center(
                        child: Text(
                          'Tidak ada barang konsinyasi',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            color: context.subColor,
                          ),
                        ),
                      )
                    : ListView.separated(
                        controller: sc,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        itemCount: allItems.length,
                        separatorBuilder: (_, __) =>
                            Divider(height: 1, color: context.cardBorder),
                        itemBuilder: (_, i) {
                          final b = allItems[i];
                          final key = i;
                          final isSelected = _selected.containsKey(key);
                          final payItem = _selected[key];

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                GestureDetector(
                                  onTap: () => _toggle(b, i),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 160),
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? context.primaryFg
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: isSelected
                                            ? context.primaryFg
                                            : context.cardBorder,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: isSelected
                                        ? const Icon(
                                            Icons.check,
                                            size: 16,
                                            color: Colors.white,
                                          )
                                        : null,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                CatalogImage(
                                  imagePath: b.catalogImagePath,
                                  size: 46,
                                  borderRadius: 10,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        b.catalogName,
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: context.nameColor,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        b.catalogCategory,
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 11,
                                          color: context.subColor,
                                        ),
                                      ),
                                      Text(
                                        formatRupiah(b.catalogPrice),
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: context.isDark
                                              ? const Color(0xFF80CBC4)
                                              : const Color(0xFF2E7D32),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (isSelected && payItem != null)
                                  QuantityStepper(
                                    quantity: payItem.qty,
                                    maxQuantity: b.quantity,
                                    onDecrement: () => _changeQty(key, -1),
                                    onIncrement: () => _changeQty(key, 1),
                                    onChanged: (val) => _setQty(key, val),
                                  )
                                else
                                  Text(
                                    'Jumlah: ${b.quantity}',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 11,
                                      color: context.subColor,
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                decoration: BoxDecoration(
                  color: context.cardBg,
                  border: Border(
                    top: BorderSide(color: context.cardBorder, width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Pembayaran',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              color: context.isDark
                                  ? Colors.white54
                                  : Colors.grey,
                            ),
                          ),
                          Text(
                            formatRupiah(totalPrice),
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: context.nameColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _isPaying
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : GradientButton(
                            label: 'Bayar',
                            onPressed: () {
                              if (_selected.isEmpty) {
                                showAppDialog(
                                  context: context,
                                  title: 'Peringatan',
                                  titleIcon: const Icon(
                                    Icons.warning_amber_rounded,
                                    color: Colors.black,
                                  ),
                                  content: 'Silakan pilih minimal satu barang.',
                                  actions: [
                                    AppDialogAction(
                                      label: 'OK',
                                      type: AppDialogActionType.gradient,
                                      onPressed: () => Navigator.pop(context),
                                    ),
                                  ],
                                );
                                return;
                              }
                              showAppDialog(
                                context: context,
                                titleIcon: const Icon(
                                  Icons.warning_amber_rounded,
                                ),
                                title: 'Pembayaran',
                                content:
                                    'Bayar ${_selected.length} item senilai ${formatRupiah(totalPrice)} untuk ${widget.client.name}?',
                                actions: [
                                  AppDialogAction(
                                    label: 'Batal',
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                  AppDialogAction(
                                    label: 'Bayar',
                                    type: AppDialogActionType.gradient,
                                    onPressed: () {
                                      Navigator.pop(context);
                                      _pay();
                                    },
                                  ),
                                ],
                              );
                            },
                            borderRadius: 12,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 28,
                              vertical: 12,
                            ),
                          ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
