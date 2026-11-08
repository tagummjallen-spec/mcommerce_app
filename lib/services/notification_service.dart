import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _notificationsRef =>
      _firestore.collection('notifications');

  Stream<List<NotificationModel>> watchUserNotifications(String userId) {
    return _notificationsRef
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final notifications = snapshot.docs
          .map((doc) => NotificationModel.fromMap(
              doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return notifications;
    });
  }

  Future<void> markAsRead(String notificationId) async {
    await _notificationsRef.doc(notificationId).update({'read': true});
  }

  Future<void> markAllAsRead(String userId) async {
    final snapshot = await _notificationsRef
        .where('userId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .get();
    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();
  }

  Future<void> createNotification({
    required String userId,
    required String title,
    required String body,
    String type = 'system',
  }) async {
    await _notificationsRef.add({
      'userId': userId,
      'title': title,
      'body': body,
      'type': type,
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
