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
import '../widgets/app_dialog.dart';
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

  bool get _isDesktop {
    return defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux;
  }

  void _showPdfOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: context.primaryBg,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.picture_as_pdf_outlined, color: context.primaryFg, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Opsi PDF',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: context.nameColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: context.successBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.save_alt_rounded, color: context.successFg, size: 20),
                ),
                title: Text('Simpan ke File', style: TextStyle(fontFamily: 'Poppins', fontSize: 14)),
                subtitle: Text('Simpan PDF ke penyimpanan lokal', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: context.subColor)),
                onTap: () {
                  Navigator.pop(ctx);
                  _savePdfToFile();
                },
              ),
              if (!_isDesktop) ListTile(
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: context.primaryBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.share_rounded, color: context.primaryFg, size: 20),
                ),
                title: Text('Bagikan', style: TextStyle(fontFamily: 'Poppins', fontSize: 14)),
                subtitle: Text('Bagikan PDF via aplikasi lain', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: context.subColor)),
                onTap: () {
                  Navigator.pop(ctx);
                  _sharePdf();
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: context.primaryBg,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.image_outlined, color: context.primaryFg, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Opsi Gambar',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: context.nameColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: context.successBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.save_alt_rounded, color: context.successFg, size: 20),
                ),
                title: Text('Simpan ke File', style: TextStyle(fontFamily: 'Poppins', fontSize: 14)),
                subtitle: Text('Simpan gambar ke penyimpanan lokal', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: context.subColor)),
                onTap: () {
                  Navigator.pop(ctx);
                  _saveImageToFile();
                },
              ),
              if (!_isDesktop) ListTile(
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: context.primaryBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.share_rounded, color: context.primaryFg, size: 20),
                ),
                title: Text('Bagikan', style: TextStyle(fontFamily: 'Poppins', fontSize: 14)),
                subtitle: Text('Bagikan gambar via aplikasi lain', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: context.subColor)),
                onTap: () {
                  Navigator.pop(ctx);
                  _shareImage();
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<String> _getDownloadPath(String fileName) async {
    Directory? directory;
    
    try {
      // Android - use Downloads folder
      if (defaultTargetPlatform == TargetPlatform.android) {
        final extDir = Directory('/storage/emulated/0/Download');
        if (await extDir.exists()) {
          return '${extDir.path}/$fileName';
        }
      }
      
      // iOS - use app documents (visible in Files app)
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        directory = await getApplicationDocumentsDirectory();
        return '${directory.path}/$fileName';
      }
      
      // Windows - use USERPROFILE\Downloads
      if (defaultTargetPlatform == TargetPlatform.windows) {
        final userProfile = Platform.environment['USERPROFILE'];
        if (userProfile != null) {
          final downloadsDir = Directory('$userProfile\\Downloads');
          if (await downloadsDir.exists()) {
            return '${downloadsDir.path}\\$fileName';
          }
        }
      }
      
      // macOS - use ~/Downloads
      if (defaultTargetPlatform == TargetPlatform.macOS) {
        final home = Platform.environment['HOME'];
        if (home != null) {
          final downloadsDir = Directory('$home/Downloads');
          if (await downloadsDir.exists()) {
            return '${downloadsDir.path}/$fileName';
          }
        }
      }
      
      // Linux - use ~/Downloads
      if (defaultTargetPlatform == TargetPlatform.linux) {
        final home = Platform.environment['HOME'];
        if (home != null) {
          final downloadsDir = Directory('$home/Downloads');
          if (await downloadsDir.exists()) {
            return '${downloadsDir.path}/$fileName';
          }
        }
      }
    } catch (e) {
      // Ignore and fallback
    }
    
    // Fallback to app documents directory
    directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/$fileName';
  }

  Future<void> _savePdfToFile() async {
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

      final filePath = await _getDownloadPath('$_invoiceId.pdf');
      final file = File(filePath);
      await file.writeAsBytes(pdfBytes);

      if (mounted) {
        _showSavedDialog(filePath, 'PDF');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan PDF: $e'),
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

  Future<void> _sharePdf() async {
    if (_isDownloading) return;

    setState(() {
      _isDownloading = true;
      _downloadMessage = 'Preparing PDF...';
    });

    try {
      Uint8List pdfBytes;
      if (widget.payment != null) {
        pdfBytes = await InvoicePdfService.generatePaymentInvoicePdf(widget.payment!);
      } else {
        pdfBytes = await InvoicePdfService.generateConsignmentInvoicePdf(widget.batch!);
      }

      setState(() {
        _downloadMessage = 'Sharing PDF...';
      });

      final filePath = await _getDownloadPath('$_invoiceId.pdf');
      final file = File(filePath);
      await file.writeAsBytes(pdfBytes);

      await Share.shareXFiles([XFile(filePath)], subject: _invoiceId);

      if (mounted) {
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
            content: Text('Gagal membagikan PDF: $e'),
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

  Future<void> _saveImageToFile() async {
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

      final filePath = await _getDownloadPath('$_invoiceId.png');
      final file = File(filePath);
      await file.writeAsBytes(imageBytes);

      if (mounted) {
        _showSavedDialog(filePath, 'Gambar');
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

  Future<void> _shareImage() async {
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
        _downloadMessage = 'Sharing Image...';
      });

      final filePath = await _getDownloadPath('$_invoiceId.png');
      final file = File(filePath);
      await file.writeAsBytes(imageBytes);

      await Share.shareXFiles([XFile(filePath)], subject: _invoiceId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gambar berhasil dibagikan'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membagikan gambar: $e'),
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
    showAppDialog(
      context: context,
      title: '$fileType Tersimpan',
      titleIcon: Icon(Icons.check_circle, color: Colors.green, size: 24),
      content: '$fileType berhasil disimpan di:\n\n$filePath',
      actions: [
        AppDialogAction(
          label: 'OK',
          type: AppDialogActionType.gradient,
          onPressed: () {
            Navigator.pop(context); // Close saved dialog
            Navigator.pop(context); // Close InvoiceDialog
          },
        ),
      ],
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
                      onPressed: _isDownloading ? null : _showPdfOptions,
                      icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                      label: const Text(
                        'PDF',
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
                      onPressed: _isDownloading ? null : _showImageOptions,
                      icon: const Icon(Icons.image_outlined, size: 18),
                      label: const Text(
                        'Gambar',
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