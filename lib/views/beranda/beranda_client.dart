import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/currency_format.dart';

// ─────────────────────────────────────────────────────────────
// HomeClientPage — dipakai sebagai body di dalam TabBarView
// TIDAK pakai Scaffold/AppBar sendiri
// ─────────────────────────────────────────────────────────────
class HomeClientPage extends StatefulWidget {
  const HomeClientPage({super.key});

  @override
  State<HomeClientPage> createState() => _HomeClientPageState();
}

class _HomeClientPageState extends State<HomeClientPage> {
  static const int _previewLimit = 5;

  String? _clientId;
  bool _loadingClient = true;

  @override
  void initState() {
    super.initState();
    _resolveClientId();
  }

  Future<void> _resolveClientId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _loadingClient = false);
      return;
    }
    try {
      final snap = await FirebaseFirestore.instance
          .collection('clients')
          .where('email', isEqualTo: user.email)
          .limit(1)
          .get();

      debugPrint('[HomeClient] email=${user.email} docs=${snap.docs.length}');
      if (snap.docs.isNotEmpty) {
        debugPrint('[HomeClient] clientId=${snap.docs.first.id}');
      }

      setState(() {
        _clientId = snap.docs.isNotEmpty ? snap.docs.first.id : null;
        _loadingClient = false;
      });
    } catch (e) {
      debugPrint('[HomeClient] _resolveClientId error: $e');
      setState(() => _loadingClient = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    if (_loadingClient) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: _RequestListCard(
        clientId: _clientId,
        previewLimit: _previewLimit,
        isDark: isDark,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Card: Request List
// ─────────────────────────────────────────────────────────────
class _RequestListCard extends StatelessWidget {
  final String? clientId;
  final int previewLimit;
  final bool isDark;

  const _RequestListCard({
    required this.clientId,
    required this.previewLimit,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final Color cardBg =
        isDark ? const Color(0xFF2B2930) : Colors.white;
    final Color headerBg =
        isDark ? const Color(0xFF3A3540) : Colors.grey.shade100;
    final Color borderColor =
        isDark ? const Color(0xFF49454F) : Colors.grey.shade200;

    if (clientId == null) {
      return _shell(
        cardBg: cardBg,
        headerBg: headerBg,
        borderColor: borderColor,
        showFooter: false,
        onFooterTap: null,
        child: _emptyState(
          icon: Icons.info_outline,
          message: 'Akun belum terdaftar sebagai klien.\nHubungi admin untuk pendaftaran.',
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('consignment_requests')
          .where('clientId', isEqualTo: clientId)
          .orderBy('createdAt', descending: true)
          .limit(previewLimit)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint('[HomeClient] stream error: ${snapshot.error}');
        }
        if (snapshot.hasData) {
          debugPrint('[HomeClient] docs: ${snapshot.data!.docs.length}');
        }

        Widget content;
        bool showFooter = false;

        if (snapshot.connectionState == ConnectionState.waiting) {
          content = const Padding(
            padding: EdgeInsets.symmetric(vertical: 36),
            child: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError) {
          content = _emptyState(
            icon: Icons.error_outline,
            message: 'Gagal memuat data:\n${snapshot.error}',
          );
        } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          content = _emptyState(
            icon: Icons.inventory_2_outlined,
            message: 'Belum ada pengajuan konsinyasi',
          );
        } else {
          showFooter = true;
          final docs = snapshot.data!.docs;
          content = ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: docs.length,
            separatorBuilder: (_, __) =>
                Divider(height: 1, color: borderColor),
            itemBuilder: (context, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              return _RequestItem(data: data, isDark: isDark);
            },
          );
        }

        return _shell(
          cardBg: cardBg,
          headerBg: headerBg,
          borderColor: borderColor,
          showFooter: showFooter,
          onFooterTap: () {
            // Navigator.push(context, MaterialPageRoute(
            //   builder: (_) => const RiwayatPengajuanPage()));
          },
          child: content,
        );
      },
    );
  }

  Widget _shell({
    required Color cardBg,
    required Color headerBg,
    required Color borderColor,
    required bool showFooter,
    required VoidCallback? onFooterTap,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black26
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: headerBg,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Text(
              'Request List',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
            ),
          ),

          // ── Content ──
          child,

          // ── Footer ──
          if (showFooter)
            InkWell(
              onTap: onFooterTap,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                alignment: Alignment.center,
                child: Text(
                  'Lebih Banyak ...',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    color: isDark ? Colors.white38 : Colors.black54,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _emptyState({required IconData icon, required String message}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 48,
                color: isDark ? Colors.white24 : Colors.black26),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: isDark ? Colors.white38 : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Row satu item pengajuan
// Membaca field yang BENAR-BENAR ada di Firestore:
//   clientName, status, createdAt, items[]
// TIDAK membaca requestId / totalPrice (tidak ada di Firestore)
// ─────────────────────────────────────────────────────────────
class _RequestItem extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isDark;

  const _RequestItem({required this.data, required this.isDark});

  // Semua nilai enum ConsignmentBatchStatus
  Color _statusColor(String s) {
    switch (s.toLowerCase()) {
      case 'received':
        return const Color(0xFF1565C0); // biru — sudah diterima
      case 'packed':
        return const Color(0xFF6A1B9A); // ungu — dikemas
      case 'processing':
        return const Color(0xFF0277BD); // biru muda — diproses
      case 'rejected':
        return const Color(0xFFC62828); // merah — ditolak
      case 'pending':
      default:
        return const Color(0xFFF57F17); // oranye — menunggu
    }
  }

  String _statusLabel(String s) {
    switch (s.toLowerCase()) {
      case 'received':
        return 'Diterima';
      case 'packed':
        return 'Dikemas';
      case 'processing':
        return 'Diproses';
      case 'rejected':
        return 'Ditolak';
      case 'pending':
      default:
        return 'Menunggu';
    }
  }

  @override
  Widget build(BuildContext context) {
    final String status = (data['status'] as String?) ?? 'pending';
    final String clientName = (data['clientName'] as String?) ?? '-';
    final Timestamp? createdAt = data['createdAt'] as Timestamp?;

    // Hitung total item & total harga langsung dari array items[]
    final List rawItems = (data['items'] as List?) ?? [];
    int totalQty = 0;
    double totalPrice = 0;
    for (final e in rawItems) {
      if (e is Map) {
        final qty = (e['quantity'] as num?)?.toInt() ?? 0;
        final price = (e['catalogPrice'] as num?)?.toDouble() ?? 0.0;
        totalQty += qty;
        totalPrice += qty * price;
      }
    }

    final Color nameColor =
        isDark ? Colors.white : const Color(0xFF1D1B20);
    final Color subColor =
        isDark ? Colors.white54 : const Color(0xFF757575);
    final Color sColor = _statusColor(status);

    String dateLabel = '';
    if (createdAt != null) {
      final dt = createdAt.toDate();
      dateLabel =
          '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Ikon kiri ──
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1A3A2A)
                  : const Color(0xFFE6F4EA),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.assignment_outlined,
              size: 20,
              color: isDark
                  ? const Color(0xFF80CBC4)
                  : const Color(0xFF2E7D32),
            ),
          ),
          const SizedBox(width: 12),

          // ── Info tengah ──
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  clientName,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: nameColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '$totalQty item  •  ${formatRupiah(totalPrice)}',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    color: subColor,
                  ),
                ),
                if (dateLabel.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    dateLabel,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      color: subColor,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ── Badge status kanan ──
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: sColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _statusLabel(status),
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: sColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
