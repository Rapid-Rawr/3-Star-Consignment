import 'package:flutter/material.dart';
import 'gradient_button.dart';

/// Tipe tombol aksi di dalam AppDialog.
enum AppDialogActionType {
  /// Pakai Untuk Konfirmasi Batal !!
  flat,

  /// Pakai Untuk Konfirmasi Iya !!
  gradient,
}

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
  String content = '',
  required List<AppDialogAction> actions,
  Widget? titleIcon,
  Widget? contentWidget,
  Widget Function(BuildContext dialogContext, StateSetter setDialogState)?
  contentBuilder,
}) {
  return showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (dialogContext, setDialogState) {
        return _AppDialogWidget(
          title: title,
          content: content,
          actions: actions,
          titleIcon: titleIcon,
          contentWidget: contentBuilder != null
              ? contentBuilder(dialogContext, setDialogState)
              : contentWidget,
        );
      },
    ),
  );
}

class _AppDialogWidget extends StatelessWidget {
  final String title;
  final String content;
  final List<AppDialogAction> actions;
  final Widget? titleIcon;
  final Widget? contentWidget;

  const _AppDialogWidget({
    required this.title,
    required this.content,
    required this.actions,
    this.titleIcon,
    this.contentWidget,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? Colors.white : const Color(0xFF1D1B20);
    final Color bgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final Color primaryColor = isDark ? const Color(0xFF4DB6AC) : const Color(0xFF00796B);
    final Color dropdownMenuBg = isDark ? const Color(0xFF2B2930) : Colors.white;
    final Color surfaceColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final Color surfaceContainer = isDark ? const Color(0xFF2B2930) : Colors.white;

    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: Theme.of(context).colorScheme.copyWith(
          primary: primaryColor,
          surface: surfaceColor,
          surfaceContainer: surfaceContainer,
          surfaceContainerHigh: surfaceContainer,
          surfaceContainerHighest: surfaceContainer,
        ),
        inputDecorationTheme: InputDecorationTheme(
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: primaryColor),
          ),
          focusColor: primaryColor,
        ),
        menuTheme: MenuThemeData(
          style: MenuStyle(
            backgroundColor: WidgetStateProperty.all(dropdownMenuBg),
            surfaceTintColor: WidgetStateProperty.all(Colors.transparent),
          ),
        ),
        dropdownMenuTheme: DropdownMenuThemeData(
          menuStyle: MenuStyle(
            backgroundColor: WidgetStateProperty.all(dropdownMenuBg),
            surfaceTintColor: WidgetStateProperty.all(Colors.transparent),
          ),
        ),
      ),
      child: AlertDialog(
        backgroundColor: bgColor,
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            if (titleIcon != null) ...[titleIcon!, const SizedBox(width: 8)],
            Text(title, style: TextStyle(color: textColor)),
          ],
        ),
        content:
            contentWidget ?? Text(content, style: TextStyle(color: textColor)),
        actions: actions.map((action) {
          if (action.type == AppDialogActionType.gradient) {
            return GradientButton(
              label: action.label,
              onPressed: action.onPressed,
            );
          }
          return TextButton(
            onPressed: action.onPressed,
            style: TextButton.styleFrom(
              splashFactory: NoSplash.splashFactory,
              overlayColor: Colors.transparent,
            ),
            child: Text(action.label, style: TextStyle(color: textColor)),
          );
        }).toList(),
      ),
    );
  }
}
