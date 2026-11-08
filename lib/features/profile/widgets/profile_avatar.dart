import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_image.dart';

/// Circular customer avatar that understands data URLs, assets and http URLs.
/// Falls back to the customer's initials on a soft green background.
class ProfileAvatar extends StatelessWidget {
  final String imageUrl;
  final String name;
  final double radius;
  final Color? backgroundColor;

  const ProfileAvatar({
    super.key,
    required this.imageUrl,
    required this.name,
    this.radius = 24,
    this.backgroundColor,
  });

  String get _initials {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'AA';
    final parts = trimmed.split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    final initials = parts
        .map((w) => w.characters.first)
        .take(2)
        .join()
        .toUpperCase();
    return initials.isEmpty ? 'AA' : initials;
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl.trim().isNotEmpty;
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor ?? AppColors.softGreen,
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: hasImage
          ? AppImage(
              source: imageUrl,
              fit: BoxFit.cover,
              fallback: _Initials(initials: _initials, radius: radius),
            )
          : _Initials(initials: _initials, radius: radius),
    );
  }
}

class _Initials extends StatelessWidget {
  final String initials;
  final double radius;

  const _Initials({required this.initials, required this.radius});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        initials,
        style: TextStyle(
          color: AppColors.primaryAccent,
          fontWeight: FontWeight.w800,
          fontSize: radius * 0.62,
        ),
      ),
    );
  }
}
