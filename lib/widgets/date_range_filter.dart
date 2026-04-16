import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

String formatDateShort(DateTime? dt) {
  if (dt == null) return '-';
  const months = [
    '',
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];
  return '${dt.day} ${months[dt.month]} ${dt.year}';
}

ThemeData buildDatePickerTheme(BuildContext context) {
  final isDark = context.isDark;
  return Theme.of(context).copyWith(
    colorScheme: isDark
        ? const ColorScheme.dark(
            primary: Color(0xFF4DB6AC),
            onPrimary: Colors.black,
            surface: Color(0xFF2B2930),
            onSurface: Colors.white,
          )
        : const ColorScheme.light(
            primary: Color(0xFF00796B),
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: Color(0xFF1D1B20),
          ),
  );
}

Future<void> selectFromDate({
  required BuildContext context,
  required DateTime? current,
  required DateTime? dateTo,
  required void Function(DateTime) onPicked,
}) async {
  final picked = await showDatePicker(
    context: context,
    initialDate: current ?? DateTime.now(),
    firstDate: DateTime(2020),
    lastDate: DateTime.now(),
    builder: (ctx, child) =>
        Theme(data: buildDatePickerTheme(ctx), child: child!),
  );
  if (picked != null) onPicked(picked);
}

Future<void> selectToDate({
  required BuildContext context,
  required DateTime? current,
  required DateTime? dateFrom,
  required void Function(DateTime) onPicked,
}) async {
  final picked = await showDatePicker(
    context: context,
    initialDate: current ?? (dateFrom ?? DateTime.now()),
    firstDate: dateFrom ?? DateTime(2020),
    lastDate: DateTime.now(),
    builder: (ctx, child) =>
        Theme(data: buildDatePickerTheme(ctx), child: child!),
  );
  if (picked != null) {
    onPicked(DateTime(picked.year, picked.month, picked.day, 23, 59, 59));
  }
}

class DateRangeFilter extends StatelessWidget {
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final VoidCallback onFromTap;
  final VoidCallback onToTap;
  final VoidCallback onClear;
  final EdgeInsetsGeometry padding;

  const DateRangeFilter({
    super.key,
    required this.dateFrom,
    required this.dateTo,
    required this.onFromTap,
    required this.onToTap,
    required this.onClear,
    this.padding = const EdgeInsets.fromLTRB(16, 6, 16, 8),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final borderActive = isDark
        ? const Color(0xFF4DB6AC)
        : const Color(0xFF00796B);
    final borderDim = context.cardBorder;
    final iconColor = isDark ? Colors.white54 : Colors.black54;
    final clearColor = isDark ? Colors.white38 : Colors.black38;

    Color textColor(bool active) => active
        ? (isDark ? Colors.white : const Color(0xFF1D1B20))
        : (isDark ? Colors.white38 : Colors.black38);

    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(
            child: _DateButton(
              label: 'Dari Tanggal',
              date: dateFrom,
              onTap: onFromTap,
              borderColor: dateFrom != null ? borderActive : borderDim,
              iconColor: iconColor,
              textColor: textColor(dateFrom != null),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _DateButton(
              label: 'Sampai Tanggal',
              date: dateTo,
              onTap: onToTap,
              borderColor: dateTo != null ? borderActive : borderDim,
              iconColor: iconColor,
              textColor: textColor(dateTo != null),
              trailing: (dateFrom != null || dateTo != null)
                  ? GestureDetector(
                      onTap: onClear,
                      child: Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: clearColor,
                      ),
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _DateButton extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;
  final Color borderColor;
  final Color iconColor;
  final Color textColor;
  final Widget? trailing;

  const _DateButton({
    required this.label,
    required this.date,
    required this.onTap,
    required this.borderColor,
    required this.iconColor,
    required this.textColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, size: 16, color: iconColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                date == null ? label : formatDateShort(date),
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: textColor,
                ),
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}
