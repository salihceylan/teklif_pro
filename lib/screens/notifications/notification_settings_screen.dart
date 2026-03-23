import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/app_notifications.dart';
import '../../core/browser_push_manager.dart';
import '../../core/app_theme.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_shell.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool _loading = true;
  bool _requestingPermission = false;
  bool _permissionGranted = false;
  String _permissionLabel = 'Kapali';
  late final bool _supported;
  Map<AppNotificationTopic, bool> _topicStates = {};

  bool get _isWebPush => kIsWeb;

  @override
  void initState() {
    super.initState();
    _supported = _isWebPush
        ? BrowserPushManager.instance.isSupported
        : AppNotifications.instance.isSupportedOnCurrentPlatform;
    _loadState();
  }

  Future<void> _loadState() async {
    final prefs = await AppNotifications.instance.topicPreferences();
    final granted = _isWebPush
        ? await BrowserPushManager.instance.permissionStatus() == 'granted'
        : await AppNotifications.instance.permissionGranted();
    final label = _isWebPush
        ? _browserPermissionLabel(
            await BrowserPushManager.instance.permissionStatus(),
          )
        : granted
        ? 'Acik'
        : 'Kapali';
    if (!mounted) return;
    setState(() {
      _topicStates = prefs;
      _permissionGranted = granted;
      _permissionLabel = label;
      _loading = false;
    });
  }

  Future<void> _toggleTopic(AppNotificationTopic topic, bool value) async {
    setState(() => _topicStates[topic] = value);
    await AppNotifications.instance.setTopicEnabled(topic, value);
    if (_isWebPush && _permissionGranted) {
      await BrowserPushManager.instance.syncTopicPreferences();
    }
  }

  Future<void> _requestPermission() async {
    setState(() => _requestingPermission = true);
    final granted = _isWebPush
        ? await BrowserPushManager.instance.requestPermissionAndSync()
        : await AppNotifications.instance.requestPermission();
    if (!mounted) return;
    setState(() {
      _permissionGranted = granted;
      _permissionLabel = granted
          ? 'Acik'
          : (_isWebPush ? 'Bekliyor / Kapali' : 'Kapali');
      _requestingPermission = false;
    });
  }

  Future<void> _sendPreview() async {
    final topic =
        _topicStates.entries
            .where((entry) => entry.value)
            .map((entry) => entry.key)
            .firstOrNull ??
        AppNotificationTopic.quoteLifecycle;
    final shown = _isWebPush
        ? await BrowserPushManager.instance.sendTestPush()
        : await AppNotifications.instance.sendPreview(topic);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          shown
              ? _isWebPush
                    ? 'Tarayici push test bildirimi gonderildi'
                    : 'Test bildirimi gonderildi'
              : 'Bildirim gosterilemedi. Izin durumunu kontrol edin.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final enabledCount = _topicStates.values.where((value) => value).length;

    return Scaffold(
      appBar: AppBar(title: const Text('Bildirimler')),
      drawer: const AppDrawer(currentRoute: '/notifications'),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : AppScrollableBody(
              maxWidth: 1020,
              children: [
                AppPageIntro(
                  badge: '$enabledCount konu aktif',
                  icon: Icons.notifications_active_outlined,
                  title: 'Bildirim Tercihleri',
                  subtitle:
                      'Olay gerceklestiginde cihazda hangi konu basliklarinin bildirim uretecegini buradan yonetebilirsiniz.',
                  trailing: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _HeroMetric(
                        label: 'Platform',
                        value: _supported
                            ? (_isWebPush ? 'Tarayici Push' : 'Cihaz Bildirimi')
                            : 'Destek Yok',
                      ),
                      _HeroMetric(label: 'Izin', value: _permissionLabel),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                AppSectionCard(
                  icon: _permissionGranted
                      ? Icons.notifications_on_outlined
                      : Icons.notifications_off_outlined,
                  title: _isWebPush
                      ? 'Tarayici Push Durumu'
                      : 'Cihaz Bildirim Durumu',
                  description: _supported
                      ? _isWebPush
                            ? 'Web surumunde browser push servis worker ve abonelik ile yonetilir.'
                            : 'Android ve masaustu uygulamalarda bildirimler bu izin ile goruntulenir.'
                      : _isWebPush
                      ? 'Bu tarayicida push API desteklenmiyor veya guvenli baglanti yok.'
                      : 'Bu platformda cihaz bildirimi desteklenmiyor.',
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _permissionGranted
                            ? const Color(0xFFEFFBF4)
                            : const Color(0xFFFFF6EB),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: _permissionGranted
                              ? const Color(0xFFB7E4C7)
                              : const Color(0xFFF3D2A2),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            _permissionGranted
                                ? Icons.check_circle_outline
                                : Icons.info_outline,
                            color: _permissionGranted
                                ? const Color(0xFF15803D)
                                : const Color(0xFFC97A0A),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _supported
                                  ? _permissionGranted
                                        ? _isWebPush
                                              ? 'Tarayici push aktif. Site kapali olsa bile secili konular gerceklestiginde browser bildirimi gelebilir.'
                                              : 'Cihaz bildirimi aktif. Secili konular gerceklestiginde aninda bildirim gorunur.'
                                        : _isWebPush
                                        ? 'Tarayici bildirimi icin izin vermeniz gerekiyor. Izin acildiginda abonelik backend ile eslenir.'
                                        : 'Bildirim izni kapali. Acar ve test bildirimi gonderirseniz cihaz ekraninda gorebilirsiniz.'
                                  : _isWebPush
                                  ? 'Bu tarayicida push kullanilamiyor. Yine de konu tercihlerini kaydedebilirsiniz.'
                                  : 'Bu platformda bildirim destegi yok.',
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppTheme.textDark,
                                height: 1.45,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        if (_supported)
                          FilledButton.icon(
                            onPressed: _requestingPermission
                                ? null
                                : _requestPermission,
                            icon: _requestingPermission
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(
                                    Icons.notifications_active_outlined,
                                  ),
                            label: Text(
                              _permissionGranted
                                  ? 'Izni Yeniden Kontrol Et'
                                  : _isWebPush
                                  ? 'Tarayici Push Iznini Ac'
                                  : 'Bildirim Iznini Ac',
                            ),
                          ),
                        OutlinedButton.icon(
                          onPressed: !_supported || !_permissionGranted
                              ? null
                              : _sendPreview,
                          icon: const Icon(Icons.campaign_outlined),
                          label: const Text('Test Bildirimi Gonder'),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                AppSectionCard(
                  icon: Icons.tune_outlined,
                  title: 'Bildirim Konulari',
                  description:
                      'Sadece aktif konular olay gerceklestiginde cihaz bildirimi uretir.',
                  children: [
                    for (final topic in AppNotificationTopic.values)
                      _TopicCard(
                        topic: topic,
                        enabled: _topicStates[topic] ?? true,
                        onChanged: (value) => _toggleTopic(topic, value),
                      ),
                  ],
                ),
              ],
            ),
    );
  }

  String _browserPermissionLabel(String permission) {
    switch (permission) {
      case 'granted':
        return 'Acik';
      case 'default':
        return 'Bekliyor';
      case 'denied':
        return 'Engelli';
      default:
        return 'Destek Yok';
    }
  }
}

class _HeroMetric extends StatelessWidget {
  final String label;
  final String value;

  const _HeroMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.74),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _TopicCard extends StatelessWidget {
  final AppNotificationTopic topic;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _TopicCard({
    required this.topic,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFD),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD8E3EE)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  topic.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  topic.description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textMedium,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Switch.adaptive(
            value: enabled,
            onChanged: onChanged,
            activeThumbColor: AppTheme.primary,
          ),
        ],
      ),
    );
  }
}
