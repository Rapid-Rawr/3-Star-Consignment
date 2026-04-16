import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import 'catalog_image.dart';

class SheetDragHandle extends StatelessWidget {
  const SheetDragHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 6),
      child: Center(
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: context.cardBorder,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}

class SheetClientAvatar extends StatelessWidget {
  final String? photoUrl;

  const SheetClientAvatar({super.key, this.photoUrl});

  @override
  Widget build(BuildContext context) {
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 19,
        backgroundImage: NetworkImage(photoUrl!),
        onBackgroundImageError: (_, __) {},
      );
    }
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: context.primaryBg,
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.store_outlined, color: context.primaryFg, size: 20),
    );
  }
}

class SheetClientHeader extends StatelessWidget {
  final String clientName;
  final String? clientAddress;
  final String? photoUrl;
  final String countBadgeText;
  final Widget? extraBadge;

  const SheetClientHeader({
    super.key,
    required this.clientName,
    required this.clientAddress,
    required this.countBadgeText,
    this.photoUrl,
    this.extraBadge,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      child: Row(
        children: [
          SheetClientAvatar(photoUrl: photoUrl),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  clientName.isNotEmpty ? clientName : 'Klien Tidak Dikenal',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: context.nameColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (clientAddress != null && clientAddress!.isNotEmpty)
                  Text(
                    clientAddress!,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      color: context.subColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          if (extraBadge != null) ...[const SizedBox(width: 4), extraBadge!],
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: context.primaryBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              countBadgeText,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: context.primaryFg,
              ),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}

class SheetSectionHeader extends StatelessWidget {
  final String title;
  final String countBadgeText;

  const SheetSectionHeader({
    super.key,
    required this.title,
    required this.countBadgeText,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: context.nameColor,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: context.primaryBg,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            countBadgeText,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: context.primaryFg,
            ),
          ),
        ),
      ],
    );
  }
}

class SheetItemCard extends StatelessWidget {
  final String? imagePath;
  final double imageSize;
  final double imageBorderRadius;
  final List<Widget> contentChildren;
  final Widget? trailing;

  const SheetItemCard({
    super.key,
    required this.imagePath,
    this.imageSize = 50,
    this.imageBorderRadius = 8,
    required this.contentChildren,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = context.isDark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF333138) : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.cardBorder, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CatalogImage(
            imagePath: imagePath,
            size: imageSize,
            borderRadius: imageBorderRadius,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: contentChildren,
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 8), trailing!],
        ],
      ),
    );
  }
}

class SheetTotalFooter extends StatelessWidget {
  final String label;
  final String amount;

  const SheetTotalFooter({
    super.key,
    required this.label,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            color: context.subColor,
          ),
        ),
        const Spacer(),
        Text(
          amount,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: context.primaryFg,
          ),
        ),
      ],
    );
  }
}
