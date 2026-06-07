import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../controllers/pengguna_controllers/operator_controller.dart';
import '../../models/pengguna_models/operator_model.dart';
import '../../widgets/search_filter_bar.dart';
import '../../widgets/app_dialog.dart';
import '../../utils/app_colors.dart';
import 'package:provider/provider.dart';
import '../../service/auth_provider.dart';
import '../../service/roles.dart';

class OperatorPage extends StatefulWidget {
  const OperatorPage({super.key});

  @override
  State<OperatorPage> createState() => _OperatorPageState();
}

class _OperatorPageState extends State<OperatorPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  late OperatorController _controller;

  static const List<FilterChipOption<String>> _roleFilters = [
    FilterChipOption(label: 'Semua', value: null),
    FilterChipOption(label: 'Administrator', value: 'Administrator'),
    FilterChipOption(label: 'Karyawan', value: 'Karyawan'),
  ];

  @override
  void initState() {
    super.initState();
    _controller = OperatorController(firestore: FirebaseFirestore.instance);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Widget _buildInitialsAvatar(Color bg, String initials) {
    return Container(
      width: 52,
      height: 52,
      color: bg,
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 16,
          fontFamily: 'Poppins',
        ),
      ),
    );
  }

  void _showAddOperatorDialog() {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    String selectedRole = 'Administrator';
    String? emailServerError;

    showAppDialog(
      context: context,
      title: 'Tambah Operator',
      contentBuilder: (dialogContext, setDialogState) => SingleChildScrollView(
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama',
                  border: OutlineInputBorder(),
                  hintText: 'Masukkan nama lengkap',
                ),
                validator: _controller.validateName,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  hintText: 'contoh@gmail.com',
                  prefixIcon: Icon(Icons.email),
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
              DropdownButtonFormField<String>(
                initialValue: selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Role',
                  border: OutlineInputBorder(),
                ),
                items: ['Administrator', 'Karyawan']
                    .map(
                      (role) =>
                          DropdownMenuItem(value: role, child: Text(role)),
                    )
                    .toList(),
                onChanged: (value) =>
                    setDialogState(() => selectedRole = value!),
                validator: _controller.validateRole,
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
              final result = await _controller.createOperator(
                name: nameController.text.trim(),
                email: email,
                role: selectedRole,
              );
              if (!context.mounted) return;

              if (result['success'] == true) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Operator berhasil ditambahkan'),
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

  void _showEditOperatorDialog(OperatorModel operator) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: operator.name);
    final emailController = TextEditingController(text: operator.email);
    String selectedRole = operator.role;
    String? emailServerError;

    showAppDialog(
      context: context,
      title: 'Edit Operator',
      contentBuilder: (dialogContext, setDialogState) => SingleChildScrollView(
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama',
                  border: OutlineInputBorder(),
                  hintText: 'Masukkan nama lengkap',
                ),
                validator: _controller.validateName,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  hintText: 'contoh@gmail.com',
                  prefixIcon: Icon(Icons.email),
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
              DropdownButtonFormField<String>(
                initialValue: selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Role',
                  border: OutlineInputBorder(),
                ),
                items: ['Administrator', 'Karyawan']
                    .map(
                      (role) =>
                          DropdownMenuItem(value: role, child: Text(role)),
                    )
                    .toList(),
                onChanged: (value) =>
                    setDialogState(() => selectedRole = value!),
                validator: _controller.validateRole,
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
              final result = await _controller.updateOperator(
                id: operator.id,
                name: nameController.text.trim(),
                email: email,
                role: selectedRole,
              );
              if (!context.mounted) return;

              if (result['success'] == true) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Operator berhasil diupdate'),
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

  void _showDeleteOperatorDialog(OperatorModel operator) {
    showAppDialog(
      context: context,
      titleIcon: const Icon(Icons.warning_amber_rounded),
      title: 'Hapus Operator',
      content: 'Apakah Anda yakin ingin menghapus ${operator.name}?',
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
            final result = await _controller.deleteOperator(operator.id);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    result['success'] == true
                        ? '${operator.name} telah dihapus'
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
        title: const Text('Operator', style: TextStyle(fontFamily: 'Poppins')),
      ),
      body: GestureDetector(
        onTap: _searchFocusNode.unfocus,
        child: Column(
          children: [
            SearchFilterBar<String>(
              searchController: _searchController,
              searchFocusNode: _searchFocusNode,
              hintText: 'Find by name, gmail, or role...',
              onSearchChanged: (value) =>
                  setState(() => _controller.setSearchQuery(value)),
              filters: _roleFilters,
              selectedFilter: _controller.selectedRoleFilter,
              onFilterSelected: (val) =>
                  setState(() => _controller.setRoleFilter(val)),
            ),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _controller.getOperatorsStream(),
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
                            'Belum Ada Operator',
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

                  final operators = snapshot.data!.docs
                      .map(
                        (doc) => (
                          operator: OperatorModel.fromMap(
                            doc.id,
                            doc.data() as Map<String, dynamic>,
                          ),
                          isPending: doc.metadata.hasPendingWrites,
                        ),
                      )
                      .toList();

                  final allOperators = operators
                      .map((e) => e.operator)
                      .toList();
                  final filteredOps = _controller.filteredOperators(
                    allOperators,
                  );
                  final filteredWithMeta = operators
                      .where(
                        (e) => filteredOps.any((o) => o.id == e.operator.id),
                      )
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
                            'Operator Tidak Ditemukan',
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
                      final operator = filteredWithMeta[index].operator;
                      final isPending = filteredWithMeta[index].isPending;
                      final avatarColors = [
                        const Color(0xFF6750A4),
                        const Color(0xFF0288D1),
                        const Color(0xFF00897B),
                        const Color(0xFFF4511E),
                        const Color(0xFF7B1FA2),
                        const Color(0xFFC62828),
                      ];
                      final avatarColor =
                          avatarColors[operator.name.isNotEmpty
                              ? operator.name.codeUnitAt(0) %
                                    avatarColors.length
                              : 0];

                      final initials = operator.name.trim().isNotEmpty
                          ? operator.name.trim().split(' ').length >= 2
                                ? '${operator.name.trim().split(' ')[0][0]}${operator.name.trim().split(' ')[1][0]}'
                                      .toUpperCase()
                                : operator.name.trim()[0].toUpperCase()
                          : '?';
                      final isAdmin = operator.role == 'Administrator';
                      final roleBadgeBg = context.roleBadgeBg(isAdmin);
                      final roleBadgeText = context.roleBadgeText(isAdmin);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: context.cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: context.cardBorder,
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
                              SizedBox(
                                width: 52,
                                height: 52,
                                child: ClipOval(
                                  child:
                                      (operator.photoUrl != null &&
                                          operator.photoUrl!.isNotEmpty)
                                      ? Image.network(
                                          operator.photoUrl!,
                                          width: 52,
                                          height: 52,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              _buildInitialsAvatar(
                                                avatarColor,
                                                initials,
                                              ),
                                        )
                                      : _buildInitialsAvatar(
                                          avatarColor,
                                          initials,
                                        ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      operator.name,
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                        color: context.nameColor,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (isPending) ...[
                                      const SizedBox(height: 1),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.access_time_rounded,
                                            size: 12,
                                            color: context.pendingColor,
                                          ),
                                          const SizedBox(width: 3),
                                          Text(
                                            'Menunggu sinkronisasi...',
                                            style: TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 10,
                                              color: context.pendingColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                    const SizedBox(height: 3),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.email_outlined,
                                          size: 13,
                                          color: context.subColor,
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            operator.email,
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
                                        color: roleBadgeBg,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        operator.role,
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: roleBadgeText,
                                        ),
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
                                    onTap: () {
                                      if (isKaryawan) {
                                        showNoAccess(context);
                                        return;
                                      }
                                      _showEditOperatorDialog(operator);
                                    },
                                    borderRadius: BorderRadius.circular(20),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: context.editBg,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Icon(
                                        Icons.edit_outlined,
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
                                      _showDeleteOperatorDialog(operator);
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
            _showAddOperatorDialog();
          },
          tooltip: 'Tambah Operator',
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
