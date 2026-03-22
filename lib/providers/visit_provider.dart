import 'package:flutter/material.dart';
import '../models/visit.dart';
import '../services/visit_service.dart';

class VisitProvider extends ChangeNotifier {
  final _service = VisitService();
  List<ServiceVisit> _items = [];
  bool _loading = false;

  List<ServiceVisit> get items => _items;
  bool get loading => _loading;

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    _items = await _service.list();
    _loading = false;
    notifyListeners();
  }

  Future<void> create(Map<String, dynamic> data) async {
    final v = await _service.create(data);
    _items.insert(0, v);
    notifyListeners();
  }

  Future<void> update(int id, Map<String, dynamic> data) async {
    final v = await _service.update(id, data);
    final idx = _items.indexWhere((e) => e.id == id);
    if (idx != -1) _items[idx] = v;
    notifyListeners();
  }

  Future<void> delete(int id) async {
    await _service.delete(id);
    _items.removeWhere((e) => e.id == id);
    notifyListeners();
  }
}
