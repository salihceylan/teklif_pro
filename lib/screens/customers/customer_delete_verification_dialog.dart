import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_theme.dart';
import '../../services/customer_delete_service.dart';
import '../../services/customer_delete_verification_service.dart';

Future<CustomerDeleteImpact?> showCustomerDeleteVerificationDialog(
  BuildContext context, {
  required int customerId,
  required String companyName,
  required Future<CustomerDeleteImpact> Function(String requestId, String code)
  onVerified,
}) async {
  return showDialog<CustomerDeleteImpact>(
    context: context,
    barrierDismissible: false,
    builder: (_) => CustomerDeleteVerificationDialog(
      customerId: customerId,
      companyName: companyName,
      onVerified: onVerified,
    ),
  );
}

class CustomerDeleteVerificationDialog extends StatefulWidget {
  final int customerId;
  final String companyName;
  final Future<CustomerDeleteImpact> Function(String requestId, String code)
  onVerified;

  const CustomerDeleteVerificationDialog({
    super.key,
    required this.customerId,
    required this.companyName,
    required this.onVerified,
  });

  @override
  State<CustomerDeleteVerificationDialog> createState() =>
      _CustomerDeleteVerificationDialogState();
}

class _CustomerDeleteVerificationDialogState
    extends State<CustomerDeleteVerificationDialog> {
  final _service = CustomerDeleteVerificationService();
  final _codeController = TextEditingController();
  Timer? _timer;

  CustomerDeleteVerificationChallenge? _challenge;
  bool _sending = true;
  bool _submitting = false;
  String? _error;
  int _resendRemaining = 0;

  @override
  void initState() {
    super.initState();
    _sendCode();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    setState(() {
      _sending = true;
      _error = null;
    });

    try {
      final challenge = await _service.sendCode(
        customerId: widget.customerId,
        companyName: widget.companyName,
      );
      if (!mounted) {
        return;
      }
      _timer?.cancel();
      setState(() {
        _challenge = challenge;
        _sending = false;
        _resendRemaining = challenge.resendAfterSeconds;
      });
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        if (_resendRemaining <= 0) {
          timer.cancel();
          return;
        }
        setState(() {
          _resendRemaining -= 1;
        });
      });
    } on CustomerDeleteVerificationException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _sending = false;
        _error = error.message;
      });
    }
  }

  Future<void> _submit() async {
    if (_challenge == null) {
      return;
    }

    final code = _codeController.text.trim();
    if (code.length != 4) {
      setState(() {
        _error = 'Lütfen 4 haneli doğrulama kodunu girin';
      });
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final impact = await widget.onVerified(_challenge!.requestId, code);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(impact);
    } on CustomerDeleteVerificationException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _submitting = false;
        _error = error.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _submitting = false;
        _error = 'Doğrulama tamamlanamadı';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final maskedEmail = _challenge?.maskedEmail;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.mark_email_unread_outlined,
                  color: AppTheme.primary,
                  size: 28,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Mail Doğrulama Kodu',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                maskedEmail == null || maskedEmail.isEmpty
                    ? 'Firma silme işlemini tamamlamak için hesabınıza 4 haneli doğrulama kodu gönderiyoruz.'
                    : '$maskedEmail adresine gönderilen 4 haneli doğrulama kodunu girin. Kod doğruysa firma ve bağlı tüm kayıtlar silinecek.',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textMedium,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              if (_sending)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                TextField(
                  controller: _codeController,
                  autofocus: true,
                  maxLength: 4,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 12,
                    color: AppTheme.textDark,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Doğrulama Kodu',
                    hintText: '0000',
                    counterText: '',
                  ),
                  onSubmitted: (_) => _submitting ? null : _submit(),
                ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: const TextStyle(
                    color: AppTheme.danger,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  TextButton(
                    onPressed: _submitting
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text('İptal'),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _sending || _resendRemaining > 0 || _submitting
                        ? null
                        : _sendCode,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: Text(
                      _resendRemaining > 0
                          ? 'Tekrar gönder ($_resendRemaining sn)'
                          : 'Kodu tekrar gönder',
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _sending || _submitting ? null : _submit,
                    child: _submitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Doğrula'),
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
