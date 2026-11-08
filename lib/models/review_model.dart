import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  final String id;
  final String productId;
  final String userId;
  final String userName;
  final double rating;
  final String comment;
  final DateTime createdAt;
  final bool isHidden;

  ReviewModel({
    required this.id,
    required this.productId,
    required this.userId,
    required this.userName,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.isHidden = false,
  });

  factory ReviewModel.fromMap(Map<String, dynamic> map, String id) {
    double parsedRating = 0.0;
    final r = map['rating'];
    if (r is num) {
      parsedRating = r.toDouble();
    } else if (r != null) {
      parsedRating = double.tryParse(r.toString()) ?? 0.0;
    }
    parsedRating = parsedRating.clamp(1.0, 5.0);

    DateTime parsedCreatedAt = DateTime.now();
    if (map['createdAt'] is Timestamp) {
      parsedCreatedAt = (map['createdAt'] as Timestamp).toDate();
    } else if (map['createdAt'] != null) {
      parsedCreatedAt =
          DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now();
    }

    return ReviewModel(
      id: id,
      productId: map['productId']?.toString() ?? '',
      userId: map['userId']?.toString() ?? '',
      userName: map['userName']?.toString() ?? 'Anonymous',
      rating: parsedRating,
      comment: map['comment']?.toString() ?? '',
      createdAt: parsedCreatedAt,
      isHidden: map['isHidden'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'userId': userId,
      'userName': userName,
      'rating': rating,
      'comment': comment,
      'isHidden': isHidden,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
