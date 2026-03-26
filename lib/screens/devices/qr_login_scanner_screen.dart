import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../models/qr_login_models.dart';
import '../../services/auth_session_service.dart';
import '../widgets/app_shell.dart';

class QrLoginScannerScreen extends StatefulWidget {
  const QrLoginScannerScreen({super.key});

  @override
  State<QrLoginScannerScreen> createState() => _QrLoginScannerScreenState();
}

class _QrLoginScannerScreenState extends State<QrLoginScannerScreen> {
  final _service = AuthSessionService();
  final _scannerController = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
  );
  final _format = DateFormat('dd.MM.yyyy HH:mm', 'tr_TR');

  bool _handlingScan = false;
  bool _closingAfterApproval = false;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  // Synchronous — returns instantly so the barcode stream is never blocked.
  void _handleDetect(BarcodeCapture capture) {
    if (_handlingScan || _closingAfterApproval) return;

    final raw =
        capture.barcodes.isEmpty ? null : capture.barcodes.first.rawValue;
    final challengeId =
        raw == null ? null : _service.parseQrChallengeId(raw);
    if (challengeId == null) return;

    setState(() => _handlingScan = true);
    // Stop camera immediately (fire-and-forget) to free CPU before the dialog.
    unawaited(_scannerController.stop());
    unawaited(_processScan(challengeId));
  }

  Future<void> _processScan(String challengeId) async {
    try {
      final preview = await _service.fetchChallengePreview(challengeId);
      if (!mounted) return;

      final approved = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => _ApproveDialog(
          preview: preview,
          format: _format,
        ),
      );

      if (approved == true) {
        await _service.approveChallenge(challengeId);
        if (!mounted) return;

        _closingAfterApproval = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          context.pop();
        });
        return;
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(buildErrorSnackBar(_service.mapError(error)));
    } finally {
      if (mounted && !_closingAfterApproval) {
        setState(() => _handlingScan = false);
        unawaited(_scannerController.start());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Scaffold(
        appBar: AppBar(title: const Text('Karekod ile Giriş')),
        body: const Center(
          child: Text('Bu ekran sadece mobil uygulamada kullanılabilir.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Karekod ile Web Girişi')),
      body: Stack(
        children: [
          Positioned.fill(
            child: MobileScanner(
              controller: _scannerController,
              onDetect: _handleDetect,
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 28,
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.62),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Tarayıcıdaki karekodu okutun',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Onay vermeden önce hangi tarayıcıda giriş açılacağını kontrol edeceksiniz.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ApproveDialog extends StatelessWidget {
  final QrLoginPreview preview;
  final DateFormat format;

  const _ApproveDialog({required this.preview, required this.format});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tarayıcı Girişini Onayla'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${preview.deviceName} için oturum açılacak.',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Text('Platform: ${preview.platform}'),
          Text('İstek: ${format.format(preview.createdAt)}'),
          Text('Son geçerlilik: ${format.format(preview.expiresAt)}'),
          const SizedBox(height: 14),
          const Text(
            'Bu giriş size ait değilse onaylamayın.',
            style: TextStyle(color: Color(0xFF9F1239)),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Vazgeç'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Onayla'),
        ),
      ],
    );
  }
}
