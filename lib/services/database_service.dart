import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_app_new/models/conversation_model.dart';
import 'package:my_app_new/models/message_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─────────────────────────────
  // USER PROFILE
  // ─────────────────────────────

  // บันทึกข้อมูล User
  Future<void> saveUserProfile(dynamic user) async {
    try {
      await _db.collection('users').doc(user.uid).set(user.toMap());
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    } catch (e) {
      throw 'บันทึกข้อมูลไม่สำเร็จ กรุณาลองใหม่อีกครั้ง';
    }
  }

  // เช็คว่ามีข้อมูล User ไหม
  Future<bool> hasUserProfile(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      return doc.exists;
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    } catch (e) {
      return false;
    }
  }

  // ดึงข้อมูล User
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) return doc.data();
      return null;
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    } catch (e) {
      return null;
    }
  }

  // ─────────────────────────────
  // CONVERSATIONS
  // ─────────────────────────────

  // สร้าง Conversation ใหม่
  Future<String> createConversation(String userId, String title) async {
    try {
      final ref = _db
          .collection('conversations')
          .doc(userId)
          .collection('chats')
          .doc();

      final conversation = ConversationModel(
        id: ref.id,
        title: title,
        lastMessage: '',
        updatedAt: DateTime.now(),
      );

      await ref.set(conversation.toMap());
      return ref.id;
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    } catch (e) {
      throw 'สร้างแชทใหม่ไม่สำเร็จ';
    }
  }

  // ดึงรายการ Conversations ทั้งหมด
  Stream<List<ConversationModel>> getConversations(String userId) {
    return _db
        .collection('conversations')
        .doc(userId)
        .collection('chats')
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ConversationModel.fromMap(doc.data()))
              .toList(),
        );
  }

  // อัปเดต Conversation title และ lastMessage
  Future<void> updateConversation({
    required String userId,
    required String conversationId,
    required String lastMessage,
    String? title,
  }) async {
    try {
      final data = {
        'lastMessage': lastMessage,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };
      if (title != null) data['title'] = title;

      await _db
          .collection('conversations')
          .doc(userId)
          .collection('chats')
          .doc(conversationId)
          .update(data);
    } catch (e) {
      // ไม่ต้อง throw เพราะไม่ critical
    }
  }

  // ลบ Conversation
  Future<void> deleteConversation(String userId, String conversationId) async {
    try {
      // ลบข้อความทั้งหมดใน Conversation
      final messages = await _db
          .collection('conversations')
          .doc(userId)
          .collection('chats')
          .doc(conversationId)
          .collection('messages')
          .get();

      for (final doc in messages.docs) {
        await doc.reference.delete();
      }

      // ลบ Conversation
      await _db
          .collection('conversations')
          .doc(userId)
          .collection('chats')
          .doc(conversationId)
          .delete();
    } catch (e) {
      throw 'ลบแชทไม่สำเร็จ';
    }
  }

  // ─────────────────────────────
  // MESSAGES
  // ─────────────────────────────

  // บันทึกข้อความ
  // บันทึกข้อความ
  Future<void> saveMessage({
    required String userId,
    required String conversationId,
    required MessageModel message,
  }) async {
    try {
      await _db
          .collection('conversations')
          .doc(userId)
          .collection('chats')
          .doc(conversationId)
          .collection('messages')
          .doc(message.id)
          .set(message.toMap());
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    } catch (e) {
      throw 'บันทึกข้อความไม่สำเร็จ';
    }
  }

  // โหลดข้อความใน Conversation
  Stream<List<MessageModel>> getMessages({
    required String userId,
    required String conversationId,
  }) {
    return _db
        .collection('conversations')
        .doc(userId)
        .collection('chats')
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => MessageModel.fromMap(doc.data()))
              .toList(),
        );
  }

  // ลบประวัติแชทเก่า (โครงสร้างเก่า)
  Future<void> clearHistory(String userId) async {
    try {
      final messages = await _db
          .collection('conversations')
          .doc(userId)
          .collection('messages')
          .get();
      for (final doc in messages.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      // ไม่ต้อง throw
    }
  }

  // แปลง Firestore Error เป็นข้อความภาษาไทย
  String _handleFirestoreError(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return 'ไม่มีสิทธิ์เข้าถึงข้อมูล กรุณา Login ใหม่';
      case 'unavailable':
        return 'เซิร์ฟเวอร์ไม่พร้อมใช้งาน กรุณาลองใหม่ภายหลัง';
      case 'not-found':
        return 'ไม่พบข้อมูลที่ต้องการ';
      case 'already-exists':
        return 'ข้อมูลนี้มีอยู่แล้ว';
      case 'cancelled':
        return 'การดำเนินการถูกยกเลิก';
      case 'deadline-exceeded':
        return 'การเชื่อมต่อใช้เวลานานเกินไป กรุณาลองใหม่';
      default:
        return 'เกิดข้อผิดพลาด: ${e.message}';
    }
  }
}
