import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/review_provider.dart';
import 'rating_star.dart';

class ReviewForm extends ConsumerStatefulWidget {
  final String productId;
  final VoidCallback? onSubmitted;
  const ReviewForm({super.key, required this.productId, this.onSubmitted});

  @override
  ConsumerState<ReviewForm> createState() => _ReviewFormState();
}

class _ReviewFormState extends ConsumerState<ReviewForm> {
  int _rating = 5;
  final _commentController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;
    final profile = ref.read(currentUserProfileProvider).valueOrNull;
    final userName =
        profile?.fullName ??
        user.displayName ??
        user.email?.split('@').first ??
        'User';

    setState(() => _submitting = true);
    try {
      await ref
          .read(reviewServiceProvider)
          .addReview(
            productId: widget.productId,
            userId: user.uid,
            userName: userName,
            rating: _rating.toDouble(),
            comment: _commentController.text.trim(),
          );
      _commentController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Review submitted!'),
            backgroundColor: AppColors.success,
          ),
        );
        widget.onSubmitted?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit review: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).valueOrNull;
    if (user == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.secondarySurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          'Log in to write a review.',
          style: TextStyle(color: AppColors.secondaryText),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.secondarySurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'WRITE A REVIEW',
            style: TextStyle(
              color: AppColors.secondaryText,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Flexible(
                child: Text(
                  'Your rating: ',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: AppColors.primaryText),
                ),
              ),
              RatingStars(
                rating: _rating.toDouble(),
                size: 24,
                interactive: true,
                onRatingChanged: (v) => setState(() => _rating = v),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _commentController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Share your thoughts about this product...',
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('SUBMIT REVIEW'),
            ),
          ),
        ],
      ),
    );
  }
}
