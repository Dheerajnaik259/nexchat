# ╔══════════════════════════════════════════════════════════════╗
# ║         NEXCHAT — ANDROID STUDIO AI AGENT INSTRUCTIONS       ║
# ║     Complete Flutter + Supabase Encrypted Messaging App      ║
# ╚══════════════════════════════════════════════════════════════╝

> **⚠️ MIGRATION NOTICE (April 2026):**
> This project has been **fully migrated from Firebase to Supabase**.
> - Backend: Supabase (Auth, PostgreSQL, Storage, Realtime)
> - Auth: Email+Password / Anonymous / Phone OTP (when enabled)
> - Database: PostgreSQL with Row Level Security (RLS)
> - Storage: Supabase Storage (avatars, chat-media, status-media)
> - Real-time: Supabase Realtime channels + Broadcast
> - SQL Schema: `supabase/migrations/001_initial_schema.sql`
> - Config: `lib/supabase_config.dart`
>
> Sections 3 & 4 below reference the original Firebase spec.
> The actual implementation uses Supabase equivalents. See `PROJECT_PROGRESS.txt` for current status.

> AGENT: Read every section carefully before writing a single line of code.
> Follow the exact folder structure, naming conventions, and package versions.
> Build module by module in the order listed. Do NOT skip any step.

---

## ════════════════════════════════════════
## SECTION 0 — PROJECT IDENTITY
## ════════════════════════════════════════

- App Name: NexChat
- Package Name: com.nexchat.app
- Flutter Version: 3.22.x (Dart 3.4.x)
- Platform: Android + iOS + Web
- Min SDK: Android 21 (iOS 13)
- Target SDK: Android 34
- Architecture: Feature-First Clean Architecture
- State Management: Riverpod 2.x
- Backend: Supabase (Auth, PostgreSQL, Storage, Realtime)
- Encryption: End-to-End (Signal Protocol / AES-256 + RSA-2048)

---

## ════════════════════════════════════════
## SECTION 1 — COMPLETE pubspec.yaml
## ════════════════════════════════════════

Create this exact pubspec.yaml at the project root:

```yaml
name: nexchat
description: NexChat - Gen-Z Encrypted Messenger
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.4.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter

  # ── State Management ──────────────────────────────
  flutter_riverpod: ^2.5.1
  riverpod_annotation: ^2.3.5
  hooks_riverpod: ^2.5.1
  flutter_hooks: ^0.20.5

  # ── Navigation ────────────────────────────────────
  go_router: ^14.2.0

  # ── Firebase ──────────────────────────────────────
  firebase_core: ^3.3.0
  firebase_auth: ^5.1.0
  cloud_firestore: ^5.2.0
  firebase_storage: ^12.1.0
  firebase_messaging: ^15.0.4
  firebase_app_check: ^0.3.1+4
  cloud_functions: ^5.0.4

  # ── Local Storage ─────────────────────────────────
  hive_flutter: ^1.1.0
  hive: ^2.2.3
  shared_preferences: ^2.3.1
  sqflite: ^2.3.3+1
  path_provider: ^2.1.3

  # ── Encryption ────────────────────────────────────
  encrypt: ^5.0.3
  pointycastle: ^3.9.1
  cryptography: ^2.7.0
  local_auth: ^2.3.0

  # ── Media & Files ─────────────────────────────────
  image_picker: ^1.1.2
  file_picker: ^8.0.6
  cached_network_image: ^3.3.1
  video_player: ^2.9.1
  chewie: ^1.8.3
  flutter_sound: ^9.2.13
  just_audio: ^0.9.39
  photo_view: ^0.15.0
  image_cropper: ^8.0.2
  flutter_image_compress: ^2.3.0
  video_compress: ^3.1.2

  # ── Calls (WebRTC) ────────────────────────────────
  flutter_webrtc: ^0.10.6
  agora_rtc_engine: ^6.3.2

  # ── Notifications ─────────────────────────────────
  flutter_local_notifications: ^17.2.2
  awesome_notifications: ^0.9.3+1

  # ── UI & Animations ───────────────────────────────
  lottie: ^3.1.2
  rive: ^0.13.4
  flutter_animate: ^4.5.0
  shimmer: ^3.0.0
  glassmorphism: ^3.0.0
  animated_text_kit: ^4.2.2
  emoji_picker_flutter: ^2.2.0
  flutter_emoji: ^2.4.1
  staggered_grid_view_flutter: ^0.0.3

  # ── Contacts & Phone ──────────────────────────────
  contacts_service: ^0.6.3
  permission_handler: ^11.3.1
  phone_form_field: ^10.0.2
  intl_phone_number_input: ^0.7.4

  # ── Utilities ─────────────────────────────────────
  uuid: ^4.4.2
  intl: ^0.19.0
  timeago: ^3.6.1
  url_launcher: ^6.3.0
  share_plus: ^9.0.0
  connectivity_plus: ^6.0.3
  package_info_plus: ^8.0.2
  device_info_plus: ^10.1.2
  path: ^1.9.0
  mime: ^1.0.5
  http: ^1.2.2
  dio: ^5.4.3+1
  rxdart: ^0.28.0
  collection: ^1.18.0
  freezed_annotation: ^2.4.4
  json_annotation: ^4.9.0
  equatable: ^2.0.5
  dartz: ^0.10.1

  # ── QR & Link Preview ─────────────────────────────
  qr_flutter: ^4.1.0
  qr_code_scanner: ^1.0.1
  any_link_preview: ^3.0.4

  # ── Backup ────────────────────────────────────────
  googleapis: ^13.2.0
  google_sign_in: ^6.2.1
  extension_google_sign_in_as_googleapis_auth: ^2.0.12

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0
  build_runner: ^2.4.11
  riverpod_generator: ^2.4.3
  freezed: ^2.5.7
  json_serializable: ^6.8.0
  hive_generator: ^2.0.1
  mockito: ^5.4.4
  fake_cloud_firestore: ^3.0.3
  firebase_auth_mocks: ^0.14.1

flutter:
  uses-material-design: true
  assets:
    - assets/images/
    - assets/animations/
    - assets/sounds/
    - assets/fonts/
  fonts:
    - family: Inter
      fonts:
        - asset: assets/fonts/Inter-Regular.ttf
        - asset: assets/fonts/Inter-Medium.ttf
          weight: 500
        - asset: assets/fonts/Inter-SemiBold.ttf
          weight: 600
        - asset: assets/fonts/Inter-Bold.ttf
          weight: 700
```

---

## ════════════════════════════════════════
## SECTION 2 — COMPLETE FOLDER STRUCTURE
## ════════════════════════════════════════

Create EXACTLY this folder structure under lib/:

