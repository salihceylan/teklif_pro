class AuthSession {
  final String id;
  final String deviceName;
  final String deviceType;
  final String platform;
  final String loginMethod;
  final String? userAgent;
  final DateTime createdAt;
  final DateTime lastSeenAt;
  final DateTime expiresAt;
  final bool isCurrent;

  const AuthSession({
    required this.id,
    required this.deviceName,
    required this.deviceType,
    required this.platform,
    required this.loginMethod,
    required this.createdAt,
    required this.lastSeenAt,
    required this.expiresAt,
    required this.isCurrent,
    this.userAgent,
  });

  factory AuthSession.fromJson(Map<String, dynamic> json) => AuthSession(
    id: json['id'] as String,
    deviceName: json['device_name'] as String? ?? 'Bilinmeyen cihaz',
    deviceType: json['device_type'] as String? ?? 'unknown',
    platform: json['platform'] as String? ?? 'Bilinmiyor',
    loginMethod: json['login_method'] as String? ?? 'password',
    userAgent: json['user_agent'] as String?,
    createdAt: DateTime.parse(json['created_at'] as String),
    lastSeenAt: DateTime.parse(json['last_seen_at'] as String),
    expiresAt: DateTime.parse(json['expires_at'] as String),
    isCurrent: json['is_current'] as bool? ?? false,
  );
}
