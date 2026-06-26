import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../controllers/barang_controllers/katalog_controller.dart';
import '../../controllers/barang_controllers/konsinyasi_controller.dart';
import '../../models/barang_models/katalog_model.dart';
import '../../widgets/search_filter_bar.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/catalog_image.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/quantity_stepper.dart';
import '../../utils/currency_format.dart';
import '../../utils/app_colors.dart';

class _SelectedItem {
  final CatalogModel catalog;
  int quantity = 1;
  _SelectedItem({required this.catalog});
}

class ConsignmentRequestPage extends StatefulWidget {
  const ConsignmentRequestPage({super.key});

  @override
  State<ConsignmentRequestPage> createState() => _ConsignmentRequestPageState();
}

class _ConsignmentRequestPageState extends State<ConsignmentRequestPage> {
  late CatalogController _catalogController;
  late ConsignmentRequestController _requestController;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final Map<String, _SelectedItem> _selected = {};

  late Stream<QuerySnapshot> _catalogStream;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final firestore = FirebaseFirestore.instance;
    _catalogController = CatalogController(firestore: firestore);
    _requestController = ConsignmentRequestController(firestore: firestore);
    _catalogStream = _catalogController.getCatalogStream();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _toggleItem(CatalogModel item) {
    setState(() {
      if (_selected.containsKey(item.id)) {
        _selected.remove(item.id);
      } else {
        _selected[item.id] = _SelectedItem(catalog: item);
      }
    });
  }

