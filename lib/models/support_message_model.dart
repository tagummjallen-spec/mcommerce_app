import 'package:cloud_firestore/cloud_firestore.dart';

class SupportMessageModel {
  final String id;
  final String senderId;
  final String senderRole; // 'customer' | 'admin'
  final String senderName;
  final String text;
  final DateTime createdAt;
  final bool readByAdmin;
  final bool readByCustomer;

  const SupportMessageModel({
    required this.id,
    required this.senderId,
    required this.senderRole,
    required this.senderName,
    required this.text,
    required this.createdAt,
    this.readByAdmin = false,
    this.readByCustomer = false,
  });

  factory SupportMessageModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime createdAt = DateTime.now();
    final raw = map['createdAt'];
    if (raw is Timestamp) {
      createdAt = raw.toDate();
    } else if (raw is DateTime) {
      createdAt = raw;
    } else if (raw != null) {
      createdAt = DateTime.tryParse(raw.toString()) ?? DateTime.now();
    }

    return SupportMessageModel(
      id: id,
      senderId: map['senderId']?.toString() ?? '',
      senderRole: map['senderRole']?.toString() ?? 'customer',
      senderName: map['senderName']?.toString() ?? '',
      text: map['text']?.toString() ?? '',
      createdAt: createdAt,
      readByAdmin: map['readByAdmin'] == true,
      readByCustomer: map['readByCustomer'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'senderId': senderId,
      'senderRole': senderRole,
      'senderName': senderName,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
      'readByAdmin': readByAdmin,
      'readByCustomer': readByCustomer,
    };
  }
}