```
lib/
├── main.dart
├── firebase_options.dart                  ← generated by FlutterFire CLI
│
├── app/
│   ├── app.dart                           ← Root MaterialApp.router
│   ├── router.dart                        ← GoRouter full config
│   └── app_lifecycle_observer.dart
│
├── core/
│   ├── constants/
│   │   ├── app_constants.dart
│   │   ├── firestore_constants.dart       ← collection names
│   │   └── route_constants.dart
│   ├── errors/
│   │   ├── exceptions.dart
│   │   └── failures.dart
│   ├── extensions/
│   │   ├── context_extensions.dart
│   │   ├── string_extensions.dart
│   │   └── datetime_extensions.dart
│   ├── theme/
│   │   ├── app_theme.dart                 ← dark theme (default)
│   │   ├── app_colors.dart                ← Gen-Z neon color palette
│   │   ├── app_text_styles.dart
│   │   └── app_gradients.dart
│   ├── utils/
│   │   ├── date_utils.dart
│   │   ├── file_utils.dart
│   │   └── validators.dart
│   └── widgets/
│       ├── custom_button.dart
│       ├── custom_text_field.dart
│       ├── loading_overlay.dart
│       ├── avatar_widget.dart
│       ├── glass_container.dart           ← glassmorphism widget
│       └── animated_gradient_bg.dart
│
├── models/
│   ├── user_model.dart
│   ├── chat_model.dart
│   ├── message_model.dart
│   ├── call_model.dart
│   ├── status_model.dart
│   ├── poll_model.dart
│   ├── contact_model.dart
│   └── notification_model.dart
│
├── services/
│   ├── firebase/
│   │   ├── auth_service.dart
│   │   ├── firestore_service.dart
│   │   ├── storage_service.dart
│   │   └── functions_service.dart
│   ├── encryption/
│   │   ├── encryption_service.dart        ← AES-256 + RSA-2048
│   │   ├── key_store.dart                 ← Hive-backed key storage
│   │   └── signal_protocol_service.dart   ← Double Ratchet
│   ├── notification_service.dart
│   ├── call_service.dart                  ← WebRTC signaling
│   ├── contact_sync_service.dart
│   ├── backup_service.dart
│   └── local_db_service.dart              ← Hive / SQLite
│
├── providers/
│   ├── auth_provider.dart
│   ├── chat_provider.dart
│   ├── message_provider.dart
│   ├── call_provider.dart
│   ├── contact_provider.dart
│   ├── status_provider.dart
│   ├── theme_provider.dart
│   └── connectivity_provider.dart
│
├── features/
│   │
│   ├── auth/
│   │   ├── screens/
│   │   │   ├── splash_screen.dart
│   │   │   ├── onboarding_screen.dart
│   │   │   ├── phone_input_screen.dart
│   │   │   ├── otp_verification_screen.dart
│   │   │   └── profile_setup_screen.dart
│   │   ├── widgets/
│   │   │   ├── phone_field_widget.dart
│   │   │   └── otp_input_widget.dart
│   │   └── controllers/
│   │       └── auth_controller.dart
│   │
│   ├── home/
│   │   ├── screens/
│   │   │   └── home_screen.dart           ← TabBar: Chats / Calls / Status
│   │   └── widgets/
│   │       ├── chat_list_tile.dart
│   │       ├── search_bar_widget.dart
│   │       └── fab_menu_widget.dart
│   │
│   ├── chat/
│   │   ├── screens/
│   │   │   ├── chat_screen.dart
│   │   │   ├── group_chat_screen.dart
│   │   │   ├── channel_screen.dart
│   │   │   └── secret_chat_screen.dart
│   │   ├── widgets/
│   │   │   ├── message_bubble.dart
│   │   │   ├── message_input_bar.dart
│   │   │   ├── media_preview_widget.dart
│   │   │   ├── reply_preview_widget.dart
│   │   │   ├── voice_message_player.dart
│   │   │   ├── poll_widget.dart
│   │   │   ├── reaction_bar.dart
│   │   │   ├── pinned_message_widget.dart
│   │   │   └── typing_indicator.dart
│   │   └── controllers/
│   │       └── chat_controller.dart
│   │
│   ├── calls/
│   │   ├── screens/
│   │   │   ├── incoming_call_screen.dart
│   │   │   ├── voice_call_screen.dart
│   │   │   └── video_call_screen.dart
│   │   ├── widgets/
│   │   │   ├── call_controls_widget.dart
│   │   │   └── call_timer_widget.dart
│   │   └── controllers/
│   │       └── call_controller.dart
│   │
│   ├── status/
│   │   ├── screens/
│   │   │   ├── status_screen.dart
│   │   │   └── status_view_screen.dart
│   │   ├── widgets/
│   │   │   ├── status_ring_widget.dart
│   │   │   └── status_creator_widget.dart
│   │   └── controllers/
│   │       └── status_controller.dart
│   │
│   ├── contacts/
│   │   ├── screens/
│   │   │   ├── contacts_screen.dart
│   │   │   └── contact_profile_screen.dart
│   │   └── controllers/
│   │       └── contacts_controller.dart
│   │
│   ├── groups/
│   │   ├── screens/
│   │   │   ├── create_group_screen.dart
│   │   │   ├── group_info_screen.dart
│   │   │   └── add_members_screen.dart
│   │   └── controllers/
│   │       └── group_controller.dart
│   │
│   ├── profile/
│   │   ├── screens/
│   │   │   ├── my_profile_screen.dart
│   │   │   └── edit_profile_screen.dart
│   │   └── controllers/
│   │       └── profile_controller.dart
│   │
│   └── settings/
│       ├── screens/
│       │   ├── settings_screen.dart
│       │   ├── privacy_settings_screen.dart
│       │   ├── notification_settings_screen.dart
│       │   ├── security_settings_screen.dart
│       │   ├── chat_settings_screen.dart
│       │   ├── storage_settings_screen.dart
│       │   └── backup_settings_screen.dart
│       └── controllers/
│           └── settings_controller.dart
```

---

## ════════════════════════════════════════
## SECTION 3 — FIRESTORE DATABASE SCHEMA
## ════════════════════════════════════════

Create these exact Firestore collections and fields:

### Collection: users/{userId}
```
{
  uid: string,
  phone: string,
  name: string,
  username: string,           ← unique @handle
  bio: string,
  profilePicUrl: string,
  publicKey: string,          ← RSA public key (base64)
  identityKey: string,        ← Signal identity key
  signedPreKey: string,       ← Signal signed pre-key
  oneTimePreKeys: [string],   ← Signal one-time pre-keys
  status: string,             ← "online" | "offline" | "typing"
  lastSeen: timestamp,
  pinnedChats: [string],      ← chatIds
  blockedUsers: [string],     ← userIds
  privacySettings: {
    lastSeen: "everyone"|"contacts"|"nobody",
    profilePhoto: "everyone"|"contacts"|"nobody",
    about: "everyone"|"contacts"|"nobody",
    readReceipts: boolean
  },
  notificationSettings: {
    muteAll: boolean,
    showPreview: boolean
  },
  twoStepPin: string,         ← hashed
  biometricEnabled: boolean,
  createdAt: timestamp,
  deviceTokens: [string]      ← FCM tokens (multi-device)
}
```

### Collection: chats/{chatId}
```
{
  chatId: string,
  type: "private"|"group"|"channel"|"secret",
  participants: [userId],
  admins: [userId],           ← for groups/channels
  createdBy: string,
  name: string,               ← for groups/channels
  description: string,
  avatarUrl: string,
  lastMessage: {
    text: string,             ← "[encrypted preview]" or type hint
    senderId: string,
    timestamp: timestamp,
    type: string
  },
  lastActivity: timestamp,
  mutedBy: [userId],
  pinnedMessageId: string,
  inviteLink: string,         ← for groups/channels
  isE2EEnabled: boolean,
  disappearingTimer: number,  ← seconds (0 = off)
  maxMembers: number,
  createdAt: timestamp
}
```

### Collection: messages/{messageId}
```
{
  messageId: string,
  chatId: string,
  senderId: string,
  type: "text"|"image"|"video"|"audio"|"document"|"poll"|"contact"|"location"|"sticker"|"gif"|"system",
  encryptedText: string,      ← ALWAYS encrypted, never plaintext
  encryptedMediaUrl: string,
  mediaMetadata: {
    size: number,
    duration: number,
    width: number,
    height: number,
    thumbnailUrl: string
  },
  replyToMessageId: string,
  forwardedFrom: string,
  reactions: {
    userId: string            ← emoji reactions map
  },
  readBy: {
    userId: timestamp         ← userId → timestamp map
  },
  deliveredTo: {
    userId: timestamp
  },
  edited: boolean,
  editedAt: timestamp,
  editHistory: [string],      ← previous encrypted versions
  isDeleted: boolean,
  deletedForEveryone: boolean,
  deletedAt: timestamp,
  selfDestructTime: number,   ← seconds (0 = off)
  isPinned: boolean,
  scheduledAt: timestamp,     ← null if not scheduled
  status: "sent"|"delivered"|"read"|"failed",
  timestamp: timestamp,
  localId: string             ← for offline support
}
```

