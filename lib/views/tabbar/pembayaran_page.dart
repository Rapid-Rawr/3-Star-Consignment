import 'package:flutter/material.dart';
import '../pembayaran/pembayaran_otomatis_page.dart';
import '../pembayaran/pembayaran_manual_page.dart';
import '../pembayaran/riwayat_pembayaran_page.dart';
import '../../widgets/menu_button.dart';
import '../../utils/app_colors.dart';

class PaymentPage extends StatelessWidget {
  const PaymentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      MenuButton(
                        svgPath: 'assets/icons/Payment.svg',
                        label: 'Pembayaran',
                        borderColor: context.borderColor,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AutoPaymentPage(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      MenuButton(
                        svgPath: 'assets/icons/Payment.svg',
                        label: 'Pembayaran Manual',
                        borderColor: context.borderColor,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ManualPaymentPage(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      MenuButton(
                        svgPath: 'assets/icons/Payment History.svg',
                        label: 'Riwayat Pembayaran',
                        borderColor: context.borderColor,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PaymentHistoryPage(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
