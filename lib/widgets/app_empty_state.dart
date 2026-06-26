import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final double iconSize;
  final EdgeInsetsGeometry? padding;

  const AppEmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.iconSize = 48,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: iconSize,
              color: context.emptyIcon,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: context.emptyText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}