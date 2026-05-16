import 'package:cloud_firestore/cloud_firestore.dart';

class ConversationModel {
  final String id;
  final String title;
  final String lastMessage;
  final DateTime updatedAt;

  ConversationModel({
    required this.id,
    required this.title,
    required this.lastMessage,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'lastMessage': lastMessage,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory ConversationModel.fromMap(Map<String, dynamic> map) {
    return ConversationModel(
      id: map['id'] ?? '',
      title: map['title'] ?? 'แชทใหม่',
      lastMessage: map['lastMessage'] ?? '',
      updatedAt: map['updatedAt'] is Timestamp
          ? (map['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }
}