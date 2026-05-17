import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Unified image widget that transparently handles both local asset paths
/// and remote HTTP(S) URLs, with a loading placeholder and error fallback.
class AppImage extends StatelessWidget {
  const AppImage({
    super.key,
    required this.src,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  final String src;
  final double? height;
  final double? width;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final Widget img = src.startsWith('http')
        ? CachedNetworkImage(
            imageUrl: src,
            height: height,
            width: width,
            fit: fit,
            placeholder: (BuildContext ctx, String url) => _placeholder(),
            errorWidget: (BuildContext ctx, String url, Object error) =>
                _fallback(),
          )
        : Image.asset(
            src,
            height: height,
            width: width,
            fit: fit,
            errorBuilder: (_, __, ___) => _fallback(),
          );

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: img);
    }
    return img;
  }

  Widget _placeholder() {
    return Container(
      height: height,
      width: width,
      color: const Color(0xFFE8F1F8),
      child: const Center(
        child: SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _fallback() {
    return Image.asset(
      'assets/1.jpeg',
      height: height,
      width: width,
      fit: fit,
    );
  }
}
