import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../service/auth_provider.dart' as app_auth;
import '../../service/roles.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../controllers/pengguna_controllers/klien_controller.dart';
import '../../controllers/barang_controllers/katalog_controller.dart';
import '../../controllers/barang_controllers/konsinyasi_controller.dart';
import '../../models/pengguna_models/klien_model.dart';
import '../../models/barang_models/katalog_model.dart';
import '../../models/barang_models/konsinyasi_model.dart';
import '../../widgets/search_filter_bar.dart';
import '../../widgets/catalog_image.dart';
import '../../widgets/gradient_button.dart';
import '../../utils/currency_format.dart';
import '../../utils/app_colors.dart';
import '../../widgets/date_range_filter.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/app_empty_state.dart';

class ConsignmentPage extends StatefulWidget {
  const ConsignmentPage({super.key});

  @override
  State<ConsignmentPage> createState() => _ConsignmentPageState();
}

class _ConsignmentPageState extends State<ConsignmentPage> {
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

  List<ClientModel> _filterClients(
    List<ClientModel> all, {
    required String? email,
    required String? role,
  }) {
    var result = List<ClientModel>.from(all);
    if (role == Roles.client) {
      result = result.where((c) => c.email == email).toList();
    }

    if (_searchQuery.isNotEmpty) {
      result = result
          .where(
            (c) =>
                c.name.toLowerCase().contains(_searchQuery) ||
                c.address.toLowerCase().contains(_searchQuery) ||
                c.phone.toLowerCase().contains(_searchQuery),
          )
          .toList();
    }

    if (_selectedCategory != null) {
      result = result
          .where(
            (c) => c.borrowedItems.any(
              (b) => b.catalogCategory == _selectedCategory,
            ),
          )
          .toList();
    }

    return result;
  }

