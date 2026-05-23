class Profile {
  final String id;
  final String fullName;
  final String email;
  final String? avatarUrl;
  final bool lifelineSetupComplete;
  final DateTime createdAt;
  final String? phoneNumber;
  final String? sosPhone;
  final DateTime? lastActive;

  const Profile({
    required this.id,
    required this.fullName,
    required this.email,
    this.avatarUrl,
    required this.lifelineSetupComplete,
    required this.createdAt,
    this.phoneNumber,
    this.sosPhone,
    this.lastActive,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      fullName: (json['full_name'] as String?) ?? '',
      email: (json['email'] as String?) ?? '',
      avatarUrl: json['avatar_url'] as String?,
      lifelineSetupComplete:
          (json['lifeline_setup_complete'] as bool?) ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      phoneNumber: json['phone_number'] as String?,
      sosPhone: json['sos_phone'] as String?,
      lastActive: json['last_active'] != null
          ? DateTime.parse(json['last_active'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'full_name': fullName,
        'email': email,
        'avatar_url': avatarUrl,
        'lifeline_setup_complete': lifelineSetupComplete,
        'phone_number': phoneNumber,
        'sos_phone': sosPhone,
        'last_active': lastActive?.toIso8601String(),
      };

  Profile copyWith({
    String? fullName,
    String? email,
    String? avatarUrl,
    bool? lifelineSetupComplete,
    String? phoneNumber,
    String? sosPhone,
  }) {
    return Profile(
      id: id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      lifelineSetupComplete:
          lifelineSetupComplete ?? this.lifelineSetupComplete,
      createdAt: createdAt,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      sosPhone: sosPhone ?? this.sosPhone,
      lastActive: lastActive ?? this.lastActive,
    );
  }
}
