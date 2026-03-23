import '../core/api_client.dart';
import '../models/quote.dart';

class QuoteService {
  Future<List<Quote>> list() async {
    final res = await ApiClient.instance.get('/quotes/');
    return (res.data as List).map((e) => Quote.fromJson(e)).toList();
  }

  Future<Quote> create(Map<String, dynamic> data) async {
    final res = await ApiClient.instance.post('/quotes/', data: data);
    return Quote.fromJson(res.data);
  }

  Future<Quote> update(int id, Map<String, dynamic> data) async {
    final res = await ApiClient.instance.put('/quotes/$id', data: data);
    return Quote.fromJson(res.data);
  }

  Future<void> delete(int id) async {
    await ApiClient.instance.delete('/quotes/$id');
  }

  Future<void> sendEmail(
    int id, {
    required String email,
    String? subject,
    String? message,
  }) async {
    await ApiClient.instance.post(
      '/quotes/$id/send',
      data: {
        'email': email,
        if (subject != null && subject.trim().isNotEmpty) 'subject': subject,
        if (message != null && message.trim().isNotEmpty) 'message': message,
      },
    );
  }
}