  void _changeQuantity(String id, int delta) {
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

  void _setQuantity(String id, int qty) {
    setState(() {
      if (!_selected.containsKey(id)) return;
      if (qty <= 0) {
        _selected.remove(id);
      } else {
        _selected[id]!.quantity = qty;
      }
    });
  }

  Future<void> _submitRequest() async {
    if (_selected.isEmpty || _isSubmitting) return;

    final user = FirebaseAuth.instance.currentUser;
    final userEmail = user?.email ?? '';

    // Lookup data klien dari collection clients berdasarkan email
    String clientId = '';
    String clientName = user?.displayName ?? user?.email?.split('@').first ?? 'Unknown';
    String clientAddress = '';

    if (userEmail.isNotEmpty) {
      try {
        final clientSnap = await FirebaseFirestore.instance
            .collection('clients')
            .where('email', isEqualTo: userEmail)
            .limit(1)
            .get();
        if (clientSnap.docs.isNotEmpty) {
          final doc = clientSnap.docs.first;
          clientId = doc.id;
          clientName = (doc.data()['name'] as String?)?.isNotEmpty == true
              ? doc.data()['name'] as String
              : clientName;
          clientAddress = (doc.data()['address'] as String?) ?? '';
          // Update photoUrl di clients doc agar selalu fresh
          final freshPhotoUrl = user?.photoURL;
          if (freshPhotoUrl != null) {
            doc.reference.update({'photoUrl': freshPhotoUrl}).catchError((_) {});
          }
        }
      } catch (_) {}
    }

    setState(() => _isSubmitting = true);

    final entries = _selected.values.toList();
    final result = await _requestController.createRequest(
      catalogItems: entries.map((e) => e.catalog).toList(),
      quantities: entries.map((e) => e.quantity).toList(),
      clientId: clientId,
      clientName: clientName,
      clientAddress: clientAddress,
      clientEmail: userEmail,
    );

    final allSuccess = result['success'] == true;

    setState(() {
      _isSubmitting = false;
      if (allSuccess) _selected.clear();
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            allSuccess
                ? 'Pengajuan konsinyasi berhasil dikirim'
                : (result['error']?.toString().toLowerCase().contains('unavailable') == true
                    ? 'Tidak ada koneksi internet, tidak bisa mengirim pengajuan'
                    : 'Gagal mengirim pengajuan: ${result['error']}'),
          ),
          backgroundColor: allSuccess ? Colors.green : Colors.red,
        ),
      );
      if (allSuccess && mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasSelection = _selected.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Pengajuan Konsinyasi',
          style: TextStyle(fontFamily: 'Poppins'),
        ),
      ),
      body: GestureDetector(
        onTap: _searchFocusNode.unfocus,
        child: StreamBuilder<QuerySnapshot>(
          stream: _catalogStream,
          builder: (context, snapshot) {
            List<String> categories = [];
            if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
              final all = snapshot.data!.docs
                  .map(
                    (d) => CatalogModel.fromMap(
                      d.id,
                      d.data() as Map<String, dynamic>,
                    ),
                  )
                  .toList();
              categories = _catalogController.uniqueCategories(all);
            }

            return Column(
              children: [
                SearchFilterBar<String>(
                  searchController: _searchController,
                  searchFocusNode: _searchFocusNode,
                  hintText: 'Cari nama atau kategori...',
                  onSearchChanged: (value) =>
                      setState(() => _catalogController.setSearchQuery(value)),
                  filters: [
                    const FilterChipOption<String>(label: 'Semua', value: null),
                    ...categories.map(
                      (cat) => FilterChipOption<String>(label: cat, value: cat),
                    ),
                  ],
                  selectedFilter: _catalogController.selectedCategory,
                  onFilterSelected: (cat) =>
                      setState(() => _catalogController.setCategory(cat)),
                ),
                Expanded(
                  child: Builder(
                    builder: (context) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                size: 64,
                                color: Colors.red,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Error: ${snapshot.error}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.red,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.inventory_2_outlined,
                                size: 64,
                                color: context.emptyIcon,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Belum Ada Barang',
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

                      final allItems = snapshot.data!.docs
                          .map(
                            (d) => CatalogModel.fromMap(
                              d.id,
                              d.data() as Map<String, dynamic>,
                            ),
                          )
                          .toList();
                      final filtered = _catalogController.filteredCatalog(
                        allItems,
                      );

                      filtered.sort((a, b) {
                        final aSelected = _selected.containsKey(a.id);
                        final bSelected = _selected.containsKey(b.id);
                        if (aSelected && !bSelected) return -1;
                        if (!aSelected && bSelected) return 1;
                        return a.name.compareTo(b.name);
                      });

                      if (filtered.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 64,
                                color: context.emptyIcon,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Barang Tidak Ditemukan',
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
                        padding: EdgeInsets.fromLTRB(
                          16,
                          0,
                          16,
                          hasSelection ? 220 : 24,
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final item = filtered[index];
                          final isSelected = _selected.containsKey(item.id);

                          return _CatalogItemCard(
                            item: item,
                            isSelected: isSelected,
                            onAdd: () => _toggleItem(item),
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
      ),
      bottomSheet: _SelectionBottomSheet(
        selected: _selected.values.toList(),
        isSubmitting: _isSubmitting,
        isVisible: hasSelection,
        onChangeQty: _changeQuantity,
        onSetQty: _setQuantity,
        onSubmit: _submitRequest,
      ),
    );
  }
}

class _CatalogItemCard extends StatelessWidget {
  final CatalogModel item;
  final bool isSelected;
  final VoidCallback onAdd;

  const _CatalogItemCard({
    required this.item,
    required this.isSelected,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? context.successFg : context.cardBorder,
          width: isSelected ? 1.8 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: context.cardShadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CatalogImage(imagePath: item.imagePath, size: 72, borderRadius: 10),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: context.nameColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.sell_outlined, size: 13, color: context.subColor),
                      const SizedBox(width: 4),
                      Text(
                        formatRupiah(item.price),
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: context.successFg,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: context.headerBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.category_outlined,
                          size: 11,
                          color: context.unselectedColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          item.category,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: context.unselectedColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: onAdd,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected ? context.successBg : context.successBg.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  isSelected ? Icons.check : Icons.add,
                  color: context.successFg,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}



class _SelectionBottomSheet extends StatefulWidget {
  final List<_SelectedItem> selected;
  final bool isSubmitting;
  final bool isVisible;
  final void Function(String id, int delta) onChangeQty;
  final void Function(String id, int exactQty) onSetQty;
  final VoidCallback onSubmit;

  const _SelectionBottomSheet({
    required this.selected,
    required this.isSubmitting,
    required this.isVisible,
    required this.onChangeQty,
    required this.onSetQty,
    required this.onSubmit,
  });

  @override
  State<_SelectionBottomSheet> createState() => _SelectionBottomSheetState();
}

class _SelectionBottomSheetState extends State<_SelectionBottomSheet> {
  final DraggableScrollableController _dragController =
      DraggableScrollableController();

  @override
  void dispose() {
    _dragController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) return const SizedBox.shrink();

    final double totalPrice = widget.selected.fold(
      0.0,
      (sum, e) => sum + e.catalog.price * e.quantity,
    );
    final int totalItems = widget.selected.fold(
      0,
      (sum, e) => sum + e.quantity,
    );

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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: DraggableScrollableSheet(
              controller: _dragController,
              initialChildSize: 0.5,
              minChildSize: 0.08,
              maxChildSize: 0.5,
              snap: true,
              snapSizes: const [0.08, 0.5],
              expand: false,
              builder: (context, scrollController) {
                return CustomScrollView(
                  controller: scrollController,
                  slivers: [
                    SliverToBoxAdapter(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
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
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                            child: Row(
                              children: [
                                Text(
                                  'Barang Dipilih',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: context.nameColor,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: context.successBg,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '$totalItems item',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: context.successFg,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) {
                          if (i.isOdd) {
                            return Divider(height: 1, color: context.cardBorder);
                          }
                          final index = i ~/ 2;
                          final entry = widget.selected[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                CatalogImage(
                                  imagePath: entry.catalog.imagePath,
                                  size: 42,
                                  borderRadius: 8,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        entry.catalog.name,
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                          color: context.nameColor,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        formatRupiah(entry.catalog.price),
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 12,
                                          color: context.successFg,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                QuantityStepper(
                                  quantity: entry.quantity,
                                  onDecrement: () =>
                                      widget.onChangeQty(entry.catalog.id, -1),
                                  onIncrement: () =>
                                      widget.onChangeQty(entry.catalog.id, 1),
                                  onChanged: (val) =>
                                      widget.onSetQty(entry.catalog.id, val),
                                ),
                              ],
                            ),
                          );
                        },
                        childCount: widget.selected.isNotEmpty
                            ? (widget.selected.length * 2) - 1
                            : 0,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
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
                widget.isSubmitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : GradientButton(
                        label: 'Kirim Pengajuan',
                        onPressed: () => showAppDialog(
                          context: context,
                          titleIcon: const Icon(Icons.warning_amber_rounded),
                          title: 'Kirim Pengajuan',
                          content:
                              'Kirim pengajuan ${widget.selected.length} item dengan total estimasi ${formatRupiah(totalPrice)}?',
                          actions: [
                            AppDialogAction(
                              label: 'Batal',
                              onPressed: () => Navigator.pop(context),
                            ),
                            AppDialogAction(
                              label: 'Kirim',
                              type: AppDialogActionType.gradient,
                              onPressed: () {
                                Navigator.pop(context);
                                widget.onSubmit();
                              },
                            ),
                          ],
                        ),
                        borderRadius: 12,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
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
