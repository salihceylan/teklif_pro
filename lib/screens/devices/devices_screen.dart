import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../models/auth_session.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_session_service.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_shell.dart';
import '../widgets/destructive_confirm_dialog.dart';

class DevicesScreen extends StatefulWidget {
  const DevicesScreen({super.key});

  @override
  State<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen> {
  final _service = AuthSessionService();
  final _format = DateFormat('dd.MM.yyyy HH:mm', 'tr_TR');

  bool _loading = true;
  bool _busy = false;
  List<AuthSession> _sessions = const [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final sessions = await _service.listSessions();
      if (!mounted) {
        return;
      }
      setState(() {
        _sessions = sessions;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = _service.mapError(error);
        _loading = false;
      });
    }
  }

  Future<void> _revokeSession(AuthSession session) async {
    final confirmed = await showDestructiveConfirmDialog(
      context,
      title: 'Cihaz Oturumunu Kapat',
      message:
          '${session.deviceName} oturumunu kapatırsanız bu cihaz yeniden giriş yapmak zorunda kalacak.',
      confirmLabel: 'Oturumu Kapat',
    );
    if (!confirmed || !mounted) {
      return;
    }

    setState(() => _busy = true);
    try {
      await _service.revokeSession(session.id);
      if (!mounted) {
        return;
      }
      if (session.isCurrent) {
        await context.read<AuthProvider>().logout();
        if (mounted) {
          context.go('/login');
        }
        return;
      }
      await _load();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cihaz oturumu kapatıldı.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(buildErrorSnackBar(_service.mapError(error)));
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeCount = _sessions.length;

    return Scaffold(
      appBar: AppBar(title: const Text('Cihazlar')),
      drawer: const AppDrawer(currentRoute: '/devices'),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : AppScrollableBody(
              maxWidth: 1020,
              children: [
                AppPageIntro(
                  badge: '$activeCount / 3 cihaz aktif',
                  icon: Icons.devices_other_rounded,
                  title: 'Oturum Açılmış Cihazlar',
                  subtitle:
                      'Hangi cihazların hesabınıza eriştiğini buradan görür, gerekirse oturumlarını kapatabilirsiniz.',
                  supporting: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AppIntroSectionLabel(
                        label: 'Oturum Özeti',
                        icon: Icons.verified_user_outlined,
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          AppIntroStatCard(
                            label: 'Aktif Cihaz',
                            value: '$activeCount',
                          ),
                          const AppIntroStatCard(
                            label: 'Maksimum Limit',
                            value: '3 Cihaz',
                          ),
                        ],
                      ),
                    ],
                  ),
                  trailing: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          AppIntroActionButton(
                            icon: Icons.qr_code_scanner_rounded,
                            label: 'Bilgisayarda Karekodla Giriş',
                            onPressed: () => context.push('/devices/qr-login'),
                            emphasized: true,
                          ),
                          AppIntroActionButton(
                            icon: Icons.refresh_rounded,
                            label: 'Listeyi Yenile',
                            onPressed: _busy ? null : _load,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Tarayıcı girişleri ve mobil uygulama oturumları aynı listede görünür. 3 cihaz sınırı aşıldığında yeni giriş bloke edilir.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 13,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                AppSectionCard(
                  icon: Icons.devices_rounded,
                  title: 'Aktif Oturumlar',
                  description:
                      'Bu listedeki her kayıt ayrı bir cihaz veya tarayıcı oturumunu temsil eder.',
                  children: [
                    if (_error != null)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF1F2),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFFDA4AF)),
                        ),
                        child: Text(
                          _error!,
                          style: const TextStyle(
                            color: Color(0xFF9F1239),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    else if (_sessions.isEmpty)
                      const Text('Henüz kayıtlı cihaz bulunmuyor.')
                    else
                      for (final session in _sessions) _SessionCard(
                        session: session,
                        format: _format,
                        busy: _busy,
                        onRevoke: () => _revokeSession(session),
                      ),
                  ],
                ),
              ],
            ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final AuthSession session;
  final DateFormat format;
  final bool busy;
  final VoidCallback onRevoke;

  const _SessionCard({
    required this.session,
    required this.format,
    required this.busy,
    required this.onRevoke,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFD),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD8E3EE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  _iconFor(session.deviceType),
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          session.deviceName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textDark,
                          ),
                        ),
                        if (session.isCurrent)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F7EF),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: const Color(0xFFB7E4C7),
                              ),
                            ),
                            child: const Text(
                              'Bu cihaz',
                              style: TextStyle(
                                color: Color(0xFF15803D),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${session.platform} • ${_loginMethodLabel(session.loginMethod)}',
                      style: const TextStyle(
                        color: AppTheme.textMedium,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: busy ? null : onRevoke,
                icon: const Icon(Icons.logout_rounded),
                label: Text(session.isCurrent ? 'Bu Oturumu Kapat' : 'Kapat'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _MetaPill(
                icon: Icons.schedule_rounded,
                label: 'Son Görülme',
                value: format.format(session.lastSeenAt.toLocal()),
              ),
              _MetaPill(
                icon: Icons.login_rounded,
                label: 'Açılış',
                value: format.format(session.createdAt.toLocal()),
              ),
              _MetaPill(
                icon: Icons.hourglass_bottom_rounded,
                label: 'Bitiş',
                value: format.format(session.expiresAt.toLocal()),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static IconData _iconFor(String type) {
    switch (type) {
      case 'web':
        return Icons.language_rounded;
      case 'desktop':
        return Icons.laptop_windows_rounded;
      case 'mobile':
        return Icons.smartphone_rounded;
      default:
        return Icons.devices_other_rounded;
    }
  }

  static String _loginMethodLabel(String method) {
    switch (method) {
      case 'qr':
        return 'Karekod ile giriş';
      default:
        return 'Şifre ile giriş';
    }
  }
}

class _MetaPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MetaPill({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD8E3EE)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppTheme.primary),
          const SizedBox(width: 8),
          Text(
            '$label: $value',
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark,
            ),
          ),
        ],
      ),
    );
  }
}
