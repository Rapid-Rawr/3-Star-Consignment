import 'package:flutter/material.dart';
import '../models/pembayaran_models/pembayaran_model.dart';
import '../models/barang_models/konsinyasi_model.dart';
import '../utils/store_info.dart';
import '../utils/currency_format.dart';

enum InvoiceType { payment, consignment }

class InvoiceView extends StatelessWidget {
  final InvoiceType type;
  final String invoiceId;
  final DateTime? date;
  final String clientName;
  final String clientAddress;
  final List<InvoiceItem> items;
  final double totalAmount;
  final String? paymentMethod;
  final String? confirmedBy;
  final ConsignmentBatchStatus? consignmentStatus;
  final String? packedBy;
  final String? receivedBy;
  final DateTime? receivedAt;

  const InvoiceView({
    super.key,
    required this.type,
    required this.invoiceId,
    required this.date,
    required this.clientName,
    required this.clientAddress,
    required this.items,
    required this.totalAmount,
    this.paymentMethod,
    this.confirmedBy,
    this.consignmentStatus,
    this.packedBy,
    this.receivedBy,
    this.receivedAt,
  });

  factory InvoiceView.fromPayment(PaymentModel payment) {
    return InvoiceView(
      type: InvoiceType.payment,
      invoiceId: 'INV-PAY-${payment.id.substring(0, 8).toUpperCase()}',
      date: payment.paidAt,
      clientName: payment.clientName,
      clientAddress: payment.clientAddress,
      items: payment.items
          .map((i) => InvoiceItem(
                name: i.catalogName,
                category: i.catalogCategory,
                quantity: i.quantity,
                price: i.catalogPrice,
              ))
          .toList(),
      totalAmount: payment.totalAmount,
      paymentMethod: payment.paymentMethod,
      confirmedBy: payment.confirmedBy,
    );
  }

  factory InvoiceView.fromConsignment(ConsignmentRequestModel batch) {
    return InvoiceView(
      type: InvoiceType.consignment,
      invoiceId: 'INV-KSN-${batch.id.substring(0, 8).toUpperCase()}',
      date: batch.receivedAt ?? batch.createdAt,
      clientName: batch.clientName,
      clientAddress: batch.clientAddress,
      items: batch.items
          .map((i) {
            final qty = i.approvedQty ?? i.quantity;
            return InvoiceItem(
              name: i.catalogName,
              category: i.catalogCategory,
              quantity: i.itemStatus == ConsignmentItemStatus.rejected ? 0 : qty,
              price: i.catalogPrice,
            );
          })
          .toList(),
      totalAmount: batch.items.fold(0.0, (sum, i) {
        final qty = i.approvedQty ?? i.quantity;
        if (i.itemStatus == ConsignmentItemStatus.rejected) return sum;
        return sum + (i.catalogPrice * qty);
      }),
      consignmentStatus: batch.status,
      packedBy: batch.packedBy,
      receivedBy: batch.receivedBy,
      receivedAt: batch.receivedAt,
    );
  }

  String get _typeLabel {
    switch (type) {
      case InvoiceType.payment:
        return 'INVOICE PEMBAYARAN';
      case InvoiceType.consignment:
        return 'INVOICE KONSINYASI';
    }
  }

  String get _methodLabel {
    if (paymentMethod == null) return '';
    switch (paymentMethod!.toLowerCase()) {
      case 'cash':
        return 'Cash';
      case 'transfer':
        return 'Transfer';
      default:
        return paymentMethod!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Colors.black12),
          const SizedBox(height: 16),
          _buildClientInfo(),
          const SizedBox(height: 12),
          if (type == InvoiceType.payment) ...[
            _buildInfoRow('Metode Pembayaran', _methodLabel),
            if (confirmedBy != null) _buildInfoRow('Dikonfirmasi oleh', confirmedBy!),
          ],
          if (type == InvoiceType.consignment) ...[
            _buildInfoRow('Status', consignmentStatus != null
                ? (consignmentStatus == ConsignmentBatchStatus.received
                    ? 'Diterima'
                    : consignmentStatus == ConsignmentBatchStatus.rejected
                        ? 'Ditolak'
                        : 'Pending')
                : '-'),
            if (packedBy != null) _buildInfoRow('Dikemas oleh', packedBy!),
            if (receivedBy != null) _buildInfoRow('Diserahkan oleh', receivedBy!),
          ],
          const SizedBox(height: 16),
          const Divider(height: 1, color: Colors.black12),
          const SizedBox(height: 16),
          _buildItemsTable(),
          const SizedBox(height: 16),
          _buildTotal(),
          const SizedBox(height: 24),
          const Divider(height: 1, color: Colors.black12),
          const SizedBox(height: 16),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        if (StoreInfo.logoAssetPath != null) ...[
          Image.asset(
            StoreInfo.logoAssetPath!,
            width: 64,
            height: 64,
          ),
          const SizedBox(height: 8),
        ],
        Text(
          StoreInfo.name,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          StoreInfo.address,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 11,
            color: Colors.black54,
          ),
          textAlign: TextAlign.center,
        ),
        if (StoreInfo.phone.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            StoreInfo.phone,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              color: Colors.black54,
            ),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: type == InvoiceType.payment
                ? const Color(0xFFE8F5E9)
                : const Color(0xFFE3F2FD),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            _typeLabel,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: type == InvoiceType.payment
                  ? const Color(0xFF2E7D32)
                  : const Color(0xFF1565C0),
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'No: $invoiceId',
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Tanggal: ${formatDateLong(date)}',
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }

  Widget _buildClientInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Klien',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Nama    : ${clientName.isNotEmpty ? clientName : '-'}',
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: Colors.black,
            ),
          ),
          if (clientAddress.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              'Alamat  : $clientAddress',
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: Colors.black,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsTable() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'DAFTAR BARANG',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black26),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              _buildTableHeader(),
              ...items.asMap().entries.map((entry) {
                final idx = entry.key;
                final item = entry.value;
                return _buildTableRow(item, idx == items.length - 1);
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFFF5F5F5),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      child: const Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              'Nama Barang',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Kategori',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'Qty',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Harga',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Total',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableRow(InvoiceItem item, bool isLast) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(color: Colors.black12, width: 1),
              ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              item.name,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 10,
                color: Colors.black,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              item.category,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 10,
                color: Colors.black54,
              ),
            ),
          ),
          Expanded(
            child: Text(
              '${item.quantity}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 10,
                color: Colors.black,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              formatRupiah(item.price),
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 10,
                color: Colors.black54,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              formatRupiah(item.price * item.quantity),
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotal() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: type == InvoiceType.payment
            ? const Color(0xFFE8F5E9)
            : const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Text(
            'TOTAL',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          const Spacer(),
          Text(
            formatRupiah(totalAmount),
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: type == InvoiceType.payment
                  ? const Color(0xFF2E7D32)
                  : const Color(0xFF1565C0),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        const Text(
          'Terima kasih atas kepercayaan Anda',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 11,
            color: Colors.black54,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          'Dibuat: ${formatDateTimeLong(DateTime.now())}',
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 10,
            color: Colors.black38,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class InvoiceItem {
  final String name;
  final String category;
  final int quantity;
  final double price;

  const InvoiceItem({
    required this.name,
    required this.category,
    required this.quantity,
    required this.price,
  });
}

String formatDateLong(DateTime? date) {
  if (date == null) return '-';
  const months = [
    '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];
  return '${date.day} ${months[date.month]} ${date.year}';
}

String formatDateTimeLong(DateTime date) {
  final dateStr = formatDateLong(date);
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '$dateStr $hour:$minute';
}