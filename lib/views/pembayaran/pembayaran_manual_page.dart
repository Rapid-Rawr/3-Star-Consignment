import 'package:flutter/material.dart';

class PembayaranManualPage extends StatelessWidget {
  const PembayaranManualPage({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color emptyIcon = isDark ? Colors.white24 : Colors.black26;
    final Color emptyText = isDark ? Colors.white38 : const Color(0xFF9E9E9E);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Pembayaran Manual',
          style: TextStyle(fontFamily: 'Poppins'),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.edit_note_rounded, size: 64, color: emptyIcon),
            const SizedBox(height: 16),
            Text(
              'Belum Ada Data Pembayaran Manual',
              style: TextStyle(
                fontSize: 16,
                color: emptyText,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