### Collection: status/{statusId}
```
{
  statusId: string,
  userId: string,
  type: "text"|"image"|"video",
  content: string,
  mediaUrl: string,
  backgroundColor: string,
  fontStyle: string,
  duration: number,           ← video duration in ms
  seenBy: [userId],
  allowedViewers: [userId],   ← empty = all contacts
  expiresAt: timestamp,       ← createdAt + 24 hours
  createdAt: timestamp
}
```

### Collection: calls/{callId}
```
{
  callId: string,
  type: "voice"|"video",
  callerId: string,
  receiverIds: [string],
  status: "ringing"|"accepted"|"rejected"|"missed"|"ended",
  startedAt: timestamp,
  endedAt: timestamp,
  duration: number,
  isGroup: boolean,
  signalingData: {            ← WebRTC SDP + ICE candidates
    offer: string,
    answer: string,
    iceCandidates: [object]
  }
}
```

### Collection: polls/{pollId}
```
{
  pollId: string,
  chatId: string,
  messageId: string,
  question: string,
  options: [{ id: string, text: string }],
  votes: { optionId: [userId] },
  isAnonymous: boolean,
  isMultipleChoice: boolean,
  isQuiz: boolean,
  correctOptionId: string,    ← only if isQuiz = true
  explanation: string,
  closedAt: timestamp,
  createdBy: string,
  createdAt: timestamp
}
```

### Collection: scheduled_messages/{id}
```
{
  id: string,
  chatId: string,
  senderId: string,
  encryptedText: string,
  scheduledAt: timestamp,
  status: "pending"|"sent"|"cancelled",
  type: string,
  createdAt: timestamp
}
```

---

## ════════════════════════════════════════
## SECTION 4 — FIREBASE SETUP INSTRUCTIONS
## ════════════════════════════════════════

AGENT: Perform these Firebase setup steps and generate the code accordingly.

### Step 1: Firebase Project Config
- Install FlutterFire CLI: `dart pub global activate flutterfire_cli`
- Run: `flutterfire configure`
- This generates: `lib/firebase_options.dart`

### Step 2: Firebase Services to Enable
1. Authentication → Phone provider (enable SMS)
2. Cloud Firestore → Start in production mode
3. Firebase Storage → Start in production mode
4. Cloud Functions → Node.js 20
5. Firebase Cloud Messaging → enabled by default
6. Firebase App Check → reCAPTCHA for web, Play Integrity for Android

### Step 3: Firestore Security Rules
Write these exact security rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    function isAuth() {
      return request.auth != null;
    }

    function isOwner(userId) {
      return request.auth.uid == userId;
    }

    function isParticipant(chatId) {
      return request.auth.uid in get(/databases/$(database)/documents/chats/$(chatId)).data.participants;
    }

    match /users/{userId} {
      allow read: if isAuth();
      allow write: if isOwner(userId);
    }

    match /chats/{chatId} {
      allow read: if isAuth() && isParticipant(chatId);
      allow create: if isAuth();
      allow update: if isAuth() && isParticipant(chatId);
    }

    match /messages/{messageId} {
      allow read: if isAuth() && isParticipant(resource.data.chatId);
      allow create: if isAuth();
      allow update: if isAuth() && (
        request.auth.uid == resource.data.senderId ||
        isParticipant(resource.data.chatId)
      );
    }

    match /status/{statusId} {
      allow read: if isAuth();
      allow write: if isAuth() && isOwner(resource.data.userId);
    }

    match /calls/{callId} {
      allow read, write: if isAuth();
    }

    match /polls/{pollId} {
      allow read: if isAuth();
      allow create: if isAuth();
      allow update: if isAuth();
    }
  }
}
```

### Step 4: Firebase Storage Rules
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /users/{userId}/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    match /chats/{chatId}/{allPaths=**} {
      allow read, write: if request.auth != null;
    }
    match /status/{userId}/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

---

## ════════════════════════════════════════
## SECTION 5 — MODELS (Data Classes)
## ════════════════════════════════════════

### lib/models/user_model.dart
```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

@freezed
class UserModel with _$UserModel {
  const factory UserModel({
    required String uid,
    required String phone,
    required String name,
    String? username,
    String? bio,
    String? profilePicUrl,
    required String publicKey,
    String? identityKey,
    @Default('offline') String status,
    DateTime? lastSeen,
    @Default([]) List<String> pinnedChats,
    @Default([]) List<String> blockedUsers,
    @Default(false) bool biometricEnabled,
    DateTime? createdAt,
    @Default([]) List<String> deviceTokens,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel.fromJson({...data, 'uid': doc.id});
  }
}
```

### lib/models/message_model.dart
```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'message_model.freezed.dart';
part 'message_model.g.dart';

enum MessageType { text, image, video, audio, document, poll, contact, location, sticker, gif, system }
enum MessageStatus { sent, delivered, read, failed }

@freezed
class MessageModel with _$MessageModel {
  const factory MessageModel({
    required String messageId,
    required String chatId,
    required String senderId,
    required MessageType type,
    required String encryptedText,
    String? encryptedMediaUrl,
    Map<String, dynamic>? mediaMetadata,
    String? replyToMessageId,
    String? forwardedFrom,
    @Default({}) Map<String, String> reactions,
    @Default({}) Map<String, DateTime> readBy,
    @Default({}) Map<String, DateTime> deliveredTo,
    @Default(false) bool edited,
    DateTime? editedAt,
    @Default(false) bool isDeleted,
    @Default(false) bool deletedForEveryone,
    @Default(0) int selfDestructTime,
    @Default(false) bool isPinned,
    DateTime? scheduledAt,
    @Default(MessageStatus.sent) MessageStatus status,
    required DateTime timestamp,
    String? localId,
  }) = _MessageModel;

  factory MessageModel.fromJson(Map<String, dynamic> json) =>
      _$MessageModelFromJson(json);
}
```

### lib/models/chat_model.dart
```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_model.freezed.dart';
part 'chat_model.g.dart';

enum ChatType { private, group, channel, secret }

@freezed
class ChatModel with _$ChatModel {
  const factory ChatModel({
    required String chatId,
    required ChatType type,
    required List<String> participants,
    @Default([]) List<String> admins,
    required String createdBy,
    String? name,
    String? description,
    String? avatarUrl,
    Map<String, dynamic>? lastMessage,
    DateTime? lastActivity,
    @Default([]) List<String> mutedBy,
    String? pinnedMessageId,
    String? inviteLink,
    @Default(true) bool isE2EEnabled,
    @Default(0) int disappearingTimer,
    DateTime? createdAt,
  }) = _ChatModel;

  factory ChatModel.fromJson(Map<String, dynamic> json) =>
      _$ChatModelFromJson(json);
}
```

---

## ════════════════════════════════════════
## SECTION 6 — ENCRYPTION SERVICE
## ════════════════════════════════════════

### lib/services/encryption/encryption_service.dart

AGENT: Implement full E2E encryption with:
- RSA-2048 key pair generation (per user, generated on first login)
- AES-256-GCM for message content encryption
- RSA-OAEP for encrypting the AES session key
- Keys stored in Hive encrypted box (NOT in Firestore plaintext)
- Public key stored in Firestore (users/{uid}/publicKey)
- Private key NEVER leaves the device

```dart
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:pointycastle/export.dart';
import 'package:hive_flutter/hive_flutter.dart';

class EncryptionService {
  static const String _keyBoxName = 'nexchat_keys';
  static const String _privateKeyField = 'private_key';
  static const String _publicKeyField = 'public_key';

  late Box _keyBox;

  Future<void> init() async {
    // Use HiveAesCipher with a key derived from device ID
    final encKey = await _deriveBoxKey();
    _keyBox = await Hive.openBox(
      _keyBoxName,
      encryptionCipher: HiveAesCipher(encKey),
    );
  }

