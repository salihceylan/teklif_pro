import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

import 'browser_push_service.dart';

class _BrowserPushServiceWeb implements BrowserPushService {
  JSObject? get _api {
    final windowObject = web.window as JSObject;
    if (!windowObject.has('teklifProPush')) return null;
    final value = windowObject['teklifProPush'];
    if (value == null) return null;
    return value as JSObject;
  }

  @override
  bool get isSupported {
    final api = _api;
    if (api == null) return false;
    return api.callMethod<JSBoolean>('isSupported'.toJS).toDart;
  }

  @override
  Future<String> permissionStatus() async {
    final api = _api;
    if (api == null) return 'unsupported';
    final result = api.callMethod<JSString>('permission'.toJS);
    return result.toDart;
  }

  @override
  Future<bool> syncSubscription({
    required String apiBaseUrl,
    required String authToken,
    required List<String> topics,
    bool requestPermission = false,
  }) async {
    final api = _api;
    if (api == null) return false;
    final result = await api
        .callMethod<JSPromise<JSAny?>>(
          'syncSubscription'.toJS,
          {
            'apiBaseUrl': apiBaseUrl,
            'authToken': authToken,
            'topics': topics,
            'requestPermission': requestPermission,
          }.jsify(),
        )
        .toDart;
    return _success(result);
  }

  @override
  Future<bool> unsubscribe({
    required String apiBaseUrl,
    required String authToken,
  }) async {
    final api = _api;
    if (api == null) return false;
    final result = await api
        .callMethod<JSPromise<JSAny?>>(
          'unsubscribe'.toJS,
          {'apiBaseUrl': apiBaseUrl, 'authToken': authToken}.jsify(),
        )
        .toDart;
    return _success(result);
  }

  @override
  Future<bool> sendTestPush({
    required String apiBaseUrl,
    required String authToken,
  }) async {
    final api = _api;
    if (api == null) return false;
    final result = await api
        .callMethod<JSPromise<JSAny?>>(
          'sendTestPush'.toJS,
          {'apiBaseUrl': apiBaseUrl, 'authToken': authToken}.jsify(),
        )
        .toDart;
    return _success(result);
  }

  bool _success(JSAny? value) {
    if (value == null) {
      return false;
    }
    final result = value as JSObject;
    if (!result.has('success')) return false;
    final success = result['success'];
    if (success == null) return false;
    return (success as JSBoolean).toDart;
  }
}

BrowserPushService createBrowserPushServiceImpl() => _BrowserPushServiceWeb();
