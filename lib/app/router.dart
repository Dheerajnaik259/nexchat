import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/constants/route_constants.dart';
import '../features/auth/screens/splash_screen.dart';
import '../features/auth/screens/onboarding_screen.dart';
import '../features/auth/screens/phone_input_screen.dart';
import '../features/auth/screens/otp_verification_screen.dart';
import '../features/auth/screens/profile_setup_screen.dart';
import '../features/home/screens/home_screen.dart';
import '../features/chat/screens/chat_screen.dart';
import '../features/chat/screens/group_chat_screen.dart';
import '../features/chat/screens/channel_screen.dart';
import '../features/chat/screens/secret_chat_screen.dart';
import '../features/calls/screens/incoming_call_screen.dart';
import '../features/calls/screens/voice_call_screen.dart';
import '../features/calls/screens/video_call_screen.dart';
import '../features/status/screens/status_screen.dart';
import '../features/status/screens/status_view_screen.dart';
import '../features/contacts/screens/contacts_screen.dart';
import '../features/contacts/screens/contact_profile_screen.dart';
import '../features/groups/screens/create_group_screen.dart';
import '../features/groups/screens/group_info_screen.dart';
import '../features/groups/screens/add_members_screen.dart';
import '../features/profile/screens/my_profile_screen.dart';
import '../features/profile/screens/edit_profile_screen.dart';
import '../features/settings/screens/settings_screen.dart';
import '../features/settings/screens/privacy_settings_screen.dart';
import '../features/settings/screens/notification_settings_screen.dart';
import '../features/settings/screens/security_settings_screen.dart';
import '../features/settings/screens/chat_settings_screen.dart';
import '../features/settings/screens/storage_settings_screen.dart';
import '../features/settings/screens/backup_settings_screen.dart';

/// GoRouter full config
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: RouteConstants.splash,
    routes: [
      // ── Auth ──────────────────────────────────────────
      GoRoute(
        path: RouteConstants.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: RouteConstants.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: RouteConstants.phoneInput,
        builder: (context, state) => const PhoneInputScreen(),
      ),
      GoRoute(
        path: RouteConstants.otpVerification,
        builder: (context, state) {
          final verificationId = state.extra as String? ?? '';
          return OtpVerificationScreen(verificationId: verificationId);
        },
      ),
      GoRoute(
        path: RouteConstants.profileSetup,
        builder: (context, state) => const ProfileSetupScreen(),
      ),

      // ── Home ──────────────────────────────────────────
      GoRoute(
        path: RouteConstants.home,
        builder: (context, state) => const HomeScreen(),
      ),

      // ── Chat ──────────────────────────────────────────
      GoRoute(
        path: '${RouteConstants.chat}/:chatId',
        builder: (context, state) {
          final chatId = state.pathParameters['chatId']!;
          return ChatScreen(chatId: chatId);
        },
      ),
      GoRoute(
        path: '${RouteConstants.groupChat}/:chatId',
        builder: (context, state) {
          final chatId = state.pathParameters['chatId']!;
          return GroupChatScreen(chatId: chatId);
        },
      ),
      GoRoute(
        path: '${RouteConstants.channel}/:chatId',
        builder: (context, state) {
          final chatId = state.pathParameters['chatId']!;
          return ChannelScreen(chatId: chatId);
        },
      ),
      GoRoute(
        path: '${RouteConstants.secretChat}/:chatId',
        builder: (context, state) {
          final chatId = state.pathParameters['chatId']!;
          return SecretChatScreen(chatId: chatId);
        },
      ),

      // ── Calls ─────────────────────────────────────────
      GoRoute(
        path: '${RouteConstants.incomingCall}/:callId',
        builder: (context, state) {
          final callId = state.pathParameters['callId']!;
          return IncomingCallScreen(callId: callId);
        },
      ),
      GoRoute(
        path: '${RouteConstants.voiceCall}/:callId',
        builder: (context, state) {
          final callId = state.pathParameters['callId']!;
          return VoiceCallScreen(callId: callId);
        },
      ),
      GoRoute(
        path: '${RouteConstants.videoCall}/:callId',
        builder: (context, state) {
          final callId = state.pathParameters['callId']!;
          return VideoCallScreen(callId: callId);
        },
      ),

      // ── Status / Stories ──────────────────────────────
      GoRoute(
        path: RouteConstants.status,
        builder: (context, state) => const StatusScreen(),
      ),
      GoRoute(
        path: '${RouteConstants.statusView}/:statusId',
        builder: (context, state) {
          final statusId = state.pathParameters['statusId']!;
          return StatusViewScreen(statusId: statusId);
        },
      ),

      // ── Contacts ──────────────────────────────────────
      GoRoute(
        path: RouteConstants.contacts,
        builder: (context, state) => const ContactsScreen(),
      ),
      GoRoute(
        path: '${RouteConstants.contactProfile}/:userId',
        builder: (context, state) {
          final userId = state.pathParameters['userId']!;
          return ContactProfileScreen(userId: userId);
        },
      ),

      // ── Groups ────────────────────────────────────────
      GoRoute(
        path: RouteConstants.createGroup,
        builder: (context, state) => const CreateGroupScreen(),
      ),
      GoRoute(
        path: '${RouteConstants.groupInfo}/:chatId',
        builder: (context, state) {
          final chatId = state.pathParameters['chatId']!;
          return GroupInfoScreen(chatId: chatId);
        },
      ),
      GoRoute(
        path: '${RouteConstants.addMembers}/:chatId',
        builder: (context, state) {
          final chatId = state.pathParameters['chatId']!;
          return AddMembersScreen(chatId: chatId);
        },
      ),

      // ── Profile ───────────────────────────────────────
      GoRoute(
        path: RouteConstants.myProfile,
        builder: (context, state) => const MyProfileScreen(),
      ),
      GoRoute(
        path: RouteConstants.editProfile,
        builder: (context, state) => const EditProfileScreen(),
      ),

      // ── Settings ──────────────────────────────────────
      GoRoute(
        path: RouteConstants.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: RouteConstants.privacySettings,
        builder: (context, state) => const PrivacySettingsScreen(),
      ),
      GoRoute(
        path: RouteConstants.notificationSettings,
        builder: (context, state) => const NotificationSettingsScreen(),
      ),
      GoRoute(
        path: RouteConstants.securitySettings,
        builder: (context, state) => const SecuritySettingsScreen(),
      ),
      GoRoute(
        path: RouteConstants.chatSettings,
        builder: (context, state) => const ChatSettingsScreen(),
      ),
      GoRoute(
        path: RouteConstants.storageSettings,
        builder: (context, state) => const StorageSettingsScreen(),
      ),
      GoRoute(
        path: RouteConstants.backupSettings,
        builder: (context, state) => const BackupSettingsScreen(),
      ),
    ],
  );
});
