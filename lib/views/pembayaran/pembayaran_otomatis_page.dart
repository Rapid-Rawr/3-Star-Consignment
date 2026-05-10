import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';

class AutoPaymentPage extends StatelessWidget {
  const AutoPaymentPage({super.key});

  @override
  Widget build(BuildContext context) {
    final Color emptyIcon = context.emptyIcon;
    final Color emptyText = context.emptyText;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Pembayaran',
          style: TextStyle(fontFamily: 'Poppins'),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.payment_outlined, size: 64, color: emptyIcon),
            const SizedBox(height: 16),
            Text(
              'Belum Ada Data Pembayaran',
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
