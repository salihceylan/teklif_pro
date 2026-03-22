import 'package:flutter/material.dart';
import '../models/invoice.dart';
import '../services/invoice_service.dart';

class InvoiceProvider extends ChangeNotifier {
  final _service = InvoiceService();
  List<Invoice> _items = [];
  bool _loading = false;

  List<Invoice> get items => _items;
  bool get loading => _loading;

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    _items = await _service.list();
    _loading = false;
    notifyListeners();
  }

  Future<void> create(Map<String, dynamic> data) async {
    final inv = await _service.create(data);
    _items.insert(0, inv);
    notifyListeners();
  }

  Future<void> createFromQuote(int quoteId) async {
    final inv = await _service.createFromQuote(quoteId);
    _items.insert(0, inv);
    notifyListeners();
  }

  Future<void> update(int id, Map<String, dynamic> data) async {
    final inv = await _service.update(id, data);
    final idx = _items.indexWhere((e) => e.id == id);
    if (idx != -1) _items[idx] = inv;
    notifyListeners();
  }

  Future<void> delete(int id) async {
    await _service.delete(id);
    _items.removeWhere((e) => e.id == id);
    notifyListeners();
  }
}
