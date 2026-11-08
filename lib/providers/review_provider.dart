import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/review_model.dart';
import '../services/review_service.dart';
import 'auth_provider.dart';

final reviewServiceProvider = Provider<ReviewService>((ref) => ReviewService());

final productReviewsProvider = StreamProvider.family<List<ReviewModel>, String>(
  (ref, productId) {
    return ref.watch(reviewServiceProvider).watchProductReviews(productId);
  },
);

final productRatingStatsProvider =
    Provider.family<({double average, int count}), String>((ref, productId) {
      final reviewsAsync = ref.watch(productReviewsProvider(productId));
      return reviewsAsync.maybeWhen(
        data: (reviews) {
          if (reviews.isEmpty) return (average: 0.0, count: 0);
          final avg =
              reviews.map((r) => r.rating).reduce((a, b) => a + b) /
              reviews.length;
          return (average: avg, count: reviews.length);
        },
        orElse: () => (average: 0.0, count: 0),
      );
    });

/// The signed-in user's review for [productId], regardless of moderation
/// state. Used to switch order-history buttons to "View Review" and to avoid
/// duplicate reviews.
final userReviewForProductProvider = FutureProvider.autoDispose
    .family<ReviewModel?, String>((ref, productId) async {
      final user = ref.watch(authStateProvider).valueOrNull;
      if (user == null) return null;
      return ref
          .watch(reviewServiceProvider)
          .fetchUserReview(productId: productId, userId: user.uid);
    });
