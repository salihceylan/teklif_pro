import 'package:dio/dio.dart';

import '../core/constants.dart';
import '../core/storage.dart';
import 'customer_delete_service.dart';

class CustomerDeleteVerificationChallenge {
  final String requestId;
  final String maskedEmail;
  final int expiresInSeconds;
  final int resendAfterSeconds;

  const CustomerDeleteVerificationChallenge({
    required this.requestId,
    required this.maskedEmail,
    required this.expiresInSeconds,
    required this.resendAfterSeconds,
  });

  factory CustomerDeleteVerificationChallenge.fromJson(
    Map<String, dynamic> json,
  ) {
    return CustomerDeleteVerificationChallenge(
      requestId: json['request_id'] as String,
      maskedEmail: (json['masked_email'] ?? '') as String,
      expiresInSeconds: (json['expires_in'] as num? ?? 0).toInt(),
      resendAfterSeconds: (json['resend_after'] as num? ?? 0).toInt(),
    );
  }
}

class CustomerDeleteVerificationService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: AppConstants.websiteUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  Future<CustomerDeleteVerificationChallenge> sendCode({
    required int customerId,
    required String companyName,
  }) async {
    final token = Storage.getToken();
    if (token == null || token.isEmpty) {
      throw const CustomerDeleteVerificationException(
        'Oturum bilgisi bulunamadı',
      );
    }

    try {
      final response = await _dio.post(
        '/api/customer-delete-verification.php',
        data: {
          'action': 'send',
          'auth_token': token,
          'customer_id': customerId,
          'company_name': companyName,
        },
      );

      return CustomerDeleteVerificationChallenge.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (error) {
      throw CustomerDeleteVerificationException(_messageFromError(error));
    }
  }

  Future<CustomerDeleteImpact> verifyAndDelete({
    required String requestId,
    required String code,
  }) async {
    final token = Storage.getToken();
    if (token == null || token.isEmpty) {
      throw const CustomerDeleteVerificationException(
        'Oturum bilgisi bulunamadı',
      );
    }

    try {
      final response = await _dio.post(
        '/api/customer-delete-verification.php',
        data: {
          'action': 'verify_delete',
          'auth_token': token,
          'request_id': requestId,
          'code': code,
        },
      );

      final data = response.data as Map<String, dynamic>;
      final impactJson = (data['impact'] ?? data) as Map<String, dynamic>;
      return CustomerDeleteImpact.fromJson(impactJson);
    } on DioException catch (error) {
      throw CustomerDeleteVerificationException(_messageFromError(error));
    }
  }

  String _messageFromError(DioException error) {
    final data = error.response?.data;
    if (data is Map && data['detail'] != null) {
      return data['detail'].toString();
    }
    return 'Doğrulama işlemi tamamlanamadı';
  }
}

class CustomerDeleteVerificationException implements Exception {
  final String message;

  const CustomerDeleteVerificationException(this.message);

  @override
  String toString() => message;
}
