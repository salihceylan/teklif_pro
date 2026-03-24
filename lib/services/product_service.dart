import '../core/api_client.dart';
import '../models/product.dart';

class ProductService {
  Future<List<Product>> list() async {
    final res = await ApiClient.instance.get('/products/');
    return (res.data as List).map((e) => Product.fromJson(e)).toList();
  }

  Future<Product> create(Map<String, dynamic> data) async {
    final res = await ApiClient.instance.post('/products/', data: data);
    return Product.fromJson(res.data);
  }

  Future<Product> update(int id, Map<String, dynamic> data) async {
    final res = await ApiClient.instance.put('/products/$id', data: data);
    return Product.fromJson(res.data);
  }

  Future<void> delete(int id) async {
    await ApiClient.instance.delete('/products/$id');
  }
}
