import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_app_new/core/constants/app_colors.dart';
import 'package:my_app_new/models/user_model.dart';
import 'package:my_app_new/screens/chat/chat_screen.dart';
import 'package:my_app_new/services/database_service.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nicknameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _ageController = TextEditingController();

  // Services
  final _dbService = DatabaseService();

  // State
  bool _isLoading = false;
  String _selectedGender = 'ไม่ระบุ';

  // ตัวเลือกเพศ
  final List<String> _genders = ['ชาย', 'หญิง', 'ไม่ระบุ'];

  // ปัญหาที่เลือกได้หลายอย่าง
  final List<String> _allProblems = [
    'ความเครียด',
    'ซึมเศร้า',
    'ความวิตกกังวล',
    'นอนไม่หลับ',
    'เหงา',
    'ปัญหาความสัมพันธ์',
    'ปัญหาการทำงาน',
    'ปัญหาครอบครัว',
    'อื่นๆ',
  ];
  final List<String> _selectedProblems = [];

  @override
  void dispose() {
    _nicknameController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  // บันทึกข้อมูลลง Firestore
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProblems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณาเลือกปัญหาที่เผชิญอยู่อย่างน้อย 1 อย่าง'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final userModel = UserModel(
        uid: user.uid,
        email: user.email ?? '',
        nickname: _nicknameController.text.trim(),
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        age: int.parse(_ageController.text.trim()),
        gender: _selectedGender,
        problems: _selectedProblems,
        createdAt: DateTime.now(),
      );

      await _dbService.saveUserProfile(userModel);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('บันทึกข้อมูลสำเร็จ! 🎉'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ChatScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 48),
                _buildHeader(),
                const SizedBox(height: 32),
                _buildNicknameField(),
                const SizedBox(height: 16),
                _buildFirstNameField(),
                const SizedBox(height: 16),
                _buildLastNameField(),
                const SizedBox(height: 16),
                _buildAgeField(),
                const SizedBox(height: 16),
                _buildGenderSelector(),
                const SizedBox(height: 24),
                _buildProblemsSelector(),
                const SizedBox(height: 32),
                _buildSaveButton(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget: Header
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.person_outline,
            color: Colors.white,
            size: 28,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'บอกเราเกี่ยวกับตัวคุณ',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimaryLight,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'เพื่อให้เราดูแลคุณได้ดียิ่งขึ้น',
          style: TextStyle(fontSize: 16, color: AppColors.textSecondaryLight),
        ),
      ],
    );
  }

  // Widget: Nickname Field
  Widget _buildNicknameField() {
    return TextFormField(
      controller: _nicknameController,
      validator: (v) =>
          v == null || v.isEmpty ? 'กรุณากรอกชื่อที่ใช้แสดง' : null,
      decoration: _inputDecoration(
        'ชื่อที่ใช้แสดง (Nickname)',
        Icons.badge_outlined,
      ),
    );
  }

  // Widget: First Name Field
  Widget _buildFirstNameField() {
    return TextFormField(
      controller: _firstNameController,
      validator: (v) => v == null || v.isEmpty ? 'กรุณากรอกชื่อจริง' : null,
      decoration: _inputDecoration('ชื่อจริง', Icons.person_outline),
    );
  }

  // Widget: Last Name Field
  Widget _buildLastNameField() {
    return TextFormField(
      controller: _lastNameController,
      validator: (v) => v == null || v.isEmpty ? 'กรุณากรอกนามสกุล' : null,
      decoration: _inputDecoration('นามสกุล', Icons.person_outline),
    );
  }

  // Widget: Age Field
  Widget _buildAgeField() {
    return TextFormField(
      controller: _ageController,
      keyboardType: TextInputType.number,
      validator: (v) {
        if (v == null || v.isEmpty) return 'กรุณากรอกอายุ';
        final age = int.tryParse(v);
        if (age == null || age < 1 || age > 120)
          return 'กรุณากรอกอายุให้ถูกต้อง';
        return null;
      },
      decoration: _inputDecoration('อายุ', Icons.cake_outlined),
    );
  }

  // Widget: Gender Selector
  Widget _buildGenderSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'เพศ',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimaryLight,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: _genders.map((gender) {
            final isSelected = _selectedGender == gender;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _selectedGender = gender),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: Text(
                      gender,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : AppColors.textPrimaryLight,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // Widget: Problems Selector
  Widget _buildProblemsSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ปัญหาที่คุณกำลังเผชิญอยู่',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimaryLight,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'เลือกได้มากกว่า 1 อย่าง',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondaryLight),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _allProblems.map((problem) {
            final isSelected = _selectedProblems.contains(problem);
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedProblems.remove(problem);
                  } else {
                    _selectedProblems.add(problem);
                  }
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : Colors.grey.shade300,
                  ),
                ),
                child: Text(
                  problem,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : AppColors.textPrimaryLight,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // Widget: Save Button
  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
                'เริ่มต้นใช้งาน 🚀',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }

  // Helper: Input Decoration
  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: AppColors.primary),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      filled: true,
      fillColor: AppColors.surfaceLight,
    );
  }
}
