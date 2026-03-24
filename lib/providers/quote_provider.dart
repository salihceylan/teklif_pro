import 'package:flutter/material.dart';
import '../core/app_notifications.dart';
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
    await AppNotifications.instance.notify(
      AppNotificationTopic.quoteLifecycle,
      title: 'Yeni teklif hazırlandı',
      body: '${q.title} için ${q.quoteCode ?? 'yeni teklif'} oluşturuldu.',
    );
  }

  Future<void> update(int id, Map<String, dynamic> data) async {
    final previous = _items.where((e) => e.id == id).firstOrNull;
    final q = await _service.update(id, data);
    final idx = _items.indexWhere((e) => e.id == id);
    if (idx != -1) _items[idx] = q;
    notifyListeners();
    await AppNotifications.instance.notify(
      AppNotificationTopic.quoteLifecycle,
      title: previous?.status != q.status
          ? 'Teklif durumu güncellendi'
          : 'Teklif güncellendi',
      body: previous?.status != q.status
          ? '${q.title} durumu ${q.statusLabel} oldu.'
          : '${q.title} teklifi güncellendi.',
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
    final quote = _items.where((e) => e.id == id).firstOrNull;
    await AppNotifications.instance.notify(
      AppNotificationTopic.quoteDelivery,
      title: 'Teklif mail ile gönderildi',
      body: '${quote?.title ?? 'Teklif'} belgesi $email adresine gönderildi.',
    );
  }
}
