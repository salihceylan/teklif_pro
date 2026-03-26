import 'package:dio/dio.dart';

/// Returns true when the error is a 401/403 (expired or invalid token).
bool isTokenExpiredError(Object error) {
  if (error is DioException) {
    final code = error.response?.statusCode;
    return code == 401 || code == 403;
  }
  return false;
}

/// Converts any API error into a user-facing Turkish message.
String parseApiError(Object error) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map && data['detail'] != null) {
      return data['detail'].toString();
    }
    switch (error.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
        return 'Sunucuya bağlanılamadı';
      case DioExceptionType.receiveTimeout:
        return 'Sunucu yanıt vermedi';
      case DioExceptionType.sendTimeout:
        return 'İstek gönderilemedi';
      case DioExceptionType.badResponse:
        final code = error.response?.statusCode;
        if (code == 401 || code == 403) return 'Oturum süresi doldu, tekrar giriş yapın';
        if (code == 404) return 'Kayıt bulunamadı';
        if (code == 422) return 'Geçersiz veri';
        if (code != null && code >= 500) return 'Sunucu hatası, lütfen tekrar deneyin';
        break;
      default:
        break;
    }
  }
  return 'Bir hata oluştu';
}
