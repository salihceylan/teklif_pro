import 'dart:async';

import 'package:app_settings/app_settings.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import 'app_theme.dart';
import 'branding.dart';
import 'constants.dart';
import 'storage.dart';

class InternetHealthService {
  InternetHealthService({Connectivity? connectivity, Dio? client})
    : _connectivity = connectivity ?? Connectivity(),
      _client =
          client ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 4),
              receiveTimeout: const Duration(seconds: 4),
              followRedirects: false,
              validateStatus: (status) => status != null && status < 500,
            ),
          );

  final Connectivity _connectivity;
  final Dio _client;

  Stream<bool> watchInternet() {
    return _connectivity.onConnectivityChanged
        .asyncMap((_) => hasInternet())
        .distinct();
  }

  Future<bool> hasInternet() async {
    final result = await _connectivity.checkConnectivity();
    if (!_hasNetworkTransport(result)) {
      return false;
    }

    try {
      final response = await _client.get(AppConstants.websiteUrl);
      return (response.statusCode ?? 0) > 0;
    } catch (_) {
      return false;
    }
  }

  bool _hasNetworkTransport(List<ConnectivityResult> result) {
    if (result.isEmpty) {
      return false;
    }
    return result.any((item) => item != ConnectivityResult.none);
  }
}

class AppInternetGate extends StatefulWidget {
  final Widget child;
  final bool enabled;
  final InternetHealthService? service;

  const AppInternetGate({
    super.key,
    required this.child,
    this.enabled = true,
    this.service,
  });

  @override
  State<AppInternetGate> createState() => _AppInternetGateState();
}

class _AppInternetGateState extends State<AppInternetGate> {
  late final InternetHealthService _service =
      widget.service ?? InternetHealthService();
  StreamSubscription<bool>? _subscription;
  bool _checking = true;
  bool _hasInternet = true;
  bool _retryingSession = false;

  @override
  void initState() {
    super.initState();
    if (!widget.enabled) {
      _checking = false;
      _hasInternet = true;
      return;
    }
    _bootstrap();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    try {
      final online = await _service.hasInternet();
      if (!mounted) {
        return;
      }
      setState(() {
        _checking = false;
        _hasInternet = online;
      });
      if (online) {
        await _retryStoredSessionIfNeeded();
      }
      _subscription = _service.watchInternet().listen((onlineNow) async {
        if (!mounted) {
          return;
        }
        setState(() => _hasInternet = onlineNow);
        if (onlineNow) {
          await _retryStoredSessionIfNeeded();
        }
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _checking = false;
        _hasInternet = true;
      });
    }
  }

  Future<void> _retryStoredSessionIfNeeded() async {
    if (_retryingSession || !mounted) {
      return;
    }
    final auth = context.read<AuthProvider>();
    if (auth.isLoggedIn || Storage.getToken() == null) {
      return;
    }

    _retryingSession = true;
    try {
      await auth.tryAutoLogin();
    } finally {
      _retryingSession = false;
    }
  }

  Future<void> _openSettings() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        await AppSettings.openAppSettings(type: AppSettingsType.wifi);
      } else {
        await AppSettings.openAppSettings(type: AppSettingsType.settings);
      }
    } catch (_) {
      try {
        await AppSettings.openAppSettings(type: AppSettingsType.settings);
      } catch (_) {}
    }
  }

  Future<void> _retryNow() async {
    setState(() => _checking = true);
    try {
      final online = await _service.hasInternet();
      if (!mounted) {
        return;
      }
      setState(() {
        _checking = false;
        _hasInternet = online;
      });
      if (online) {
        await _retryStoredSessionIfNeeded();
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _checking = false;
        _hasInternet = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }
    if (_checking) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_hasInternet) {
      return widget.child;
    }
    return _NoInternetScreen(
      onRetry: _retryNow,
      onOpenSettings: _openSettings,
    );
  }
}

class _NoInternetScreen extends StatelessWidget {
  final Future<void> Function() onRetry;
  final Future<void> Function() onOpenSettings;

  const _NoInternetScreen({
    required this.onRetry,
    required this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.primaryDark, AppTheme.primary, AppTheme.secondary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryDark.withValues(alpha: 0.2),
                        blurRadius: 36,
                        offset: const Offset(0, 18),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 78,
                        height: 78,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Image.asset(Branding.logoAsset, fit: BoxFit.cover),
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'İnternet bağlantısı gerekli',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Uygulamanın güvenli şekilde çalışması için internet bağlantısı açık olmalı. Lütfen Wi‑Fi veya mobil veriyi açın, ardından tekrar deneyin.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textMedium,
                          height: 1.55,
                        ),
                      ),
                      const SizedBox(height: 22),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FBFD),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFD8E3EE)),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.wifi_off_rounded,
                              color: AppTheme.primary,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Bağlantı sağlanınca uygulama kaldığı yerden normal akışına döner. Kayıtlı oturum varsa otomatik devam etmeyi tekrar dener.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textDark,
                                  height: 1.45,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () => onOpenSettings(),
                          icon: const Icon(Icons.settings_outlined),
                          label: const Text('Ayarları Aç'),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => onRetry(),
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Tekrar Dene'),
                        ),
                      ),
                      if (kIsWeb) ...[
                        const SizedBox(height: 12),
                        const Text(
                          'Web sürümünde tarayıcı ayarlarından ağ bağlantınızı kontrol edin.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textLight,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
