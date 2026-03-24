import '../core/api_client.dart';
import '../core/storage.dart';
import '../models/user.dart';

class AuthService {
  Future<User> login(String email, String password) async {
    final res = await ApiClient.instance.post(
      '/auth/login',
      data: {'email': email, 'password': password},
    );
    await Storage.saveToken(res.data['access_token']);
    return User.fromJson(res.data['user']);
  }

  Future<User> register({
    required String email,
    required String password,
    required String fullName,
    String? phone,
    String? companyName,
  }) async {
    final res = await ApiClient.instance.post(
      '/auth/register',
      data: {
        'email': email,
        'password': password,
        'full_name': fullName,
        'phone': phone,
        'company_name': companyName,
      },
    );
    await Storage.saveToken(res.data['access_token']);
    return User.fromJson(res.data['user']);
  }

  Future<User> me() async {
    final res = await ApiClient.instance.get('/auth/me');
    return User.fromJson(res.data);
  }

  Future<void> logout() async => await Storage.clear();
}
