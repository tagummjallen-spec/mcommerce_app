import 'package:cloud_firestore/cloud_firestore.dart';

class SupportChatModel {
  final String id; // same as userId
  final String userId;
  final String userName;
  final String userEmail;
  final String lastMessage;
  final DateTime? lastMessageAt;
  final String lastSender; // 'customer' | 'admin'
  final int unreadByAdmin;
  final int unreadByCustomer;
  final String status; // 'open' | 'closed'
  final DateTime? createdAt;

  const SupportChatModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.lastMessage,
    required this.lastSender,
    this.lastMessageAt,
    this.unreadByAdmin = 0,
    this.unreadByCustomer = 0,
    this.status = 'open',
    this.createdAt,
  });

  static DateTime? _parseDate(dynamic raw) {
    if (raw is Timestamp) return raw.toDate();
    if (raw is DateTime) return raw;
    if (raw != null) return DateTime.tryParse(raw.toString());
    return null;
  }

  factory SupportChatModel.fromMap(Map<String, dynamic> map, String id) {
    return SupportChatModel(
      id: id,
      userId: map['userId']?.toString() ?? id,
      userName: map['userName']?.toString() ?? 'Customer',
      userEmail: map['userEmail']?.toString() ?? '',
      lastMessage: map['lastMessage']?.toString() ?? '',
      lastMessageAt: _parseDate(map['lastMessageAt']),
      lastSender: map['lastSender']?.toString() ?? '',
      unreadByAdmin: (map['unreadByAdmin'] as num?)?.toInt() ?? 0,
      unreadByCustomer: (map['unreadByCustomer'] as num?)?.toInt() ?? 0,
      status: map['status']?.toString() ?? 'open',
      createdAt: _parseDate(map['createdAt']),
    );
  }
}
