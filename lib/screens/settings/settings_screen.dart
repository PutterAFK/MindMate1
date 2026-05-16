import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_app_new/core/constants/app_colors.dart';
import 'package:my_app_new/core/widgets/user_avatar.dart';
import 'package:my_app_new/models/user_model.dart';
import 'package:my_app_new/providers/theme_provider.dart';
import 'package:my_app_new/screens/auth/login_screen.dart';
import 'package:my_app_new/services/auth_service.dart';
import 'package:my_app_new/services/database_service.dart';
import 'package:provider/provider.dart';
import 'edit_profile_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _authService = AuthService();
  final _dbService = DatabaseService();

  UserModel? _userProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  // โหลดข้อมูล User จาก Firestore
  Future<void> _loadProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final data = await _dbService.getUserProfile(uid);
      if (data != null && mounted) {
        setState(() {
          _userProfile = UserModel.fromMap(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Logout
  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ออกจากระบบ'),
        content: const Text('ต้องการออกจากระบบใช่ไหม?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _authService.signOut();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('ออกจากระบบ'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ตั้งค่า'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Card
                  _buildProfileCard(),

                  const SizedBox(height: 24),

                  // การตั้งค่า
                  _buildSectionTitle('การตั้งค่า'),
                  const SizedBox(height: 12),

                  // Dark Mode Toggle
                  _buildDarkModeToggle(isDark),

                  const SizedBox(height: 24),

                  // บัญชีผู้ใช้
                  _buildSectionTitle('บัญชีผู้ใช้'),
                  const SizedBox(height: 12),

                  // Logout Button
                  _buildLogoutButton(),
                ],
              ),
            ),
    );
  }

  // Profile Card
  Widget _buildProfileCard() {
    final user = FirebaseAuth.instance.currentUser;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryLight, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          UserAvatar(
            imageUrl: user?.photoURL,
            nickname: _userProfile?.nickname,
            size: 64,
          ),

          const SizedBox(width: 16),

          // ข้อมูล
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _userProfile?.nickname.isNotEmpty == true
                      ? _userProfile!.nickname
                      : user?.displayName ?? 'ผู้ใช้',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_userProfile?.firstName ?? ''} '
                          '${_userProfile?.lastName ?? ''}'
                      .trim(),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? '',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          // ปุ่ม Edit
          IconButton(
            onPressed: () async {
              // ไปหน้า Edit Profile แล้วรอผล
              final updated = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      EditProfileScreen(userProfile: _userProfile!),
                ),
              );
              // ถ้าอัปเดตสำเร็จ โหลดข้อมูลใหม่
              if (updated == true) _loadProfile();
            },
            icon: const Icon(Icons.edit_outlined, color: Colors.white),
          ),
        ],
      ),
    );
  }

  // Section Title
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondaryLight,
      ),
    );
  }

  // Dark Mode Toggle
  Widget _buildDarkModeToggle(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: SwitchListTile(
        secondary: Icon(
          isDark ? Icons.dark_mode : Icons.light_mode,
          color: AppColors.primary,
        ),
        title: Text(
          isDark ? 'โหมดมืด' : 'โหมดสว่าง',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          isDark ? 'ปิดหน้าจอสีเข้ม' : 'เปิดหน้าจอสีเข้ม',
          style: const TextStyle(fontSize: 12),
        ),
        value: isDark,
        activeThumbColor: AppColors.primary,
        onChanged: (_) => context.read<ThemeProvider>().toggleTheme(),
      ),
    );
  }

  // Logout Button
  Widget _buildLogoutButton() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListTile(
        leading: const Icon(Icons.logout, color: AppColors.error),
        title: const Text(
          'ออกจากระบบ',
          style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w500),
        ),
        onTap: _logout,
      ),
    );
  }
}
