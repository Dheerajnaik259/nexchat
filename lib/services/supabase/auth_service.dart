import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/user_model.dart';

/// Authentication service powered by Supabase Auth
///
/// Supports:
/// - Email + Password sign-up / sign-in
/// - Phone + OTP sign-in (when enabled in dashboard)
/// - Auth state streaming
/// - Profile management (users table)
/// - Session persistence (handled automatically by supabase_flutter)
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  /// Supabase client shorthand
  SupabaseClient get _client => Supabase.instance.client;

  /// Current auth user (nullable)
  User? get currentUser => _client.auth.currentUser;

  /// Current user ID
  String? get currentUserId => currentUser?.id;

  /// Whether the user is authenticated
  bool get isAuthenticated => currentUser != null;

  /// Auth state change stream
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  // ─── Anonymous Authentication (always available) ──────────────

  /// Sign in anonymously — no email/phone needed
  Future<AuthResponse> signInAnonymously() async {
    try {
      final response = await _client.auth.signInAnonymously();
      debugPrint('[AuthService] Anonymous sign in successful');
      return response;
    } catch (e) {
      debugPrint('[AuthService] Anonymous sign in failed: $e');
      rethrow;
    }
  }

  // ─── Email + Password Authentication ─────────────────────────

  /// Sign up with email and password
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
      );
      debugPrint('[AuthService] Sign up successful for $email');
      return response;
    } catch (e) {
      debugPrint('[AuthService] Sign up failed: $e');
      rethrow;
    }
  }

  /// Sign in with email and password
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      debugPrint('[AuthService] Sign in successful for $email');
      return response;
    } catch (e) {
      debugPrint('[AuthService] Sign in failed: $e');
      rethrow;
    }
  }

  // ─── Phone OTP Authentication (when enabled) ────────────────

  /// Send OTP to phone number
  /// [phone] must include country code, e.g. "+919876543210"
  Future<void> sendOTP({required String phone}) async {
    try {
      await _client.auth.signInWithOtp(phone: phone);
      debugPrint('[AuthService] OTP sent to $phone');
    } catch (e) {
      debugPrint('[AuthService] Failed to send OTP: $e');
      rethrow;
    }
  }

  /// Verify OTP and complete sign-in
  Future<AuthResponse> verifyOTP({
    required String phone,
    required String otp,
  }) async {
    try {
      final response = await _client.auth.verifyOTP(
        phone: phone,
        token: otp,
        type: OtpType.sms,
      );
      debugPrint('[AuthService] OTP verified for $phone');
      return response;
    } catch (e) {
      debugPrint('[AuthService] OTP verification failed: $e');
      rethrow;
    }
  }

  /// Sign out the current user
  Future<void> signOut() async {
    try {
      // Update user status to offline before signing out
      if (currentUserId != null) {
        await _client.from('users').update({
          'status': 'offline',
          'last_seen': DateTime.now().toIso8601String(),
        }).eq('id', currentUserId!);
      }
      await _client.auth.signOut();
      debugPrint('[AuthService] User signed out');
    } catch (e) {
      debugPrint('[AuthService] Sign out failed: $e');
      rethrow;
    }
  }

  // ─── User Profile Management ───────────────────────────────

  /// Check if a user profile exists in the users table
  Future<bool> profileExists() async {
    if (currentUserId == null) return false;
    final data = await _client
        .from('users')
        .select('id')
        .eq('id', currentUserId!)
        .maybeSingle();
    return data != null;
  }

  /// Create or update user profile in the users table
  Future<UserModel> setupProfile({
    required String name,
    String username = '',
    String bio = '',
    String profilePicUrl = '',
    required String publicKey,
  }) async {
    final user = currentUser;
    if (user == null) throw Exception('User not authenticated');

    final userData = UserModel(
      uid: user.id,
      phone: user.phone ?? '',
      name: name,
      username: username,
      bio: bio,
      profilePicUrl: profilePicUrl,
      publicKey: publicKey,
      status: 'online',
      lastSeen: DateTime.now(),
      createdAt: DateTime.now(),
    );

    await _client.from('users').upsert(userData.toJson());
    debugPrint('[AuthService] Profile created/updated for ${user.id}');
    return userData;
  }

  /// Get user profile from the users table
  Future<UserModel?> getProfile({String? userId}) async {
    final id = userId ?? currentUserId;
    if (id == null) return null;

    final data = await _client
        .from('users')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (data == null) return null;
    return UserModel.fromJson(data);
  }

  /// Update specific user fields
  Future<void> updateProfile(Map<String, dynamic> updates) async {
    if (currentUserId == null) return;
    await _client.from('users').update(updates).eq('id', currentUserId!);
  }

  /// Update online status
  Future<void> setOnlineStatus(bool isOnline) async {
    if (currentUserId == null) return;
    await _client.from('users').update({
      'status': isOnline ? 'online' : 'offline',
      'last_seen': DateTime.now().toIso8601String(),
    }).eq('id', currentUserId!);
  }

  /// Update push notification token
  Future<void> updateDeviceToken(String token) async {
    if (currentUserId == null) return;
    await _client.rpc('add_device_token', params: {
      'user_id': currentUserId!,
      'token': token,
    });
  }

  /// Search users by username or phone
  Future<List<UserModel>> searchUsers(String query) async {
    if (query.isEmpty) return [];
    final data = await _client
        .from('users')
        .select()
        .or('username.ilike.%$query%,phone.ilike.%$query%,name.ilike.%$query%')
        .limit(20);

    return data.map((json) => UserModel.fromJson(json)).toList();
  }

  /// Get user by phone number
  Future<UserModel?> getUserByPhone(String phone) async {
    final data = await _client
        .from('users')
        .select()
        .eq('phone', phone)
        .maybeSingle();
    if (data == null) return null;
    return UserModel.fromJson(data);
  }

  /// Stream user profile changes (real-time)
  Stream<UserModel?> streamProfile({String? userId}) {
    final id = userId ?? currentUserId;
    if (id == null) return Stream.value(null);

    return _client
        .from('users')
        .stream(primaryKey: ['id'])
        .eq('id', id)
        .map((data) {
          if (data.isEmpty) return null;
          return UserModel.fromJson(data.first);
        });
  }
}
