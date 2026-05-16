import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_app_new/models/conversation_model.dart';
import 'package:my_app_new/models/message_model.dart';
import 'package:my_app_new/services/ai_service.dart';
import 'package:my_app_new/services/database_service.dart';

class ChatProvider extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  final AIService _aiService = AIService();

  // messages ปัจจุบัน
  final List<MessageModel> _messages = [];
  List<MessageModel> get messages => _messages;

  // conversations ทั้งหมด
  List<ConversationModel> _conversations = [];
  List<ConversationModel> get conversations => _conversations;

  // conversation ที่เปิดอยู่
  String? _currentConversationId;
  String? get currentConversationId => _currentConversationId;

  bool _isTyping = false;
  bool get isTyping => _isTyping;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? get _userId => FirebaseAuth.instance.currentUser?.uid;

  // =========================
  // โหลด conversations
  // =========================
  void loadConversations() {
    if (_userId == null) return;

    _dbService.getConversations(_userId!).listen((data) {
      _conversations = data;
      notifyListeners();
    });
  }

  // =========================
  // สร้าง chat ใหม่
  // =========================
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
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // =========================
  // เปิด conversation
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
        .listen((data) {
      _messages.clear();
      _messages.addAll(data);
      notifyListeners();
    });
  }

  // =========================
  // ลบ conversation (FIXED)
  // =========================
  Future<void> deleteConversation(String conversationId) async {
    if (_userId == null) return;

    await _dbService.deleteConversation(
      _userId!,
      conversationId,
    );

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

    if (_currentConversationId == null) {
      await startNewChat();
    }

    final conversationId = _currentConversationId!;

    final userMessage = MessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content.trim(),
      role: 'user',
      timestamp: DateTime.now(),
      conversationId: conversationId,
    );

    _messages.add(userMessage);
    notifyListeners();

    await _dbService.saveMessage(
      userId: _userId!,
      conversationId: conversationId,
      message: userMessage,
    );

    _isTyping = true;
    notifyListeners();

    String reply;

    try {
      reply = await _aiService.sendMessage(
        message: content,
        userId: _userId!,
      );
    } catch (e) {
      reply = '⚠️ ${e.toString()}';
    }

    final botMessage = MessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: reply,
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
  }
}
