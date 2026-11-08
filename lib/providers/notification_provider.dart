import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';
import 'auth_provider.dart';

final notificationServiceProvider =
    Provider<NotificationService>((ref) => NotificationService());

final userNotificationsProvider =
    StreamProvider<List<NotificationModel>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value([]);
  return ref
      .watch(notificationServiceProvider)
      .watchUserNotifications(user.uid);
});

final unreadNotificationCountProvider = Provider<int>((ref) {
  final notificationsAsync = ref.watch(userNotificationsProvider);
  return notificationsAsync.maybeWhen(
    data: (notifications) => notifications.where((n) => !n.read).length,
    orElse: () => 0,
  );
});
