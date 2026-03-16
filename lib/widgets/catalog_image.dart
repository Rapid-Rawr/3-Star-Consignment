import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../utils/supabase_service.dart';

class CatalogImage extends StatelessWidget {
  final String? imagePath;
  final double size;
  final double borderRadius;
  final Color? backgroundColor;

  const CatalogImage({
    super.key,
    required this.imagePath,
    this.size = 72,
    this.borderRadius = 12,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bg =
        backgroundColor ??
        (isDark ? const Color(0xFF3A3540) : const Color(0xFFF3EFF4));
    final Color iconColor = isDark ? Colors.white24 : const Color(0xFFB0B0B0);

    final String? publicUrl = SupabaseService.getPublicUrl(imagePath);

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        width: size,
        height: size,
        child: (publicUrl != null && publicUrl.isNotEmpty)
            ? CachedNetworkImage(
                imageUrl: publicUrl,
                width: size,
                height: size,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: bg,
                  child: Center(
                    child: SizedBox(
                      width: size * 0.35,
                      height: size * 0.35,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: isDark
                            ? Colors.white38
                            : const Color(0xFFB0B0B0),
                      ),
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: bg,
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: iconColor,
                    size: size * 0.4,
                  ),
                ),
                maxHeightDiskCache: 400,
                maxWidthDiskCache: 400,
              )
            : Container(
                color: bg,
                child: Icon(
                  Icons.image_outlined,
                  color: iconColor,
                  size: size * 0.4,
                ),
              ),
      ),
    );
  }
}
