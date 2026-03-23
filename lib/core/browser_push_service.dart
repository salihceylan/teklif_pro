import 'browser_push_service_stub.dart'
    if (dart.library.js_interop) 'browser_push_service_web.dart';

abstract class BrowserPushService {
  bool get isSupported;

  Future<String> permissionStatus();

  Future<bool> syncSubscription({
    required String apiBaseUrl,
    required String authToken,
    required List<String> topics,
    bool requestPermission = false,
  });

  Future<bool> unsubscribe({
    required String apiBaseUrl,
    required String authToken,
  });

  Future<bool> sendTestPush({
    required String apiBaseUrl,
    required String authToken,
  });
}

BrowserPushService createBrowserPushService() => createBrowserPushServiceImpl();