  /// Generate RSA-2048 key pair for new user
  Future<Map<String, String>> generateKeyPair() async {
    final keyGen = RSAKeyGenerator()
      ..init(ParametersWithRandom(
        RSAKeyGeneratorParameters(BigInt.parse('65537'), 2048, 64),
        _secureRandom(),
      ));

    final pair = keyGen.generateKeyPair();
    final publicKey = pair.publicKey as RSAPublicKey;
    final privateKey = pair.privateKey as RSAPrivateKey;

    final publicPem = _encodePublicKeyToPem(publicKey);
    final privatePem = _encodePrivateKeyToPem(privateKey);

    // Store private key ONLY on device
    await _keyBox.put(_privateKeyField, privatePem);
    await _keyBox.put(_publicKeyField, publicPem);

    return {'publicKey': publicPem, 'privateKey': privatePem};
  }

  /// Encrypt message text using recipient's public key + AES-256
  String encryptMessage(String plaintext, String recipientPublicKeyPem) {
    // 1. Generate random AES-256 session key
    final aesKey = enc.Key.fromSecureRandom(32);
    final iv = enc.IV.fromSecureRandom(16);
    final encrypter = enc.Encrypter(enc.AES(aesKey, mode: enc.AESMode.gcm));

    // 2. Encrypt message with AES
    final encryptedMessage = encrypter.encrypt(plaintext, iv: iv);

    // 3. Encrypt AES key with recipient's RSA public key
    final rsaPublicKey = _parsePublicKeyFromPem(recipientPublicKeyPem);
    final encryptedAesKey = _rsaEncrypt(aesKey.bytes, rsaPublicKey);

    // 4. Bundle: base64(encryptedAesKey) + "." + base64(iv) + "." + base64(ciphertext)
    return '${base64.encode(encryptedAesKey)}.${iv.base64}.${encryptedMessage.base64}';
  }

  /// Decrypt message using our private key
  String decryptMessage(String encryptedBundle) {
    final parts = encryptedBundle.split('.');
    if (parts.length != 3) throw Exception('Invalid encrypted bundle');

    final encryptedAesKey = base64.decode(parts[0]);
    final iv = enc.IV.fromBase64(parts[1]);
    final ciphertext = enc.Encrypted.fromBase64(parts[2]);

    // 1. Decrypt AES key with our private key
    final privateKeyPem = _keyBox.get(_privateKeyField) as String?;
    if (privateKeyPem == null) throw Exception('Private key not found');

    final rsaPrivateKey = _parsePrivateKeyFromPem(privateKeyPem);
    final aesKeyBytes = _rsaDecrypt(encryptedAesKey, rsaPrivateKey);
    final aesKey = enc.Key(Uint8List.fromList(aesKeyBytes));

    // 2. Decrypt message with AES key
    final encrypter = enc.Encrypter(enc.AES(aesKey, mode: enc.AESMode.gcm));
    return encrypter.decrypt(ciphertext, iv: iv);
  }

  String? getStoredPublicKey() => _keyBox.get(_publicKeyField) as String?;

  // ── Private helpers ──────────────────────────────────────────

  SecureRandom _secureRandom() {
    final random = FortunaRandom();
    final seed = List<int>.generate(32, (_) => Random.secure().nextInt(256));
    random.seed(KeyParameter(Uint8List.fromList(seed)));
    return random;
  }

  Future<Uint8List> _deriveBoxKey() async {
    // Derive from device-specific data + app salt
    // In production: use flutter_secure_storage or biometric-protected key
    final salt = 'nexchat_secure_salt_v1';
    final keyMaterial = utf8.encode(salt);
    return Uint8List.fromList(keyMaterial.take(32).toList());
  }

  Uint8List _rsaEncrypt(Uint8List data, RSAPublicKey publicKey) {
    final cipher = OAEPEncoding(RSAEngine())
      ..init(true, PublicKeyParameter<RSAPublicKey>(publicKey));
    return cipher.process(data);
  }

  Uint8List _rsaDecrypt(Uint8List data, RSAPrivateKey privateKey) {
    final cipher = OAEPEncoding(RSAEngine())
      ..init(false, PrivateKeyParameter<RSAPrivateKey>(privateKey));
    return cipher.process(data);
  }

  // PEM encoding/decoding helpers — implement standard PKCS8/X509 format
  String _encodePublicKeyToPem(RSAPublicKey key) { /* implement */ return ''; }
  String _encodePrivateKeyToPem(RSAPrivateKey key) { /* implement */ return ''; }
  RSAPublicKey _parsePublicKeyFromPem(String pem) { /* implement */ throw UnimplementedError(); }
  RSAPrivateKey _parsePrivateKeyFromPem(String pem) { /* implement */ throw UnimplementedError(); }
}
```

---

## ════════════════════════════════════════
## SECTION 7 — AUTHENTICATION MODULE
## ════════════════════════════════════════

### lib/services/firebase/auth_service.dart

AGENT: Implement complete phone authentication:

```dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../encryption/encryption_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final EncryptionService _encryption = EncryptionService();

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Current user
  User? get currentUser => _auth.currentUser;

  /// Step 1: Send OTP to phone number
  Future<void> sendOTP({
    required String phoneNumber,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(FirebaseAuthException e) onError,
    required void Function(PhoneAuthCredential credential) onAutoVerified,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: onAutoVerified,
      verificationFailed: onError,
      codeSent: onCodeSent,
      codeAutoRetrievalTimeout: (id) {},
      timeout: const Duration(seconds: 60),
    );
  }

  /// Step 2: Verify OTP and sign in
  Future<UserCredential> verifyOTP({
    required String verificationId,
    required String smsCode,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    return await _auth.signInWithCredential(credential);
  }

  /// Step 3: Create or update user in Firestore after first login
  Future<bool> setupUserProfile({
    required String uid,
    required String phone,
    required String name,
    String? username,
    String? profilePicUrl,
  }) async {
    // Generate encryption keys for new user
    await _encryption.init();
    final keys = await _encryption.generateKeyPair();

    final userRef = _firestore.collection('users').doc(uid);
    final userDoc = await userRef.get();

    if (!userDoc.exists) {
      // New user — create full profile
      await userRef.set({
        'uid': uid,
        'phone': phone,
        'name': name,
        'username': username ?? '',
        'bio': '',
        'profilePicUrl': profilePicUrl ?? '',
        'publicKey': keys['publicKey'],
        'status': 'offline',
        'lastSeen': FieldValue.serverTimestamp(),
        'pinnedChats': [],
        'blockedUsers': [],
        'biometricEnabled': false,
        'createdAt': FieldValue.serverTimestamp(),
        'deviceTokens': [],
        'privacySettings': {
          'lastSeen': 'everyone',
          'profilePhoto': 'everyone',
          'about': 'everyone',
          'readReceipts': true,
        },
      });
      return true; // new user
    } else {
      // Existing user — update device token and status
      await userRef.update({
        'status': 'online',
        'lastSeen': FieldValue.serverTimestamp(),
      });
      return false; // existing user
    }
  }

  /// Update user online status
  Future<void> updateOnlineStatus(bool isOnline) async {
    final uid = currentUser?.uid;
    if (uid == null) return;
    await _firestore.collection('users').doc(uid).update({
      'status': isOnline ? 'online' : 'offline',
      'lastSeen': FieldValue.serverTimestamp(),
    });
  }

  /// Sign out
  Future<void> signOut() async {
    await updateOnlineStatus(false);
    await _auth.signOut();
  }
}
```

### lib/features/auth/screens/phone_input_screen.dart

AGENT: Build a Gen-Z styled phone input screen with:
- Animated gradient background (purple → cyan → pink)
- Glassmorphism card for the input
- Country code picker (intl_phone_number_input)
- Smooth loading animation when sending OTP
- Error handling with SnackBar

### lib/features/auth/screens/otp_verification_screen.dart

AGENT: Build OTP screen with:
- 6 individual digit boxes (auto-advance on input)
- Auto-fill from SMS
- 60-second countdown resend timer
- Animated success checkmark on correct OTP (Lottie)

---

## ════════════════════════════════════════
## SECTION 8 — CHAT ENGINE
## ════════════════════════════════════════

### lib/services/firebase/firestore_service.dart

AGENT: Implement ALL these Firestore operations:

```dart
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Chat Operations ──────────────────────────────────────────

