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
  // Direct stream subscription so we can pause/resume in Dart only,
  // without touching the Android camera (no platform-thread blocking).
  StreamSubscription<BarcodeCapture>? _barcodeSub;
  final _format = DateFormat('dd.MM.yyyy HH:mm', 'tr_TR');

  bool _closingAfterApproval = false;

  @override
  void initState() {
    super.initState();
    _barcodeSub = _scannerController.barcodes.listen(_onBarcode);
  }

  @override
  void dispose() {
    _barcodeSub?.cancel();
    _scannerController.dispose();
    super.dispose();
  }

  void _onBarcode(BarcodeCapture capture) {
    if (_closingAfterApproval) return;

    // Pause the stream immediately — pure Dart operation,
    // zero Android platform-thread involvement.
    _barcodeSub?.pause();

    final raw =
        capture.barcodes.isEmpty ? null : capture.barcodes.first.rawValue;
    final challengeId =
        raw == null ? null : _service.parseQrChallengeId(raw);

    if (challengeId == null) {
      _barcodeSub?.resume();
      return;
    }

    _processScan(challengeId);
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
          // Drawer'dan açıldığında context.go() kullanıldığı için stack boş
          // olabilir; canPop kontrolü ile güvenli şekilde geri dön.
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/devices');
          }
        });
        return;
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(buildErrorSnackBar(_service.mapError(error)));
    } finally {
      // Resume only if we're still on this screen and not closing.
      if (mounted && !_closingAfterApproval) {
        _barcodeSub?.resume();
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final screenHeight = constraints.maxHeight;
        final windowSize = screenWidth * 0.68;
        final left = (screenWidth - windowSize) / 2;
        final top = (screenHeight - windowSize) / 2 - 40;
        final scanWindow = Rect.fromLTWH(left, top, windowSize, windowSize);

        return Scaffold(
          appBar: AppBar(title: const Text('Karekod ile Web Girişi')),
          body: Stack(
            children: [
              Positioned.fill(
                // scanWindow restricts ML analysis to the central square —
                // dramatically reduces TFLite CPU load and prevents ANR.
                child: MobileScanner(
                  controller: _scannerController,
                  scanWindow: scanWindow,
                ),
              ),
              // Dark overlay with a hole cut out for the scan window.
              Positioned.fill(
                child: _ScanOverlay(scanWindow: scanWindow),
              ),
              // Corner brackets drawn on top.
              Positioned(
                left: left,
                top: top,
                width: windowSize,
                height: windowSize,
                child: const _ScanCorners(),
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
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
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
      },
    );
  }
}

/// Draws a dark semi-transparent overlay with a transparent rectangle
/// cut out at [scanWindow].
class _ScanOverlay extends StatelessWidget {
  final Rect scanWindow;

  const _ScanOverlay({required this.scanWindow});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _OverlayPainter(scanWindow: scanWindow));
  }
}

class _OverlayPainter extends CustomPainter {
  final Rect scanWindow;

  _OverlayPainter({required this.scanWindow});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withValues(alpha: 0.55);
    final full = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(
      scanWindow,
      const Radius.circular(16),
    );
    // Fill everything, then cut the hole.
    final path = Path()
      ..addRect(full)
      ..addRRect(rrect)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_OverlayPainter old) => old.scanWindow != scanWindow;
}

/// Draws animated corner brackets inside the scan window.
class _ScanCorners extends StatelessWidget {
  const _ScanCorners();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _CornerPainter());
  }
}

class _CornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const len = 28.0;
    const radius = 12.0;
    const stroke = 3.5;
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = stroke
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final corners = [
      // top-left
      [Offset(0, radius), Offset(0, 0), Offset(radius, 0)],
      // top-right
      [
        Offset(size.width - radius, 0),
        Offset(size.width, 0),
        Offset(size.width, radius),
      ],
      // bottom-left
      [
        Offset(0, size.height - radius),
        Offset(0, size.height),
        Offset(radius, size.height),
      ],
      // bottom-right
      [
        Offset(size.width - radius, size.height),
        Offset(size.width, size.height),
        Offset(size.width, size.height - radius),
      ],
    ];

    for (final pts in corners) {
      // extend each arm by `len`
      final a = pts[0];
      final corner = pts[1];
      final b = pts[2];
      final da = (a - corner) / (a - corner).distance * len;
      final db = (b - corner) / (b - corner).distance * len;
      final path = Path()
        ..moveTo(corner.dx + da.dx, corner.dy + da.dy)
        ..lineTo(corner.dx, corner.dy)
        ..lineTo(corner.dx + db.dx, corner.dy + db.dy);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_CornerPainter old) => false;
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
