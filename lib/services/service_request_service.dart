import '../core/api_client.dart';
import '../models/service_request.dart';

class ServiceRequestService {
  Future<List<ServiceRequest>> list() async {
    final res = await ApiClient.instance.get('/service-requests/');
    return (res.data as List).map((e) => ServiceRequest.fromJson(e)).toList();
  }

  Future<ServiceRequest> create(Map<String, dynamic> data) async {
    final res = await ApiClient.instance.post('/service-requests/', data: data);
    return ServiceRequest.fromJson(res.data);
  }

  Future<ServiceRequest> update(int id, Map<String, dynamic> data) async {
    final res =
        await ApiClient.instance.put('/service-requests/$id', data: data);
    return ServiceRequest.fromJson(res.data);
  }

  Future<void> delete(int id) async {
    await ApiClient.instance.delete('/service-requests/$id');
  }
}
