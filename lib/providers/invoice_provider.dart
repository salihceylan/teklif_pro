import 'package:flutter/material.dart';

import '../core/api_exception.dart';
import '../core/app_notifications.dart';
import '../models/invoice.dart';
import '../services/invoice_service.dart';

class InvoiceProvider extends ChangeNotifier {
  final _service = InvoiceService();
  List<Invoice> _items = [];
  bool _loading = false;
  String? _error;

  List<Invoice> get items => _items;
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
    final inv = await _service.create(data);
    _items.insert(0, inv);
    notifyListeners();
    await AppNotifications.instance.notify(
      AppNotificationTopic.invoiceLifecycle,
      title: 'Yeni fatura oluşturuldu',
      body: '${inv.invoiceNumber} numaralı fatura kaydedildi.',
    );
  }

  Future<void> createFromQuote(int quoteId) async {
    final inv = await _service.createFromQuote(quoteId);
    _items.insert(0, inv);
    notifyListeners();
    await AppNotifications.instance.notify(
      AppNotificationTopic.invoiceLifecycle,
      title: 'Tekliften fatura oluşturuldu',
      body: '${inv.invoiceNumber} numaralı fatura oluşturuldu.',
    );
  }

  Future<void> update(int id, Map<String, dynamic> data) async {
    final previous = _items.where((e) => e.id == id).firstOrNull;
    final inv = await _service.update(id, data);
    final idx = _items.indexWhere((e) => e.id == id);
    if (idx != -1) _items[idx] = inv;
    notifyListeners();
    await AppNotifications.instance.notify(
      AppNotificationTopic.invoiceLifecycle,
      title: previous?.status != inv.status
          ? 'Fatura durumu güncellendi'
          : 'Fatura güncellendi',
      body: previous?.status != inv.status
          ? '${inv.invoiceNumber} durumu ${inv.statusLabel} oldu.'
          : '${inv.invoiceNumber} numaralı fatura güncellendi.',
    );
  }

  Future<void> delete(int id) async {
    await _service.delete(id);
    _items.removeWhere((e) => e.id == id);
    notifyListeners();
  }
}
