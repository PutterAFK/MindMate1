import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_app_new/models/conversation_model.dart';
import 'package:my_app_new/models/message_model.dart';
import 'package:my_app_new/services/ai_service.dart';
import 'package:my_app_new/services/database_service.dart';

class ChatProvider extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  final AIService _aiService = AIService();

  // ข้อความในห้องแชทปัจจุบัน
  final List<MessageModel> _messages = [];
  List<MessageModel> get messages => _messages;

  // รายการห้องแชททั้งหมด
  List<ConversationModel> _conversations = [];
  List<ConversationModel> get conversations => _conversations;

  // ห้องแชทที่กำลังเปิดอยู่
  String? _currentConversationId;
  String? get currentConversationId => _currentConversationId;

  // สถานะ AI กำลังตอบ
  bool _isTyping = false;
  bool get isTyping => _isTyping;

  // สถานะโหลด
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // User ID
  String? get _userId => FirebaseAuth.instance.currentUser?.uid;

  // =========================
  // โหลดรายการห้องแชททั้งหมด
  // =========================
  void loadConversations() {
    if (_userId == null) return;

    _dbService.getConversations(_userId!).listen((conversations) {
      _conversations = conversations;
      notifyListeners();
    });
  }

  // =========================
  // สร้างห้องแชทใหม่
  // =========================
  Future<void> startNewChat() async {
    if (_userId == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final conversationId = await _dbService.createConversation(
        _userId!,
        'แชทใหม่',
      );

      await openConversation(conversationId);
    } catch (e) {
      debugPrint("Create chat error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // =========================
  // เปิดห้องแชท
  // =========================
  Future<void> openConversation(String conversationId) async {
    if (_userId == null) return;

    _currentConversationId = conversationId;

    _messages.clear();
    notifyListeners();

    _dbService
        .getMessages(
          userId: _userId!,
          conversationId: conversationId,
        )
        .listen((messages) {
      _messages.clear();
      _messages.addAll(messages);
      notifyListeners();
    });
  }

  // =========================
  // ลบห้องแชท
  // =========================
  Future<void> deleteConversation(String conversationId) async {
    if (_userId == null) return;

    await _dbService.deleteConversation(
      _userId!,
      conversationId,
    );

    // ถ้าห้องที่ลบคือห้องที่กำลังเปิดอยู่
    if (_currentConversationId == conversationId) {
      _currentConversationId = null;
      _messages.clear();
    }

    notifyListeners();
  }

  // =========================
  // ส่งข้อความ
  // =========================
  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;
    if (_userId == null) return;

    // ถ้ายังไม่มีห้อง → สร้างใหม่
    if (_currentConversationId == null) {
      await startNewChat();
    }

    final conversationId = _currentConversationId!;

    // ข้อความจาก user
    final userMessage = MessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content.trim(),
      role: 'user',
      timestamp: DateTime.now(),
      conversationId: conversationId,
    );

    _messages.add(userMessage);
    notifyListeners();

    // บันทึกลง database
    await _dbService.saveMessage(
      userId: _userId!,
      conversationId: conversationId,
      message: userMessage,
    );

    // ถ้าเป็นข้อความแรก ใช้ตั้งชื่อห้อง
    final isFirstMessage = _messages.length == 1;

    await _dbService.updateConversation(
      userId: _userId!,
      conversationId: conversationId,
      lastMessage: content.trim(),
      title: isFirstMessage
          ? content.trim().substring(
              0,
              content.trim().length > 30
                  ? 30
                  : content.trim().length,
            )
          : null,
    );

    // แสดง AI typing
    _isTyping = true;
    notifyListeners();

    // เรียก AI
    String botReply;

    try {
      botReply = await _aiService.sendMessage(
        message: content,
        userId: _userId!,
      );
    } catch (e) {
      botReply = '⚠️ Error: $e';
    }

    // ข้อความจาก AI
    final botMessage = MessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: botReply,
      role: 'bot',
      timestamp: DateTime.now(),
      conversationId: conversationId,
    );

    _messages.add(botMessage);

    _isTyping = false;
    notifyListeners();

    // บันทึกข้อความ AI
    await _dbService.saveMessage(
      userId: _userId!,
      conversationId: conversationId,
      message: botMessage,
    );

    // อัปเดตข้อความล่าสุด
    await _dbService.updateConversation(
      userId: _userId!,
      conversationId: conversationId,
      lastMessage: botReply,
    );
  }
}
