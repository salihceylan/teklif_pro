import 'package:flutter/material.dart';
import '../core/app_notifications.dart';
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
    await AppNotifications.instance.notify(
      AppNotificationTopic.serviceForms,
      title: 'Yeni servis formu hazırlandı',
      body:
          '${v.customerCompanyName ?? 'Müşteri'} için ${v.serviceCode ?? 'servis formu'} oluşturuldu.',
    );
  }

  Future<void> update(int id, Map<String, dynamic> data) async {
    final previous = _items.where((e) => e.id == id).firstOrNull;
    final v = await _service.update(id, data);
    final idx = _items.indexWhere((e) => e.id == id);
    if (idx != -1) _items[idx] = v;
    notifyListeners();
    await AppNotifications.instance.notify(
      AppNotificationTopic.serviceForms,
      title: previous?.status != v.status
          ? 'Servis formu durumu güncellendi'
          : 'Servis formu güncellendi',
      body: previous?.status != v.status
          ? '${v.serviceCode ?? 'Servis formu'} durumu ${v.statusLabel} oldu.'
          : '${v.serviceCode ?? 'Servis formu'} kaydı güncellendi.',
    );
  }

  Future<void> delete(int id) async {
    await _service.delete(id);
    _items.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  Future<void> sendEmail(
    int id, {
    required String email,
    String? subject,
    String? message,
  }) async {
    await _service.sendEmail(
      id,
      email: email,
      subject: subject,
      message: message,
    );
    final visit = _items.where((e) => e.id == id).firstOrNull;
    await AppNotifications.instance.notify(
      AppNotificationTopic.serviceForms,
      title: 'Servis formu mail ile gonderildi',
      body:
          '${visit?.serviceCode ?? 'Servis formu'} belgesi $email adresine gonderildi.',
    );
  }
}
