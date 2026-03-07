import 'package:flutter/material.dart';

/// Tombol dengan background gradient yang adaptif terhadap light/dark mode.
///
/// Light mode: gradient #67636D → #1D1B20 (gelap), teks putih
/// Dark mode:  gradient #A3A3A3 → #FFFFFF (terang), teks #1D1B20
///
/// Contoh pemakaian:
/// ```dart
/// GradientButton(label: 'Simpan', onPressed: () { ... })
/// GradientButton(label: 'Hapus', onPressed: () { ... }, borderRadius: 8)
/// ```
class GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final TextStyle? textStyle;

  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.borderRadius = 20,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final List<Color> gradientColors = isDark
        ? [const Color(0xFFA3A3A3), const Color(0xFFFFFFFF)]
        : [const Color(0xFF67636D), const Color(0xFF1D1B20)];

    final Color textColor = isDark ? const Color(0xFF1D1B20) : Colors.white;

    final Color splashColor = isDark ? const Color(0xFF1D1B20) : Colors.white;

    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
        overlayColor: splashColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomLeft,
            end: Alignment.topRight,
            colors: gradientColors,
          ),
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: Padding(
          padding: padding,
          child: Text(
            label,
            style:
                textStyle ??
                TextStyle(color: textColor, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}
