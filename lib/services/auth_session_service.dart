import 'package:dio/dio.dart';

import '../core/api_client.dart';
import '../core/device_descriptor.dart';
import '../models/auth_session.dart';
import '../models/qr_login_models.dart';

class AuthSessionService {
  Future<List<AuthSession>> listSessions() async {
    final res = await ApiClient.instance.get('/auth/sessions');
    final data = res.data as List<dynamic>;
    return data
        .map((item) => AuthSession.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  Future<void> revokeSession(String sessionId) async {
    await ApiClient.instance.post('/auth/sessions/$sessionId/revoke');
  }

  Future<QrLoginChallenge> createQrChallenge() async {
    final descriptor = await resolveCurrentDeviceDescriptor();
    final res = await ApiClient.instance.post(
      '/auth/qr/request',
      data: descriptor.toJson(),
    );
    return QrLoginChallenge.fromJson(
      Map<String, dynamic>.from(res.data as Map),
    );
  }

  Future<QrLoginStatus> pollChallenge({
    required String challengeId,
    required String pollToken,
  }) async {
    final res = await ApiClient.instance.get(
      '/auth/qr/$challengeId/status',
      queryParameters: {'poll_token': pollToken},
    );
    return QrLoginStatus.fromJson(Map<String, dynamic>.from(res.data as Map));
  }

  Future<QrLoginPreview> fetchChallengePreview(String challengeId) async {
    final res = await ApiClient.instance.get('/auth/qr/$challengeId/preview');
    return QrLoginPreview.fromJson(Map<String, dynamic>.from(res.data as Map));
  }

  Future<void> approveChallenge(String challengeId) async {
    await ApiClient.instance.post('/auth/qr/$challengeId/approve');
  }

  String? parseQrChallengeId(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    final uri = Uri.tryParse(trimmed);
    if (uri == null) {
      return null;
    }

    if (uri.queryParameters['challenge'] case final challenge?
        when challenge.isNotEmpty) {
      return challenge;
    }

    if (uri.pathSegments.isNotEmpty && uri.pathSegments.last.isNotEmpty) {
      return uri.pathSegments.last;
    }

    return null;
  }

  String mapError(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data['detail'] != null) {
        return data['detail'].toString();
      }
      if (error.response?.statusCode == 409) {
        return 'Maksimum 3 cihaz siniri dolu. Devam etmek icin bir cihaz oturumunu kapatin.';
      }
    }
    return 'Islem su anda tamamlanamadi.';
  }
}
