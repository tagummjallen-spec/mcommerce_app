import 'dart:convert';

import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Renders the three image reference formats used by the storefront:
/// base64 data URLs (uploaded profile/product photos), bundled asset paths,
/// and remote http(s) URLs.
class AppImage extends StatelessWidget {
  final String source;
  final BoxFit fit;
  final Widget? fallback;
  final IconData fallbackIcon;
  final double fallbackIconSize;

  const AppImage({
    super.key,
    required this.source,
    this.fit = BoxFit.cover,
    this.fallback,
    this.fallbackIcon = Icons.image_outlined,
    this.fallbackIconSize = 32,
  });

  Widget _fallback() =>
      fallback ??
      Center(
        child: Icon(
          fallbackIcon,
          color: AppColors.tertiaryText,
          size: fallbackIconSize,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final path = source.trim();
    if (path.isEmpty) return _fallback();

    if (path.startsWith('data:image/')) {
      try {
        final commaIndex = path.indexOf(',');
        if (commaIndex >= 0 && commaIndex < path.length - 1) {
          return Image.memory(
            base64Decode(path.substring(commaIndex + 1)),
            fit: fit,
            gaplessPlayback: true,
            errorBuilder: (_, _, _) => _fallback(),
          );
        }
      } catch (e) {
        debugPrint('DATA URL IMAGE ERROR: $e');
      }
      return _fallback();
    }

    if (path.startsWith('assets/')) {
      return Image.asset(
        path,
        fit: fit,
        errorBuilder: (_, _, _) => _fallback(),
      );
    }

    if (path.startsWith('http')) {
      return Image.network(
        path,
        fit: fit,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return ColoredBox(
            color: AppColors.cardSurface,
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: AppColors.primaryAccent,
                  strokeWidth: 2,
                ),
              ),
            ),
          );
        },
        errorBuilder: (_, _, _) => _fallback(),
      );
    }

    return _fallback();
  }
}
