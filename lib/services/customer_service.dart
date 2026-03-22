import '../core/api_client.dart';
import '../models/customer.dart';

class CustomerService {
  Future<List<Customer>> list() async {
    final res = await ApiClient.instance.get('/customers/');
    return (res.data as List).map((e) => Customer.fromJson(e)).toList();
  }

  Future<Customer> create(Map<String, dynamic> data) async {
    final res = await ApiClient.instance.post('/customers/', data: data);
    return Customer.fromJson(res.data);
  }

  Future<Customer> update(int id, Map<String, dynamic> data) async {
    final res = await ApiClient.instance.put('/customers/$id', data: data);
    return Customer.fromJson(res.data);
  }

  Future<void> delete(int id) async {
    await ApiClient.instance.delete('/customers/$id');
  }
}
