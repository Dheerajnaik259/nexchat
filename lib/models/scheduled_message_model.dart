/// Supabase table: scheduled_messages
class ScheduledMessageModel {
  final String id;
  final String chatId;
  final String senderId;
  final String encryptedText;
  final DateTime? scheduledAt;
  final String status;             // "pending" | "sent" | "cancelled"
  final String type;               // message type
  final DateTime? createdAt;

  const ScheduledMessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.encryptedText,
    this.scheduledAt,
    this.status = 'pending',
    required this.type,
    this.createdAt,
  });

  factory ScheduledMessageModel.fromJson(Map<String, dynamic> json) {
    return ScheduledMessageModel(
      id: json['id'] as String? ?? '',
      chatId: json['chat_id'] as String? ?? json['chatId'] as String? ?? '',
      senderId: json['sender_id'] as String? ?? json['senderId'] as String? ?? '',
      encryptedText: json['encrypted_text'] as String? ?? json['encryptedText'] as String? ?? '',
      scheduledAt: _parseDateTime(json['scheduled_at'] ?? json['scheduledAt']),
      status: json['status'] as String? ?? 'pending',
      type: json['type'] as String? ?? 'text',
      createdAt: _parseDateTime(json['created_at'] ?? json['createdAt']),
    );
  }

  /// Convert to Supabase-compatible JSON (snake_case)
  Map<String, dynamic> toJson() => {
    'id': id,
    'chat_id': chatId,
    'sender_id': senderId,
    'encrypted_text': encryptedText,
    'scheduled_at': scheduledAt?.toIso8601String(),
    'status': status,
    'type': type,
    'created_at': createdAt?.toIso8601String(),
  };

  ScheduledMessageModel copyWith({
    String? id, String? chatId, String? senderId, String? encryptedText,
    DateTime? scheduledAt, String? status, String? type, DateTime? createdAt,
  }) {
    return ScheduledMessageModel(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      encryptedText: encryptedText ?? this.encryptedText,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      status: status ?? this.status,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
