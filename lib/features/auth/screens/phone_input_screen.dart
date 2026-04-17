import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/constants/route_constants.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/animated_gradient_bg.dart';
import '../../../services/supabase/auth_service.dart';

/// Email auth screen — sign up or sign in with email + password
class PhoneInputScreen extends StatefulWidget {
  const PhoneInputScreen({super.key});

  @override
  State<PhoneInputScreen> createState() => _PhoneInputScreenState();
}

class _PhoneInputScreenState extends State<PhoneInputScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isSignUp = true; // toggle between sign up and sign in
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      setState(() => _errorMessage = 'Enter a valid email address');
      return;
    }
    if (password.isEmpty || password.length < 6) {
      setState(() => _errorMessage = 'Password must be at least 6 characters');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_isSignUp) {
        await AuthService.instance.signUpWithEmail(
          email: email,
          password: password,
        );
        // After sign up, check if profile exists
        if (mounted) {
          setState(() => _isLoading = false);
          // Auto sign-in after sign up
          await AuthService.instance.signInWithEmail(
            email: email,
            password: password,
          );
          if (mounted) {
            final hasProfile = await AuthService.instance.profileExists();
            if (mounted) {
              context.go(hasProfile
                  ? RouteConstants.home
                  : RouteConstants.profileSetup);
            }
          }
        }
      } else {
        await AuthService.instance.signInWithEmail(
          email: email,
          password: password,
        );
        if (mounted) {
          setState(() => _isLoading = false);
          final hasProfile = await AuthService.instance.profileExists();
          if (mounted) {
            context.go(hasProfile
                ? RouteConstants.home
                : RouteConstants.profileSetup);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = _isSignUp
              ? 'Sign up failed. Email may already be in use.'
              : 'Invalid email or password.';
        });
      }
    }
  }

  Future<void> _quickStart() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await AuthService.instance.signInAnonymously();
      if (mounted) {
        setState(() => _isLoading = false);
        context.go(RouteConstants.profileSetup);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Quick start failed. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: AnimatedGradientBg(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 60),

                // Back button
                IconButton(
                  onPressed: () => context.go(RouteConstants.onboarding),
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 40),

                // Title
                ShaderMask(
                  shaderCallback: (bounds) =>
                      AppGradients.primary.createShader(bounds),
                  child: Text(
                    _isSignUp ? 'Create your\naccount' : 'Welcome\nback',
                    style: AppTextStyles.h1.copyWith(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  _isSignUp
                      ? 'Sign up to start chatting securely'
                      : 'Sign in to continue your conversations',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: Colors.white70,
                  ),
                ),

                const SizedBox(height: 48),

                // Auth input card (glass effect)
                GlassContainer(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Email field
                      TextField(
                        controller: _emailController,
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: Colors.white,
                        ),
                        keyboardType: TextInputType.emailAddress,
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: 'Email address',
                          hintStyle: AppTextStyles.bodyLarge.copyWith(
                            color: AppColors.textTertiary,
                          ),
                          filled: true,
                          fillColor:
                              AppColors.bgDarkTertiary.withValues(alpha: 0.5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          prefixIcon: const Icon(
                            Icons.email_outlined,
                            color: AppColors.neonPurple,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Password field
                      TextField(
                        controller: _passwordController,
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: Colors.white,
                        ),
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          hintText: 'Password',
                          hintStyle: AppTextStyles.bodyLarge.copyWith(
                            color: AppColors.textTertiary,
                          ),
                          filled: true,
                          fillColor:
                              AppColors.bgDarkTertiary.withValues(alpha: 0.5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          prefixIcon: const Icon(
                            Icons.lock_outline_rounded,
                            color: AppColors.neonPurple,
                          ),
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(
                                  () => _obscurePassword = !_obscurePassword);
                            },
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ),
                      ),

                      // Error message
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _errorMessage!,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // Submit button
                      CustomButton(
                        text: _isSignUp ? 'Create Account' : 'Sign In',
                        onPressed: _submit,
                        isLoading: _isLoading,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Divider with "or"
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 1,
                        color: Colors.white24,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'or',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.white54,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        height: 1,
                        color: Colors.white24,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Anonymous Quick Start button
                GlassContainer(
                  padding: const EdgeInsets.all(4),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: _isLoading ? null : _quickStart,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.rocket_launch_rounded,
                              color: AppColors.neonCyan,
                              size: 22,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Quick Start (No Account Needed)',
                              style: AppTextStyles.bodyLarge.copyWith(
                                color: AppColors.neonCyan,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Toggle sign up / sign in
                Center(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _isSignUp = !_isSignUp;
                        _errorMessage = null;
                      });
                    },
                    child: RichText(
                      text: TextSpan(
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.white70,
                        ),
                        children: [
                          TextSpan(
                            text: _isSignUp
                                ? 'Already have an account? '
                                : 'Don\'t have an account? ',
                          ),
                          TextSpan(
                            text: _isSignUp ? 'Sign In' : 'Sign Up',
                            style: const TextStyle(
                              color: AppColors.neonCyan,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Privacy note
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.lock_outline_rounded,
                        size: 14,
                        color: AppColors.textTertiary.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Your data is encrypted and never shared',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textTertiary.withValues(alpha: 0.6),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
