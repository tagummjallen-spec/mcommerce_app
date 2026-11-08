import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/review_model.dart';

class ReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _reviewsRef => _firestore.collection('reviews');

  Stream<List<ReviewModel>> watchProductReviews(String productId) {
    return _reviewsRef.where('productId', isEqualTo: productId).snapshots().map(
      (snapshot) {
        // Hide reviews moderated by an admin. Filtering client-side keeps
        // legacy reviews (which lack `isHidden`) visible.
        final reviews = snapshot.docs
            .map(
              (doc) => ReviewModel.fromMap(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ),
            )
            .where((review) => !review.isHidden)
            .toList();
        reviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return reviews;
      },
    );
  }

  Future<void> addReview({
    required String productId,
    required String userId,
    required String userName,
    required double rating,
    required String comment,
  }) async {
    // Check if user already reviewed this product
    final existing = await _reviewsRef
        .where('productId', isEqualTo: productId)
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      // Update existing review
      await _reviewsRef.doc(existing.docs.first.id).update({
        'rating': rating.clamp(1.0, 5.0),
        'comment': comment,
        'userName': userName,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      await _reviewsRef.add({
        'productId': productId,
        'userId': userId,
        'userName': userName,
        'rating': rating.clamp(1.0, 5.0),
        'comment': comment,
        'isHidden': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Returns the user's existing review for [productId], including reviews
  /// hidden by an admin (used to prevent duplicate submissions).
  Future<ReviewModel?> fetchUserReview({
    required String productId,
    required String userId,
  }) async {
    if (productId.isEmpty || userId.isEmpty) return null;

    final snapshot = await _reviewsRef
        .where('productId', isEqualTo: productId)
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    final doc = snapshot.docs.first;
    return ReviewModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  Future<void> deleteReview(String reviewId) async {
    await _reviewsRef.doc(reviewId).delete();
  }
}
