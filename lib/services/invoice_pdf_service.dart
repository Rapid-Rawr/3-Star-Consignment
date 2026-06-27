import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/pembayaran_models/pembayaran_model.dart';
import '../models/barang_models/konsinyasi_model.dart';
import '../utils/store_info.dart';
import '../utils/currency_format.dart';

class InvoicePdfService {
  static Future<Uint8List> generatePaymentInvoicePdf(PaymentModel payment) async {
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          _buildHeader(InvoiceType.payment),
          pw.SizedBox(height: 16),
          pw.Divider(color: PdfColors.grey300),
          pw.SizedBox(height: 16),
          _buildClientInfo(payment.clientName, payment.clientAddress),
          pw.SizedBox(height: 12),
          _buildPaymentInfo(payment),
          pw.SizedBox(height: 16),
          pw.Divider(color: PdfColors.grey300),
          pw.SizedBox(height: 16),
          _buildItemsTablePayment(payment.items),
          pw.SizedBox(height: 16),
          _buildTotal(payment.totalAmount, InvoiceType.payment),
          pw.SizedBox(height: 24),
          pw.Divider(color: PdfColors.grey300),
          pw.SizedBox(height: 16),
          _buildFooter(),
        ],
      ),
    );

    return pdf.save();
  }

  static Future<Uint8List> generateConsignmentInvoicePdf(ConsignmentRequestModel batch) async {
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          _buildHeader(InvoiceType.consignment),
          pw.SizedBox(height: 16),
          pw.Divider(color: PdfColors.grey300),
          pw.SizedBox(height: 16),
          _buildClientInfo(batch.clientName, batch.clientAddress),
          pw.SizedBox(height: 12),
          _buildConsignmentInfo(batch),
          pw.SizedBox(height: 16),
          pw.Divider(color: PdfColors.grey300),
          pw.SizedBox(height: 16),
          _buildItemsTableConsignment(batch.items),
          pw.SizedBox(height: 16),
          _buildTotal(_calculateTotal(batch.items), InvoiceType.consignment),
          pw.SizedBox(height: 24),
          pw.Divider(color: PdfColors.grey300),
          pw.SizedBox(height: 16),
          _buildFooter(),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildHeader(InvoiceType type) {
    final typeLabel = type == InvoiceType.payment ? 'INVOICE PEMBAYARAN' : 'INVOICE KONSINYASI';
    final bgColor = type == InvoiceType.payment ? PdfColor.fromInt(0xFFE8F5E9) : PdfColor.fromInt(0xFFE3F2FD);
    final textColor = type == InvoiceType.payment ? PdfColor.fromInt(0xFF2E7D32) : PdfColor.fromInt(0xFF1565C0);

    return pw.Column(
      children: [
        pw.Text(
          StoreInfo.name,
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
          ),
          textAlign: pw.TextAlign.center,
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          StoreInfo.address,
          style: pw.TextStyle(
            fontSize: 11,
            color: PdfColors.grey600,
          ),
          textAlign: pw.TextAlign.center,
        ),
        if (StoreInfo.phone.isNotEmpty) ...[
          pw.SizedBox(height: 2),
          pw.Text(
            StoreInfo.phone,
            style: pw.TextStyle(
              fontSize: 11,
              color: PdfColors.grey600,
            ),
            textAlign: pw.TextAlign.center,
          ),
        ],
        pw.SizedBox(height: 16),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: pw.BoxDecoration(
            color: bgColor,
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Text(
            typeLabel,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: textColor,
            ),
            textAlign: pw.TextAlign.center,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildClientInfo(String clientName, String clientAddress) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Klien',
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey600,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Nama    : ${clientName.isNotEmpty ? clientName : '-'}',
            style: const pw.TextStyle(fontSize: 13),
          ),
          if (clientAddress.isNotEmpty) ...[
            pw.SizedBox(height: 2),
            pw.Text(
              'Alamat  : $clientAddress',
              style: const pw.TextStyle(fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }

  static pw.Widget _buildPaymentInfo(PaymentModel payment) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'No Invoice: INV-PAY-${payment.id.substring(0, 8).toUpperCase()}',
          style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          'Tanggal: ${formatDateLong(payment.paidAt)}',
          style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'Metode Pembayaran: ${payment.paymentMethod == 'cash' ? 'Cash' : payment.paymentMethod}',
          style: const pw.TextStyle(fontSize: 12),
        ),
        if (payment.confirmedBy != null && payment.confirmedBy!.isNotEmpty) ...[
          pw.SizedBox(height: 2),
          pw.Text(
            'Dikonfirmasi oleh: ${payment.confirmedBy}',
            style: const pw.TextStyle(fontSize: 12),
          ),
        ],
      ],
    );
  }

  static pw.Widget _buildConsignmentInfo(ConsignmentRequestModel batch) {
    final statusLabel = batch.status == ConsignmentBatchStatus.received
        ? 'Diterima'
        : batch.status == ConsignmentBatchStatus.rejected
            ? 'Ditolak'
            : 'Pending';

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'No Invoice: INV-KSN-${batch.id.substring(0, 8).toUpperCase()}',
          style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          'Tanggal: ${formatDateLong(batch.receivedAt ?? batch.createdAt)}',
          style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'Status: $statusLabel',
          style: const pw.TextStyle(fontSize: 12),
        ),
        if (batch.packedBy != null) ...[
          pw.SizedBox(height: 2),
          pw.Text(
            'Dikemas oleh: ${batch.packedBy}',
            style: const pw.TextStyle(fontSize: 12),
          ),
        ],
        if (batch.receivedBy != null) ...[
          pw.SizedBox(height: 2),
          pw.Text(
            batch.status == ConsignmentBatchStatus.rejected
                ? 'Ditolak oleh: ${batch.receivedBy}'
                : 'Diserahkan oleh: ${batch.receivedBy}',
            style: const pw.TextStyle(fontSize: 12),
          ),
        ],
      ],
    );
  }

  static pw.Widget _buildItemsTablePayment(List<PaidItem> items) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'DAFTAR BARANG',
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          columnWidths: {
            0: const pw.FlexColumnWidth(3),
            1: const pw.FlexColumnWidth(2),
            2: const pw.FlexColumnWidth(1),
            3: const pw.FlexColumnWidth(2),
            4: const pw.FlexColumnWidth(2),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                _buildTableCell('Nama Barang', isHeader: true),
                _buildTableCell('Kategori', isHeader: true),
                _buildTableCell('Qty', isHeader: true, align: pw.Alignment.center),
                _buildTableCell('Harga', isHeader: true, align: pw.Alignment.centerRight),
                _buildTableCell('Total', isHeader: true, align: pw.Alignment.centerRight),
              ],
            ),
            ...items.map((item) => pw.TableRow(
              children: [
                _buildTableCell(item.catalogName),
                _buildTableCell(item.catalogCategory),
                _buildTableCell('${item.quantity}', align: pw.Alignment.center),
                _buildTableCell(formatRupiah(item.catalogPrice), align: pw.Alignment.centerRight),
                _buildTableCell(formatRupiah(item.catalogPrice * item.quantity), align: pw.Alignment.centerRight),
              ],
            )),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildItemsTableConsignment(List<ConsignmentItemEntry> items) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'DAFTAR BARANG',
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          columnWidths: {
            0: const pw.FlexColumnWidth(3),
            1: const pw.FlexColumnWidth(2),
            2: const pw.FlexColumnWidth(1),
            3: const pw.FlexColumnWidth(2),
            4: const pw.FlexColumnWidth(2),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                _buildTableCell('Nama Barang', isHeader: true),
                _buildTableCell('Kategori', isHeader: true),
                _buildTableCell('Qty', isHeader: true, align: pw.Alignment.center),
                _buildTableCell('Harga', isHeader: true, align: pw.Alignment.centerRight),
                _buildTableCell('Total', isHeader: true, align: pw.Alignment.centerRight),
              ],
            ),
            ...items.map((item) {
              final qty = item.approvedQty ?? item.quantity;
              final effectiveQty = item.itemStatus == ConsignmentItemStatus.rejected ? 0 : qty;
              return pw.TableRow(
                children: [
                  _buildTableCell(item.catalogName),
                  _buildTableCell(item.catalogCategory),
                  _buildTableCell('$effectiveQty', align: pw.Alignment.center),
                  _buildTableCell(formatRupiah(item.catalogPrice), align: pw.Alignment.centerRight),
                  _buildTableCell(formatRupiah(item.catalogPrice * effectiveQty), align: pw.Alignment.centerRight),
                ],
              );
            }),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildTableCell(String text, {bool isHeader = false, pw.Alignment? align}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: isHeader ? pw.FontWeight.bold : null,
        ),
        textAlign: align == pw.Alignment.center
            ? pw.TextAlign.center
            : align == pw.Alignment.centerRight
                ? pw.TextAlign.right
                : pw.TextAlign.left,
      ),
    );
  }

  static pw.Widget _buildTotal(double amount, InvoiceType type) {
    final bgColor = type == InvoiceType.payment ? PdfColor.fromInt(0xFFE8F5E9) : PdfColor.fromInt(0xFFE3F2FD);
    final textColor = type == InvoiceType.payment ? PdfColor.fromInt(0xFF2E7D32) : PdfColor.fromInt(0xFF1565C0);

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: bgColor,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        children: [
          pw.Text(
            'TOTAL',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.Spacer(),
          pw.Text(
            formatRupiah(amount),
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter() {
    return pw.Column(
      children: [
        pw.Text(
          'Terima kasih atas kepercayaan Anda',
          style: pw.TextStyle(
            fontSize: 11,
            color: PdfColors.grey600,
          ),
          textAlign: pw.TextAlign.center,
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'Dibuat: ${formatDateTimeLong(DateTime.now())}',
          style: pw.TextStyle(
            fontSize: 10,
            color: PdfColors.grey400,
          ),
          textAlign: pw.TextAlign.center,
        ),
      ],
    );
  }

  static double _calculateTotal(List<ConsignmentItemEntry> items) {
    return items.fold(0.0, (sum, item) {
      final qty = item.approvedQty ?? item.quantity;
      if (item.itemStatus == ConsignmentItemStatus.rejected) return sum;
      return sum + (item.catalogPrice * qty);
    });
  }

  static Future<String?> downloadPdf(Uint8List pdfBytes, String fileName) async {
    // On Windows/macOS/Linux, save to file and return path
    if (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux) {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(pdfBytes);
      return filePath;
    }
    // On mobile, use share sheet
    await Printing.sharePdf(bytes: pdfBytes, filename: fileName);
    return null;
  }

  static Future<String?> savePdfToDevice(Uint8List pdfBytes, String fileName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(pdfBytes);
      return file.path;
    } catch (e) {
      return null;
    }
  }
}

enum InvoiceType { payment, consignment }

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