import 'package:flutter/material.dart';
import '../core/app_notifications.dart';
import '../models/service_request.dart';
import '../services/service_request_service.dart';

class ServiceRequestProvider extends ChangeNotifier {
  final _service = ServiceRequestService();
  List<ServiceRequest> _items = [];
  bool _loading = false;

  List<ServiceRequest> get items => _items;
  bool get loading => _loading;

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    _items = await _service.list();
    _loading = false;
    notifyListeners();
  }

  Future<void> create(Map<String, dynamic> data) async {
    final r = await _service.create(data);
    _items.insert(0, r);
    notifyListeners();
    await AppNotifications.instance.notify(
      AppNotificationTopic.serviceRequests,
      title: 'Yeni servis talebi açıldı',
      body: '${r.title} talebi kaydedildi.',
    );
  }

  Future<void> update(int id, Map<String, dynamic> data) async {
    final previous = _items.where((e) => e.id == id).firstOrNull;
    final r = await _service.update(id, data);
    final idx = _items.indexWhere((e) => e.id == id);
    if (idx != -1) _items[idx] = r;
    notifyListeners();
    await AppNotifications.instance.notify(
      AppNotificationTopic.serviceRequests,
      title: previous?.status != r.status
          ? 'Servis talebi durumu değişti'
          : 'Servis talebi güncellendi',
      body: previous?.status != r.status
          ? '${r.title} durumu ${r.statusLabel} oldu.'
          : '${r.title} kaydı güncellendi.',
    );
  }

  Future<void> delete(int id) async {
    await _service.delete(id);
    _items.removeWhere((e) => e.id == id);
    notifyListeners();
  }
}
