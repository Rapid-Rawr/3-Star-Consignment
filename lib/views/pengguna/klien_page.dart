import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../controllers/pengguna_controllers/klien_controller.dart';
import '../../models/pengguna_models/klien_model.dart';
import '../../widgets/search_filter_bar.dart';
import '../../widgets/app_dialog.dart';
import '../../utils/currency_format.dart';
import '../../utils/app_colors.dart';
import 'package:provider/provider.dart';
import '../../service/auth_provider.dart';
import '../../service/roles.dart';

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
    String? emailServerError;

    showAppDialog(
      context: context,
      title: 'Tambah Klien',
      contentBuilder: (dialogContext, setDialogState) => SingleChildScrollView(
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
                onChanged: (val) {
                  if (emailServerError != null) {
                    emailServerError = null;
                    formKey.currentState?.validate();
                  }
                },
                validator: (value) {
                  if (emailServerError != null) return emailServerError;
                  return _controller.validateEmail(value);
                },
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
        AppDialogAction(
          label: 'Batal',
          onPressed: () => Navigator.pop(context),
        ),
        AppDialogAction(
          label: 'Tambah',
          type: AppDialogActionType.gradient,
          onPressed: () async {
            emailServerError = null;
            if (formKey.currentState!.validate()) {
              final email = emailController.text.trim();

              final result = await _controller.createClient(
                name: nameController.text.trim(),
                phone: phoneController.text.trim(),
                email: email,
                address: addressController.text.trim(),
              );

              if (!context.mounted) return;

              if (result['success'] == true) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Klien berhasil ditambahkan'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                if (result['error'] == 'Email sudah terdaftar') {
                  emailServerError = result['error'];
                  formKey.currentState!.validate();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(result['error'] ?? 'Terjadi kesalahan'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            }
          },
        ),
      ],
    );
  }

  void _showEditClientDialog(ClientModel client) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: client.name);
    final phoneController = TextEditingController(text: client.phone);
    final emailController = TextEditingController(text: client.email);
    final addressController = TextEditingController(text: client.address);
    String? emailServerError;

    showAppDialog(
      context: context,
      title: 'Edit Klien',
      contentBuilder: (dialogContext, setDialogState) => SingleChildScrollView(
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
                onChanged: (val) {
                  if (emailServerError != null) {
                    emailServerError = null;
                    formKey.currentState?.validate();
                  }
                },
                validator: (value) {
                  if (emailServerError != null) return emailServerError;
                  return _controller.validateEmail(value);
                },
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
        AppDialogAction(
          label: 'Batal',
          onPressed: () => Navigator.pop(context),
        ),
        AppDialogAction(
          label: 'Simpan',
          type: AppDialogActionType.gradient,
          onPressed: () async {
            emailServerError = null;
            if (formKey.currentState!.validate()) {
              final email = emailController.text.trim();

              final result = await _controller.updateClient(
                id: client.id,
                name: nameController.text.trim(),
                phone: phoneController.text.trim(),
                email: email,
                address: addressController.text.trim(),
              );

              if (!context.mounted) return;

              if (result['success'] == true) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Klien berhasil diupdate'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                if (result['error'] == 'Email sudah terdaftar') {
                  emailServerError = result['error'];
                  formKey.currentState!.validate();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(result['error'] ?? 'Terjadi kesalahan'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            }
          },
        ),
      ],
    );
  }

  void _showDeleteClientDialog(ClientModel client) {
    if (client.borrowedItems.isNotEmpty) {
      showAppDialog(
        context: context,
        titleIcon: const Icon(Icons.block_rounded),
        title: 'Ditolak',
        content: '${client.name} masih memiliki hutang.',
        actions: [
          AppDialogAction(
            label: 'Mengerti',
            onPressed: () => Navigator.pop(context),
          ),
        ],
      );
      return;
    }

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
            await _controller.deleteClient(client.id);
          },
        ),
      ],
    );
  }

  void showNoAccess(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Karyawan tidak memiliki akses')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final role = context.watch<AuthProvider>().role;
    final isKaryawan = role == Roles.karyawan;

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
                            color: context.emptyIcon,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Belum Ada Klien',
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

                  // Cleanup docs marked for deletion when online
                  _controller.cleanupPendingDeletes(snapshot.data!.docs);

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
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: context.emptyIcon,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Klien Tidak Ditemukan',
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
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                    itemCount: filteredWithMeta.length,
                    itemBuilder: (context, index) {
                      final client = filteredWithMeta[index].client;
                      final isPending = filteredWithMeta[index].isPending;
                      final isPendingDelete = client.pendingDelete;

                      final hasDebt = client.computedDebt > 0;
                      final debtBg = context.debtBg(hasDebt);
                      final debtTextColor = context.debtTextColor(hasDebt);

                      return Opacity(
                        opacity: isPendingDelete ? 0.5 : 1.0,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: isPendingDelete ? context.pendingDeleteBg : context.cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isPendingDelete ? context.pendingDeleteFg.withValues(alpha: 0.4) : context.cardBorder,
                              width: 1,
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
                                              color: context.nameColor,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (isPendingDelete) ...[
                                          const SizedBox(width: 4),
                                          Tooltip(
                                            message: 'Menunggu hapus...',
                                            child: Icon(
                                              Icons.delete_forever_rounded,
                                              size: 14,
                                              color: context.pendingDeleteFg,
                                            ),
                                          ),
                                        ] else if (isPending) ...[
                                          const SizedBox(width: 4),
                                          Tooltip(
                                            message: 'Menunggu sinkronisasi...',
                                            child: Icon(
                                              Icons.access_time_rounded,
                                              size: 14,
                                              color: context.pendingColor,
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
                                          color: context.subColor,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          client.phone,
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 12,
                                            color: context.subColor,
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
                                              color: context.subColor,
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                client.email,
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
                                      ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.location_on_outlined,
                                          size: 13,
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
                                                ? formatRupiah(
                                                    client.computedDebt,
                                                  )
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
                                  if (isPendingDelete) ...[
                                      InkWell(
                                        onTap: () async {
                                          await _controller.undoDeleteClient(client.id);
                                        },
                                        borderRadius: BorderRadius.circular(20),
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: context.pendingDeleteBg,
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Icon(
                                            Icons.undo_rounded,
                                            color: context.pendingDeleteFg,
                                            size: 18,
                                          ),
                                        ),
                                      ),
                                    ] else ...[
                                      InkWell(
                                        onTap: () {
                                          if (isKaryawan) {
                                            showNoAccess(context);
                                            return;
                                          }
                                          _showEditClientDialog(client);
                                        },
                                        borderRadius: BorderRadius.circular(20),
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: context.editBg,
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Icon(
                                            Icons.edit,
                                            color: context.editIcon,
                                            size: 18,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      InkWell(
                                        onTap: () {
                                          if (isKaryawan) {
                                            showNoAccess(context);
                                            return;
                                          }
                                          _showDeleteClientDialog(client);
                                        },
                                        borderRadius: BorderRadius.circular(20),
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: context.deleteBg,
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Icon(
                                            Icons.delete_outline,
                                            color: context.deleteIcon,
                                            size: 18,
                                          ),
                                        ),
                                      ),
                                    ],
                                ],
                              ),
                            ],
                          ),
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
            colors: context.fabGradient,
          ),
          shape: BoxShape.circle,
        ),
        child: FloatingActionButton(
          onPressed: () {
            if (isKaryawan) {
              showNoAccess(context);
              return;
            }
            _showAddClientDialog();
          },
          tooltip: 'Tambah Klien',
          backgroundColor: Colors.transparent,
          foregroundColor: context.isDark
              ? const Color(0xFF1D1B20)
              : Colors.white,
          elevation: 0,
          shape: const CircleBorder(),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
