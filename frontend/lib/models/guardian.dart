class Guardian {
  final String id;
  final String userId;
  final String fullName;
  final String phone;
  final String relation;
  final bool isActive;
  final DateTime createdAt;
  final String? avatarUrl;
  final bool isAppUser;
  final String? profileId;
  final bool isOnline;
  final DateTime? lastActive;

  const Guardian({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.phone,
    this.relation = '',
    this.isActive = true,
    required this.createdAt,
    this.avatarUrl,
    this.isAppUser = false,
    this.profileId,
    this.isOnline = false,
    this.lastActive,
  });

  factory Guardian.fromJson(Map<String, dynamic> json) {
    return Guardian(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      fullName: (json['guardian_name'] as String?) ?? (json['full_name'] as String?) ?? '',
      phone: (json['guardian_phone'] as String?) ?? (json['phone'] as String?) ?? '',
      relation: (json['relation'] as String?) ?? '',
      isActive: (json['is_active'] as bool?) ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      avatarUrl: json['avatar_url'] as String?,
      isAppUser: (json['is_app_user'] as bool?) ?? (json['guardian_user_id'] != null),
      profileId: (json['profile_id'] as String?) ?? (json['guardian_user_id'] as String?),
      isOnline: (json['is_online'] as bool?) ?? false,
      lastActive: json['last_active'] != null ? DateTime.parse(json['last_active'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'guardian_name': fullName,
        'guardian_phone': phone,
        'relation': relation,
        'is_active': isActive,
      };
}
