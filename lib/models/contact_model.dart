/// Contact model for synced device contacts
class ContactModel {
  final String id;
  final String name;
  final String phone;
  final String? profilePicUrl;
  final bool isRegistered;       // whether contact uses NexChat
  final String? nexChatUid;      // their uid if registered
  final String? username;        // their @handle if registered
  final String? bio;
  final String? status;          // "online" | "offline"
  final DateTime? lastSeen;
  final bool isBlocked;
  final bool isFavorite;

  const ContactModel({
    required this.id,
    required this.name,
    required this.phone,
    this.profilePicUrl,
    this.isRegistered = false,
    this.nexChatUid,
    this.username,
    this.bio,
    this.status,
    this.lastSeen,
    this.isBlocked = false,
    this.isFavorite = false,
  });

  factory ContactModel.fromJson(Map<String, dynamic> json) {
    return ContactModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      profilePicUrl: json['profilePicUrl'] as String?,
      isRegistered: json['isRegistered'] as bool? ?? false,
      nexChatUid: json['nexChatUid'] as String?,
      username: json['username'] as String?,
      bio: json['bio'] as String?,
      status: json['status'] as String?,
      lastSeen: json['lastSeen'] != null
          ? DateTime.tryParse(json['lastSeen'].toString())
          : null,
      isBlocked: json['isBlocked'] as bool? ?? false,
      isFavorite: json['isFavorite'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'phone': phone,
    'profilePicUrl': profilePicUrl,
    'isRegistered': isRegistered,
    'nexChatUid': nexChatUid,
    'username': username,
    'bio': bio,
    'status': status,
    'lastSeen': lastSeen?.toIso8601String(),
    'isBlocked': isBlocked,
    'isFavorite': isFavorite,
  };

  ContactModel copyWith({
    String? id, String? name, String? phone, String? profilePicUrl,
    bool? isRegistered, String? nexChatUid, String? username, String? bio,
    String? status, DateTime? lastSeen, bool? isBlocked, bool? isFavorite,
  }) {
    return ContactModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      profilePicUrl: profilePicUrl ?? this.profilePicUrl,
      isRegistered: isRegistered ?? this.isRegistered,
      nexChatUid: nexChatUid ?? this.nexChatUid,
      username: username ?? this.username,
      bio: bio ?? this.bio,
      status: status ?? this.status,
      lastSeen: lastSeen ?? this.lastSeen,
      isBlocked: isBlocked ?? this.isBlocked,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  /// Display name with @handle if available
  String get displayName => username != null ? '$name (@$username)' : name;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContactModel &&
          runtimeType == other.runtimeType &&
          phone == other.phone;

  @override
  int get hashCode => phone.hashCode;

  @override
  String toString() => 'ContactModel(id: $id, name: $name, phone: $phone, registered: $isRegistered)';
}
