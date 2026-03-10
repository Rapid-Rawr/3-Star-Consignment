import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../controllers/operator_controller.dart';
import '../models/operator_model.dart';
import '../widgets/search_filter_bar.dart';

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
    FilterChipOption(label: 'All', value: null),
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

  //============DIALOG TAMBAH OPERATOR============\\
  void _showAddOperatorDialog() {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    String selectedRole = 'Administrator';

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Tambah Operator'),
          content: SingleChildScrollView(
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
                    validator: _controller.validateEmail,
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
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final result = await _controller.createOperator(
                    name: nameController.text.trim(),
                    email: emailController.text.trim(),
                    role: selectedRole,
                  );
                  if (dialogContext.mounted) {
                    if (result['success'] == true) {
                      Navigator.pop(dialogContext);
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(
                          content: Text('Operator berhasil ditambahkan'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        SnackBar(
                          content: Text(result['error'] ?? 'Terjadi kesalahan'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              },
              child: const Text('Tambah'),
            ),
          ],
        ),
      ),
    );
  }
  //============DIALOG TAMBAH OPERATOR============\\

  //============DIALOG EDIT OPERATOR============\\
  void _showEditOperatorDialog(OperatorModel operator) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: operator.name);
    final emailController = TextEditingController(text: operator.email);
    String selectedRole = operator.role;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Edit Operator'),
          content: SingleChildScrollView(
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
                    validator: _controller.validateEmail,
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
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final result = await _controller.updateOperator(
                    id: operator.id,
                    name: nameController.text.trim(),
                    email: emailController.text.trim(),
                    role: selectedRole,
                  );
                  if (dialogContext.mounted) {
                    if (result['success'] == true) {
                      Navigator.pop(dialogContext);
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(
                          content: Text('Operator berhasil diupdate'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        SnackBar(
                          content: Text(result['error'] ?? 'Terjadi kesalahan'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }
  //============DIALOG EDIT OPERATOR============\\

  //============DIALOG HAPUS OPERATOR============\\
  void _showDeleteOperatorDialog(OperatorModel operator) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus Operator'),
        content: Text('Apakah Anda yakin ingin menghapus ${operator.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              final result = await _controller.deleteOperator(operator.id);
              if (dialogContext.mounted) {
                Navigator.pop(dialogContext);
                if (result['success'] == true) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                      content: Text('${operator.name} telah dihapus'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                      content: Text(result['error'] ?? 'Terjadi kesalahan'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
  //============DIALOG HAPUS OPERATOR============\\

  //============HALAMAN OPERATOR============\\
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

            // TABEL OPERATOR
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
                            color: emptyIcon,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No Operator Available',
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

                  final operators = snapshot.data!.docs
                      .map(
                        (doc) => OperatorModel.fromMap(
                          doc.id,
                          doc.data() as Map<String, dynamic>,
                        ),
                      )
                      .toList();

                  final filteredOperators = _controller.filteredOperators(
                    operators,
                  );

                  if (filteredOperators.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off, size: 64, color: emptyIcon),
                          const SizedBox(height: 16),
                          Text(
                            'No Operator Found',
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
                    itemCount: filteredOperators.length,
                    itemBuilder: (context, index) {
                      final operator = filteredOperators[index];
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
                      final roleBadgeBg = isAdmin
                          ? (isDark
                                ? const Color(0xFF4A2E76)
                                : const Color(0xFFEDE7F6))
                          : (isDark
                                ? const Color(0xFF1A3E3A)
                                : const Color(0xFFE0F2F1));
                      final roleBadgeText = isAdmin
                          ? (isDark
                                ? const Color(0xFFCE93D8)
                                : const Color(0xFF6A1B9A))
                          : (isDark
                                ? const Color(0xFF80CBC4)
                                : const Color(0xFF00695C));

                      final cardBg = isDark
                          ? const Color(0xFF2B2930)
                          : Colors.white;
                      final cardBorder = isDark
                          ? const Color(0xFF49454F)
                          : const Color(0xFFE0E0E0);
                      final nameColor = isDark
                          ? Colors.white
                          : const Color(0xFF1D1B20);
                      final emailColor = isDark
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
                              // Avatar
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
                              // Info
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
                                        color: nameColor,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 3),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.email_outlined,
                                          size: 13,
                                          color: emailColor,
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            operator.email,
                                            style: TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 12,
                                              color: emailColor,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    // Role badge
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
                              // Action buttons
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  InkWell(
                                    onTap: () =>
                                        _showEditOperatorDialog(operator),
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
                                        _showDeleteOperatorDialog(operator),
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
          onPressed: _showAddOperatorDialog,
          tooltip: 'Tambah Operator',
          backgroundColor: Colors.transparent,
          foregroundColor: isDark ? const Color(0xFF1D1B20) : Colors.white,
          elevation: 0,
          shape: const CircleBorder(),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  //============HALAMAN OPERATOR============\\
}
