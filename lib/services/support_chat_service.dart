import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/support_chat_model.dart';
import '../models/support_message_model.dart';

class SupportChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _chats =>
      _firestore.collection('support_chats');

  CollectionReference<Map<String, dynamic>> _messages(String chatId) =>
      _chats.doc(chatId).collection('messages');

  /// Streams messages for a chat (chatId == userId). Sorted client-side to
  /// avoid requiring a composite index on the subcollection.
  Stream<List<SupportMessageModel>> watchMessages(String chatId) {
    return _messages(chatId).snapshots().map((snap) {
      final items = snap.docs
          .map((d) => SupportMessageModel.fromMap(d.data(), d.id))
          .toList();
      items.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return items;
    });
  }

  Stream<SupportChatModel?> watchChat(String chatId) {
    return _chats.doc(chatId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return SupportChatModel.fromMap(doc.data()!, doc.id);
    });
  }

  Future<void> ensureChatExists({
    required String userId,
    required String userName,
    required String userEmail,
  }) async {
    final ref = _chats.doc(userId);
    final snap = await ref.get();
    if (snap.exists) {
      // Keep profile info reasonably fresh.
      await ref.set(
        {
          'userId': userId,
          'userName': userName,
          'userEmail': userEmail,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      return;
    }
    await ref.set({
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'lastMessage': '',
      'lastMessageAt': null,
      'lastSender': '',
      'unreadByAdmin': 0,
      'unreadByCustomer': 0,
      'status': 'open',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> sendCustomerMessage({
    required String userId,
    required String userName,
    required String userEmail,
    required String text,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    await ensureChatExists(
      userId: userId,
      userName: userName,
      userEmail: userEmail,
    );

    final chatRef = _chats.doc(userId);
    final msgRef = _messages(userId).doc();
    final batch = _firestore.batch();

    batch.set(msgRef, {
      'senderId': userId,
      'senderRole': 'customer',
      'senderName': userName.isNotEmpty ? userName : 'Customer',
      'text': trimmed,
      'createdAt': FieldValue.serverTimestamp(),
      'readByAdmin': false,
      'readByCustomer': true,
    });

    batch.set(
      chatRef,
      {
        'userId': userId,
        'userName': userName.isNotEmpty ? userName : 'Customer',
        'userEmail': userEmail,
        'lastMessage': trimmed.length > 120 ? '${trimmed.substring(0, 120)}…' : trimmed,
        'lastMessageAt': FieldValue.serverTimestamp(),
        'lastSender': 'customer',
        'unreadByAdmin': FieldValue.increment(1),
        'status': 'open',
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    try {
      await batch.commit();
      debugPrint('SupportChatService: customer message sent chat=$userId');
    } catch (e, st) {
      debugPrint('SupportChatService: send failed $e\n$st');
      rethrow;
    }
  }

  /// Marks admin replies as read by the customer and clears unread counter.
  Future<void> markReadByCustomer(String chatId) async {
    try {
      final chatRef = _chats.doc(chatId);
      final unread = await _messages(chatId)
          .where('senderRole', isEqualTo: 'admin')
          .where('readByCustomer', isEqualTo: false)
          .get();
      final batch = _firestore.batch();
      for (final d in unread.docs) {
        batch.update(d.reference, {'readByCustomer': true});
      }
      batch.set(
        chatRef,
        {'unreadByCustomer': 0, 'updatedAt': FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      );
      await batch.commit();
    } catch (e, st) {
      debugPrint('SupportChatService: markReadByCustomer failed $e\n$st');
    }
  }
}
