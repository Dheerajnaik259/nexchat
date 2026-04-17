/// Sub-model: Last message preview embedded in ChatModel
class LastMessage {
  final String text;        // "[encrypted preview]" or type hint
  final String senderId;
  final DateTime? timestamp;
  final String type;

  const LastMessage({
    this.text = '',
    this.senderId = '',
    this.timestamp,
    this.type = 'text',
  });

  factory LastMessage.fromJson(Map<String, dynamic> json) {
    return LastMessage(
      text: json['text'] as String? ?? '',
      senderId: json['sender_id'] as String? ?? json['senderId'] as String? ?? '',
      timestamp: _parseDateTime(json['timestamp']),
      type: json['type'] as String? ?? 'text',
    );
  }

  Map<String, dynamic> toJson() => {
    'text': text,
    'sender_id': senderId,
    'timestamp': timestamp?.toIso8601String(),
    'type': type,
  };

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}

/// Chat types
enum ChatType { private_, group, channel, secret }

/// Supabase table: chats
class ChatModel {
  final String chatId;
  final ChatType type;                 // "private" | "group" | "channel" | "secret"
  final List<String> participants;     // [userId]
  final List<String> admins;           // for groups/channels
  final String createdBy;
  final String? name;                  // for groups/channels
  final String? description;
  final String? avatarUrl;
  final LastMessage? lastMessage;
  final DateTime? lastActivity;
  final List<String> mutedBy;          // [userId]
  final String? pinnedMessageId;
  final String? inviteLink;            // for groups/channels
  final bool isE2EEnabled;
  final int disappearingTimer;         // seconds (0 = off)
  final int? maxMembers;
  final DateTime? createdAt;

  const ChatModel({
    required this.chatId,
    required this.type,
    required this.participants,
    this.admins = const [],
    required this.createdBy,
    this.name,
    this.description,
    this.avatarUrl,
    this.lastMessage,
    this.lastActivity,
    this.mutedBy = const [],
    this.pinnedMessageId,
    this.inviteLink,
    this.isE2EEnabled = true,
    this.disappearingTimer = 0,
    this.maxMembers,
    this.createdAt,
  });

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    return ChatModel(
      chatId: json['chat_id'] as String? ?? json['chatId'] as String? ?? json['id'] as String? ?? '',
      type: _chatTypeFromString(json['type'] as String? ?? 'private'),
      participants: List<String>.from(json['participants'] ?? []),
      admins: List<String>.from(json['admins'] ?? []),
      createdBy: json['created_by'] as String? ?? json['createdBy'] as String? ?? '',
      name: json['name'] as String?,
      description: json['description'] as String?,
      avatarUrl: json['avatar_url'] as String? ?? json['avatarUrl'] as String?,
      lastMessage: json['last_message'] != null
          ? LastMessage.fromJson(Map<String, dynamic>.from(json['last_message']))
          : json['lastMessage'] != null
              ? LastMessage.fromJson(Map<String, dynamic>.from(json['lastMessage']))
              : null,
      lastActivity: _parseDateTime(json['last_activity'] ?? json['lastActivity']),
      mutedBy: List<String>.from(json['muted_by'] ?? json['mutedBy'] ?? []),
      pinnedMessageId: json['pinned_message_id'] as String? ?? json['pinnedMessageId'] as String?,
      inviteLink: json['invite_link'] as String? ?? json['inviteLink'] as String?,
      isE2EEnabled: json['is_e2e_enabled'] as bool? ?? json['isE2EEnabled'] as bool? ?? true,
      disappearingTimer: json['disappearing_timer'] as int? ?? json['disappearingTimer'] as int? ?? 0,
      maxMembers: json['max_members'] as int? ?? json['maxMembers'] as int?,
      createdAt: _parseDateTime(json['created_at'] ?? json['createdAt']),
    );
  }

  /// Convert to Supabase-compatible JSON (snake_case)
  Map<String, dynamic> toJson() => {
    'id': chatId,
    'type': _chatTypeToString(type),
    'participants': participants,
    'admins': admins,
    'created_by': createdBy,
    'name': name,
    'description': description,
    'avatar_url': avatarUrl,
    'last_message': lastMessage?.toJson(),
    'last_activity': lastActivity?.toIso8601String(),
    'muted_by': mutedBy,
    'pinned_message_id': pinnedMessageId,
    'invite_link': inviteLink,
    'is_e2e_enabled': isE2EEnabled,
    'disappearing_timer': disappearingTimer,
    'max_members': maxMembers,
    'created_at': createdAt?.toIso8601String(),
  };

  ChatModel copyWith({
    String? chatId, ChatType? type, List<String>? participants,
    List<String>? admins, String? createdBy, String? name,
    String? description, String? avatarUrl, LastMessage? lastMessage,
    DateTime? lastActivity, List<String>? mutedBy, String? pinnedMessageId,
    String? inviteLink, bool? isE2EEnabled, int? disappearingTimer,
    int? maxMembers, DateTime? createdAt,
  }) {
    return ChatModel(
      chatId: chatId ?? this.chatId,
      type: type ?? this.type,
      participants: participants ?? this.participants,
      admins: admins ?? this.admins,
      createdBy: createdBy ?? this.createdBy,
      name: name ?? this.name,
      description: description ?? this.description,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      lastMessage: lastMessage ?? this.lastMessage,
      lastActivity: lastActivity ?? this.lastActivity,
      mutedBy: mutedBy ?? this.mutedBy,
      pinnedMessageId: pinnedMessageId ?? this.pinnedMessageId,
      inviteLink: inviteLink ?? this.inviteLink,
      isE2EEnabled: isE2EEnabled ?? this.isE2EEnabled,
      disappearingTimer: disappearingTimer ?? this.disappearingTimer,
      maxMembers: maxMembers ?? this.maxMembers,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static ChatType _chatTypeFromString(String value) {
    switch (value) {
      case 'private': return ChatType.private_;
      case 'group': return ChatType.group;
      case 'channel': return ChatType.channel;
      case 'secret': return ChatType.secret;
      default: return ChatType.private_;
    }
  }

  static String _chatTypeToString(ChatType type) {
    switch (type) {
      case ChatType.private_: return 'private';
      case ChatType.group: return 'group';
      case ChatType.channel: return 'channel';
      case ChatType.secret: return 'secret';
    }
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
