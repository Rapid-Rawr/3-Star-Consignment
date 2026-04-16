import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Widget tombol menu yang dapat digunakan ulang di seluruh halaman tabbar.
///
/// Properti yang dapat dikustomisasi:
/// - [svgPath]: path aset SVG ikon
/// - [label]: teks label di bawah ikon
/// - [borderColor]: warna border kartu
/// - [onTap]: callback saat tombol ditekan
/// - [iconSize]: ukuran ikon SVG (default 80)
/// - [verticalPadding]: padding vertikal kartu (default 28)
/// - [iconLabelSpacing]: jarak antara ikon dan label (default 10)
/// - [imageOffset]: geser posisi ikon (default [Offset.zero])
///

class MenuButton extends StatelessWidget {
  final String svgPath;
  final String label;
  final Color borderColor;
  final VoidCallback onTap;
  final double iconSize;
  final double verticalPadding;
  final double iconLabelSpacing;
  final Offset imageOffset;

  const MenuButton({
    super.key,
    required this.svgPath,
    required this.label,
    required this.borderColor,
    required this.onTap,
    this.iconSize = 80,
    this.verticalPadding = 28,
    this.iconLabelSpacing = 10,
    this.imageOffset = Offset.zero,
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
          padding: EdgeInsets.symmetric(
            vertical: verticalPadding,
            horizontal: 12,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 1.2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Transform.translate(
                offset: imageOffset,
                child: Padding(
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
                            width: iconSize,
                            height: iconSize,
                            colorFilter: const ColorFilter.mode(
                              Color(0x55000000),
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                      ),
                      SvgPicture.asset(
                        svgPath,
                        width: iconSize,
                        height: iconSize,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: iconLabelSpacing),
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
