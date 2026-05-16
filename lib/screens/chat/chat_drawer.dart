import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:my_app_new/core/constants/app_colors.dart';
import 'package:my_app_new/core/widgets/user_avatar.dart';
import 'package:my_app_new/models/conversation_model.dart';
import 'package:my_app_new/providers/chat_provider.dart';
import 'package:my_app_new/screens/settings/settings_screen.dart';
import 'package:provider/provider.dart';

class ChatDrawer extends StatelessWidget {
  const ChatDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Drawer(
      backgroundColor: isDark
          ? const Color(0xFF1E1E2E) // Dark mode → สีเข้ม
          : Colors.white, // Light mode → สีขาว
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(isDark),
            _buildNewChatButton(context),
            const SizedBox(height: 8),
            Expanded(child: _buildConversationList(context, isDark)),
            Divider(color: isDark ? Colors.white12 : Colors.grey.shade200),
            _buildSettingsButton(context, isDark),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // Header
  Widget _buildHeader(bool isDark) {
    final user = FirebaseAuth.instance.currentUser;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Avatar
          UserAvatar(
            imageUrl: user?.photoURL,
            nickname: user?.displayName,
            size: 40,
          ),

          const SizedBox(width: 12),

          // ชื่อ
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.displayName ?? 'MindMate',
                  style: TextStyle(
                    color: isDark ? Colors.white : AppColors.textPrimaryLight,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  user?.email ?? '',
                  style: TextStyle(
                    color: isDark
                        ? Colors.white38
                        : AppColors.textSecondaryLight,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ปุ่มแชทใหม่
  Widget _buildNewChatButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: ElevatedButton.icon(
        onPressed: () {
          context.read<ChatProvider>().startNewChat();
          Navigator.pop(context); // ปิด Drawer
        },
        icon: const Icon(Icons.add, size: 18),
        label: const Text('แชทใหม่'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  // รายการแชทเก่า
  Widget _buildConversationList(BuildContext context, bool isDark) {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, _) {
        final conversations = chatProvider.conversations;

        if (conversations.isEmpty) {
          return Center(
            child: Text(
              'ยังไม่มีประวัติแชท',
              style: TextStyle(
                color: isDark ? Colors.white38 : Colors.grey.shade400,
                fontSize: 14,
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          itemCount: conversations.length,
          itemBuilder: (context, index) {
            return _buildConversationTile(
              context,
              conversations[index],
              chatProvider,
              isDark,
            );
          },
        );
      },
    );
  }

  // แต่ละรายการแชท
  Widget _buildConversationTile(
    BuildContext context,
    ConversationModel conversation,
    ChatProvider chatProvider,
    bool isDark,
  ) {
    final isSelected = chatProvider.currentConversationId == conversation.id;

    return GestureDetector(
      onLongPress: () => _showDeleteDialog(context, conversation, chatProvider),
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: ListTile(
          dense: true,
          leading: Icon(
            Icons.chat_bubble_outline,
            color: isDark ? Colors.white54 : Colors.grey.shade500,
            size: 18,
          ),
          title: Text(
            conversation.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isSelected
                  ? AppColors.primary
                  : isDark
                  ? Colors.white70
                  : AppColors.textPrimaryLight,
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          subtitle: conversation.lastMessage.isNotEmpty
              ? Text(
                  conversation.lastMessage,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isDark ? Colors.white38 : Colors.grey.shade500,
                    fontSize: 12,
                  ),
                )
              : null,
          onTap: () {
            chatProvider.openConversation(conversation.id);
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  // Dialog ยืนยันการลบ
  void _showDeleteDialog(
    BuildContext context,
    ConversationModel conversation,
    ChatProvider chatProvider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ลบแชทนี้?'),
        content: Text('ต้องการลบ "${conversation.title}" ใช่ไหม?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () {
              chatProvider.deleteConversation(conversation.id);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );
  }

  // ปุ่ม Settings
  Widget _buildSettingsButton(BuildContext context, bool isDark) {
    return ListTile(
      leading: Icon(
        Icons.settings_outlined,
        color: isDark ? Colors.white54 : Colors.grey.shade600,
      ),
      title: Text(
        'ตั้งค่า',
        style: TextStyle(
          color: isDark ? Colors.white70 : AppColors.textPrimaryLight,
          fontSize: 14,
        ),
      ),
      onTap: () {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SettingsScreen()),
        );
      },
    );
  }
}
