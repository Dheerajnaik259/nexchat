/// Sub-model: WebRTC signaling data embedded in CallModel
class SignalingData {
  final String? offer;             // SDP offer
  final String? answer;            // SDP answer
  final List<Map<String, dynamic>> iceCandidates;

  const SignalingData({
    this.offer,
    this.answer,
    this.iceCandidates = const [],
  });

  factory SignalingData.fromJson(Map<String, dynamic> json) {
    return SignalingData(
      offer: json['offer'] as String?,
      answer: json['answer'] as String?,
      iceCandidates: json['ice_candidates'] != null
          ? List<Map<String, dynamic>>.from(
              (json['ice_candidates'] as List).map((e) => Map<String, dynamic>.from(e)))
          : json['iceCandidates'] != null
              ? List<Map<String, dynamic>>.from(
                  (json['iceCandidates'] as List).map((e) => Map<String, dynamic>.from(e)))
              : [],
    );
  }

  Map<String, dynamic> toJson() => {
    'offer': offer,
    'answer': answer,
    'ice_candidates': iceCandidates,
  };
}

/// Supabase table: calls
class CallModel {
  final String callId;
  final String type;               // "voice" | "video"
  final String callerId;
  final List<String> receiverIds;
  final String status;             // "ringing" | "accepted" | "rejected" | "missed" | "ended"
  final DateTime? startedAt;
  final DateTime? endedAt;
  final int? duration;             // seconds
  final bool isGroup;
  final SignalingData? signalingData;

  const CallModel({
    required this.callId,
    required this.type,
    required this.callerId,
    required this.receiverIds,
    required this.status,
    this.startedAt,
    this.endedAt,
    this.duration,
    this.isGroup = false,
    this.signalingData,
  });

  factory CallModel.fromJson(Map<String, dynamic> json) {
    return CallModel(
      callId: json['call_id'] as String? ?? json['callId'] as String? ?? json['id'] as String? ?? '',
      type: json['type'] as String? ?? 'voice',
      callerId: json['caller_id'] as String? ?? json['callerId'] as String? ?? '',
      receiverIds: List<String>.from(json['receiver_ids'] ?? json['receiverIds'] ?? []),
      status: json['status'] as String? ?? 'ringing',
      startedAt: _parseDateTime(json['started_at'] ?? json['startedAt']),
      endedAt: _parseDateTime(json['ended_at'] ?? json['endedAt']),
      duration: json['duration'] as int?,
      isGroup: json['is_group'] as bool? ?? json['isGroup'] as bool? ?? false,
      signalingData: json['signaling_data'] != null
          ? SignalingData.fromJson(Map<String, dynamic>.from(json['signaling_data']))
          : json['signalingData'] != null
              ? SignalingData.fromJson(Map<String, dynamic>.from(json['signalingData']))
              : null,
    );
  }

  /// Convert to Supabase-compatible JSON (snake_case)
  Map<String, dynamic> toJson() => {
    'id': callId,
    'type': type,
    'caller_id': callerId,
    'receiver_ids': receiverIds,
    'status': status,
    'started_at': startedAt?.toIso8601String(),
    'ended_at': endedAt?.toIso8601String(),
    'duration': duration,
    'is_group': isGroup,
    'signaling_data': signalingData?.toJson(),
  };

  CallModel copyWith({
    String? callId, String? type, String? callerId, List<String>? receiverIds,
    String? status, DateTime? startedAt, DateTime? endedAt, int? duration,
    bool? isGroup, SignalingData? signalingData,
  }) {
    return CallModel(
      callId: callId ?? this.callId,
      type: type ?? this.type,
      callerId: callerId ?? this.callerId,
      receiverIds: receiverIds ?? this.receiverIds,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      duration: duration ?? this.duration,
      isGroup: isGroup ?? this.isGroup,
      signalingData: signalingData ?? this.signalingData,
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
