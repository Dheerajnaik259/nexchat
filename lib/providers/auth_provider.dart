import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../services/supabase/auth_service.dart';

// ─── Core Supabase Auth State ────────────────────────────────

/// Provides the current Supabase auth user (nullable)
final authUserProvider = StreamProvider<User?>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange.map(
    (state) => state.session?.user,
  );
});

/// Whether the user is currently authenticated
final isAuthenticatedProvider = Provider<bool>((ref) {
  return Supabase.instance.client.auth.currentUser != null;
});

/// Current user ID shorthand
final currentUserIdProvider = Provider<String?>((ref) {
  return Supabase.instance.client.auth.currentUser?.id;
});

// ─── User Profile ────────────────────────────────────────────

/// Stream the current user's profile from the users table
final userProfileProvider = StreamProvider<UserModel?>((ref) {
  return AuthService.instance.streamProfile();
});

// ─── Auth UI State ───────────────────────────────────────────

/// Loading state for auth operations
final authLoadingProvider = StateProvider<bool>((ref) => false);

/// Phone number entered during OTP flow
final authPhoneProvider = StateProvider<String>((ref) => '');

/// Verification step tracker
enum AuthStep { phoneInput, otpSent, verifying, profileSetup, authenticated }
final authStepProvider = StateProvider<AuthStep>((ref) => AuthStep.phoneInput);

/// Error message during auth flow
final authErrorProvider = StateProvider<String?>((ref) => null);
