import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../../controllers/barang_controllers/katalog_controller.dart';
import '../../models/barang_models/katalog_model.dart';
import '../../widgets/search_filter_bar.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/catalog_image.dart';
import '../../utils/currency_format.dart';

class CatalogPage extends StatefulWidget {
  const CatalogPage({super.key, this.isReadOnly = false});

  final bool isReadOnly;

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  late CatalogController _controller;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = CatalogController(firestore: FirebaseFirestore.instance);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  static const List<String> _categories = [
    'Alat',
    'Alat Tulis',
    'Seragam',
    'Kerajinan',
    'Aksesori',
    'Lainnya',
  ];

  Future<XFile?> _pickImage() async {
    final picker = ImagePicker();
    final XFile? file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 80,
    );
    return file;
  }

  void _showAddItemDialog() {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    String selectedCategory = _categories.first;
    XFile? pickedImage;
    String? nameServerError;

    showAppDialog(
      context: context,
      title: 'Tambah Barang',
      contentBuilder: (dialogContext, setDialogState) => SingleChildScrollView(
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () async {
                  final file = await _pickImage();
                  if (file != null) {
                    setDialogState(() => pickedImage = file);
                  }
                },
                child: _ImagePickerPreview(
                  pickedImage: pickedImage,
                  existingPath: null,
                  onRemove: () => setDialogState(() => pickedImage = null),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Barang',
                  border: OutlineInputBorder(),
                  hintText: 'Masukkan nama barang',
                  prefixIcon: Icon(Icons.inventory_2_outlined),
                ),
                onChanged: (val) {
                  if (nameServerError != null) {
                    nameServerError = null;
                    formKey.currentState?.validate();
                  }
                },
                validator: (value) {
                  if (nameServerError != null) return nameServerError;
                  return _controller.validateName(value);
                },
                textCapitalization: TextCapitalization.words,
                autovalidateMode: AutovalidateMode.onUserInteraction,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: priceController,
                decoration: const InputDecoration(
                  labelText: 'Harga (Rp)',
                  border: OutlineInputBorder(),
                  hintText: '0',
                  prefixIcon: Icon(Icons.sell_outlined),
                ),
                keyboardType: TextInputType.number,
                validator: _controller.validatePrice,
                autovalidateMode: AutovalidateMode.onUserInteraction,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Kategori',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                dropdownColor: Theme.of(dialogContext).brightness == Brightness.dark
                    ? const Color(0xFF2B2930)
                    : Colors.white,
                items: _categories
                    .map(
                      (cat) => DropdownMenuItem(value: cat, child: Text(cat)),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setDialogState(() => selectedCategory = value);
                  }
                },
                validator: _controller.validateCategory,
              ),
            ],
          ),
        ),
      ),
      actions: [
        AppDialogAction(
          label: 'Batal',
          onPressed: () => Navigator.pop(context),
        ),
        AppDialogAction(
          label: 'Tambah',
          type: AppDialogActionType.gradient,
          onPressed: () async {
            nameServerError = null;
            if (formKey.currentState!.validate()) {
              final nameExists = await _controller.checkNameExists(
                nameController.text.trim(),
              );
              if (nameExists) {
                nameServerError = 'Nama barang sudah terdaftar';
                formKey.currentState!.validate();
                return;
              }

              final price =
                  double.tryParse(
                    priceController.text
                        .trim()
                        .replaceAll(',', '')
                        .replaceAll('.', ''),
                  ) ??
                  0.0;

              if (!context.mounted) return;
              Navigator.pop(context);

              final result = await _controller.createItem(
                name: nameController.text.trim(),
                price: price,
                category: selectedCategory,
                imageFile: pickedImage,
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      result['success'] == true
                          ? 'Barang berhasil ditambahkan'
                          : (result['error'] ?? 'Terjadi kesalahan'),
                    ),
                    backgroundColor: result['success'] == true
                        ? Colors.green
                        : Colors.red,
                  ),
                );
              }
            }
          },
        ),
      ],
    );
  }

  void _showEditItemDialog(CatalogModel item) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: item.name);
    final priceController = TextEditingController(
      text: item.price == 0 ? '' : item.price.toStringAsFixed(0),
    );
    String selectedCategory = _categories.contains(item.category)
        ? item.category
        : _categories.first;
    XFile? pickedImage;
    bool removeImage = false;
    String? nameServerError;

    showAppDialog(
      context: context,
      title: 'Edit Barang',
      contentBuilder: (dialogContext, setDialogState) => SingleChildScrollView(
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () async {
                  final file = await _pickImage();
                  if (file != null) {
                    setDialogState(() {
                      pickedImage = file;
                      removeImage = false;
                    });
                  }
                },
                child: _ImagePickerPreview(
                  pickedImage: pickedImage,
                  existingPath: removeImage ? null : item.imagePath,
                  onRemove: () => setDialogState(() {
                    pickedImage = null;
                    removeImage = true;
                  }),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Barang',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.inventory_2_outlined),
                ),
                onChanged: (val) {
                  if (nameServerError != null) {
                    nameServerError = null;
                    formKey.currentState?.validate();
                  }
                },
                validator: (value) {
                  if (nameServerError != null) return nameServerError;
                  return _controller.validateName(value);
                },
                textCapitalization: TextCapitalization.words,
                autovalidateMode: AutovalidateMode.onUserInteraction,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: priceController,
                decoration: const InputDecoration(
                  labelText: 'Harga (Rp)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.sell_outlined),
                ),
                keyboardType: TextInputType.number,
                validator: _controller.validatePrice,
                autovalidateMode: AutovalidateMode.onUserInteraction,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Kategori',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                dropdownColor: Theme.of(dialogContext).brightness == Brightness.dark
                    ? const Color(0xFF2B2930)
                    : Colors.white,
                items: _categories
                    .map(
                      (cat) => DropdownMenuItem(value: cat, child: Text(cat)),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setDialogState(() => selectedCategory = value);
                  }
                },
                validator: _controller.validateCategory,
              ),
            ],
          ),
        ),
      ),
      actions: [
        AppDialogAction(
          label: 'Batal',
          onPressed: () => Navigator.pop(context),
        ),
        AppDialogAction(
          label: 'Simpan',
          type: AppDialogActionType.gradient,
          onPressed: () async {
            nameServerError = null;
            if (formKey.currentState!.validate()) {
              final nameExists = await _controller.checkNameExists(
                nameController.text.trim(),
                excludeId: item.id,
              );
              if (nameExists) {
                nameServerError = 'Nama barang sudah terdaftar';
                formKey.currentState!.validate();
                return;
              }

              final price =
                  double.tryParse(
                    priceController.text
                        .trim()
                        .replaceAll(',', '')
                        .replaceAll('.', ''),
                  ) ??
                  0.0;

              if (!context.mounted) return;
              Navigator.pop(context);

              final result = await _controller.updateItem(
                id: item.id,
                name: nameController.text.trim(),
                price: price,
                category: selectedCategory,
                newImageFile: pickedImage,
                oldImagePath: item.imagePath,
                removeImage: removeImage,
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      result['success'] == true
                          ? 'Barang berhasil diupdate'
                          : (result['error'] ?? 'Terjadi kesalahan'),
                    ),
                    backgroundColor: result['success'] == true
                        ? Colors.green
                        : Colors.red,
                  ),
                );
              }
            }
          },
        ),
      ],
    );
  }

  void _showDeleteItemDialog(CatalogModel item) {
    showAppDialog(
      context: context,
      titleIcon: const Icon(Icons.warning_amber_rounded),
      title: 'Hapus Barang',
      content: 'Apakah Anda yakin ingin menghapus ${item.name}?',
      actions: [
        AppDialogAction(
          label: 'Batal',
          onPressed: () => Navigator.pop(context),
        ),
        AppDialogAction(
          label: 'Hapus',
          type: AppDialogActionType.gradient,
          onPressed: () async {
            Navigator.pop(context);
            final result = await _controller.deleteItem(item.id);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    result['success'] == true
                        ? '${item.name} telah dihapus'
                        : (result['error'] ?? 'Terjadi kesalahan'),
                  ),
                  backgroundColor: result['success'] == true
                      ? Colors.green
                      : Colors.red,
                ),
              );
            }
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final Color editBg = isDark
        ? const Color(0xFF49454F)
        : const Color(0xFFE8E5EC);
    final Color editIcon = isDark ? Colors.white : const Color(0xFF1D1B20);
    final Color deleteBg = isDark
        ? const Color(0xFF4D2B2B)
        : const Color(0xFFFCE8E8);
    final Color deleteIcon = isDark ? const Color(0xFFFF8A8A) : Colors.red;
    final Color emptyIcon = isDark ? Colors.white24 : Colors.black26;
    final Color emptyText = isDark ? Colors.white38 : const Color(0xFF9E9E9E);

    final List<Color> fabGradient = isDark
        ? [const Color(0xFFA3A3A3), const Color(0xFFFFFFFF)]
        : [const Color(0xFF67636D), const Color(0xFF1D1B20)];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Manajemen Katalog',
          style: TextStyle(fontFamily: 'Poppins'),
        ),
      ),
      body: GestureDetector(
        onTap: _searchFocusNode.unfocus,
        child: StreamBuilder<QuerySnapshot>(
          stream: _controller.getCatalogStream(),
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
              categories = _controller.uniqueCategories(all);
            }

            return Column(
              children: [
                SearchFilterBar<String>(
                  searchController: _searchController,
                  searchFocusNode: _searchFocusNode,
                  hintText: 'Cari nama atau kategori...',
                  onSearchChanged: (value) =>
                      setState(() => _controller.setSearchQuery(value)),
                  filters: [
                    const FilterChipOption<String>(label: 'Semua', value: null),
                    ...categories.map(
                      (cat) => FilterChipOption<String>(label: cat, value: cat),
                    ),
                  ],
                  selectedFilter: _controller.selectedCategory,
                  onFilterSelected: (cat) =>
                      setState(() => _controller.setCategory(cat)),
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
                                color: emptyIcon,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Belum Ada Barang',
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

                      final items = snapshot.data!.docs
                          .map(
                            (doc) => (
                              item: CatalogModel.fromMap(
                                doc.id,
                                doc.data() as Map<String, dynamic>,
                              ),
                              isPending: doc.metadata.hasPendingWrites,
                            ),
                          )
                          .toList();

                      final allItems = items.map((e) => e.item).toList();
                      final filtered = _controller.filteredCatalog(allItems);
                      final filteredWithMeta = items
                          .where((e) => filtered.any((i) => i.id == e.item.id))
                          .toList();

                      if (filteredWithMeta.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 64,
                                color: emptyIcon,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Barang Tidak Ditemukan',
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
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                        itemCount: filteredWithMeta.length,
                        itemBuilder: (context, index) {
                          final item = filteredWithMeta[index].item;
                          final isPending = filteredWithMeta[index].isPending;

                          final cardBg = isDark
                              ? const Color(0xFF2B2930)
                              : Colors.white;
                          final cardBorder = isDark
                              ? const Color(0xFF49454F)
                              : const Color(0xFFE0E0E0);
                          final nameColor = isDark
                              ? Colors.white
                              : const Color(0xFF1D1B20);
                          final subColor = isDark
                              ? Colors.white54
                              : const Color(0xFF757575);
                          final categoryBg = isDark
                              ? const Color(0xFF3A3540)
                              : const Color(0xFFF3EFF4);
                          final categoryText = isDark
                              ? Colors.white70
                              : const Color(0xFF49454F);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
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
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  CatalogImage(
                                    imagePath: item.imagePath,
                                    size: 72,
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
                                                item.name,
                                                style: TextStyle(
                                                  fontFamily: 'Poppins',
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 15,
                                                  color: nameColor,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            if (isPending) ...[
                                              const SizedBox(width: 4),
                                              Tooltip(
                                                message:
                                                    'Menunggu sinkronisasi...',
                                                child: Icon(
                                                  Icons.access_time_rounded,
                                                  size: 14,
                                                  color: isDark
                                                      ? Colors.amber.shade300
                                                      : Colors.orange,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.sell_outlined,
                                              size: 13,
                                              color: subColor,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              formatRupiah(item.price),
                                              style: TextStyle(
                                                fontFamily: 'Poppins',
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: isDark
                                                    ? const Color(0xFF80CBC4)
                                                    : const Color(0xFF2E7D32),
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
                                            color: categoryBg,
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.category_outlined,
                                                size: 11,
                                                color: categoryText,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                item.category,
                                                style: TextStyle(
                                                  fontFamily: 'Poppins',
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w500,
                                                  color: categoryText,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (!widget.isReadOnly) const SizedBox(width: 8),
                                  if (!widget.isReadOnly) Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      InkWell(
                                        onTap: () => _showEditItemDialog(item),
                                        borderRadius: BorderRadius.circular(20),
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: editBg,
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.edit_outlined,
                                            color: editIcon,
                                            size: 18,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      InkWell(
                                        onTap: () =>
                                            _showDeleteItemDialog(item),
                                        borderRadius: BorderRadius.circular(20),
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: deleteBg,
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.delete_outline,
                                            color: deleteIcon,
                                            size: 18,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
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
      floatingActionButton: widget.isReadOnly ? null : DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomLeft,
            end: Alignment.topRight,
            colors: fabGradient,
          ),
          shape: BoxShape.circle,
        ),
        child: FloatingActionButton(
          onPressed: _showAddItemDialog,
          tooltip: 'Tambah Barang',
          backgroundColor: Colors.transparent,
          foregroundColor: isDark ? const Color(0xFF1D1B20) : Colors.white,
          elevation: 0,
          shape: const CircleBorder(),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}

class _ImagePickerPreview extends StatefulWidget {
  final XFile? pickedImage;
  final String? existingPath;
  final VoidCallback onRemove;

  const _ImagePickerPreview({
    required this.pickedImage,
    required this.existingPath,
    required this.onRemove,
  });

  @override
  State<_ImagePickerPreview> createState() => _ImagePickerPreviewState();
}

class _ImagePickerPreviewState extends State<_ImagePickerPreview> {
  Uint8List? _cachedBytes;
  XFile? _cachedFile;

  Future<Uint8List?> _getBytes() async {
    final file = widget.pickedImage;
    if (file == null) return null;
    if (_cachedFile == file && _cachedBytes != null) return _cachedBytes;
    _cachedBytes = await file.readAsBytes();
    _cachedFile = file;
    return _cachedBytes;
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bg = isDark ? const Color(0xFF3A3540) : const Color(0xFFF5F5F5);
    final Color iconColor = isDark ? Colors.white38 : const Color(0xFFB0B0B0);
    final Color borderColor = isDark
        ? const Color(0xFF49454F)
        : const Color(0xFFE0E0E0);

    Widget content;

    if (widget.pickedImage != null) {
      content = Stack(
        fit: StackFit.expand,
        children: [
          FutureBuilder<Uint8List?>(
            future: _getBytes(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Container(
                  color: bg,
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: iconColor,
                      ),
                    ),
                  ),
                );
              }
              final bytes = snapshot.data;
              if (bytes == null) {
                return Icon(
                  Icons.broken_image_outlined,
                  color: iconColor,
                  size: 36,
                );
              }
              return Image.memory(bytes, fit: BoxFit.cover);
            },
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: widget.onRemove,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      );
    } else if (widget.existingPath != null && widget.existingPath!.isNotEmpty) {
      content = Stack(
        fit: StackFit.expand,
        children: [
          CatalogImage(
            imagePath: widget.existingPath,
            size: 100,
            borderRadius: 0,
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: widget.onRemove,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      );
    } else {
      content = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_photo_alternate_outlined, color: iconColor, size: 32),
          const SizedBox(height: 6),
          Text(
            'Tap untuk pilih foto',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              color: iconColor,
            ),
          ),
        ],
      );
    }

    return Container(
      height: 100,
      width: double.infinity,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: content,
    );
  }
}



