import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class RatingStars extends StatelessWidget {
  final double rating;
  final double size;
  final bool interactive;
  final ValueChanged<int>? onRatingChanged;

  const RatingStars({
    super.key,
    required this.rating,
    this.size = 16,
    this.interactive = false,
    this.onRatingChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starValue = index + 1;
        IconData icon;
        if (rating >= starValue) {
          icon = Icons.star;
        } else if (rating >= starValue - 0.5) {
          icon = Icons.star_half;
        } else {
          icon = Icons.star_border;
        }
        final star = Icon(
          icon,
          size: size,
          color: AppColors.warning,
        );
        if (!interactive) return star;
        return GestureDetector(
          onTap: () => onRatingChanged?.call(starValue),
          child: star,
        );
      }),
    );
  }
}
