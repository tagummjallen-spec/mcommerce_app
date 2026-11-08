import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String body;
  final String type; // order, promo, system, review
  final bool read;
  final DateTime createdAt;

  /// Related order id for order-status notifications, if any.
  final String? orderId;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    required this.read,
    required this.createdAt,
    this.orderId,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime parsedCreatedAt = DateTime.now();
    if (map['createdAt'] is Timestamp) {
      parsedCreatedAt = (map['createdAt'] as Timestamp).toDate();
    } else if (map['createdAt'] != null) {
      parsedCreatedAt =
          DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now();
    }

    final rawOrderId = map['orderId']?.toString().trim();

    return NotificationModel(
      id: id,
      userId: map['userId']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      body: map['body']?.toString() ?? '',
      type: map['type']?.toString() ?? 'system',
      read: map['read'] is bool ? map['read'] as bool : false,
      createdAt: parsedCreatedAt,
      orderId: (rawOrderId == null || rawOrderId.isEmpty) ? null : rawOrderId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'body': body,
      'type': type,
      'read': read,
      'createdAt': FieldValue.serverTimestamp(),
      if (orderId != null) 'orderId': orderId,
    };
  }
}
