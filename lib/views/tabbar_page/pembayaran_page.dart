import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../pembayaran/pembayaran_page.dart';
import '../pembayaran/pembayaran_manual_page.dart';
import '../pembayaran/history_pembayaran_page.dart';

class PesananPage extends StatelessWidget {
  const PesananPage({super.key});

  @override
  Widget build(BuildContext context) {
    final Color borderColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.white24
        : Colors.black12;

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
                      _MenuButton(
                        svgPath: 'assets/icons/Payment.svg',
                        label: 'Pembayaran',
                        borderColor: borderColor,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PembayaranPage(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _MenuButton(
                        svgPath: 'assets/icons/Payment.svg',
                        label: 'Pembayaran Manual',
                        borderColor: borderColor,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PembayaranManualPage(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _MenuButton(
                        svgPath: 'assets/icons/Payment History.svg',
                        label: 'History Pembayaran',
                        borderColor: borderColor,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const HistoryPembayaranPage(),
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

class _MenuButton extends StatelessWidget {
  final String svgPath;
  final String label;
  final Color borderColor;
  final VoidCallback onTap;

  const _MenuButton({
    required this.svgPath,
    required this.label,
    required this.borderColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 1.2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 4, bottom: 4),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      top: 5,
                      left: 5,
                      child: ImageFiltered(
                        imageFilter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                        child: SvgPicture.asset(
                          svgPath,
                          width: 80,
                          height: 80,
                          colorFilter: const ColorFilter.mode(
                            Color(0x55000000),
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ),
                    SvgPicture.asset(svgPath, width: 80, height: 80),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                style: textTheme.titleLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
