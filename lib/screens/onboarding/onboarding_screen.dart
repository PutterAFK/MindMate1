import 'package:flutter/material.dart';
import 'package:my_app_new/core/constants/app_colors.dart';
import 'package:my_app_new/screens/auth/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // ข้อมูลแต่ละหน้า Onboarding
  final List<OnboardingData> _pages = [
    OnboardingData(
      icon: Icons.favorite_rounded,
      color: const Color(0xFFFF8C69),
      title: 'ยินดีต้อนรับสู่ MindMate',
      description:
          'เพื่อนที่พร้อมรับฟังคุณทุกเวลา\nไม่ว่าจะเป็นความเครียด ความเหงา\nหรือเรื่องราวที่อยากระบาย',
    ),
    OnboardingData(
      icon: Icons.chat_bubble_rounded,
      color: const Color(0xFF7C9EE8),
      title: 'พูดคุยได้ทุกเรื่อง',
      description:
          'ไม่มีการตัดสิน ไม่มีการวิจารณ์\nMindMate พร้อมรับฟังคุณด้วยความเข้าใจ\nและห่วงใยเสมอ 💙',
    ),
    OnboardingData(
      icon: Icons.lock_rounded,
      color: const Color(0xFF66BB6A),
      title: 'ปลอดภัย เป็นส่วนตัว',
      description:
          'ข้อมูลของคุณถูกเก็บอย่างปลอดภัย\nเฉพาะคุณเท่านั้นที่เข้าถึงได้\nไม่มีใครรู้ว่าคุณพูดอะไร 🔒',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // บันทึกว่าดู Onboarding แล้ว
  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: SafeArea(
        child: Column(
          children: [
            // ปุ่ม Skip
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextButton(
                  onPressed: _completeOnboarding,
                  child: const Text(
                    'ข้าม',
                    style: TextStyle(
                      color: AppColors.textSecondaryLight,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),

            // PageView
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemBuilder: (context, index) {
                  return _buildPage(_pages[index]);
                },
              ),
            ),

            // Dots Indicator
            _buildDotsIndicator(),

            const SizedBox(height: 24),

            // ปุ่ม Next / เริ่มต้นใช้งาน
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _buildNextButton(),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // หน้าแต่ละ Page
  Widget _buildPage(OnboardingData data) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: data.color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(36),
            ),
            child: Icon(
              data.icon,
              size: 60,
              color: data.color,
            ),
          ),

          const SizedBox(height: 48),

          // Title
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimaryLight,
              height: 1.3,
            ),
          ),

          const SizedBox(height: 16),

          // Description
          Text(
            data.description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textSecondaryLight,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  // Dots Indicator
  Widget _buildDotsIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_pages.length, (index) {
        final isActive = _currentPage == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : AppColors.primaryLight,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  // ปุ่ม Next / เริ่มต้นใช้งาน
  Widget _buildNextButton() {
    final isLastPage = _currentPage == _pages.length - 1;

    return SizedBox(
      width: double.infinity,
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primaryLight, AppColors.primary],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: () {
            if (isLastPage) {
              _completeOnboarding();
            } else {
              _pageController.nextPage(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: Text(
            isLastPage ? 'เริ่มต้นใช้งาน 🚀' : 'ถัดไป',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

// Model ข้อมูลแต่ละหน้า
class OnboardingData {
  final IconData icon;
  final Color color;
  final String title;
  final String description;

  OnboardingData({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
  });
}