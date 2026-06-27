import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/pembayaran_models/pembayaran_model.dart';
import '../models/barang_models/konsinyasi_model.dart';
import '../services/invoice_pdf_service.dart';
import '../utils/app_colors.dart';
import 'invoice_view.dart';

class InvoiceDialog extends StatefulWidget {
  final PaymentModel? payment;
  final ConsignmentRequestModel? batch;

  const InvoiceDialog({super.key, this.payment, this.batch});

  @override
  State<InvoiceDialog> createState() => _InvoiceDialogState();
}

class _InvoiceDialogState extends State<InvoiceDialog> {
  final GlobalKey _repaintBoundaryKey = GlobalKey();
  bool _isDownloading = false;
  String? _downloadMessage;

  InvoiceView get _invoiceView {
    if (widget.payment != null) {
      return InvoiceView.fromPayment(widget.payment!);
    }
    return InvoiceView.fromConsignment(widget.batch!);
  }

  String get _invoiceId {
    if (widget.payment != null) {
      return 'INV-PAY-${widget.payment!.id.substring(0, 8).toUpperCase()}';
    }
    return 'INV-KSN-${widget.batch!.id.substring(0, 8).toUpperCase()}';
  }

  Future<void> _downloadPdf() async {
    if (_isDownloading) return;

    setState(() {
      _isDownloading = true;
      _downloadMessage = 'Generating PDF...';
    });

    try {
      Uint8List pdfBytes;
      if (widget.payment != null) {
        pdfBytes = await InvoicePdfService.generatePaymentInvoicePdf(widget.payment!);
      } else {
        pdfBytes = await InvoicePdfService.generateConsignmentInvoicePdf(widget.batch!);
      }

      setState(() {
        _downloadMessage = 'Saving PDF...';
      });

      final filePath = await InvoicePdfService.downloadPdf(pdfBytes, '$_invoiceId.pdf');

      // On Windows/macOS/Linux, show a dialog with the file path
      if (filePath != null && mounted) {
        Navigator.pop(context);
        _showSavedDialog(filePath, 'PDF');
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF berhasil dibagikan'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengunduh PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _downloadMessage = null;
        });
      }
    }
  }

  Future<void> _downloadImage() async {
    if (_isDownloading) return;

    setState(() {
      _isDownloading = true;
      _downloadMessage = 'Generating Image...';
    });

    try {
      await Future.delayed(const Duration(milliseconds: 100));

      final boundary = _repaintBoundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        throw Exception('Failed to get render boundary');
      }

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        throw Exception('Failed to convert image');
      }

      final imageBytes = byteData.buffer.asUint8List();

      setState(() {
        _downloadMessage = 'Saving Image...';
      });

      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$_invoiceId.png';
      final file = File(filePath);
      await file.writeAsBytes(imageBytes);

      // On Windows/macOS/Linux, show a dialog with the file path instead of sharing
      if (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.linux) {
        if (mounted) {
          Navigator.pop(context);
          _showSavedDialog(filePath, 'Gambar');
        }
      } else {
        // On mobile platforms, use share sheet
        await Share.shareXFiles(
          [XFile(filePath)],
          subject: _invoiceId,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gambar berhasil dibagikan'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan gambar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _downloadMessage = null;
        });
      }
    }
  }

  void _showSavedDialog(String filePath, String fileType) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 24),
            const SizedBox(width: 8),
            Text(
              '$fileType Tersimpan',
              style: TextStyle(fontFamily: 'Poppins', fontSize: 18),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$fileType berhasil disimpan di:',
              style: TextStyle(fontFamily: 'Poppins', fontSize: 13),
            ),
            const SizedBox(height: 8),
            SelectableText(
              filePath,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK', style: TextStyle(fontFamily: 'Poppins')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: context.cardBorder),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: context.primaryBg,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.receipt_long_outlined,
                      color: context.primaryFg,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Invoice',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: context.nameColor,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _isDownloading ? null : () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: RepaintBoundary(
                  key: _repaintBoundaryKey,
                  child: Container(
                    color: Colors.white,
                    child: _invoiceView,
                  ),
                ),
              ),
            ),
            if (_isDownloading && _downloadMessage != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _downloadMessage!,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: context.subColor,
                      ),
                    ),
                  ],
                ),
              ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: context.cardBorder),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isDownloading ? null : _downloadPdf,
                      icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                      label: const Text(
                        'Download PDF',
                        style: TextStyle(fontFamily: 'Poppins', fontSize: 12),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: context.primaryFg,
                        side: BorderSide(color: context.primaryFg),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isDownloading ? null : _downloadImage,
                      icon: const Icon(Icons.image_outlined, size: 18),
                      label: const Text(
                        'Download Gambar',
                        style: TextStyle(fontFamily: 'Poppins', fontSize: 12),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.primaryFg,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
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

void showInvoiceDialog(BuildContext context, {PaymentModel? payment, ConsignmentRequestModel? batch}) {
  showDialog(
    context: context,
    builder: (_) => InvoiceDialog(payment: payment, batch: batch),
  );
}