  /// Create or get existing private chat between two users
  Future<String> getOrCreatePrivateChat(String userId1, String userId2) async {
    // Check if chat already exists
    final existing = await _db.collection('chats')
      .where('type', isEqualTo: 'private')
      .where('participants', arrayContains: userId1)
      .get();

    for (final doc in existing.docs) {
      final participants = List<String>.from(doc['participants']);
      if (participants.contains(userId2)) return doc.id;
    }

    // Create new chat
    final chatRef = _db.collection('chats').doc();
    await chatRef.set({
      'chatId': chatRef.id,
      'type': 'private',
      'participants': [userId1, userId2],
      'admins': [],
      'createdBy': userId1,
      'isE2EEnabled': true,
      'disappearingTimer': 0,
      'lastActivity': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    return chatRef.id;
  }

  /// Send a message
  Future<void> sendMessage(Map<String, dynamic> messageData) async {
    final msgRef = _db.collection('messages').doc();
    final batch = _db.batch();

    // Add message
    batch.set(msgRef, {
      ...messageData,
      'messageId': msgRef.id,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Update chat's lastMessage and lastActivity
    final chatRef = _db.collection('chats').doc(messageData['chatId']);
    batch.update(chatRef, {
      'lastMessage': {
        'text': '[Encrypted]',
        'senderId': messageData['senderId'],
        'timestamp': FieldValue.serverTimestamp(),
        'type': messageData['type'],
      },
      'lastActivity': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  /// Real-time message stream with pagination
  Stream<List<MessageModel>> getMessages(String chatId, {int limit = 30}) {
    return _db.collection('messages')
      .where('chatId', isEqualTo: chatId)
      .where('isDeleted', isEqualTo: false)
      .orderBy('timestamp', descending: true)
      .limit(limit)
      .snapshots()
      .map((snap) => snap.docs
          .map((d) => MessageModel.fromJson(d.data()))
          .toList());
  }

  /// Get user's chat list (real-time)
  Stream<List<ChatModel>> getUserChats(String userId) {
    return _db.collection('chats')
      .where('participants', arrayContains: userId)
      .orderBy('lastActivity', descending: true)
      .snapshots()
      .map((snap) => snap.docs
          .map((d) => ChatModel.fromJson(d.data()))
          .toList());
  }

  /// Edit message
  Future<void> editMessage(String messageId, String newEncryptedText) async {
    await _db.collection('messages').doc(messageId).update({
      'encryptedText': newEncryptedText,
      'edited': true,
      'editedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Delete message for everyone
  Future<void> deleteMessage(String messageId, {bool forEveryone = true}) async {
    await _db.collection('messages').doc(messageId).update({
      'isDeleted': true,
      'deletedForEveryone': forEveryone,
      'deletedAt': FieldValue.serverTimestamp(),
      'encryptedText': '',
    });
  }

  /// Mark messages as read
  Future<void> markAsRead(String chatId, String userId) async {
    final unread = await _db.collection('messages')
      .where('chatId', isEqualTo: chatId)
      .where('readBy.$userId', isNull: true)
      .where('senderId', isNotEqualTo: userId)
      .get();

    final batch = _db.batch();
    for (final doc in unread.docs) {
      batch.update(doc.reference, {
        'readBy.$userId': FieldValue.serverTimestamp(),
        'status': 'read',
      });
    }
    await batch.commit();
  }

  /// Add/update reaction to message
  Future<void> addReaction(String messageId, String userId, String emoji) async {
    await _db.collection('messages').doc(messageId).update({
      'reactions.$userId': emoji,
    });
  }

  /// Pin/unpin message in chat
  Future<void> pinMessage(String chatId, String messageId) async {
    await _db.collection('chats').doc(chatId).update({
      'pinnedMessageId': messageId,
    });
    await _db.collection('messages').doc(messageId).update({
      'isPinned': true,
    });
  }

  /// Set typing indicator
  Future<void> setTyping(String chatId, String userId, bool isTyping) async {
    await _db.collection('chats').doc(chatId)
      .collection('typing').doc(userId).set({
        'isTyping': isTyping,
        'timestamp': FieldValue.serverTimestamp(),
      });
  }

  // ── Group Operations ──────────────────────────────────────────

  Future<String> createGroup({
    required String creatorId,
    required String name,
    required List<String> members,
    String? description,
    String? avatarUrl,
  }) async {
    final chatRef = _db.collection('chats').doc();
    final inviteLink = 'https://nexchat.app/join/${chatRef.id}';

    await chatRef.set({
      'chatId': chatRef.id,
      'type': 'group',
      'participants': [creatorId, ...members],
      'admins': [creatorId],
      'createdBy': creatorId,
      'name': name,
      'description': description ?? '',
      'avatarUrl': avatarUrl ?? '',
      'inviteLink': inviteLink,
      'isE2EEnabled': true,
      'disappearingTimer': 0,
      'maxMembers': 1024,
      'lastActivity': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    return chatRef.id;
  }

  Future<void> addGroupMembers(String chatId, List<String> newMembers) async {
    await _db.collection('chats').doc(chatId).update({
      'participants': FieldValue.arrayUnion(newMembers),
    });
  }

  Future<void> removeGroupMember(String chatId, String userId) async {
    await _db.collection('chats').doc(chatId).update({
      'participants': FieldValue.arrayRemove([userId]),
      'admins': FieldValue.arrayRemove([userId]),
    });
  }

  // ── Poll Operations ──────────────────────────────────────────

  Future<void> createPoll(Map<String, dynamic> pollData) async {
    final pollRef = _db.collection('polls').doc();
    await pollRef.set({...pollData, 'pollId': pollRef.id});
  }

  Future<void> votePoll(String pollId, String optionId, String userId) async {
    await _db.collection('polls').doc(pollId).update({
      'votes.$optionId': FieldValue.arrayUnion([userId]),
    });
  }

  // ── User Operations ──────────────────────────────────────────

  Future<UserModel?> getUser(String userId) async {
    final doc = await _db.collection('users').doc(userId).get();
    if (!doc.exists) return null;
    return UserModel.fromJson({...doc.data()!, 'uid': doc.id});
  }

  Stream<UserModel?> watchUser(String userId) {
    return _db.collection('users').doc(userId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromJson({...doc.data()!, 'uid': doc.id});
    });
  }

  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    await _db.collection('users').doc(userId).update(data);
  }

  Future<void> blockUser(String myId, String targetId) async {
    await _db.collection('users').doc(myId).update({
      'blockedUsers': FieldValue.arrayUnion([targetId]),
    });
  }

  Future<void> pinChat(String userId, String chatId) async {
    await _db.collection('users').doc(userId).update({
      'pinnedChats': FieldValue.arrayUnion([chatId]),
    });
  }
}
```

---

## ════════════════════════════════════════
## SECTION 9 — MEDIA SERVICE
## ════════════════════════════════════════

### lib/services/firebase/storage_service.dart

AGENT: Implement media upload with:
- Image compression before upload (flutter_image_compress)
- Video compression before upload
- Encrypted filename (UUID-based, no original filename)
- Progress callback
- Download URL retrieval

```dart
class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadMedia({
    required File file,
    required String chatId,
    required String userId,
    required String messageId,
    void Function(double progress)? onProgress,
  }) async {
    // Compress if image
    File uploadFile = file;
    final mime = lookupMimeType(file.path);

    if (mime?.startsWith('image/') == true) {
      final compressed = await FlutterImageCompress.compressAndGetFile(
        file.path,
        '${file.parent.path}/${messageId}_compressed.jpg',
        quality: 75,
        minWidth: 1280,
        minHeight: 720,
      );
      if (compressed != null) uploadFile = compressed;
    }

    // Upload to Firebase Storage
    final ext = extension(file.path);
    final ref = _storage.ref('chats/$chatId/$messageId$ext');
    final task = ref.putFile(uploadFile);

    task.snapshotEvents.listen((snap) {
      final progress = snap.bytesTransferred / snap.totalBytes;
      onProgress?.call(progress);
    });

    await task;
    return await ref.getDownloadURL();
  }

  Future<void> deleteMedia(String url) async {
    final ref = _storage.refFromURL(url);
    await ref.delete();
  }
}
```

---

## ════════════════════════════════════════
## SECTION 10 — NOTIFICATIONS SERVICE
## ════════════════════════════════════════

### lib/services/notification_service.dart

AGENT: Implement:
- FCM token registration + refresh
- Foreground notification handling
- Background/terminated notification handling
- Deep-link navigation on tap (open specific chat)
- Local notification display with flutter_local_notifications
- Notification categories: message, call, mention, group

```dart
class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotif = FlutterLocalNotificationsPlugin();

  Future<void> init(BuildContext context) async {
    // Request permission
    await _fcm.requestPermission(alert: true, badge: true, sound: true);

    // Get token and save to Firestore
    final token = await _fcm.getToken();
    if (token != null) await _saveTokenToFirestore(token);

    // Handle token refresh
    _fcm.onTokenRefresh.listen(_saveTokenToFirestore);

    // Init local notifications
    await _localNotif.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: (details) {
        // Navigate to chat from payload
        final chatId = details.payload;
        if (chatId != null) context.push('/chat/$chatId');
      },
    );

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background tap
    FirebaseMessaging.onMessageOpenedApp.listen((msg) {
      final chatId = msg.data['chatId'];
      if (chatId != null) context.push('/chat/$chatId');
    });
  }

  Future<void> _handleForegroundMessage(RemoteMessage msg) async {
    await _localNotif.show(
      msg.hashCode,
      msg.notification?.title,
      msg.notification?.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'nexchat_messages',
          'Messages',
          channelDescription: 'NexChat message notifications',
          importance: Importance.high,
          priority: Priority.high,
          styleInformation: BigTextStyleInformation(msg.notification?.body ?? ''),
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: msg.data['chatId'],
    );
  }

  Future<void> _saveTokenToFirestore(String token) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'deviceTokens': FieldValue.arrayUnion([token]),
    });
  }
}
```

---

## ════════════════════════════════════════
## SECTION 11 — CALLS (WebRTC)
## ════════════════════════════════════════

### lib/services/call_service.dart

AGENT: Implement WebRTC calling with Firebase signaling:

```dart
class CallService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;

  final RTCConfiguration _config = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
    ]
  };

  Future<MediaStream> getUserMedia({bool video = false}) async {
    return await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': video ? {'facingMode': 'user'} : false,
    });
  }

  /// Caller: create offer + store in Firestore
  Future<String> initiateCall({
    required String callerId,
    required String receiverId,
    required bool isVideo,
  }) async {
    _localStream = await getUserMedia(video: isVideo);
    _peerConnection = await createPeerConnection(_config);

    _localStream!.getTracks().forEach((track) {
      _peerConnection!.addTrack(track, _localStream!);
    });

    final callRef = _db.collection('calls').doc();
    final callId = callRef.id;

    // Collect ICE candidates
    final candidates = <RTCIceCandidate>[];
    _peerConnection!.onIceCandidate = (c) {
      if (c.candidate != null) candidates.add(c);
    };

    // Create offer
    final offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);

    await callRef.set({
      'callId': callId,
      'type': isVideo ? 'video' : 'voice',
      'callerId': callerId,
      'receiverIds': [receiverId],
      'status': 'ringing',
      'startedAt': FieldValue.serverTimestamp(),
      'signalingData': {
        'offer': offer.sdp,
        'iceCandidates': [],
      },
    });

    // Listen for answer
    callRef.snapshots().listen((snap) async {
      final data = snap.data();
      if (data?['signalingData']?['answer'] != null && _peerConnection != null) {
        final answer = RTCSessionDescription(
          data!['signalingData']['answer'],
          'answer',
        );
        await _peerConnection!.setRemoteDescription(answer);
      }
    });

    return callId;
  }

  /// Receiver: answer the call
  Future<void> answerCall(String callId) async {
    _localStream = await getUserMedia(video: false);
    _peerConnection = await createPeerConnection(_config);

    _localStream!.getTracks().forEach((track) {
      _peerConnection!.addTrack(track, _localStream!);
    });

    final callDoc = await _db.collection('calls').doc(callId).get();
    final offer = RTCSessionDescription(
      callDoc.data()!['signalingData']['offer'],
      'offer',
    );

    await _peerConnection!.setRemoteDescription(offer);
    final answer = await _peerConnection!.createAnswer();
    await _peerConnection!.setLocalDescription(answer);

    await _db.collection('calls').doc(callId).update({
      'status': 'accepted',
      'signalingData.answer': answer.sdp,
    });
  }

  Future<void> endCall(String callId) async {
    await _peerConnection?.close();
    await _localStream?.dispose();
    _peerConnection = null;
    _localStream = null;

    await _db.collection('calls').doc(callId).update({
      'status': 'ended',
      'endedAt': FieldValue.serverTimestamp(),
    });
  }
}
```

---

## ════════════════════════════════════════
## SECTION 12 — STATUS / STORIES
## ════════════════════════════════════════

### lib/services/firebase/status_service.dart

AGENT: Implement:
- Post text/image/video status (expires in 24 hours)
- Fetch statuses from contacts only
- Track viewers
- Delete own status
- Cloud Function to auto-delete expired statuses

```dart
class StatusService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final StorageService _storage = StorageService();

  Future<void> postStatus({
    required String userId,
    required String type,
    String? textContent,
    File? mediaFile,
    String? backgroundColor,
  }) async {
    String? mediaUrl;
    if (mediaFile != null) {
      final statusId = const Uuid().v4();
      mediaUrl = await _storage.uploadMedia(
        file: mediaFile,
        chatId: 'status',
        userId: userId,
        messageId: statusId,
      );
    }

    final statusRef = _db.collection('status').doc();
    await statusRef.set({
      'statusId': statusRef.id,
      'userId': userId,
      'type': type,
      'content': textContent ?? '',
      'mediaUrl': mediaUrl ?? '',
      'backgroundColor': backgroundColor ?? '#1a1a2e',
      'seenBy': [],
      'expiresAt': Timestamp.fromDate(
        DateTime.now().add(const Duration(hours: 24))
      ),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Map<String, dynamic>>> getContactStatuses(List<String> contactIds) {
    return _db.collection('status')
      .where('userId', whereIn: contactIds)
      .where('expiresAt', isGreaterThan: Timestamp.now())
      .orderBy('expiresAt')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map((d) => d.data()).toList());
  }

  Future<void> markStatusSeen(String statusId, String viewerId) async {
    await _db.collection('status').doc(statusId).update({
      'seenBy': FieldValue.arrayUnion([viewerId]),
    });
  }
}
```

---

## ════════════════════════════════════════
## SECTION 13 — CONTACT SYNC
## ════════════════════════════════════════

### lib/services/contact_sync_service.dart

AGENT: Implement:
- Request contacts permission
- Read phone contacts
- Normalize phone numbers (E.164 format)
- Query Firestore to find which contacts are on NexChat
- Return matched users

```dart
class ContactSyncService {
  Future<List<UserModel>> syncContacts() async {
    // 1. Request permission
    final status = await Permission.contacts.request();
    if (!status.isGranted) return [];

    // 2. Get all phone contacts
    final contacts = await ContactsService.getContacts(withThumbnails: false);
    final phones = contacts
      .expand((c) => c.phones ?? [])
      .map((p) => _normalizePhone(p.value ?? ''))
      .where((p) => p.isNotEmpty)
      .toList();

    if (phones.isEmpty) return [];

    // 3. Query Firestore in batches of 10 (Firestore whereIn limit)
    final List<UserModel> nexChatUsers = [];
    for (int i = 0; i < phones.length; i += 10) {
      final batch = phones.sublist(i, min(i + 10, phones.length));
      final snap = await FirebaseFirestore.instance
        .collection('users')
        .where('phone', whereIn: batch)
        .get();
      nexChatUsers.addAll(
        snap.docs.map((d) => UserModel.fromJson({...d.data(), 'uid': d.id}))
      );
    }

    return nexChatUsers;
  }

  String _normalizePhone(String phone) {
    // Strip everything except digits and leading +
    final digits = phone.replaceAll(RegExp(r'[^\d+]'), '');
    if (digits.isEmpty) return '';
    return digits.startsWith('+') ? digits : '+$digits';
  }
}
```

---

## ════════════════════════════════════════
## SECTION 14 — CLOUD FUNCTIONS
## ════════════════════════════════════════

AGENT: Create `functions/src/index.ts` with these Cloud Functions:

```typescript
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

admin.initializeApp();
const db = admin.firestore();

// ── 1. Auto-delete expired statuses (runs every hour) ──────────
export const deleteExpiredStatuses = functions.pubsub
  .schedule('every 60 minutes')
  .onRun(async () => {
    const now = admin.firestore.Timestamp.now();
    const expired = await db.collection('status')
      .where('expiresAt', '<=', now)
      .get();

    const batch = db.batch();
    expired.docs.forEach(doc => batch.delete(doc.ref));
    await batch.commit();
  });

// ── 2. Send scheduled messages (runs every minute) ─────────────
export const sendScheduledMessages = functions.pubsub
  .schedule('every 1 minutes')
  .onRun(async () => {
    const now = admin.firestore.Timestamp.now();
    const pending = await db.collection('scheduled_messages')
      .where('status', '==', 'pending')
      .where('scheduledAt', '<=', now)
      .get();

    for (const doc of pending.docs) {
      const data = doc.data();
      const msgRef = db.collection('messages').doc();

      await db.runTransaction(async (t) => {
        t.set(msgRef, {
          ...data,
          messageId: msgRef.id,
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
        });
        t.update(doc.ref, { status: 'sent' });
      });
    }
  });

// ── 3. Auto-delete self-destruct messages ──────────────────────
export const deleteSelfDestructMessages = functions.pubsub
  .schedule('every 1 minutes')
  .onRun(async () => {
    const now = admin.firestore.Timestamp.now();
    const messages = await db.collection('messages')
      .where('selfDestructTime', '>', 0)
      .get();

    const batch = db.batch();
    for (const doc of messages.docs) {
      const data = doc.data();
      const createdAt = data.timestamp?.toDate();
      if (!createdAt) continue;

      const expiresAt = new Date(createdAt.getTime() + data.selfDestructTime * 1000);
      if (expiresAt <= now.toDate()) {
        batch.update(doc.ref, {
          isDeleted: true,
          deletedForEveryone: true,
          encryptedText: '',
          deletedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }
    }
    await batch.commit();
  });

// ── 4. Send FCM push notification on new message ───────────────
export const onNewMessage = functions.firestore
  .document('messages/{messageId}')
  .onCreate(async (snap) => {
    const msg = snap.data();
    const chatId = msg.chatId;
    const senderId = msg.senderId;

    const chatDoc = await db.collection('chats').doc(chatId).get();
    const participants: string[] = chatDoc.data()?.participants || [];

    const receiverIds = participants.filter(id => id !== senderId);

    for (const receiverId of receiverIds) {
      const userDoc = await db.collection('users').doc(receiverId).get();
      const tokens: string[] = userDoc.data()?.deviceTokens || [];

      const senderDoc = await db.collection('users').doc(senderId).get();
      const senderName = senderDoc.data()?.name || 'Someone';

      if (tokens.length > 0) {
        await admin.messaging().sendEachForMulticast({
          tokens,
          notification: {
            title: senderName,
            body: msg.type === 'text' ? '🔒 Encrypted message' : `📎 ${msg.type}`,
          },
          data: { chatId, senderId, messageId: snap.id },
          android: {
            priority: 'high',
            notification: { channelId: 'nexchat_messages' },
          },
          apns: {
            payload: { aps: { contentAvailable: true, badge: 1 } },
          },
        });
      }
    }
  });

// ── 5. On call initiated — notify receiver ─────────────────────
export const onCallInitiated = functions.firestore
  .document('calls/{callId}')
  .onCreate(async (snap) => {
    const call = snap.data();
    if (call.status !== 'ringing') return;

    const callerDoc = await db.collection('users').doc(call.callerId).get();
    const callerName = callerDoc.data()?.name || 'Unknown';

    for (const receiverId of call.receiverIds) {
      const userDoc = await db.collection('users').doc(receiverId).get();
      const tokens: string[] = userDoc.data()?.deviceTokens || [];

      if (tokens.length > 0) {
        await admin.messaging().sendEachForMulticast({
          tokens,
          notification: {
            title: `Incoming ${call.type} call`,
            body: `${callerName} is calling you`,
          },
          data: {
            type: 'call',
            callId: snap.id,
            callType: call.type,
            callerId: call.callerId,
          },
          android: { priority: 'high' },
          apns: {
            payload: { aps: { contentAvailable: true, badge: 0 } },
          },
        });
      }
    }
  });
```

---

## ════════════════════════════════════════
## SECTION 15 — THEME (GEN-Z DARK UI)
## ════════════════════════════════════════

### lib/core/theme/app_colors.dart

```dart
class AppColors {
  // ── Background ────────────────────────────────────────────────
  static const bg100 = Color(0xFF0A0A0F);   // deepest bg
  static const bg200 = Color(0xFF12121A);   // card bg
  static const bg300 = Color(0xFF1A1A2E);   // elevated surface

  // ── Brand (neon) ──────────────────────────────────────────────
  static const primary = Color(0xFF7C3AED);    // vivid purple
  static const secondary = Color(0xFF06B6D4);  // cyan
  static const accent = Color(0xFFEC4899);     // hot pink

  // ── Neon Glow ─────────────────────────────────────────────────
  static const neonPurple = Color(0xFFBF40FF);
  static const neonCyan = Color(0xFF00FFF7);
  static const neonPink = Color(0xFFFF006E);

  // ── Text ──────────────────────────────────────────────────────
  static const textPrimary = Color(0xFFF0F0F7);
  static const textSecondary = Color(0xFF9898B8);
  static const textMuted = Color(0xFF5A5A7A);

  // ── Status ────────────────────────────────────────────────────
  static const online = Color(0xFF22C55E);
  static const away = Color(0xFFFACC15);
  static const offline = Color(0xFF6B7280);
  static const error = Color(0xFFEF4444);

  // ── Message Bubbles ───────────────────────────────────────────
  static const myBubble = Color(0xFF4C1D95);    // dark purple (sent)
  static const theirBubble = Color(0xFF1E1E2E); // dark surface (received)

  // ── Gradients ─────────────────────────────────────────────────
  static const List<Color> primaryGradient = [
    Color(0xFF7C3AED),
    Color(0xFFEC4899),
  ];
  static const List<Color> bgGradient = [
    Color(0xFF0A0A0F),
    Color(0xFF1A1A2E),
    Color(0xFF0A0A1F),
  ];
}
```

### lib/core/theme/app_theme.dart

```dart
class AppTheme {
  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.bg100,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.bg200,
      error: AppColors.error,
    ),
    fontFamily: 'Inter',
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.bg200,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        fontFamily: 'Inter',
      ),
      iconTheme: IconThemeData(color: AppColors.textPrimary),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.bg300,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      hintStyle: const TextStyle(color: AppColors.textMuted),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          fontFamily: 'Inter',
        ),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.bg200,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textMuted,
    ),
  );
}
```

---

## ════════════════════════════════════════
## SECTION 16 — ROUTER (GoRouter)
## ════════════════════════════════════════

### lib/app/router.dart

```dart
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  
  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final isLoggedIn = authState.valueOrNull != null;
      final isAuthRoute = state.fullPath?.startsWith('/auth') ?? false;
      
      if (!isLoggedIn && !isAuthRoute && state.fullPath != '/splash') {
        return '/auth/phone';
      }
      if (isLoggedIn && isAuthRoute) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
      
      // Auth routes
      GoRoute(path: '/auth/phone', builder: (_, __) => const PhoneInputScreen()),
      GoRoute(path: '/auth/otp', builder: (_, state) => OTPScreen(
        verificationId: state.extra as String,
      )),
      GoRoute(path: '/auth/setup', builder: (_, __) => const ProfileSetupScreen()),
      
      // Main app (shell route with bottom nav)
      ShellRoute(
        builder: (_, __, child) => MainShell(child: child),
        routes: [
          GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
          GoRoute(path: '/calls', builder: (_, __) => const CallsScreen()),
          GoRoute(path: '/status', builder: (_, __) => const StatusScreen()),
          GoRoute(path: '/contacts', builder: (_, __) => const ContactsScreen()),
          GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
        ],
      ),
      
      // Chat routes
      GoRoute(
        path: '/chat/:chatId',
        builder: (_, state) => ChatScreen(chatId: state.pathParameters['chatId']!),
      ),
      GoRoute(
        path: '/group/:chatId',
        builder: (_, state) => GroupChatScreen(chatId: state.pathParameters['chatId']!),
      ),
      
      // Call routes
      GoRoute(
        path: '/call/incoming/:callId',
        builder: (_, state) => IncomingCallScreen(callId: state.pathParameters['callId']!),
      ),
      GoRoute(
        path: '/call/voice/:callId',
        builder: (_, state) => VoiceCallScreen(callId: state.pathParameters['callId']!),
      ),
      GoRoute(
        path: '/call/video/:callId',
        builder: (_, state) => VideoCallScreen(callId: state.pathParameters['callId']!),
      ),
      
      // Profile & Settings
      GoRoute(
        path: '/profile/:userId',
        builder: (_, state) => ContactProfileScreen(userId: state.pathParameters['userId']!),
      ),
      GoRoute(path: '/settings/privacy', builder: (_, __) => const PrivacySettingsScreen()),
      GoRoute(path: '/settings/notifications', builder: (_, __) => const NotificationSettingsScreen()),
      GoRoute(path: '/settings/security', builder: (_, __) => const SecuritySettingsScreen()),
      GoRoute(path: '/settings/backup', builder: (_, __) => const BackupSettingsScreen()),
    ],
  );
});
```

---

## ════════════════════════════════════════
## SECTION 17 — MAIN.DART
## ════════════════════════════════════════

### lib/main.dart

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'firebase_options.dart';
import 'app/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // System UI
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF0A0A0F),
  ));

  // Lock to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Init Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Init Hive
  await Hive.initFlutter();

  runApp(const ProviderScope(child: NexChatApp()));
}
```

