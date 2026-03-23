import 'package:flutter/foundation.dart';

import 'app_notifications.dart';
import 'browser_push_service.dart';
import 'constants.dart';
import 'storage.dart';

class BrowserPushManager {
  BrowserPushManager._();

  static final BrowserPushManager instance = BrowserPushManager._();

  final BrowserPushService _service = createBrowserPushService();

  bool get isSupported => kIsWeb && _service.isSupported;

  Future<String> permissionStatus() async {
    if (!isSupported) return 'unsupported';
    return _service.permissionStatus();
  }

  Future<bool> syncCurrentUser({bool requestPermission = false}) async {
    if (!isSupported) return false;
    final token = Storage.getToken();
    if (token == null || token.isEmpty) return false;
    final topics = await _enabledTopicNames();
    return _service.syncSubscription(
      apiBaseUrl: AppConstants.baseUrl,
      authToken: token,
      topics: topics,
      requestPermission: requestPermission,
    );
  }

  Future<bool> syncTopicPreferences() async {
    final permission = await permissionStatus();
    if (permission != 'granted') return false;
    return syncCurrentUser();
  }

  Future<bool> requestPermissionAndSync() {
    return syncCurrentUser(requestPermission: true);
  }

  Future<bool> unsubscribeCurrentUser() async {
    if (!isSupported) return false;
    final token = Storage.getToken();
    if (token == null || token.isEmpty) return false;
    return _service.unsubscribe(
      apiBaseUrl: AppConstants.baseUrl,
      authToken: token,
    );
  }

  Future<bool> sendTestPush() async {
    if (!isSupported) return false;
    final token = Storage.getToken();
    if (token == null || token.isEmpty) return false;
    return _service.sendTestPush(
      apiBaseUrl: AppConstants.baseUrl,
      authToken: token,
    );
  }

  Future<List<String>> _enabledTopicNames() async {
    final topics = await AppNotifications.instance.topicPreferences();
    return topics.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key.name)
        .toList();
  }
}
