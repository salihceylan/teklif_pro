import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../models/qr_login_models.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_session_service.dart';

class QrLoginDialog extends StatefulWidget {
  const QrLoginDialog({super.key});

  @override
  State<QrLoginDialog> createState() => _QrLoginDialogState();
}

class _QrLoginDialogState extends State<QrLoginDialog> {
  final _service = AuthSessionService();

  QrLoginChallenge? _challenge;
  Timer? _pollTimer;
  Timer? _countdownTimer;
  Duration _remaining = Duration.zero;
  bool _loading = false;
  bool _finishingLogin = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_createChallenge());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _createChallenge() async {
    if (_loading) {
      return;
    }
    _pollTimer?.cancel();
    _countdownTimer?.cancel();
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
        _challenge = null;
        _remaining = Duration.zero;
      });
    }

    try {
      final challenge = await _service.createQrChallenge();
      if (!mounted) {
        return;
      }
      setState(() {
        _challenge = challenge;
        _remaining = challenge.expiresAt.difference(DateTime.now());
        _loading = false;
      });

      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        final expiresAt = _challenge?.expiresAt;
        if (!mounted || expiresAt == null) {
          return;
        }
        final next = expiresAt.difference(DateTime.now());
        if (next.isNegative || next.inSeconds <= 0) {
          _countdownTimer?.cancel();
          _pollTimer?.cancel();
          setState(() => _remaining = Duration.zero);
          return;
        }
        setState(() => _remaining = next);
      });

      _pollTimer = Timer.periodic(
        Duration(seconds: challenge.pollIntervalSeconds),
        (_) => _pollChallenge(),
      );
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

  Future<void> _pollChallenge() async {
    final challenge = _challenge;
    if (challenge == null || _finishingLogin) {
      return;
    }
    try {
      final status = await _service.pollChallenge(
        challengeId: challenge.challengeId,
        pollToken: challenge.pollToken,
      );
      if (!mounted) {
        return;
      }
      if (status.status == 'approved' &&
          status.accessToken != null &&
          status.user != null) {
        _finishingLogin = true;
        await context.read<AuthProvider>().completeExternalLogin(
          accessToken: status.accessToken!,
          user: status.user!,
        );
        if (!mounted) {
          return;
        }
        Navigator.of(context).pop();
        context.go('/panel');
        return;
      }
      if (status.status == 'expired' ||
          status.status == 'rejected' ||
          status.status == 'consumed') {
        _pollTimer?.cancel();
        _countdownTimer?.cancel();
        setState(() {
          _error = status.detail ?? 'Karekod oturumu sona erdi.';
          _remaining = Duration.zero;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _loading
              ? const SizedBox(
                  height: 260,
                  child: Center(child: CircularProgressIndicator()),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Karekod ile Giriş',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _error ??
                          'Mobil uygulamadaki “Bilgisayarda Karekodla Giriş” ekranını açıp bu karekodu okutun.',
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      height: 276,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FBFD),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFD8E3EE)),
                      ),
                      child: Center(
                        child: _challenge == null
                            ? const Icon(
                                Icons.qr_code_2_rounded,
                                size: 88,
                                color: Color(0xFFCBD5E1),
                              )
                            : QrImageView(
                                data: _challenge!.qrPayload,
                                version: QrVersions.auto,
                                size: 240,
                                gapless: false,
                                eyeStyle: const QrEyeStyle(
                                  color: Color(0xFF173B72),
                                ),
                                dataModuleStyle: const QrDataModuleStyle(
                                  color: Color(0xFF173B72),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FBFD),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFD8E3EE),
                              ),
                            ),
                            child: Text(
                              _challenge == null
                                  ? 'Karekod bekleniyor'
                                  : _remaining.inSeconds > 0
                                  ? 'Kalan süre: ${_remaining.inMinutes.toString().padLeft(2, '0')}:${(_remaining.inSeconds % 60).toString().padLeft(2, '0')}'
                                  : 'Karekod süresi doldu',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF173B72),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      alignment: WrapAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: _createChallenge,
                          child: const Text('Yeni Karekod Oluştur'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Kapat'),
                        ),
                      ],
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
