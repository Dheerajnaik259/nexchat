/// Sub-model: Privacy settings embedded in UserModel
class PrivacySettings {
  final String lastSeen;       // "everyone" | "contacts" | "nobody"
  final String profilePhoto;   // "everyone" | "contacts" | "nobody"
  final String about;          // "everyone" | "contacts" | "nobody"
  final bool readReceipts;

  const PrivacySettings({
    this.lastSeen = 'everyone',
    this.profilePhoto = 'everyone',
    this.about = 'everyone',
    this.readReceipts = true,
  });

  factory PrivacySettings.fromJson(Map<String, dynamic> json) {
    return PrivacySettings(
      lastSeen: json['lastSeen'] as String? ?? 'everyone',
      profilePhoto: json['profilePhoto'] as String? ?? 'everyone',
      about: json['about'] as String? ?? 'everyone',
      readReceipts: json['readReceipts'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'lastSeen': lastSeen,
    'profilePhoto': profilePhoto,
    'about': about,
    'readReceipts': readReceipts,
  };
}

/// Sub-model: Notification settings embedded in UserModel
class NotificationSettings {
  final bool muteAll;
  final bool showPreview;

  const NotificationSettings({
    this.muteAll = false,
    this.showPreview = true,
  });

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      muteAll: json['muteAll'] as bool? ?? false,
      showPreview: json['showPreview'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'muteAll': muteAll,
    'showPreview': showPreview,
  };
}

/// Supabase table: users
class UserModel {
  final String uid;
  final String phone;
  final String name;
  final String username;               // unique @handle
  final String bio;
  final String profilePicUrl;
  final String publicKey;              // RSA public key (base64)
  final String identityKey;            // Signal identity key
  final String signedPreKey;           // Signal signed pre-key
  final List<String> oneTimePreKeys;   // Signal one-time pre-keys
  final String status;                 // "online" | "offline" | "typing"
  final DateTime? lastSeen;
  final List<String> pinnedChats;      // chatIds
  final List<String> blockedUsers;     // userIds
  final PrivacySettings privacySettings;
  final NotificationSettings notificationSettings;
  final String? twoStepPin;           // hashed
  final bool biometricEnabled;
  final DateTime? createdAt;
  final List<String> deviceTokens;     // push notification tokens (multi-device)

  const UserModel({
    required this.uid,
    required this.phone,
    required this.name,
    this.username = '',
    this.bio = '',
    this.profilePicUrl = '',
    required this.publicKey,
    this.identityKey = '',
    this.signedPreKey = '',
    this.oneTimePreKeys = const [],
    this.status = 'offline',
    this.lastSeen,
    this.pinnedChats = const [],
    this.blockedUsers = const [],
    this.privacySettings = const PrivacySettings(),
    this.notificationSettings = const NotificationSettings(),
    this.twoStepPin,
    this.biometricEnabled = false,
    this.createdAt,
    this.deviceTokens = const [],
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] as String? ?? json['id'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      name: json['name'] as String? ?? '',
      username: json['username'] as String? ?? '',
      bio: json['bio'] as String? ?? '',
      profilePicUrl: json['profile_pic_url'] as String? ?? json['profilePicUrl'] as String? ?? '',
      publicKey: json['public_key'] as String? ?? json['publicKey'] as String? ?? '',
      identityKey: json['identity_key'] as String? ?? json['identityKey'] as String? ?? '',
      signedPreKey: json['signed_pre_key'] as String? ?? json['signedPreKey'] as String? ?? '',
      oneTimePreKeys: List<String>.from(json['one_time_pre_keys'] ?? json['oneTimePreKeys'] ?? []),
      status: json['status'] as String? ?? 'offline',
      lastSeen: _parseDateTime(json['last_seen'] ?? json['lastSeen']),
      pinnedChats: List<String>.from(json['pinned_chats'] ?? json['pinnedChats'] ?? []),
      blockedUsers: List<String>.from(json['blocked_users'] ?? json['blockedUsers'] ?? []),
      privacySettings: json['privacy_settings'] != null
          ? PrivacySettings.fromJson(Map<String, dynamic>.from(json['privacy_settings']))
          : json['privacySettings'] != null
              ? PrivacySettings.fromJson(Map<String, dynamic>.from(json['privacySettings']))
              : const PrivacySettings(),
      notificationSettings: json['notification_settings'] != null
          ? NotificationSettings.fromJson(Map<String, dynamic>.from(json['notification_settings']))
          : json['notificationSettings'] != null
              ? NotificationSettings.fromJson(Map<String, dynamic>.from(json['notificationSettings']))
              : const NotificationSettings(),
      twoStepPin: json['two_step_pin'] as String? ?? json['twoStepPin'] as String?,
      biometricEnabled: json['biometric_enabled'] as bool? ?? json['biometricEnabled'] as bool? ?? false,
      createdAt: _parseDateTime(json['created_at'] ?? json['createdAt']),
      deviceTokens: List<String>.from(json['device_tokens'] ?? json['deviceTokens'] ?? []),
    );
  }

  /// Convert to Supabase-compatible JSON (snake_case)
  Map<String, dynamic> toJson() => {
    'id': uid,
    'phone': phone,
    'name': name,
    'username': username,
    'bio': bio,
    'profile_pic_url': profilePicUrl,
    'public_key': publicKey,
    'identity_key': identityKey,
    'signed_pre_key': signedPreKey,
    'one_time_pre_keys': oneTimePreKeys,
    'status': status,
    'last_seen': lastSeen?.toIso8601String(),
    'pinned_chats': pinnedChats,
    'blocked_users': blockedUsers,
    'privacy_settings': privacySettings.toJson(),
    'notification_settings': notificationSettings.toJson(),
    'two_step_pin': twoStepPin,
    'biometric_enabled': biometricEnabled,
    'created_at': createdAt?.toIso8601String(),
    'device_tokens': deviceTokens,
  };

  UserModel copyWith({
    String? uid, String? phone, String? name, String? username, String? bio,
    String? profilePicUrl, String? publicKey, String? identityKey,
    String? signedPreKey, List<String>? oneTimePreKeys, String? status,
    DateTime? lastSeen, List<String>? pinnedChats, List<String>? blockedUsers,
    PrivacySettings? privacySettings, NotificationSettings? notificationSettings,
    String? twoStepPin, bool? biometricEnabled, DateTime? createdAt,
    List<String>? deviceTokens,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      phone: phone ?? this.phone,
      name: name ?? this.name,
      username: username ?? this.username,
      bio: bio ?? this.bio,
      profilePicUrl: profilePicUrl ?? this.profilePicUrl,
      publicKey: publicKey ?? this.publicKey,
      identityKey: identityKey ?? this.identityKey,
      signedPreKey: signedPreKey ?? this.signedPreKey,
      oneTimePreKeys: oneTimePreKeys ?? this.oneTimePreKeys,
      status: status ?? this.status,
      lastSeen: lastSeen ?? this.lastSeen,
      pinnedChats: pinnedChats ?? this.pinnedChats,
      blockedUsers: blockedUsers ?? this.blockedUsers,
      privacySettings: privacySettings ?? this.privacySettings,
      notificationSettings: notificationSettings ?? this.notificationSettings,
      twoStepPin: twoStepPin ?? this.twoStepPin,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      createdAt: createdAt ?? this.createdAt,
      deviceTokens: deviceTokens ?? this.deviceTokens,
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
