import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/review_model.dart';
import 'rating_star.dart';

class ReviewCard extends StatelessWidget {
  final ReviewModel review;
  const ReviewCard({super.key, required this.review});

  String _formatDate(DateTime d) =>
      '${d.month}/${d.day}/${d.year}';

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.secondarySurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  review.userName,
                  style: const TextStyle(
                    color: AppColors.primaryText,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                _formatDate(review.createdAt),
                style: const TextStyle(
                  color: AppColors.tertiaryText,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          RatingStars(rating: review.rating),
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              review.comment,
              style: const TextStyle(
                color: AppColors.secondaryText,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
