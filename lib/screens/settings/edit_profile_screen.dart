import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_app_new/core/constants/app_colors.dart';
import 'package:my_app_new/models/user_model.dart';
import 'package:my_app_new/services/database_service.dart';

class EditProfileScreen extends StatefulWidget {
  final UserModel userProfile;

  const EditProfileScreen({super.key, required this.userProfile});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dbService = DatabaseService();

  // Controllers
  late TextEditingController _nicknameController;
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _ageController;

  // State
  bool _isLoading = false;
  late String _selectedGender;
  late List<String> _selectedProblems;

  final List<String> _genders = ['ชาย', 'หญิง', 'ไม่ระบุ'];
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

  @override
  void initState() {
    super.initState();
    // โหลดข้อมูลเดิมมาใส่ใน Controllers
    _nicknameController = TextEditingController(
      text: widget.userProfile.nickname,
    );
    _firstNameController = TextEditingController(
      text: widget.userProfile.firstName,
    );
    _lastNameController = TextEditingController(
      text: widget.userProfile.lastName,
    );
    _ageController = TextEditingController(
      text: widget.userProfile.age.toString(),
    );
    _selectedGender = widget.userProfile.gender;
    _selectedProblems = List.from(widget.userProfile.problems);
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  // บันทึกข้อมูลที่แก้ไข
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProblems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณาเลือกปัญหาอย่างน้อย 1 อย่าง'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final updatedUser = UserModel(
        uid: uid,
        email: widget.userProfile.email,
        nickname: _nicknameController.text.trim(),
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        age: int.parse(_ageController.text.trim()),
        gender: _selectedGender,
        problems: _selectedProblems,
        createdAt: widget.userProfile.createdAt,
      );

      await _dbService.saveUserProfile(updatedUser);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('บันทึกข้อมูลสำเร็จ! ✅'),
            backgroundColor: AppColors.success,
          ),
        );
        // ส่งค่า true กลับไปบอก Settings ว่าอัปเดตแล้ว
        Navigator.pop(context, true);
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
      appBar: AppBar(
        title: const Text('แก้ไขข้อมูลส่วนตัว'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // ปุ่ม Save ด้านบนขวา
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: const Text(
              'บันทึก',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
    );
  }

  Widget _buildNicknameField() {
    return TextFormField(
      controller: _nicknameController,
      validator: (v) =>
          v == null || v.isEmpty ? 'กรุณากรอกชื่อที่ใช้แสดง' : null,
      decoration: _inputDecoration('ชื่อที่ใช้แสดง (Nickname)', Icons.badge_outlined),
    );
  }

  Widget _buildFirstNameField() {
    return TextFormField(
      controller: _firstNameController,
      validator: (v) => v == null || v.isEmpty ? 'กรุณากรอกชื่อจริง' : null,
      decoration: _inputDecoration('ชื่อจริง', Icons.person_outline),
    );
  }

  Widget _buildLastNameField() {
    return TextFormField(
      controller: _lastNameController,
      validator: (v) => v == null || v.isEmpty ? 'กรุณากรอกนามสกุล' : null,
      decoration: _inputDecoration('นามสกุล', Icons.person_outline),
    );
  }

  Widget _buildAgeField() {
    return TextFormField(
      controller: _ageController,
      keyboardType: TextInputType.number,
      validator: (v) {
        if (v == null || v.isEmpty) return 'กรุณากรอกอายุ';
        final age = int.tryParse(v);
        if (age == null || age < 1 || age > 120) {
          return 'กรุณากรอกอายุให้ถูกต้อง';
        }
        return null;
      },
      decoration: _inputDecoration('อายุ', Icons.cake_outlined),
    );
  }

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
                          : Colors.grey.shade100,
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

  Widget _buildProblemsSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ปัญหาที่กำลังเผชิญอยู่',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimaryLight,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'เลือกได้มากกว่า 1 อย่าง',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textSecondaryLight,
          ),
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
                      : Colors.grey.shade100,
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
                'บันทึกการเปลี่ยนแปลง',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: AppColors.primary),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      filled: true,
      fillColor: Colors.grey.shade50,
    );
  }
}