import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/constants/route_constants.dart';
import '../../../core/widgets/custom_button.dart';

/// Onboarding screen — 3 swipe pages with Gen-Z design
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingData> _pages = [
    _OnboardingData(
      icon: Icons.lock_rounded,
      title: 'End-to-End\nEncrypted',
      subtitle: 'Your messages are yours. Always.\nNot even we can read them.',
      gradient: AppGradients.purpleBlue,
      accentColor: AppColors.neonPurple,
    ),
    _OnboardingData(
      icon: Icons.speed_rounded,
      title: 'Lightning\nFast',
      subtitle: 'Instant messaging with real-time\nsync across all your devices.',
      gradient: AppGradients.cyanGreen,
      accentColor: AppColors.neonCyan,
    ),
    _OnboardingData(
      icon: Icons.group_rounded,
      title: 'Groups &\nChannels',
      subtitle: 'Create groups up to 1,024 members.\nBroadcast to unlimited subscribers.',
      gradient: AppGradients.pinkOrange,
      accentColor: AppColors.neonPink,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      context.go(RouteConstants.phoneInput);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextButton(
                  onPressed: () => context.go(RouteConstants.phoneInput),
                  child: Text(
                    'Skip',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),

            // Page content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (context, index) {
                  return _OnboardingPage(data: _pages[index]);
                },
              ),
            ),

            // Page indicators
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_pages.length, (index) {
                  final isActive = index == _currentPage;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: isActive ? 32 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      gradient: isActive ? AppGradients.purpleBlue : null,
                      color: isActive ? null : AppColors.textTertiary.withValues(alpha: 0.3),
                    ),
                  );
                }),
              ),
            ),

            // Next / Get Started button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: CustomButton(
                text: _currentPage == _pages.length - 1 ? 'Get Started' : 'Next',
                onPressed: _nextPage,
                gradient: _pages[_currentPage].gradient,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Data class ──────────────────────────────────────────────────

class _OnboardingData {
  final IconData icon;
  final String title;
  final String subtitle;
  final Gradient gradient;
  final Color accentColor;

  const _OnboardingData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.accentColor,
  });
}

// ─── Page widget ─────────────────────────────────────────────────

class _OnboardingPage extends StatelessWidget {
  final _OnboardingData data;

  const _OnboardingPage({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Glowing icon container
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: data.gradient,
              boxShadow: [
                BoxShadow(
                  color: data.accentColor.withValues(alpha: 0.5),
                  blurRadius: 50,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: Icon(data.icon, size: 72, color: Colors.white),
          ),

          const SizedBox(height: 48),

          // Title with gradient shader
          ShaderMask(
            shaderCallback: (bounds) => data.gradient.createShader(bounds),
            child: Text(
              data.title,
              textAlign: TextAlign.center,
              style: AppTextStyles.h1.copyWith(
                fontSize: 36,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                height: 1.2,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Subtitle
          Text(
            data.subtitle,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
