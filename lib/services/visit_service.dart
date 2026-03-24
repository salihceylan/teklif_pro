import '../core/api_client.dart';
import '../models/visit.dart';

class VisitService {
  Future<List<ServiceVisit>> list() async {
    final res = await ApiClient.instance.get('/visits/');
    return (res.data as List).map((e) => ServiceVisit.fromJson(e)).toList();
  }

  Future<ServiceVisit> create(Map<String, dynamic> data) async {
    final res = await ApiClient.instance.post('/visits/', data: data);
    return ServiceVisit.fromJson(res.data);
  }

  Future<ServiceVisit> update(int id, Map<String, dynamic> data) async {
    final res = await ApiClient.instance.put('/visits/$id', data: data);
    return ServiceVisit.fromJson(res.data);
  }

  Future<void> delete(int id) async {
    await ApiClient.instance.delete('/visits/$id');
  }

  Future<void> sendEmail(
    int id, {
    required String email,
    String? subject,
    String? message,
  }) async {
    await ApiClient.instance.post(
      '/visits/$id/send',
      data: {
        'email': email,
        if (subject != null && subject.trim().isNotEmpty) 'subject': subject,
        if (message != null && message.trim().isNotEmpty) 'message': message,
      },
    );
  }
}
