import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/review_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/order_provider.dart';
import '../../../providers/review_provider.dart';
import 'rating_star.dart';
import 'review_form.dart';
import 'review_gate_dialog.dart';

/// Opens the review submission modal for [productId].
Future<void> showReviewFormDialog({
  required BuildContext context,
  required String productId,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.72),
    builder: (dialogContext) => Dialog(
      backgroundColor: AppColors.secondarySurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.border),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          child: ReviewForm(
            productId: productId,
            onSubmitted: () => Navigator.of(dialogContext).pop(),
          ),
        ),
      ),
    ),
  );
}

/// Product-details flow: only opens the form after confirming the signed-in
/// customer has a completed/delivered order containing [productId].
Future<void> openVerifiedReviewFlow({
  required BuildContext context,
  required WidgetRef ref,
  required String productId,
}) async {
  final user = ref.read(authStateProvider).valueOrNull;
  if (user == null) {
    await showReviewGateDialog(context);
    return;
  }

  bool eligible;
  try {
    eligible = await ref
        .read(orderServiceProvider)
        .hasCompletedPurchase(userId: user.uid, productId: productId);
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Could not verify your purchase: $e'),
        backgroundColor: AppColors.error,
      ),
    );
    return;
  }

  if (!context.mounted) return;
  if (!eligible) {
    await showReviewGateDialog(context);
    return;
  }

  await showReviewFormDialog(context: context, productId: productId);
}

/// Order-history flow: the order is already completed, so this opens the form
/// directly — or shows the existing review read-only if one is already saved.
Future<void> openOrderReviewFlow({
  required BuildContext context,
  required WidgetRef ref,
  required String productId,
}) async {
  final user = ref.read(authStateProvider).valueOrNull;
  if (user == null) {
    await showReviewGateDialog(context);
    return;
  }

  ReviewModel? existing;
  try {
    existing = await ref
        .read(reviewServiceProvider)
        .fetchUserReview(productId: productId, userId: user.uid);
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Could not load your review: $e'),
        backgroundColor: AppColors.error,
      ),
    );
    return;
  }

  if (!context.mounted) return;

  if (existing != null) {
    await showExistingReviewDialog(context: context, review: existing);
    return;
  }

  await showReviewFormDialog(context: context, productId: productId);
  ref.invalidate(userReviewForProductProvider(productId));
}

/// Read-only modal for an already-submitted review.
Future<void> showExistingReviewDialog({
  required BuildContext context,
  required ReviewModel review,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.72),
    builder: (ctx) => Dialog(
      backgroundColor: AppColors.secondarySurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.border),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'YOUR REVIEW',
                      style: TextStyle(
                        color: AppColors.secondaryText,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      icon: const Icon(Icons.close, size: 18),
                      color: AppColors.secondaryText,
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                RatingStars(rating: review.rating, size: 22),
                const SizedBox(height: 14),
                Text(
                  review.comment.trim().isEmpty
                      ? 'No written comment.'
                      : review.comment,
                  style: const TextStyle(
                    color: AppColors.secondaryText,
                    height: 1.5,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Submitted ${review.createdAt.month}/${review.createdAt.day}/${review.createdAt.year}',
                  style: const TextStyle(
                    color: AppColors.tertiaryText,
                    fontSize: 11.5,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('CLOSE'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