### lib/app/app.dart

```dart
class NexChatApp extends ConsumerWidget {
  const NexChatApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'NexChat',
      theme: AppTheme.darkTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
        child: child!,
      ),
    );
  }
}
```

---

## ════════════════════════════════════════
## SECTION 18 — ANDROID MANIFEST
## ════════════════════════════════════════

Add to android/app/src/main/AndroidManifest.xml inside <manifest>:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.READ_CONTACTS"/>
<uses-permission android:name="android.permission.WRITE_CONTACTS"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.VIBRATE"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.USE_BIOMETRIC"/>
<uses-permission android:name="android.permission.USE_FINGERPRINT"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="com.google.android.c2dm.permission.RECEIVE"/>
```

Set in android/app/build.gradle:
```
minSdkVersion 21
targetSdkVersion 34
compileSdkVersion 34
multiDexEnabled true
```

---

## ════════════════════════════════════════
## SECTION 19 — BUILD ORDER FOR AGENT
## ════════════════════════════════════════

AGENT: Build in this exact order, complete each before starting next:

### PHASE 1 — Foundation
1. Create Flutter project: flutter create nexchat --org com.nexchat
2. Replace pubspec.yaml with Section 1 exactly
3. Create all folders from Section 2
4. Run: flutter pub get
5. Run: flutterfire configure
6. Implement main.dart and app.dart (Section 17)
7. Implement AppColors and AppTheme (Section 15)

### PHASE 2 — Data Layer
8. Create all Models with freezed (Section 5)
9. Run: dart run build_runner build --delete-conflicting-outputs
10. Implement EncryptionService (Section 6)
11. Implement FirestoreService (Section 8)
12. Implement StorageService (Section 9)
13. Implement AuthService (Section 7)

### PHASE 3 — Auth Screens
14. SplashScreen (animated logo with Lottie)
15. OnboardingScreen (3 swipe pages, Gen-Z design)
16. PhoneInputScreen (Section 7 spec)
17. OTPVerificationScreen (Section 7 spec)
18. ProfileSetupScreen (photo upload + name + username)

### PHASE 4 — Core Chat
19. Implement GoRouter (Section 16)
20. HomeScreen with bottom navigation
21. ChatListTile widget
22. ChatScreen with message list
23. MessageBubble widget (sent/received)
24. MessageInputBar (text + emoji + media + voice)
25. Implement sendMessage, getMessages in providers

### PHASE 5 — Message Features
26. Voice message recorder + player
27. Image/Video sharing
28. Message reactions bar
29. Reply preview
30. Forward message
31. Edit/Delete message
32. Pinned message
33. Typing indicator
34. Read receipts (✓✓)

### PHASE 6 — Groups & Channels
35. CreateGroupScreen
36. GroupInfoScreen
37. Broadcast Channels
38. Group admin controls
39. Invite link generation

### PHASE 7 — Calls
40. CallService WebRTC (Section 11)
41. IncomingCallScreen
42. VoiceCallScreen
43. VideoCallScreen

### PHASE 8 — Advanced Features
44. StatusService + StatusScreen
45. PollWidget + createPoll
46. ScheduledMessages UI
47. SecretChat (self-destruct)
48. ContactSyncService
49. BiometricLock

### PHASE 9 — Settings & Backup
50. All Settings screens
51. PrivacySettings
52. NotificationSettings
53. BackupService (Google Drive)
54. StorageSettings

### PHASE 10 — Cloud Functions + Polish
55. Deploy Cloud Functions (Section 14)
56. NotificationService (Section 10)
57. Animations (Lottie/Rive on key screens)
58. Performance: lazy loading, caching
59. Unit tests
60. flutter build apk --release

---

## ════════════════════════════════════════
## SECTION 20 — CRITICAL RULES FOR AGENT
## ════════════════════════════════════════

1. NEVER store plaintext messages in Firestore — ALWAYS encrypt first
2. NEVER expose private keys — they stay on device in Hive encrypted box
3. ALWAYS use const constructors where possible
4. ALWAYS handle null safety — no ! force-unwrap without null check
5. ALWAYS use async/await, never .then() chains
6. ALWAYS show loading states during async operations
7. ALWAYS handle errors with user-friendly messages
8. ALWAYS use GoRouter for navigation, never Navigator directly
9. ALWAYS use Riverpod providers for state, never setState in feature screens
10. ALWAYS paginate message lists (load 30 at a time)
11. ALWAYS compress media before upload
12. ALWAYS dispose controllers, streams, and subscriptions in dispose()
13. NEVER hardcode strings — use AppConstants
14. ALWAYS support dark mode only (no light mode)
15. ALWAYS test on both Android and iOS before marking done

---

## ════════════════════════════════════════
## ENVIRONMENT CHECKLIST (DO FIRST)
## ════════════════════════════════════════

Before writing any code, verify:
□ Flutter 3.22+ installed (flutter --version)
□ Dart 3.4+ installed
□ Android Studio with Flutter + Dart plugins
□ Firebase CLI installed (npm install -g firebase-tools)
□ FlutterFire CLI installed (dart pub global activate flutterfire_cli)
□ Node.js 20+ installed (for Cloud Functions)
□ Firebase project created at console.firebase.google.com
□ google-services.json placed in android/app/
□ GoogleService-Info.plist placed in ios/Runner/
□ firebase_options.dart generated (flutterfire configure)

---

# END OF INSTRUCTIONS
# Total: 20 Sections | ~900 lines of spec
# App: NexChat | Stack: Flutter + Firebase + E2EE
```
