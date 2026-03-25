import '../core/api_date_time.dart';
import 'user.dart';

class QrLoginChallenge {
  final String challengeId;
  final String qrPayload;
  final String pollToken;
  final DateTime expiresAt;
  final int pollIntervalSeconds;

  const QrLoginChallenge({
    required this.challengeId,
    required this.qrPayload,
    required this.pollToken,
    required this.expiresAt,
    required this.pollIntervalSeconds,
  });

  factory QrLoginChallenge.fromJson(Map<String, dynamic> json) =>
      QrLoginChallenge(
        challengeId: json['challenge_id'] as String,
        qrPayload: json['qr_payload'] as String,
        pollToken: json['poll_token'] as String,
        expiresAt: parseApiDateTime(json['expires_at'] as String),
        pollIntervalSeconds: json['poll_interval_seconds'] as int? ?? 2,
      );
}

class QrLoginPreview {
  final String challengeId;
  final String deviceName;
  final String platform;
  final DateTime createdAt;
  final DateTime expiresAt;

  const QrLoginPreview({
    required this.challengeId,
    required this.deviceName,
    required this.platform,
    required this.createdAt,
    required this.expiresAt,
  });

  factory QrLoginPreview.fromJson(Map<String, dynamic> json) => QrLoginPreview(
    challengeId: json['challenge_id'] as String,
    deviceName: json['device_name'] as String? ?? 'Tarayıcı',
    platform: json['platform'] as String? ?? 'Bilinmiyor',
    createdAt: parseApiDateTime(json['created_at'] as String),
    expiresAt: parseApiDateTime(json['expires_at'] as String),
  );
}

class QrLoginStatus {
  final String status;
  final DateTime expiresAt;
  final String? detail;
  final String? accessToken;
  final User? user;

  const QrLoginStatus({
    required this.status,
    required this.expiresAt,
    this.detail,
    this.accessToken,
    this.user,
  });

  factory QrLoginStatus.fromJson(Map<String, dynamic> json) => QrLoginStatus(
    status: json['status'] as String? ?? 'pending',
    expiresAt: parseApiDateTime(json['expires_at'] as String),
    detail: json['detail'] as String?,
    accessToken: json['access_token'] as String?,
    user: json['user'] is Map
        ? User.fromJson(Map<String, dynamic>.from(json['user'] as Map))
        : null,
  );

  bool get isTerminal =>
      status == 'approved' ||
      status == 'expired' ||
      status == 'rejected' ||
      status == 'consumed';
}
