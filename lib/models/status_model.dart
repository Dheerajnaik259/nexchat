/// Supabase table: status
class StatusModel {
  final String statusId;
  final String userId;
  final String type;               // "text" | "image" | "video"
  final String? content;           // text content
  final String? mediaUrl;
  final String? backgroundColor;   // hex color for text status
  final String? fontStyle;
  final int? duration;             // video duration in ms
  final List<String> seenBy;       // [userId]
  final List<String> allowedViewers; // empty = all contacts
  final DateTime? expiresAt;       // createdAt + 24 hours
  final DateTime? createdAt;

  const StatusModel({
    required this.statusId,
    required this.userId,
    required this.type,
    this.content,
    this.mediaUrl,
    this.backgroundColor,
    this.fontStyle,
    this.duration,
    this.seenBy = const [],
    this.allowedViewers = const [],
    this.expiresAt,
    this.createdAt,
  });

  factory StatusModel.fromJson(Map<String, dynamic> json) {
    return StatusModel(
      statusId: json['status_id'] as String? ?? json['statusId'] as String? ?? json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? json['userId'] as String? ?? '',
      type: json['type'] as String? ?? 'text',
      content: json['content'] as String?,
      mediaUrl: json['media_url'] as String? ?? json['mediaUrl'] as String?,
      backgroundColor: json['background_color'] as String? ?? json['backgroundColor'] as String?,
      fontStyle: json['font_style'] as String? ?? json['fontStyle'] as String?,
      duration: json['duration'] as int?,
      seenBy: List<String>.from(json['seen_by'] ?? json['seenBy'] ?? []),
      allowedViewers: List<String>.from(json['allowed_viewers'] ?? json['allowedViewers'] ?? []),
      expiresAt: _parseDateTime(json['expires_at'] ?? json['expiresAt']),
      createdAt: _parseDateTime(json['created_at'] ?? json['createdAt']),
    );
  }

  /// Convert to Supabase-compatible JSON (snake_case)
  Map<String, dynamic> toJson() => {
    'id': statusId,
    'user_id': userId,
    'type': type,
    'content': content,
    'media_url': mediaUrl,
    'background_color': backgroundColor,
    'font_style': fontStyle,
    'duration': duration,
    'seen_by': seenBy,
    'allowed_viewers': allowedViewers,
    'expires_at': expiresAt?.toIso8601String(),
    'created_at': createdAt?.toIso8601String(),
  };

  /// Check if this status has expired
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  StatusModel copyWith({
    String? statusId, String? userId, String? type, String? content,
    String? mediaUrl, String? backgroundColor, String? fontStyle,
    int? duration, List<String>? seenBy, List<String>? allowedViewers,
    DateTime? expiresAt, DateTime? createdAt,
  }) {
    return StatusModel(
      statusId: statusId ?? this.statusId,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      content: content ?? this.content,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      fontStyle: fontStyle ?? this.fontStyle,
      duration: duration ?? this.duration,
      seenBy: seenBy ?? this.seenBy,
      allowedViewers: allowedViewers ?? this.allowedViewers,
      expiresAt: expiresAt ?? this.expiresAt,
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
