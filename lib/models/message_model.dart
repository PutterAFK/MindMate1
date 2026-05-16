import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String content;
  final String role;
  final DateTime timestamp;
  final String conversationId; // เพิ่มใหม่

  MessageModel({
    required this.id,
    required this.content,
    required this.role,
    required this.timestamp,
    required this.conversationId,
  });

  bool get isUser => role == 'user';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content': content,
      'role': role,
      'timestamp': Timestamp.fromDate(timestamp),
      'conversationId': conversationId,
    };
  }

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      id: map['id'] ?? '',
      content: map['content'] ?? '',
      role: map['role'] ?? 'user',
      timestamp: map['timestamp'] is Timestamp
          ? (map['timestamp'] as Timestamp).toDate()
          : DateTime.parse(map['timestamp']),
      conversationId: map['conversationId'] ?? '',
    );
  }
}