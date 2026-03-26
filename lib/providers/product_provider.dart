import 'package:flutter/material.dart';

import '../core/api_exception.dart';
import '../models/product.dart';
import '../services/product_service.dart';

class ProductProvider extends ChangeNotifier {
  final _service = ProductService();
  List<Product> _items = [];
  bool _loading = false;
  String? _error;

  List<Product> get items => _items;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _items = await _service.list();
    } catch (e) {
      _error = parseApiError(e);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> create(Map<String, dynamic> data) async {
    final product = await _service.create(data);
    _items.insert(0, product);
    notifyListeners();
  }

  Future<void> update(int id, Map<String, dynamic> data) async {
    final product = await _service.update(id, data);
    final index = _items.indexWhere((item) => item.id == id);
    if (index != -1) {
      _items[index] = product;
    }
    notifyListeners();
  }

  Future<void> delete(int id) async {
    await _service.delete(id);
    _items.removeWhere((item) => item.id == id);
    notifyListeners();
  }
}
