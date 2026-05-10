import 'package:flutter/material.dart';
import '../models/barang_models/konsinyasi_model.dart';

// ─── Item Status ────────────────────────────────────────────────────────────

Color itemStatusBg(ConsignmentItemStatus s, bool isDark) {
  switch (s) {
    case ConsignmentItemStatus.pending:
      return isDark ? const Color(0xFF2A2A1A) : const Color(0xFFFFF8E1);
    case ConsignmentItemStatus.approved:
      return isDark ? const Color(0xFF1A3A2A) : const Color(0xFFE6F4EA);
    case ConsignmentItemStatus.partial:
      return isDark ? const Color(0xFF1A2A3A) : const Color(0xFFE3F2FD);
    case ConsignmentItemStatus.rejected:
      return isDark ? const Color(0xFF3A1A1A) : const Color(0xFFFCE8E8);
  }
}

Color itemStatusFg(ConsignmentItemStatus s, bool isDark) {
  switch (s) {
    case ConsignmentItemStatus.pending:
      return isDark ? const Color(0xFFFFD54F) : const Color(0xFFF57F17);
    case ConsignmentItemStatus.approved:
      return isDark ? const Color(0xFF80CBC4) : const Color(0xFF2E7D32);
    case ConsignmentItemStatus.partial:
      return isDark ? const Color(0xFF90CAF9) : const Color(0xFF1565C0);
    case ConsignmentItemStatus.rejected:
      return isDark ? const Color(0xFFFF8A8A) : Colors.red;
  }
}

IconData itemStatusIcon(ConsignmentItemStatus s) {
  switch (s) {
    case ConsignmentItemStatus.pending:
      return Icons.hourglass_empty_rounded;
    case ConsignmentItemStatus.approved:
      return Icons.check_circle_outline_rounded;
    case ConsignmentItemStatus.partial:
      return Icons.rule_rounded;
    case ConsignmentItemStatus.rejected:
      return Icons.cancel_outlined;
  }
}

String itemStatusLabel(ConsignmentItemStatus s) {
  switch (s) {
    case ConsignmentItemStatus.pending:
      return 'Menunggu';
    case ConsignmentItemStatus.approved:
      return 'Diterima';
    case ConsignmentItemStatus.partial:
      return 'Sebagian';
    case ConsignmentItemStatus.rejected:
      return 'Ditolak';
  }
}

// ─── Batch Status ────────────────────────────────────────────────────────────

Color batchStatusBg(ConsignmentBatchStatus s, bool isDark) {
  if (s == ConsignmentBatchStatus.rejected) {
    return isDark ? const Color(0xFF3A1A1A) : const Color(0xFFFCE8E8);
  }
  return isDark ? const Color(0xFF1A3A3A) : const Color(0xFFE0F2F1);
}

Color batchStatusFg(ConsignmentBatchStatus s, bool isDark) {
  if (s == ConsignmentBatchStatus.rejected) {
    return isDark ? const Color(0xFFFF8A8A) : Colors.red;
  }
  return isDark ? const Color(0xFF4DB6AC) : const Color(0xFF00796B);
}

IconData batchStatusIcon(ConsignmentBatchStatus s) {
  if (s == ConsignmentBatchStatus.rejected) return Icons.cancel_outlined;
  return Icons.verified_outlined;
}

String batchStatusLabel(ConsignmentBatchStatus s) {
  if (s == ConsignmentBatchStatus.rejected) return 'Ditolak';
  return 'Diserahkan';
}
