import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../widgets/app_shell.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();
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
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _companyCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.register(
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
      fullName: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      companyName: _companyCtrl.text.trim().isEmpty
          ? null
          : _companyCtrl.text.trim(),
    );
    if (!ok && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(buildErrorSnackBar(auth.error ?? 'Kayıt başarısız'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<AuthProvider>().loading;

    return AuthScaffold(
      eyebrow: 'Kurulum birkaç dakikada hazır',
      title:
          'Saha operasyonlarınızı düzenli ve profesyonel bir yapıya taşıyın.',
      subtitle:
          'Yeni hesap oluşturduktan sonra müşterilerinizi, servis taleplerinizi, tekliflerinizi ve faturalarınızı aynı panelden yönetebilirsiniz.',
      formTitle: 'Yeni hesap oluşturun',
      formSubtitle: 'Bilgilerinizi girin, ardından doğrudan panele geçin.',
      highlights: const [
        AuthHighlight(
          icon: Icons.people_outline,
          title: 'Müşteri odaklı yapı',
          description:
              'Her müşteri için teklif, ziyaret ve fatura geçmişi tek yerde toplanır.',
        ),
        AuthHighlight(
          icon: Icons.request_quote_outlined,
          title: 'Tekliften faturaya akış',
          description:
              'Hazırladığınız teklifleri kısa sürede hizmet ve tahsilat sürecine bağlayın.',
        ),
        AuthHighlight(
          icon: Icons.analytics_outlined,
          title: 'Net operasyon görünümü',
          description:
              'Panel kartları ve formlar hem masaüstü hem mobilde okunabilir kalır.',
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
            onPressed: () => context.go('/login'),
            child: const Text('Zaten hesabınız var mı? Giriş yapın'),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.words,
              autofillHints: const [AutofillHints.name],
              decoration: const InputDecoration(
                labelText: 'Ad Soyad',
                hintText: 'Salih Ceylan',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (value) => value!.isEmpty ? 'Ad Soyad girin' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(
                labelText: 'E-posta',
                hintText: 'ornek@firma.com',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              validator: (value) => value!.isEmpty ? 'E-posta girin' : null,
            ),
            const SizedBox(height: 16),
            AdaptiveFieldRow(
              children: [
                TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  autofillHints: const [AutofillHints.telephoneNumber],
                  decoration: const InputDecoration(
                    labelText: 'Telefon',
                    hintText: '05xx xxx xx xx',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                TextFormField(
                  controller: _companyCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Firma Adı',
                    hintText: 'Güde Teknoloji',
                    prefixIcon: Icon(Icons.business_outlined),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passCtrl,
              obscureText: _obscure,
              autofillHints: const [AutofillHints.newPassword],
              decoration: InputDecoration(
                labelText: 'Şifre',
                hintText: 'En az 6 karakter',
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
                  value!.length < 6 ? 'En az 6 karakter' : null,
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
                  : const Text('Kayıt Ol'),
            ),
          ],
        ),
      ),
    );
  }
}
