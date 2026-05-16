import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:my_app_new/models/conversation_model.dart';
import 'package:my_app_new/models/message_model.dart';

import 'package:my_app_new/services/ai_service.dart';
import 'package:my_app_new/services/database_service.dart';

class ChatProvider extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  final AIService _aiService = AIService();

  // Current Messages
  final List<MessageModel> _messages = [];
  List<MessageModel> get messages => _messages;

  // All Conversations
  List<ConversationModel> _conversations = [];
  List<ConversationModel> get conversations => _conversations;

  // Current Opened Conversation
  String? _currentConversationId;
  String? get currentConversationId => _currentConversationId;

  bool _isTyping = false;
  bool get isTyping => _isTyping;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? get _userId => FirebaseAuth.instance.currentUser?.uid;

  // ============================
  // Load Conversations
  // ============================
  void loadConversations() {
    if (_userId == null) return;

    _dbService.getConversations(_userId!).listen((data) {
      _conversations = data;
      notifyListeners();
    });
  }

  // ============================
  // Create New Chat
  // ============================
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
      debugPrint('Create chat error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ============================
  // Open Existing Conversation
  // ============================
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

  // ============================
  // Delete Conversation
  // ============================
  Future<void> deleteConversation(String conversationId) async {
    if (_userId == null) return;

    try {
      await _dbService.deleteConversation(
        _userId!,
        conversationId,
      );

      // Remove from UI instantly
      _conversations.removeWhere(
        (item) => item.id == conversationId,
      );

      // If deleting current opened chat
      if (_currentConversationId == conversationId) {
        _currentConversationId = null;
        _messages.clear();
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Delete error: $e');
    }
  }

  // ============================
  // Send Message
  // ============================
  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;
    if (_userId == null) return;

    // Auto create chat
    if (_currentConversationId == null) {
      await startNewChat();
    }

    final conversationId = _currentConversationId!;

    // User message
    final userMessage = MessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content.trim(),
      role: 'user',
      timestamp: DateTime.now(),
      conversationId: conversationId,
    );

    _messages.add(userMessage);
    notifyListeners();

    // Save to database
    await _dbService.saveMessage(
      userId: _userId!,
      conversationId: conversationId,
      message: userMessage,
    );

    // Update conversation info
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

    // Typing UI
    _isTyping = true;
    notifyListeners();

    // Ask AI
    String aiReply;

    try {
      aiReply = await _aiService.sendMessage(
        message: content,
        userId: _userId!,
      );
    } catch (e) {
      aiReply = '⚠️ ${e.toString()}';
    }

    // Bot message
    final botMessage = MessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: aiReply,
      role: 'bot',
      timestamp: DateTime.now(),
      conversationId: conversationId,
    );

    _messages.add(botMessage);

    _isTyping = false;
    notifyListeners();

    // Save bot message
    await _dbService.saveMessage(
      userId: _userId!,
      conversationId: conversationId,
      message: botMessage,
    );

    // Update conversation
    await _dbService.updateConversation(
      userId: _userId!,
      conversationId: conversationId,
      lastMessage: aiReply,
    );
  }
}
