import 'package:flutter/material.dart';

/// Global theme notifier — controls dark/light mode across the app.
/// Kept in a separate file to avoid circular imports.
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);
