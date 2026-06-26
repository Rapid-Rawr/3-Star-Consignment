import 'package:flutter/material.dart';

extension AppColorsExtension on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  Color get editBg =>
      isDark ? const Color(0xFF49454F) : const Color(0xFFE8E5EC);
  Color get editIcon => isDark ? Colors.white : const Color(0xFF1D1B20);

  Color get deleteBg =>
      isDark ? const Color(0xFF4D2B2B) : const Color(0xFFFCE8E8);
  Color get deleteIcon => isDark ? const Color(0xFFFF8A8A) : Colors.red;

  Color get emptyIcon => isDark ? Colors.white24 : Colors.black26;
  Color get emptyText => isDark ? Colors.white38 : const Color(0xFF9E9E9E);

  Color get cardBg => isDark ? const Color(0xFF2B2930) : Colors.white;
  Color get cardBorder =>
      isDark ? const Color(0xFF49454F) : const Color(0xFFE0E0E0);

  List<Color> get fabGradient => isDark
      ? [const Color(0xFFA3A3A3), const Color(0xFFFFFFFF)]
      : [const Color(0xFF67636D), const Color(0xFF1D1B20)];

  Color debtBg(bool hasDebt) => hasDebt
      ? deleteBg
      : (isDark ? const Color(0xFF1A3A2A) : const Color(0xFFE8F5E9));

  Color debtTextColor(bool hasDebt) => hasDebt
      ? deleteIcon
      : (isDark ? const Color(0xFF80CBC4) : const Color(0xFF2E7D32));

  Color get unselectedColor =>
      isDark ? Colors.white70 : const Color(0xFF49454F);

  Color get nameColor => isDark ? Colors.white : const Color(0xFF1D1B20);

  Color get subColor => isDark ? Colors.white54 : const Color(0xFF757575);

  Color roleBadgeBg(bool isAdmin) => isAdmin
      ? (isDark ? const Color(0xFF4A2E76) : const Color(0xFFEDE7F6))
      : (isDark ? const Color(0xFF1A3E3A) : const Color(0xFFE0F2F1));

  Color roleBadgeText(bool isAdmin) => isAdmin
      ? (isDark ? const Color(0xFFCE93D8) : const Color(0xFF6A1B9A))
      : (isDark ? const Color(0xFF80CBC4) : const Color(0xFF00695C));

  Color get pendingColor => isDark ? Colors.amber.shade300 : Colors.orange;

  Color get pendingDeleteBg =>
      isDark ? const Color(0xFF3A1A1A) : const Color(0xFFFDECEA);
  Color get pendingDeleteFg =>
      isDark ? const Color(0xFFFF8A8A) : const Color(0xFFC62828);

  Color get primaryFg =>
      isDark ? const Color(0xFF4DB6AC) : const Color(0xFF00796B);
  Color get primaryBg =>
      isDark ? const Color(0xFF1A3A3A) : const Color(0xFFE0F2F1);

  Color get infoFg =>
      isDark ? const Color(0xFF90CAF9) : const Color(0xFF1565C0);
  Color get infoBg =>
      isDark ? const Color(0xFF1A2A3A) : const Color(0xFFE3F2FD);

  Color get successFg =>
      isDark ? const Color(0xFF80CBC4) : const Color(0xFF2E7D32);
  Color get successBg =>
      isDark ? const Color(0xFF1A3A2A) : const Color(0xFFE6F4EA);

  Color get cardShadow =>
      isDark ? Colors.black26 : Colors.black.withValues(alpha: 0.06);

  Color get borderColor => isDark ? Colors.white24 : Colors.black12;

  Color get chipBg => isDark ? const Color(0xFF333138) : const Color(0xFFE0E0E0);
  Color get chipText => isDark ? Colors.white70 : Colors.black87;

  Color get scaffoldBg =>
      isDark ? const Color(0xFF1C1B1F) : const Color(0xFFF5F5F5);

  Color get headerBg =>
      isDark ? const Color(0xFF3A3540) : Colors.grey.shade100;

  Color get pendingFg =>
      isDark ? const Color(0xFFFFD54F) : const Color(0xFFF57F17);
  Color get pendingBg =>
      isDark ? const Color(0xFF2A2A1A) : const Color(0xFFFFF8E1);

  Color get processingFg =>
      isDark ? const Color(0xFF4DB6AC) : const Color(0xFF00796B);
  Color get processingBg =>
      isDark ? const Color(0xFF1A3A3A) : const Color(0xFFE0F2F1);

  Color get packedFg =>
      isDark ? const Color(0xFF9C7AB6) : const Color(0xFF6A1B9A);
  Color get packedBg =>
      isDark ? const Color(0xFF3A2A4A) : const Color(0xFFF3E5F5);

  Color get receivedFg =>
      isDark ? const Color(0xFF90CAF9) : const Color(0xFF1565C0);
  Color get receivedBg =>
      isDark ? const Color(0xFF1A2A3A) : const Color(0xFFE3F2FD);

  Color get rejectedFg =>
      isDark ? const Color(0xFFFF8A8A) : Colors.red;
  Color get rejectedBg =>
      isDark ? const Color(0xFF3A1A1A) : const Color(0xFFFCE8E8);

  Color statusFg(String status) {
    switch (status) {
      case 'pending':
        return pendingFg;
      case 'processing':
        return processingFg;
      case 'packed':
        return packedFg;
      case 'received':
        return receivedFg;
      case 'rejected':
        return rejectedFg;
      default:
        return subColor;
    }
  }

  Color statusBg(String status) {
    switch (status) {
      case 'pending':
        return pendingBg;
      case 'processing':
        return processingBg;
      case 'packed':
        return packedBg;
      case 'received':
        return receivedBg;
      case 'rejected':
        return rejectedBg;
      default:
        return cardBg;
    }
  }
}

extension AppTextThemeExtension on BuildContext {
  TextStyle get titleLarge => TextStyle(
    fontFamily: 'Poppins',
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: nameColor,
  );

  TextStyle get titleMedium => TextStyle(
    fontFamily: 'Poppins',
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: nameColor,
  );

  TextStyle get titleSmall => TextStyle(
    fontFamily: 'Poppins',
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: nameColor,
  );

  TextStyle get bodyLarge => TextStyle(
    fontFamily: 'Poppins',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: nameColor,
  );

  TextStyle get bodyMedium => TextStyle(
    fontFamily: 'Poppins',
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: nameColor,
  );

  TextStyle get bodySmall => TextStyle(
    fontFamily: 'Poppins',
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: nameColor,
  );

  TextStyle get labelLarge => TextStyle(
    fontFamily: 'Poppins',
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: subColor,
  );

  TextStyle get labelMedium => TextStyle(
    fontFamily: 'Poppins',
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: subColor,
  );

  TextStyle get labelSmall => TextStyle(
    fontFamily: 'Poppins',
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: subColor,
  );

  TextStyle get caption => TextStyle(
    fontFamily: 'Poppins',
    fontSize: 10,
    fontWeight: FontWeight.w400,
    color: subColor,
  );
}