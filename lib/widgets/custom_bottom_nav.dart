import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CustomBottomNavItem {
  final IconData? icon;
  final IconData? activeIcon;
  final String? iconSvg;
  final String? activeIconSvg;
  final double? iconSize;
  final double? activeIconSize;

  const CustomBottomNavItem({
    this.icon,
    this.activeIcon,
    this.iconSvg,
    this.activeIconSvg,
    this.iconSize,
    this.activeIconSize,
  }) : assert((icon != null || iconSvg != null), 'Harus ada icon atau iconSvg');
}

class CustomBottomNav extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<CustomBottomNavItem> items;
  final double iconSize;
  final double activeIconSize;

  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.iconSize = 26,
    this.activeIconSize = 28,
  });

  @override
  State<CustomBottomNav> createState() => _CustomBottomNavState();
}

class _CustomBottomNavState extends State<CustomBottomNav> {
  late List<double> _scales;

  @override
  void initState() {
    super.initState();
    _scales = List.filled(widget.items.length, 1.0);
  }

  void _onTapDown(int index) {
    setState(() => _scales[index] = 0.80);
  }

  void _onTapUp(int index) {
    setState(() => _scales[index] = 1.0);
    widget.onTap(index);
  }

  void _onTapCancel(int index) {
    setState(() => _scales[index] = 1.0);
  }

  Widget _buildIcon({
    required CustomBottomNavItem item,
    required bool isActive,
    required double size,
    required Color color,
  }) {
    final String? svgPath = isActive
        ? (item.activeIconSvg ?? item.iconSvg)
        : item.iconSvg;

    if (svgPath != null) {
      return SvgPicture.asset(
        svgPath,
        width: size,
        height: size,
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      );
    }

    // Fallback ke IconData
    final IconData iconData = isActive
        ? (item.activeIcon ?? item.icon!)
        : item.icon!;
    return Icon(iconData, size: size, color: color);
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor = Theme.of(context).scaffoldBackgroundColor;
    final Color activeColor = isDark ? Colors.white : const Color(0xFF1D1B20);
    final Color inactiveColor = isDark ? Colors.white38 : Colors.black38;

    final Color borderColor = isDark ? Colors.white24 : Colors.black12;

    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [
          Colors.transparent,
          Colors.white,
          Colors.white,
          Colors.transparent,
        ],
        stops: [0.0, 0.08, 0.92, 1.0],
      ).createShader(bounds),
      blendMode: BlendMode.dstIn,
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(35)),
          border: Border(
            top: BorderSide(color: borderColor, width: 0.8),
            left: BorderSide(color: borderColor, width: 0.8),
            right: BorderSide(color: borderColor, width: 0.8),
          ),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 60,
            child: Row(
              children: List.generate(widget.items.length, (i) {
                final item = widget.items[i];
                final bool isActive = widget.currentIndex == i;
                return Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapDown: (_) => _onTapDown(i),
                    onTapUp: (_) => _onTapUp(i),
                    onTapCancel: () => _onTapCancel(i),
                    child: AnimatedScale(
                      scale: _scales[i],
                      duration: const Duration(milliseconds: 120),
                      curve: Curves.easeOut,
                      child: _buildIcon(
                        item: item,
                        isActive: isActive,
                        size: isActive
                            ? (item.activeIconSize ?? widget.activeIconSize)
                            : (item.iconSize ?? widget.iconSize),
                        color: isActive ? activeColor : inactiveColor,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ), // SafeArea
      ), // Container
    ); // ShaderMask
  }
}
