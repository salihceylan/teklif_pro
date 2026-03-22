import 'package:flutter/material.dart';
import '../models/customer.dart';
import '../services/customer_service.dart';

class CustomerProvider extends ChangeNotifier {
  final _service = CustomerService();
  List<Customer> _items = [];
  bool _loading = false;

  List<Customer> get items => _items;
  bool get loading => _loading;

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    _items = await _service.list();
    _loading = false;
    notifyListeners();
  }

  Future<void> create(Map<String, dynamic> data) async {
    final c = await _service.create(data);
    _items.insert(0, c);
    notifyListeners();
  }

  Future<void> update(int id, Map<String, dynamic> data) async {
    final c = await _service.update(id, data);
    final idx = _items.indexWhere((e) => e.id == id);
    if (idx != -1) _items[idx] = c;
    notifyListeners();
  }

  Future<void> delete(int id) async {
    await _service.delete(id);
    _items.removeWhere((e) => e.id == id);
    notifyListeners();
  }
}
