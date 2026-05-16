import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_app_new/models/conversation_model.dart';
import 'package:my_app_new/models/message_model.dart';
import 'package:my_app_new/services/ai_service.dart';
import 'package:my_app_new/services/database_service.dart';

class ChatProvider extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  final AIService _aiService = AIService();

  // ข้อความใน Conversation ปัจจุบัน
  final List<MessageModel> _messages = [];
  List<MessageModel> get messages => _messages;

  // รายการ Conversations ทั้งหมด
  List<ConversationModel> _conversations = [];
  List<ConversationModel> get conversations => _conversations;

  // Conversation ที่เปิดอยู่
  String? _currentConversationId;
  String? get currentConversationId => _currentConversationId;

  bool _isTyping = false;
  bool get isTyping => _isTyping;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? get _userId => FirebaseAuth.instance.currentUser?.uid;

  // โหลดรายการ Conversations ทั้งหมด
  void loadConversations() {
    if (_userId == null) return;

    _dbService.getConversations(_userId!).listen((conversations) {
      _conversations = conversations;
      notifyListeners();
    });
  }

  // สร้าง Conversation ใหม่
  Future<void> startNewChat() async {
    if (_userId == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final id = await _dbService.createConversation(
        _userId!,
        'แชทใหม่',
      );

      await openConversation(id);
    } catch (e) {
      // handle error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // เปิด Conversation ที่มีอยู่แล้ว
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

  // ลบ Conversation
  Future<void> deleteConversation(String conversationId) async {
    if (_userId == null) return;

    await _dbService.deleteConversation(
      _userId!,
      conversationId,
    );

    // ถ้าลบห้องที่กำลังเปิดอยู่
    if (_currentConversationId == conversationId) {
      _currentConversationId = null;
      _messages.clear();
    }

    notifyListeners();
  }

  // ส่งข้อความ
  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;
    if (_userId == null) return;

    // ถ้ายังไม่มี Conversation → สร้างใหม่อัตโนมัติ
    if (_currentConversationId == null) {
      await startNewChat();
    }

    final conversationId = _currentConversationId!;

    // ข้อความ User
    final userMessage = MessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content.trim(),
      role: 'user',
      timestamp: DateTime.now(),
      conversationId: conversationId,
    );

    _messages.add(userMessage);
    notifyListeners();

    // บันทึกลง Database
    await _dbService.saveMessage(
      userId: _userId!,
      conversationId: conversationId,
      message: userMessage,
    );

    // อัปเดต Title ของ Conversation
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

    // Typing indicator
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
      botReply = '⚠️ ${e.toString()}';
    }

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

    await _dbService.saveMessage(
      userId: _userId!,
      conversationId: conversationId,
      message: botMessage,
    );

    await _dbService.updateConversation(
      userId: _userId!,
      conversationId: conversationId,
      lastMessage: botMessage.content,
    );
  }
}
