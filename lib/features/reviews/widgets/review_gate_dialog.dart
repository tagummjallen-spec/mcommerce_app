import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

/// Shown when a customer is not allowed to review a product because they are
/// signed out or have no completed/delivered order containing it.
Future<void> showReviewGateDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.72),
    builder: (ctx) => Dialog(
      backgroundColor: AppColors.secondarySurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppColors.border),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.primaryAccent.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primaryAccent.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Icon(
                    Icons.verified_user_outlined,
                    color: AppColors.primaryAccent,
                    size: 34,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'VERIFIED REVIEWS ONLY',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.primaryText,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Reviews come after delivery. You can review this product '
                  'once an order containing it is completed. Thanks for helping '
                  'us keep reviews verified.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.secondaryText,
                    height: 1.55,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('GOT IT'),
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
