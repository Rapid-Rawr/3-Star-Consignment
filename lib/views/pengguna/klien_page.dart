import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../controllers/pengguna_controllers/klien_controller.dart';
import '../../models/pengguna_models/klien_model.dart';
import '../../widgets/search_filter_bar.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/gradient_button.dart';
import '../../utils/currency_format.dart';

class ClientPage extends StatefulWidget {
  const ClientPage({super.key});

  @override
  State<ClientPage> createState() => _ClientPageState();
}

class _ClientPageState extends State<ClientPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  late ClientController _controller;
  String _searchQuery = '';

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

  void _showAddClientDialog() {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    final addressController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Tambah Klien'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Klien',
                    border: OutlineInputBorder(),
                    hintText: 'Masukkan nama lengkap',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: _controller.validateName,
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Nomor Telepon',
                    border: OutlineInputBorder(),
                    hintText: '08xxxxxxxxxx',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: _controller.validatePhone,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                    hintText: 'contoh@email.com',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: _controller.validateEmail,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: addressController,
                  decoration: const InputDecoration(
                    labelText: 'Alamat',
                    border: OutlineInputBorder(),
                    hintText: 'Masukkan alamat lengkap',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                  maxLines: 2,
                  validator: _controller.validateAddress,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(dialogContext).colorScheme.onSurface,
              splashFactory: NoSplash.splashFactory,
              overlayColor: Colors.transparent,
            ),
            child: const Text('Batal'),
          ),
          GradientButton(
            label: 'Tambah',
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                Navigator.pop(dialogContext);
                final result = await _controller.createClient(
                  name: nameController.text.trim(),
                  phone: phoneController.text.trim(),
                  email: emailController.text.trim(),
                  address: addressController.text.trim(),
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        result['success'] == true
                            ? 'Klien berhasil ditambahkan'
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
      ),
    );
  }

  void _showEditClientDialog(ClientModel client) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: client.name);
    final phoneController = TextEditingController(text: client.phone);
    final emailController = TextEditingController(text: client.email);
    final addressController = TextEditingController(text: client.address);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Klien'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Klien',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: _controller.validateName,
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Nomor Telepon',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: _controller.validatePhone,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: _controller.validateEmail,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: addressController,
                  decoration: const InputDecoration(
                    labelText: 'Alamat',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                  maxLines: 2,
                  validator: _controller.validateAddress,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(dialogContext).colorScheme.onSurface,
              splashFactory: NoSplash.splashFactory,
              overlayColor: Colors.transparent,
            ),
            child: const Text('Batal'),
          ),
          GradientButton(
            label: 'Simpan',
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                Navigator.pop(dialogContext);
                final result = await _controller.updateClient(
                  id: client.id,
                  name: nameController.text.trim(),
                  phone: phoneController.text.trim(),
                  email: emailController.text.trim(),
                  address: addressController.text.trim(),
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        result['success'] == true
                            ? 'Klien berhasil diupdate'
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
      ),
    );
  }

  void _showDeleteClientDialog(ClientModel client) {
    showAppDialog(
      context: context,
      titleIcon: const Icon(Icons.warning_amber_rounded),
      title: 'Hapus Klien',
      content: 'Apakah Anda yakin ingin menghapus ${client.name}?',
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
            final result = await _controller.deleteClient(client.id);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    result['success'] == true
                        ? '${client.name} telah dihapus'
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
        title: const Text('Klien', style: TextStyle(fontFamily: 'Poppins')),
      ),
      body: GestureDetector(
        onTap: _searchFocusNode.unfocus,
        child: Column(
          children: [
            SearchFilterBar<String>(
              searchController: _searchController,
              searchFocusNode: _searchFocusNode,
              hintText: 'Cari nama, telepon, atau alamat...',
              onSearchChanged: (value) =>
                  setState(() => _searchQuery = value.trim().toLowerCase()),
              filters: const [],
              selectedFilter: null,
              onFilterSelected: (_) {},
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _controller.getClientsStream(),
                builder: (context, snapshot) {
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
                            Icons.people_outline,
                            size: 64,
                            color: emptyIcon,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Belum Ada Klien',
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

                  final clients = snapshot.data!.docs
                      .map(
                        (doc) => (
                          client: ClientModel.fromMap(
                            doc.id,
                            doc.data() as Map<String, dynamic>,
                          ),
                          isPending: doc.metadata.hasPendingWrites,
                        ),
                      )
                      .toList();

                  final allClients = clients.map((e) => e.client).toList();
                  final filtered = _searchQuery.isEmpty
                      ? allClients
                      : allClients
                            .where(
                              (c) =>
                                  c.name.toLowerCase().contains(_searchQuery) ||
                                  c.phone.toLowerCase().contains(
                                    _searchQuery,
                                  ) ||
                                  c.address.toLowerCase().contains(
                                    _searchQuery,
                                  ),
                            )
                            .toList();
                  final filteredWithMeta = clients
                      .where((e) => filtered.any((c) => c.id == e.client.id))
                      .toList();

                  if (filteredWithMeta.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off, size: 64, color: emptyIcon),
                          const SizedBox(height: 16),
                          Text(
                            'Klien Tidak Ditemukan',
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
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                    itemCount: filteredWithMeta.length,
                    itemBuilder: (context, index) {
                      final client = filteredWithMeta[index].client;
                      final isPending = filteredWithMeta[index].isPending;

                      final hasDebt = client.computedDebt > 0;
                      final debtBg = hasDebt
                          ? (isDark
                                ? const Color(0xFF4D2B2B)
                                : const Color(0xFFFCE8E8))
                          : (isDark
                                ? const Color(0xFF1A3A2A)
                                : const Color(0xFFE8F5E9));
                      final debtTextColor = hasDebt
                          ? (isDark ? const Color(0xFFFF8A8A) : Colors.red)
                          : (isDark
                                ? const Color(0xFF80CBC4)
                                : const Color(0xFF2E7D32));

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
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            client.name,
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
                                            message: 'Menunggu sinkronisasi...',
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
                                    const SizedBox(height: 3),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.phone_outlined,
                                          size: 13,
                                          color: subColor,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          client.phone,
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 12,
                                            color: subColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    if (client.email.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 2,
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.email_outlined,
                                              size: 13,
                                              color: subColor,
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                client.email,
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
                                      ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.location_on_outlined,
                                          size: 13,
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
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: debtBg,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            hasDebt
                                                ? Icons.account_balance_wallet
                                                : Icons.check_circle_outline,
                                            size: 11,
                                            color: debtTextColor,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            hasDebt
                                                ? formatRupiah(client.computedDebt)
                                                : 'Lunas',
                                            style: TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: debtTextColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  InkWell(
                                    onTap: () => _showEditClientDialog(client),
                                    borderRadius: BorderRadius.circular(20),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: editBg,
                                        borderRadius: BorderRadius.circular(20),
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
                                        _showDeleteClientDialog(client),
                                    borderRadius: BorderRadius.circular(20),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: deleteBg,
                                        borderRadius: BorderRadius.circular(20),
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
        ),
      ),
      floatingActionButton: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomLeft,
            end: Alignment.topRight,
            colors: fabGradient,
          ),
          shape: BoxShape.circle,
        ),
        child: FloatingActionButton(
          onPressed: _showAddClientDialog,
          tooltip: 'Tambah Klien',
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
