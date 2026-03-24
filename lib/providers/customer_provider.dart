import 'package:flutter/material.dart';

import '../core/app_notifications.dart';
import '../models/customer.dart';
import '../services/customer_delete_service.dart';
import '../services/customer_service.dart';

class CustomerProvider extends ChangeNotifier {
  final _service = CustomerService();
  final _deleteService = CustomerDeleteService();
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
    final customer = await _service.create(data);
    _items.insert(0, customer);
    notifyListeners();
    await AppNotifications.instance.notify(
      AppNotificationTopic.companyRecords,
      title: 'Yeni firma kaydedildi',
      body: '${customer.companyName} için firma kartı oluşturuldu.',
    );
  }

  Future<void> update(int id, Map<String, dynamic> data) async {
    final previous = _items.where((item) => item.id == id).firstOrNull;
    final customer = await _service.update(id, data);
    final index = _items.indexWhere((item) => item.id == id);
    if (index != -1) {
      _items[index] = customer;
    }
    notifyListeners();
    await AppNotifications.instance.notify(
      AppNotificationTopic.companyRecords,
      title: 'Firma profili güncellendi',
      body:
          '${previous?.companyName ?? customer.companyName} firma kaydı güncellendi.',
    );
  }

  Future<CustomerDeleteImpact> inspectDeleteImpact(int id) async {
    return _deleteService.inspect(id);
  }

  Future<CustomerDeleteImpact> delete(int id) async {
    final impact = await _deleteService.deleteCascade(id);
    _items.removeWhere((item) => item.id == id);
    notifyListeners();
    await AppNotifications.instance.notify(
      AppNotificationTopic.companyRecords,
      title: 'Firma ve bağlı kayıtlar silindi',
      body: impact.hasDependencies
          ? 'Firma kaydı ile birlikte bağlı teklif, servis ve fatura kayıtları kaldırıldı.'
          : 'Firma kaydı silindi.',
    );
    return impact;
  }
}
