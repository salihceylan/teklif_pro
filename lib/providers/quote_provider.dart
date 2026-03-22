import 'package:flutter/material.dart';
import '../models/quote.dart';
import '../services/quote_service.dart';

class QuoteProvider extends ChangeNotifier {
  final _service = QuoteService();
  List<Quote> _items = [];
  bool _loading = false;

  List<Quote> get items => _items;
  bool get loading => _loading;

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    _items = await _service.list();
    _loading = false;
    notifyListeners();
  }

  Future<void> create(Map<String, dynamic> data) async {
    final q = await _service.create(data);
    _items.insert(0, q);
    notifyListeners();
  }

  Future<void> update(int id, Map<String, dynamic> data) async {
    final q = await _service.update(id, data);
    final idx = _items.indexWhere((e) => e.id == id);
    if (idx != -1) _items[idx] = q;
    notifyListeners();
  }

  Future<void> delete(int id) async {
    await _service.delete(id);
    _items.removeWhere((e) => e.id == id);
    notifyListeners();
  }
}
