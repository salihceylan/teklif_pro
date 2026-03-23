import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'constants.dart';
import 'storage.dart';

enum AppNotificationTopic {
  companyRecords(
    title: 'Firma kayitlari',
    description:
        'Yeni firma kartlari ve firma profili guncellemeleri bildirilsin.',
    channelId: 'company_records',
    channelName: 'Firma Bildirimleri',
    previewTitle: 'Firma bildirimi hazir',
    previewBody: 'Yeni firma kartlari ve profil guncellemeleri burada gorunur.',
  ),
  serviceRequests(
    title: 'Servis talepleri',
    description:
        'Yeni servis talebi acildiginda veya talep durumu degistiginde bildirilsin.',
    channelId: 'service_requests',
    channelName: 'Servis Talebi Bildirimleri',
    previewTitle: 'Servis talebi guncellendi',
    previewBody: 'Yeni talep acma ve durum gecisleri cihazda gorunur.',
  ),
  quoteLifecycle(
    title: 'Teklif sureci',
    description: 'Teklif hazirlama ve teklif durum degisiklikleri bildirilsin.',
    channelId: 'quote_lifecycle',
    channelName: 'Teklif Bildirimleri',
    previewTitle: 'Yeni teklif hazirlandi',
    previewBody: 'Teklif kaydi ve teklif durumu hareketleri burada gorunur.',
  ),
  quoteDelivery(
    title: 'Teklif teslimati',
    description:
        'Teklif e-posta ile gonderildiginde teslimat bildirimi gelsin.',
    channelId: 'quote_delivery',
    channelName: 'Teklif Teslimat Bildirimleri',
    previewTitle: 'Teklif mail ile gonderildi',
    previewBody: 'Mail gonderimi tamamlandiginda cihaz bildirimi gorunur.',
  ),
  serviceForms(
    title: 'Servis formlari',
    description:
        'Servis formu olusturma ve servis operasyonu tamamlanma bildirimleri gelsin.',
    channelId: 'service_forms',
    channelName: 'Servis Formu Bildirimleri',
    previewTitle: 'Servis formu hazir',
    previewBody:
        'Operasyon formu kayitlari ve tamamlanma bilgileri burada gorunur.',
  ),
  invoiceLifecycle(
    title: 'Fatura takibi',
    description:
        'Fatura olusturma ve odendi durumuna gecis bildirimleri gelsin.',
    channelId: 'invoice_lifecycle',
    channelName: 'Fatura Bildirimleri',
    previewTitle: 'Fatura hareketi olustu',
    previewBody: 'Yeni fatura ve tahsilat hareketleri cihazda gorunur.',
  );

  const AppNotificationTopic({
    required this.title,
    required this.description,
    required this.channelId,
    required this.channelName,
    required this.previewTitle,
    required this.previewBody,
  });

  final String title;
  final String description;
  final String channelId;
  final String channelName;
  final String previewTitle;
  final String previewBody;

  String get prefKey => '${AppConstants.notificationPrefix}$name';
}

class AppNotifications {
  AppNotifications._();

  static final AppNotifications instance = AppNotifications._();

  static const _windowsGuid = '3a7d5b8f-7d3a-4d8a-a1d1-0f93e0d7f8c4';
  static const _windowsAppId = 'GudeTeknoloji.TeklifPro.App.1';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool _permissionChecked = false;
  bool _permissionGranted = false;

  bool get isSupportedOnCurrentPlatform {
    if (kIsWeb) return false;
    return switch (defaultTargetPlatform) {
      TargetPlatform.android ||
      TargetPlatform.iOS ||
      TargetPlatform.macOS ||
      TargetPlatform.windows ||
      TargetPlatform.linux => true,
      _ => false,
    };
  }

  Future<void> init() async {
    await _ensureInitialized();
    if (!_permissionChecked) {
      await requestPermission();
    }
  }

  Future<void> _ensureInitialized() async {
    if (_initialized || !isSupportedOnCurrentPlatform) {
      _initialized = true;
      return;
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const linux = LinuxInitializationSettings(defaultActionName: 'Ac');
    const windows = WindowsInitializationSettings(
      appName: 'Teklif Pro',
      appUserModelId: _windowsAppId,
      guid: _windowsGuid,
    );

    final settings = const InitializationSettings(
      android: android,
      iOS: darwin,
      macOS: darwin,
      linux: linux,
      windows: windows,
    );

    await _plugin.initialize(settings);
    _initialized = true;
  }

  Future<bool> requestPermission() async {
    await _ensureInitialized();
    _permissionChecked = true;

    if (!isSupportedOnCurrentPlatform) {
      _permissionGranted = false;
      return false;
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      final plugin = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      _permissionGranted =
          await plugin?.requestNotificationsPermission() ?? false;
      return _permissionGranted;
    }

    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final plugin = _plugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >();
        _permissionGranted =
            await plugin?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            ) ??
            false;
        return _permissionGranted;
      }

      final plugin = _plugin
          .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin
          >();
      _permissionGranted =
          await plugin?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
      return _permissionGranted;
    }

    _permissionGranted = true;
    return true;
  }

  Future<bool> permissionGranted() async {
    await _ensureInitialized();
    return _permissionGranted;
  }

  Future<Map<AppNotificationTopic, bool>> topicPreferences() async {
    await Storage.init();
    return {
      for (final topic in AppNotificationTopic.values)
        topic: Storage.getBool(topic.prefKey, defaultValue: true),
    };
  }

  Future<bool> isTopicEnabled(AppNotificationTopic topic) async {
    await Storage.init();
    return Storage.getBool(topic.prefKey, defaultValue: true);
  }

  Future<void> setTopicEnabled(AppNotificationTopic topic, bool enabled) async {
    await Storage.setBool(topic.prefKey, enabled);
  }

  Future<bool> notify(
    AppNotificationTopic topic, {
    required String title,
    required String body,
    bool ignoreTopicPreference = false,
  }) async {
    await init();
    if (!isSupportedOnCurrentPlatform || !_permissionGranted) return false;

    final enabled = ignoreTopicPreference || await isTopicEnabled(topic);
    if (!enabled) return false;

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch.remainder(2147483647),
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          topic.channelId,
          topic.channelName,
          channelDescription: topic.description,
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
        macOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
        linux: const LinuxNotificationDetails(defaultActionName: 'Ac'),
        windows: const WindowsNotificationDetails(),
      ),
      payload: topic.name,
    );
    return true;
  }

  Future<bool> sendPreview(AppNotificationTopic topic) {
    return notify(
      topic,
      title: topic.previewTitle,
      body: topic.previewBody,
      ignoreTopicPreference: true,
    );
  }
}
