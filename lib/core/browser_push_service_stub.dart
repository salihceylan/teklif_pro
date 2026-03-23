import 'browser_push_service.dart';

class _BrowserPushServiceStub implements BrowserPushService {
  @override
  bool get isSupported => false;

  @override
  Future<String> permissionStatus() async => 'unsupported';

  @override
  Future<bool> sendTestPush({
    required String apiBaseUrl,
    required String authToken,
  }) async => false;

  @override
  Future<bool> syncSubscription({
    required String apiBaseUrl,
    required String authToken,
    required List<String> topics,
    bool requestPermission = false,
  }) async => false;

  @override
  Future<bool> unsubscribe({
    required String apiBaseUrl,
    required String authToken,
  }) async => false;
}

BrowserPushService createBrowserPushServiceImpl() => _BrowserPushServiceStub();
