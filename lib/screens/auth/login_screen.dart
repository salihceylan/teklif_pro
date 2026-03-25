import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../widgets/app_shell.dart';
import 'qr_login_dialog.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;

  static const _buttonTextStyle = TextStyle(
    fontFamily: AppTheme.fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w700,
    height: 1.15,
  );

  static const _linkTextStyle = TextStyle(
    fontFamily: AppTheme.fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    height: 1.15,
  );

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final auth = context.read<AuthProvider>();
    final ok = await auth.login(_emailCtrl.text.trim(), _passCtrl.text);
    if (!ok && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(buildErrorSnackBar(auth.error ?? 'Giriş başarısız'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<AuthProvider>().loading;

    return AuthScaffold(
      showIntro: false,
      eyebrow: 'Saha ekibi için tek panel',
      title: 'Teklif, servis ve tahsilat sürecini aynı merkezden yönetin.',
      subtitle:
          'Teklif Pro; müşteri operasyonlarını düzenli, hızlı ve izlenebilir tutmak için tasarlandı. Tüm süreçleriniz her cihazda aynı netlikle görünür.',
      formTitle: 'Hesabınıza giriş yapın',
      formSubtitle: 'Devam etmek için e-posta ve şifrenizi girin.',
      highlights: const [
        AuthHighlight(
          icon: Icons.dashboard_customize_outlined,
          title: 'Merkezi görünüm',
          description:
              'Müşteriler, talepler, ziyaretler ve faturalar tek akışta kalır.',
        ),
        AuthHighlight(
          icon: Icons.mobile_friendly_outlined,
          title: 'Mobil uyumlu kullanım',
          description:
              'Dar ekranlarda taşmadan çalışan, okunabilir ve kontrollü arayüz.',
        ),
        AuthHighlight(
          icon: Icons.verified_user_outlined,
          title: 'Güvenli oturum',
          description:
              'Tüm istekler doğrulanmış oturum üzerinden ilerler; yeni cihazlar ayrıca yönetilebilir.',
        ),
      ],
      footer: Column(
        children: [
          const Divider(height: 1),
          const SizedBox(height: 14),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.primary,
              textStyle: _linkTextStyle,
            ),
            onPressed: () => context.go('/register'),
            child: const Text('Hesabınız yok mu? Kayıt olun'),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.username],
              decoration: const InputDecoration(
                labelText: 'E-posta',
                hintText: 'ornek@firma.com',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              validator: (value) =>
                  value == null || value.isEmpty ? 'E-posta girin' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passCtrl,
              obscureText: _obscure,
              autofillHints: const [AutofillHints.password],
              decoration: InputDecoration(
                labelText: 'Şifre',
                hintText: 'Şifrenizi girin',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              validator: (value) =>
                  value == null || value.isEmpty ? 'Şifre girin' : null,
            ),
            const SizedBox(height: 20),
            FilledButton(
              style: FilledButton.styleFrom(
                foregroundColor: Colors.white,
                textStyle: _buttonTextStyle,
              ),
              onPressed: loading ? null : _submit,
              child: loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Giriş Yap'),
            ),
            if (kIsWeb) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: loading
                    ? null
                    : () => showDialog<void>(
                        context: context,
                        barrierDismissible: true,
                        builder: (_) => const QrLoginDialog(),
                      ),
                icon: const Icon(Icons.qr_code_2_rounded),
                label: const Text('Karekod ile Giriş'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
