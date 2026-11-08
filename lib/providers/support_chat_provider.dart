import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/support_chat_model.dart';
import '../models/support_message_model.dart';
import '../services/support_chat_service.dart';
import 'auth_provider.dart';

final supportChatServiceProvider =
    Provider<SupportChatService>((ref) => SupportChatService());

final mySupportChatProvider = StreamProvider<SupportChatModel?>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value(null);
  return ref.watch(supportChatServiceProvider).watchChat(user.uid);
});

final mySupportMessagesProvider =
    StreamProvider<List<SupportMessageModel>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value(const <SupportMessageModel>[]);
  return ref.watch(supportChatServiceProvider).watchMessages(user.uid);
});

final supportUnreadByCustomerProvider = Provider<int>((ref) {
  final chat = ref.watch(mySupportChatProvider).valueOrNull;
  return chat?.unreadByCustomer ?? 0;
});
