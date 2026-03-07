import 'package:flutter/material.dart';
import 'gradient_button.dart';

// ─────────────────────────────────────────────
// Model untuk setiap tombol aksi di dialog
// ─────────────────────────────────────────────

/// Tipe tombol aksi di dalam AppDialog.
enum AppDialogActionType {
  /// Tombol tanpa background — style TextButton biasa (mengikuti tema)
  flat,

  /// Tombol dengan background gradient yang mengikuti dark/light mode
  gradient,
}

/// Definisi satu tombol aksi di AppDialog.
class AppDialogAction {
  final String label;
  final VoidCallback onPressed;
  final AppDialogActionType type;

  const AppDialogAction({
    required this.label,
    required this.onPressed,
    this.type = AppDialogActionType.flat,
  });
}

// ─────────────────────────────────────────────
// 3 Star Consignment AppDialog
// ─────────────────────────────────────────────

/// Dialog yang dapat di-reuse di seluruh aplikasi.
///
/// Fitur:
/// - Judul dengan ikon opsional
/// - Konten teks
/// - Daftar tombol aksi (flat atau gradient)
/// - Warna teks mengikuti dark/light mode secara otomatis
///
/// Contoh pemakaian:
/// ```dart
/// showAppDialog(
///   context: context,
///   title: 'Hapus Data',
///   titleIcon: Icon(Icons.warning_amber_rounded),
///   content: 'Apakah anda yakin ingin menghapus data ini?',
///   actions: [
///     AppDialogAction(label: 'Batal', onPressed: () => Navigator.pop(context)),
///     AppDialogAction(
///       label: 'Hapus',
///       type: AppDialogActionType.gradient,
///       onPressed: () { ... },
///     ),
///   ],
/// );
/// ```
Future<void> showAppDialog({
  required BuildContext context,
  required String title,
  required String content,
  required List<AppDialogAction> actions,
  Widget? titleIcon,
}) {
  return showDialog(
    context: context,
    builder: (ctx) => _AppDialogWidget(
      title: title,
      content: content,
      actions: actions,
      titleIcon: titleIcon,
    ),
  );
}

class _AppDialogWidget extends StatelessWidget {
  final String title;
  final String content;
  final List<AppDialogAction> actions;
  final Widget? titleIcon;

  const _AppDialogWidget({
    required this.title,
    required this.content,
    required this.actions,
    this.titleIcon,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? Colors.white : const Color(0xFF1D1B20);

    return AlertDialog(
      // ── Judul dengan ikon opsional ──
      title: Row(
        children: [
          if (titleIcon != null) ...[titleIcon!, const SizedBox(width: 8)],
          Text(title, style: TextStyle(color: textColor)),
        ],
      ),

      // ── Konten ──
      content: Text(content, style: TextStyle(color: textColor)),

      // ── Tombol aksi ──
      actions: actions.map((action) {
        if (action.type == AppDialogActionType.gradient) {
          return GradientButton(
            label: action.label,
            onPressed: action.onPressed,
          );
        }

        // Flat button (default) — tanpa splash
        return TextButton(
          onPressed: action.onPressed,
          style: TextButton.styleFrom(
            splashFactory: NoSplash.splashFactory,
            overlayColor: Colors.transparent,
          ),
          child: Text(action.label, style: TextStyle(color: textColor)),
        );
      }).toList(),
    );
  }
}
