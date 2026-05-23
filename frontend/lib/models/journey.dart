enum JourneyType { all, secure, alert }

class Journey {
  final String id;
  final String userId;
  final String origin;
  final String destination;
  final String status;
  final String duration;
  final DateTime createdAt;
  final bool hadAlert;
  final int? sosCount;

  const Journey({
    required this.id,
    required this.userId,
    required this.origin,
    required this.destination,
    required this.status,
    required this.duration,
    required this.createdAt,
    this.hadAlert = false,
    this.sosCount,
  });

  factory Journey.fromJson(Map<String, dynamic> json) {
    return Journey(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      origin: json['origin'] as String,
      destination: json['destination'] as String,
      status: json['status'] as String,
      duration: json['duration'] as String? ?? '0 mins',
      createdAt: DateTime.parse(json['created_at'] as String),
      hadAlert: json['had_alert'] as bool? ?? false,
      sosCount: json['sos_count'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'origin': origin,
        'destination': destination,
        'status': status,
        'duration': duration,
        'had_alert': hadAlert,
        'sos_count': sosCount,
      };

  bool get isSecure => status == 'completed' && !hadAlert;
  bool get hasAlert => hadAlert || status == 'sosTriggered';
  bool get isSuccessful => status == 'completed';
}
