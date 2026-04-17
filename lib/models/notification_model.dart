/// Notification types for in-app notifications
enum NotificationType { message, call, mention, group, status, system }

/// Notification model for in-app notification management
class NotificationModel {
  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final String? chatId;
  final String? senderId;
  final String? senderName;
  final String? senderAvatar;
  final String? messageId;
  final String? action;           // deep link or action identifier
  final Map<String, dynamic>? payload;  // additional data
  final DateTime timestamp;
  final bool isRead;
  final bool isSilent;            // for background notifications

  const NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.chatId,
    this.senderId,
    this.senderName,
    this.senderAvatar,
    this.messageId,
    this.action,
    this.payload,
    required this.timestamp,
    this.isRead = false,
    this.isSilent = false,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String? ?? '',
      type: _notificationTypeFromString(json['type'] as String? ?? 'message'),
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      chatId: json['chatId'] as String?,
      senderId: json['senderId'] as String?,
      senderName: json['senderName'] as String?,
      senderAvatar: json['senderAvatar'] as String?,
      messageId: json['messageId'] as String?,
      action: json['action'] as String?,
      payload: json['payload'] != null
          ? Map<String, dynamic>.from(json['payload'])
          : null,
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
      isRead: json['isRead'] as bool? ?? false,
      isSilent: json['isSilent'] as bool? ?? false,
    );
  }

  /// Create from FCM remote message data
  factory NotificationModel.fromFCMData(Map<String, dynamic> data) {
    return NotificationModel(
      id: data['notificationId'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      type: _notificationTypeFromString(data['type'] as String? ?? 'message'),
      title: data['title'] as String? ?? '',
      body: data['body'] as String? ?? '',
      chatId: data['chatId'] as String?,
      senderId: data['senderId'] as String?,
      senderName: data['senderName'] as String?,
      senderAvatar: data['senderAvatar'] as String?,
      messageId: data['messageId'] as String?,
      action: data['action'] as String?,
      payload: data,
      timestamp: DateTime.now(),
      isRead: false,
      isSilent: data['isSilent'] == 'true',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': _notificationTypeToString(type),
    'title': title,
    'body': body,
    'chatId': chatId,
    'senderId': senderId,
    'senderName': senderName,
    'senderAvatar': senderAvatar,
    'messageId': messageId,
    'action': action,
    'payload': payload,
    'timestamp': timestamp.toIso8601String(),
    'isRead': isRead,
    'isSilent': isSilent,
  };

  NotificationModel copyWith({
    String? id, NotificationType? type, String? title, String? body,
    String? chatId, String? senderId, String? senderName, String? senderAvatar,
    String? messageId, String? action, Map<String, dynamic>? payload,
    DateTime? timestamp, bool? isRead, bool? isSilent,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderAvatar: senderAvatar ?? this.senderAvatar,
      messageId: messageId ?? this.messageId,
      action: action ?? this.action,
      payload: payload ?? this.payload,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      isSilent: isSilent ?? this.isSilent,
    );
  }

  /// Mark notification as read
  NotificationModel markAsRead() => copyWith(isRead: true);

  // ── Private helpers ──────────────────────────────────────────

  static NotificationType _notificationTypeFromString(String value) {
    switch (value) {
      case 'message': return NotificationType.message;
      case 'call': return NotificationType.call;
      case 'mention': return NotificationType.mention;
      case 'group': return NotificationType.group;
      case 'status': return NotificationType.status;
      case 'system': return NotificationType.system;
      default: return NotificationType.message;
    }
  }

  static String _notificationTypeToString(NotificationType type) => type.name;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'NotificationModel(id: $id, type: ${type.name}, title: $title)';
}
