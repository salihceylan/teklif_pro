import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../widgets/app_shell.dart';

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

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
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
              'JWT tabanlı giriş ile tüm istekler doğrulanmış oturum üzerinden çalışır.',
        ),
      ],
      footer: Column(
        children: [
          const Divider(height: 1),
          const SizedBox(height: 14),
          TextButton(
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
              validator: (value) => value!.isEmpty ? 'E-posta girin' : null,
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
              validator: (value) => value!.isEmpty ? 'Şifre girin' : null,
            ),
            const SizedBox(height: 20),
            FilledButton(
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
          ],
        ),
      ),
    );
  }
}
