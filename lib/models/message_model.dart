/// Sub-model: Media metadata embedded in MessageModel
class MediaMetadata {
  final int? size;            // bytes
  final int? duration;        // ms
  final int? width;
  final int? height;
  final String? thumbnailUrl;

  const MediaMetadata({
    this.size,
    this.duration,
    this.width,
    this.height,
    this.thumbnailUrl,
  });

  factory MediaMetadata.fromJson(Map<String, dynamic> json) {
    return MediaMetadata(
      size: json['size'] as int?,
      duration: json['duration'] as int?,
      width: json['width'] as int?,
      height: json['height'] as int?,
      thumbnailUrl: json['thumbnail_url'] as String? ?? json['thumbnailUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'size': size,
    'duration': duration,
    'width': width,
    'height': height,
    'thumbnail_url': thumbnailUrl,
  };
}

/// Message types
enum MessageType { text, image, video, audio, document, poll, contact, location, sticker, gif, system }

/// Message delivery status
enum MessageStatus { sent, delivered, read, failed }

/// Supabase table: messages
class MessageModel {
  final String messageId;
  final String chatId;
  final String senderId;
  final MessageType type;
  final String encryptedText;          // ALWAYS encrypted, never plaintext
  final String? encryptedMediaUrl;
  final MediaMetadata? mediaMetadata;
  final String? replyToMessageId;
  final String? forwardedFrom;
  final Map<String, String> reactions; // userId → emoji
  final Map<String, DateTime> readBy;  // userId → timestamp
  final Map<String, DateTime> deliveredTo; // userId → timestamp
  final bool edited;
  final DateTime? editedAt;
  final List<String> editHistory;      // previous encrypted versions
  final bool isDeleted;
  final bool deletedForEveryone;
  final DateTime? deletedAt;
  final int selfDestructTime;          // seconds (0 = off)
  final bool isPinned;
  final DateTime? scheduledAt;         // null if not scheduled
  final MessageStatus status;
  final DateTime timestamp;
  final String? localId;               // for offline support

  const MessageModel({
    required this.messageId,
    required this.chatId,
    required this.senderId,
    required this.type,
    required this.encryptedText,
    this.encryptedMediaUrl,
    this.mediaMetadata,
    this.replyToMessageId,
    this.forwardedFrom,
    this.reactions = const {},
    this.readBy = const {},
    this.deliveredTo = const {},
    this.edited = false,
    this.editedAt,
    this.editHistory = const [],
    this.isDeleted = false,
    this.deletedForEveryone = false,
    this.deletedAt,
    this.selfDestructTime = 0,
    this.isPinned = false,
    this.scheduledAt,
    this.status = MessageStatus.sent,
    required this.timestamp,
    this.localId,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      messageId: json['message_id'] as String? ?? json['messageId'] as String? ?? json['id'] as String? ?? '',
      chatId: json['chat_id'] as String? ?? json['chatId'] as String? ?? '',
      senderId: json['sender_id'] as String? ?? json['senderId'] as String? ?? '',
      type: _messageTypeFromString(json['type'] as String? ?? 'text'),
      encryptedText: json['encrypted_text'] as String? ?? json['encryptedText'] as String? ?? '',
      encryptedMediaUrl: json['encrypted_media_url'] as String? ?? json['encryptedMediaUrl'] as String?,
      mediaMetadata: json['media_metadata'] != null
          ? MediaMetadata.fromJson(Map<String, dynamic>.from(json['media_metadata']))
          : json['mediaMetadata'] != null
              ? MediaMetadata.fromJson(Map<String, dynamic>.from(json['mediaMetadata']))
              : null,
      replyToMessageId: json['reply_to_message_id'] as String? ?? json['replyToMessageId'] as String?,
      forwardedFrom: json['forwarded_from'] as String? ?? json['forwardedFrom'] as String?,
      reactions: _parseStringMap(json['reactions']),
      readBy: _parseDateTimeMap(json['read_by'] ?? json['readBy']),
      deliveredTo: _parseDateTimeMap(json['delivered_to'] ?? json['deliveredTo']),
      edited: json['edited'] as bool? ?? false,
      editedAt: _parseDateTime(json['edited_at'] ?? json['editedAt']),
      editHistory: List<String>.from(json['edit_history'] ?? json['editHistory'] ?? []),
      isDeleted: json['is_deleted'] as bool? ?? json['isDeleted'] as bool? ?? false,
      deletedForEveryone: json['deleted_for_everyone'] as bool? ?? json['deletedForEveryone'] as bool? ?? false,
      deletedAt: _parseDateTime(json['deleted_at'] ?? json['deletedAt']),
      selfDestructTime: json['self_destruct_time'] as int? ?? json['selfDestructTime'] as int? ?? 0,
      isPinned: json['is_pinned'] as bool? ?? json['isPinned'] as bool? ?? false,
      scheduledAt: _parseDateTime(json['scheduled_at'] ?? json['scheduledAt']),
      status: _messageStatusFromString(json['status'] as String? ?? 'sent'),
      timestamp: _parseDateTime(json['timestamp'] ?? json['created_at']) ?? DateTime.now(),
      localId: json['local_id'] as String? ?? json['localId'] as String?,
    );
  }

  /// Convert to Supabase-compatible JSON (snake_case)
  Map<String, dynamic> toJson() => {
    'message_id': messageId,
    'chat_id': chatId,
    'sender_id': senderId,
    'type': _messageTypeToString(type),
    'encrypted_text': encryptedText,
    'encrypted_media_url': encryptedMediaUrl,
    'media_metadata': mediaMetadata?.toJson(),
    'reply_to_message_id': replyToMessageId,
    'forwarded_from': forwardedFrom,
    'reactions': reactions,
    'read_by': readBy.map((k, v) => MapEntry(k, v.toIso8601String())),
    'delivered_to': deliveredTo.map((k, v) => MapEntry(k, v.toIso8601String())),
    'edited': edited,
    'edited_at': editedAt?.toIso8601String(),
    'edit_history': editHistory,
    'is_deleted': isDeleted,
    'deleted_for_everyone': deletedForEveryone,
    'deleted_at': deletedAt?.toIso8601String(),
    'self_destruct_time': selfDestructTime,
    'is_pinned': isPinned,
    'scheduled_at': scheduledAt?.toIso8601String(),
    'status': _messageStatusToString(status),
    'timestamp': timestamp.toIso8601String(),
    'local_id': localId,
  };

  MessageModel copyWith({
    String? messageId, String? chatId, String? senderId, MessageType? type,
    String? encryptedText, String? encryptedMediaUrl, MediaMetadata? mediaMetadata,
    String? replyToMessageId, String? forwardedFrom, Map<String, String>? reactions,
    Map<String, DateTime>? readBy, Map<String, DateTime>? deliveredTo,
    bool? edited, DateTime? editedAt, List<String>? editHistory,
    bool? isDeleted, bool? deletedForEveryone, DateTime? deletedAt,
    int? selfDestructTime, bool? isPinned, DateTime? scheduledAt,
    MessageStatus? status, DateTime? timestamp, String? localId,
  }) {
    return MessageModel(
      messageId: messageId ?? this.messageId,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      type: type ?? this.type,
      encryptedText: encryptedText ?? this.encryptedText,
      encryptedMediaUrl: encryptedMediaUrl ?? this.encryptedMediaUrl,
      mediaMetadata: mediaMetadata ?? this.mediaMetadata,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      forwardedFrom: forwardedFrom ?? this.forwardedFrom,
      reactions: reactions ?? this.reactions,
      readBy: readBy ?? this.readBy,
      deliveredTo: deliveredTo ?? this.deliveredTo,
      edited: edited ?? this.edited,
      editedAt: editedAt ?? this.editedAt,
      editHistory: editHistory ?? this.editHistory,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedForEveryone: deletedForEveryone ?? this.deletedForEveryone,
      deletedAt: deletedAt ?? this.deletedAt,
      selfDestructTime: selfDestructTime ?? this.selfDestructTime,
      isPinned: isPinned ?? this.isPinned,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      localId: localId ?? this.localId,
    );
  }

  // ── Private helpers ──────────────────────────────────────────

  static MessageType _messageTypeFromString(String value) {
    switch (value) {
      case 'text': return MessageType.text;
      case 'image': return MessageType.image;
      case 'video': return MessageType.video;
      case 'audio': return MessageType.audio;
      case 'document': return MessageType.document;
      case 'poll': return MessageType.poll;
      case 'contact': return MessageType.contact;
      case 'location': return MessageType.location;
      case 'sticker': return MessageType.sticker;
      case 'gif': return MessageType.gif;
      case 'system': return MessageType.system;
      default: return MessageType.text;
    }
  }

  static String _messageTypeToString(MessageType type) => type.name;

  static MessageStatus _messageStatusFromString(String value) {
    switch (value) {
      case 'sent': return MessageStatus.sent;
      case 'delivered': return MessageStatus.delivered;
      case 'read': return MessageStatus.read;
      case 'failed': return MessageStatus.failed;
      default: return MessageStatus.sent;
    }
  }

  static String _messageStatusToString(MessageStatus status) => status.name;

  static Map<String, String> _parseStringMap(dynamic data) {
    if (data == null) return {};
    return Map<String, String>.from(
      (data as Map).map((k, v) => MapEntry(k.toString(), v.toString())),
    );
  }

  static Map<String, DateTime> _parseDateTimeMap(dynamic data) {
    if (data == null) return {};
    return (data as Map).map((k, v) {
      final dt = _parseDateTime(v) ?? DateTime.now();
      return MapEntry(k.toString(), dt);
    });
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
