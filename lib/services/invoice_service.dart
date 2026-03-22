import '../core/api_client.dart';
import '../models/invoice.dart';

class InvoiceService {
  Future<List<Invoice>> list() async {
    final res = await ApiClient.instance.get('/invoices/');
    return (res.data as List).map((e) => Invoice.fromJson(e)).toList();
  }

  Future<Invoice> create(Map<String, dynamic> data) async {
    final res = await ApiClient.instance.post('/invoices/', data: data);
    return Invoice.fromJson(res.data);
  }

  Future<Invoice> createFromQuote(int quoteId) async {
    final res =
        await ApiClient.instance.post('/invoices/from-quote/$quoteId');
    return Invoice.fromJson(res.data);
  }

  Future<Invoice> update(int id, Map<String, dynamic> data) async {
    final res = await ApiClient.instance.put('/invoices/$id', data: data);
    return Invoice.fromJson(res.data);
  }

  Future<void> delete(int id) async {
    await ApiClient.instance.delete('/invoices/$id');
  }
}