  void _showDetail(BuildContext context, ClientModel client) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ClientDetailSheet(
        client: client,
        formatDate: formatDateShort,
        initialCategory: _selectedCategory,
      ),
    );
  }

  void _showSerahkanSheet(
    BuildContext context,
    List<ClientModel> clients, {
    ClientModel? initialClient,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SerahkanBottomSheet(
        clients: clients,
        clientController: _controller,
        initialClient: initialClient,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<app_auth.AuthProvider>();
    final role = authProvider.role;
    final email = FirebaseAuth.instance.currentUser?.email;

    return StreamBuilder<QuerySnapshot>(
      stream: _stream,
      builder: (context, snap) {
        final allClients = (snap.data?.docs ?? [])
            .map(
              (d) =>
                  ClientModel.fromMap(d.id, d.data() as Map<String, dynamic>),
            )
            .toList();

        var clients = _filterClients(
          allClients,
          email: email,
          role: role,
        );

        if (role == Roles.admin || role == Roles.karyawan) {
          clients.sort((a, b) {
            final aHasDebt = a.computedDebt > 0;
            final bHasDebt = b.computedDebt > 0;
            if (aHasDebt != bHasDebt) {
              return aHasDebt ? -1 : 1;
            }
            return 0;
          });
        }

        final allCats =
            clients
                .expand((c) => c.borrowedItems.map((b) => b.catalogCategory))
                .toSet()
                .toList()
              ..sort();

        final filterOptions = <FilterChipOption<String>>[
          const FilterChipOption(label: 'Semua', value: null),
          ...allCats.map((c) => FilterChipOption(label: c, value: c)),
        ];

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Barang Konsinyasi',
              style: TextStyle(fontFamily: 'Poppins'),
            ),
          ),
          floatingActionButton: role == Roles.admin
              ? FloatingActionButton.extended(
                  onPressed: () => _showSerahkanSheet(context, allClients),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text(
                    'Konsinyasi',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  backgroundColor: context.primaryFg,
                  foregroundColor: Colors.white,
                )
              : null,
          body: Column(
            children: [
              SearchFilterBar<String>(
                searchController: _searchController,
                searchFocusNode: _searchFocusNode,
                hintText: role == Roles.client
                    ? 'Cari nama barang...'
                    : 'Cari nama klien atau alamat...',
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
                      return AppEmptyState(
                        icon: Icons.people_outline_rounded,
                        message: _searchQuery.isNotEmpty ||
                                _selectedCategory != null
                            ? 'Klien Tidak Ditemukan'
                            : 'Belum Ada Klien',
                        iconSize: 64,
                      );
                    }

                    if (role == Roles.client) {
                      final client = clients.first;
                      return _ClientConsignmentView(
                        client: client,
                        selectedCategory: _selectedCategory,
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
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
                        return ClientCard(
                          client: client,
                          displayItems: displayItems,
                          formatDate: formatDateShort,
                          onDetail: () => _showDetail(context, client),
                          onSerahkan: () => _showSerahkanSheet(
                            context,
                            allClients,
                            initialClient: client,
                          ),
                          role: role,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ClientConsignmentView extends StatelessWidget {
  final ClientModel client;
  final String? selectedCategory;

  const _ClientConsignmentView({
    required this.client,
    required this.selectedCategory,
  });

  @override
  Widget build(BuildContext context) {
    final displayItems = selectedCategory != null
        ? client.borrowedItems.where((b) => b.catalogCategory == selectedCategory).toList()
        : client.borrowedItems;

    return Container(
      color: context.scaffoldBg,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                _StatCard(
                  label: 'Total Item',
                  value: '${displayItems.fold(0, (s, b) => s + b.quantity)} unit',
                  icon: Icons.inventory_2_outlined,
                ),
                const SizedBox(width: 12),
                _StatCard(
                  label: 'Total Nilai',
                  value: formatRupiah(displayItems.fold(0.0, (s, b) => s + b.catalogPrice * b.quantity)),
                  icon: Icons.monetization_on_outlined,
                ),
              ],
            ),
            const SizedBox(height: 16),

            Container(
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
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                    child: Row(
                      children: [
                        Icon(Icons.list_alt_rounded, color: context.primaryFg, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Daftar Barang',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: context.nameColor,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: context.primaryBg,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${displayItems.length} item',
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

                  if (displayItems.isEmpty)
                    AppEmptyState(
                      icon: Icons.inventory_2_outlined,
                      message: 'Belum ada barang konsinyasi',
                      padding: const EdgeInsets.symmetric(vertical: 32),
                    )
                  else
                    ...displayItems.asMap().entries.map((entry) {
                      final i = entry.key;
                      final b = entry.value;
                      final isLast = i == displayItems.length - 1;
                      return Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CatalogImage(imagePath: b.catalogImagePath, size: 52, borderRadius: 10),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        b.catalogName,
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: context.nameColor,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        b.catalogCategory,
                                        style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: context.subColor),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${b.quantity}x ${formatRupiah(b.catalogPrice)}',
                                        style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: context.subColor),
                                      ),
                                      if (b.lastReceivedAt != null)
                                        Text(
                                          'Diterima: ${formatDateShort(b.lastReceivedAt)}',
                                          style: TextStyle(fontFamily: 'Poppins', fontSize: 10, color: context.subColor),
                                        ),
                                    ],
                                  ),
                                ),
                                Text(
                                  formatRupiah(b.catalogPrice * b.quantity),
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: context.primaryFg,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!isLast) Divider(height: 1, color: context.cardBorder),
                        ],
                      );
                    }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.cardBorder, width: 1),
          boxShadow: [
            BoxShadow(
              color: context.cardShadow,
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: context.primaryBg, shape: BoxShape.circle),
              child: Icon(icon, color: context.primaryFg, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 10, color: context.subColor),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: context.nameColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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

class ClientCard extends StatelessWidget {
  final ClientModel client;
  final List<BorrowedItem> displayItems;
  final String Function(DateTime?) formatDate;
  final VoidCallback onDetail;
  final VoidCallback onSerahkan;
  final String? role;

  const ClientCard({
    super.key,
    required this.client,
    required this.displayItems,
    required this.formatDate,
    required this.onDetail,
    required this.onSerahkan,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    final bool isAdmin = role == Roles.admin;

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
                    color: hasBorrowed ? context.primaryBg : context.headerBg,
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
                            color: context.headerBg,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            c,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 10,
                              color: context.chipText,
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
                  if (isAdmin) ...[
                    Material(
                      color: context.primaryBg,
                      shape: const CircleBorder(),
                      clipBehavior: Clip.hardEdge,
                      child: Tooltip(
                        message: 'Tambah Konsinyasi',
                        child: InkWell(
                          onTap: onSerahkan,
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            child: Icon(
                              Icons.add_rounded,
                              color: context.primaryFg,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  OutlinedButton.icon(
                    onPressed: onDetail,
                    icon: const Icon(Icons.list_alt_rounded, size: 15),
                    label: const Text(
                      'Lihat Semua',
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: context.nameColor,
                      side: BorderSide(color: context.cardBorder),
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
                  color: context.headerBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Belum ada barang konsinyasi',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: context.subColor,
                      ),
                    ),
                    if (isAdmin) ...[
                      const SizedBox(height: 12),
                      Material(
                        color: context.primaryBg,
                        shape: const CircleBorder(),
                        clipBehavior: Clip.hardEdge,
                        child: Tooltip(
                          message: 'Tambah Konsinyasi',
                          child: InkWell(
                            onTap: onSerahkan,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              child: Icon(
                                Icons.add_rounded,
                                color: context.primaryFg,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ClientDetailSheet extends StatefulWidget {
  final ClientModel client;
  final String Function(DateTime?) formatDate;
  final String? initialCategory;

  const ClientDetailSheet({
    super.key,
    required this.client,
    required this.formatDate,
    required this.initialCategory,
  });

  @override
  State<ClientDetailSheet> createState() => _ClientDetailSheetState();
}

class _ClientDetailSheetState extends State<ClientDetailSheet> {
  String? _catFilter;

  @override
  void initState() {
    super.initState();
    _catFilter = widget.initialCategory;
  }

  @override
  Widget build(BuildContext context) {
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
      builder: (context, sc) => SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            color: context.cardBg,
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
                        '$totalQty unit',
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
                      _chip(context, 'Semua', null),
                      ...allCats.map((c) => _chip(context, c, c)),
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
                        '${items.length} item',
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
                child: items.isEmpty
                    ? AppEmptyState(
                        icon: Icons.inventory_2_outlined,
                        message: 'Tidak ada barang di kategori ini',
                      )
                    : ListView.separated(
                        controller: sc,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        itemCount: items.length,
                        separatorBuilder: (_, __) =>
                            Divider(height: 1, color: context.cardBorder),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                                color: context.nameColor,
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
                                          color: context.subColor,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                        Text(
                                          '${b.quantity}x ${formatRupiah(b.catalogPrice)}',
                                          style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 12,
                                          color: context.subColor,
                                        ),
                                      ),
                                      if (b.lastReceivedAt != null)
                                        Text(
                                          'Terakhir diterima: ${widget.formatDate(b.lastReceivedAt)}',
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 10,
                                            color: context.subColor,
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
                                    color: context.primaryFg,
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
                  color: context.cardBg,
                  border: Border(top: BorderSide(color: context.cardBorder)),
                ),
                child: Row(
                  children: [
                    Text(
                      'Total Nilai Konsinyasi',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: context.subColor,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      formatRupiah(grandTotal),
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: context.primaryFg,
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

  Widget _chip(BuildContext context, String label, String? value) {
    final bool isSelected = _catFilter == value;

    return GestureDetector(
      onTap: () => setState(() => _catFilter = isSelected ? null : value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? context.primaryFg : context.chipBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? context.primaryFg : context.cardBorder),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : context.chipText,
          ),
        ),
      ),
    );
  }
}

class SelectedItem {
  final CatalogModel catalog;
  int quantity;
  SelectedItem({required this.catalog}) : quantity = 1;
}

class _SerahkanBottomSheet extends StatefulWidget {
  final List<ClientModel> clients;
  final ClientController clientController;
  final ClientModel? initialClient;

  const _SerahkanBottomSheet({
    required this.clients,
    required this.clientController,
    this.initialClient,
  });

  @override
  State<_SerahkanBottomSheet> createState() => _SerahkanBottomSheetState();
}

class _SerahkanBottomSheetState extends State<_SerahkanBottomSheet> {
  late final CatalogController _catalogController;
  late final ConsignmentRequestController _consignmentRequestController;
  late final Stream<QuerySnapshot> _catalogStream;

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _clientSearchController = TextEditingController();
  final FocusNode _clientFocusNode = FocusNode();
  final Map<String, SelectedItem> _selected = {};

  ClientModel? _selectedClient;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _catalogController = CatalogController(
      firestore: FirebaseFirestore.instance,
    );
    _consignmentRequestController = ConsignmentRequestController(
      firestore: FirebaseFirestore.instance,
    );
    _catalogStream = _catalogController.getCatalogStream();
    if (widget.initialClient != null) {
      _selectedClient = widget.initialClient;
      _clientSearchController.text = widget.initialClient!.name;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _clientSearchController.dispose();
    _clientFocusNode.dispose();
    super.dispose();
  }

  void _toggle(CatalogModel item) {
    setState(() {
      if (_selected.containsKey(item.id)) {
        _selected.remove(item.id);
      } else {
        _selected[item.id] = SelectedItem(catalog: item);
      }
    });
  }

  void _changeQty(String id, int delta) {
    setState(() {
      if (!_selected.containsKey(id)) return;
      final newQty = _selected[id]!.quantity + delta;
      if (newQty <= 0) {
        _selected.remove(id);
      } else {
        _selected[id]!.quantity = newQty;
      }
    });
  }

  void _showValidationError(String message) {
    showAppDialog(
      context: context,
      title: 'Peringatan',
      titleIcon: const Icon(Icons.warning_amber_rounded, color: Colors.black),
      content: message,
      actions: [
        AppDialogAction(
          label: 'OK',
          type: AppDialogActionType.gradient,
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Future<void> _serahkan() async {
    if (_selectedClient == null || _selected.isEmpty || _isSubmitting) return;
    setState(() => _isSubmitting = true);

    final newItems = _selected.values
        .map(
          (si) => {
            'catalogId': si.catalog.id,
            'catalogName': si.catalog.name,
            'catalogPrice': si.catalog.price,
            'catalogCategory': si.catalog.category,
            'catalogImagePath': si.catalog.imagePath,
            'quantity': si.quantity,
          },
        )
        .toList();

    final result = await widget.clientController.addBorrowedItemsDirect(
      clientId: _selectedClient!.id,
      newItems: newItems,
    );

    if (result['success'] == true) {
      final consignmentItems = _selected.values
          .map(
            (si) => ConsignmentItemEntry(
              catalogId: si.catalog.id,
              catalogName: si.catalog.name,
              catalogCategory: si.catalog.category,
              catalogImagePath: si.catalog.imagePath,
              catalogPrice: si.catalog.price,
              quantity: si.quantity,
              approvedQty: si.quantity,
              itemStatus: ConsignmentItemStatus.approved,
            ),
          )
          .toList();

      await _consignmentRequestController.createDirectReceivedRequest(
        clientId: _selectedClient!.id,
        clientName: _selectedClient!.name,
        clientAddress: _selectedClient!.address,
        clientEmail: _selectedClient!.email,
        items: consignmentItems,
      );
    }

    setState(() => _isSubmitting = false);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['success'] == true
                ? 'Barang berhasil diserahkan ke ${_selectedClient!.name}'
                : (result['error']?.toString().toLowerCase().contains(
                            'unavailable',
                          ) ==
                          true
                      ? 'Tidak ada koneksi internet, tidak bisa mencatat penyerahan barang'
                      : 'Gagal: ${result['error']}'),
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
    final selectedList = _selected.values.toList();
    final double totalEst = selectedList.fold(
      0.0,
      (s, e) => s + e.catalog.price * e.quantity,
    );
    final int totalQty = selectedList.fold(0, (s, e) => s + e.quantity);

    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: context.cardBorder, width: 1)),
        boxShadow: [
          BoxShadow(
            color: context.cardShadow,
            blurRadius: 16,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.90,
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
                padding: const EdgeInsets.fromLTRB(16, 2, 8, 10),
                child: Row(
                  children: [
                    Icon(
                      Icons.local_shipping_outlined,
                      color: context.primaryFg,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Tambah Barang Konsinyasi',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: context.nameColor,
                        ),
                      ),
                    ),
                    if (totalQty > 0)
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
                          '$totalQty item dipilih',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: context.primaryFg,
                          ),
                        ),
                      ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: _selectedClient == null
                    ? Autocomplete<ClientModel>(
                        optionsBuilder: (TextEditingValue textValue) {
                          if (textValue.text.isEmpty) {
                            return widget.clients;
                          }
                          final q = textValue.text.toLowerCase();
                          return widget.clients.where(
                            (c) =>
                                c.name.toLowerCase().contains(q) ||
                                c.address.toLowerCase().contains(q) ||
                                c.phone.toLowerCase().contains(q),
                          );
                        },
                        displayStringForOption: (c) => c.name,
                        fieldViewBuilder:
                            (
                              context,
                              textEditingController,
                              focusNode,
                              onFieldSubmitted,
                            ) {
                              return TextField(
                                controller: textEditingController,
                                focusNode: focusNode,
                                decoration: InputDecoration(
                                  hintText: 'Cari nama klien...',
                                  hintStyle: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 13,
                                    color: context.isDark ? Colors.white38 : Colors.black38,
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.person_search_outlined,
                                    size: 20,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: context.cardBorder),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: context.cardBorder),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: context.primaryFg),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  isDense: true,
                                ),
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 13,
                                  color: context.nameColor,
                                ),
                              );
                            },
                        optionsViewBuilder: (context, onSelected, options) {
                          return Align(
                            alignment: Alignment.topLeft,
                            child: Material(
                              elevation: 4,
                              borderRadius: BorderRadius.circular(12),
                              color: context.cardBg,
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxHeight: 200,
                                  maxWidth: 380,
                                ),
                                child: ListView.builder(
                                  padding: EdgeInsets.zero,
                                  shrinkWrap: true,
                                  itemCount: options.length,
                                  itemBuilder: (context, index) {
                                    final client = options.elementAt(index);
                                    return InkWell(
                                      onTap: () => onSelected(client),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 12,
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.store_outlined,
                                              size: 16,
                                              color: context.primaryFg,
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    client.name.isNotEmpty
                                                        ? client.name
                                                        : 'Klien Tanpa Nama',
                                                    style: TextStyle(
                                                      fontFamily: 'Poppins',
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: context.nameColor,
                                                    ),
                                                  ),
                                                  if (client.address.isNotEmpty)
                                                    Text(
                                                      client.address,
                                                      style: TextStyle(
                                                        fontFamily: 'Poppins',
                                                        fontSize: 11,
                                                        color: context.subColor,
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                        onSelected: (client) =>
                            setState(() => _selectedClient = client),
                      )
                    : Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: context.primaryFg),
                          borderRadius: BorderRadius.circular(12),
                          color: context.primaryBg,
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.store_outlined, color: context.primaryFg, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _selectedClient!.name.isNotEmpty
                                    ? _selectedClient!.name
                                    : 'Klien Tanpa Nama',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: context.primaryFg,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () =>
                                  setState(() => _selectedClient = null),
                              child: Icon(Icons.close, size: 18, color: context.primaryFg),
                            ),
                          ],
                        ),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Cari katalog...',
                    hintStyle: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      color: context.isDark ? Colors.white38 : Colors.black38,
                    ),
                    prefixIcon: const Icon(Icons.search, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: context.cardBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: context.cardBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: context.primaryFg),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    isDense: true,
                  ),
                ),
              ),
              Divider(height: 1, color: context.cardBorder),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _catalogStream,
                  builder: (ctx, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final query = _searchController.text.trim().toLowerCase();
                    final allItems = (snap.data?.docs ?? [])
                        .map(
                          (d) => CatalogModel.fromMap(
                            d.id,
                            d.data() as Map<String, dynamic>,
                          ),
                        )
                        .where(
                          (c) =>
                              query.isEmpty ||
                              c.name.toLowerCase().contains(query) ||
                              c.category.toLowerCase().contains(query),
                        )
                        .toList();

                    if (allItems.isEmpty) {
                      return AppEmptyState(
                        icon: Icons.search_off_rounded,
                        message: 'Katalog tidak ditemukan',
                      );
                    }

                    return ListView.separated(
                      controller: sc,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemCount: allItems.length,
                      separatorBuilder: (_, __) =>
                          Divider(height: 1, color: context.cardBorder),
                      itemBuilder: (_, i) {
                        final catalog = allItems[i];
                        final isSelected = _selected.containsKey(catalog.id);
                        final selItem = _selected[catalog.id];

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: () => _toggle(catalog),
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
                                      color: isSelected ? context.primaryFg : context.cardBorder,
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
                                imagePath: catalog.imagePath,
                                size: 46,
                                borderRadius: 10,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      catalog.name,
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
                                      catalog.category,
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 11,
                                        color: context.subColor,
                                      ),
                                    ),
                                    Text(
                                      formatRupiah(catalog.price),
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: context.successFg,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (isSelected && selItem != null)
                                InlineQtyStepper(
                                  quantity: selItem.quantity,
                                  onDecrement: () => _changeQty(catalog.id, -1),
                                  onIncrement: () => _changeQty(catalog.id, 1),
                                ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
                decoration: BoxDecoration(
                  color: context.cardBg,
                  border: Border(top: BorderSide(color: context.cardBorder, width: 1)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Estimasi',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              color: context.subColor,
                            ),
                          ),
                          Text(
                            formatRupiah(totalEst),
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
                    _isSubmitting
                        ? const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : GradientButton(
                            label: 'Serahkan',
                            onPressed: () {
                              if (_selectedClient == null) {
                                _showValidationError('Silakan pilih klien terlebih dahulu.');
                                return;
                              }
                              if (_selected.isEmpty) {
                                _showValidationError('Silakan pilih minimal satu barang.');
                                return;
                              }
                              _serahkan();
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

class InlineQtyStepper extends StatelessWidget {
  final int quantity;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  const InlineQtyStepper({
    super.key,
    required this.quantity,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: context.headerBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: onDecrement,
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Icon(
                quantity <= 1 ? Icons.delete_outline : Icons.remove,
                size: 16,
                color: context.successFg,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              '$quantity',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: context.nameColor,
              ),
            ),
          ),
          InkWell(
            onTap: onIncrement,
            borderRadius: const BorderRadius.horizontal(
              right: Radius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Icon(Icons.add, size: 16, color: context.successFg),
            ),
          ),
        ],
      ),
    );
  }
}
