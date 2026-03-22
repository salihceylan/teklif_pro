import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/customer_provider.dart';
import '../widgets/app_shell.dart';

class CustomerFormScreen extends StatefulWidget {
  final int? customerId;

  const CustomerFormScreen({super.key, this.customerId});

  @override
  State<CustomerFormScreen> createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends State<CustomerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _saving = false;

  bool get _isEdit => widget.customerId != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final customer = context
            .read<CustomerProvider>()
            .items
            .where((item) => item.id == widget.customerId)
            .firstOrNull;
        if (customer != null) {
          _nameCtrl.text = customer.fullName;
          _emailCtrl.text = customer.email ?? '';
          _phoneCtrl.text = customer.phone ?? '';
          _addressCtrl.text = customer.address ?? '';
          _cityCtrl.text = customer.city ?? '';
          _notesCtrl.text = customer.notes ?? '';
        }
      });
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    final data = {
      'full_name': _nameCtrl.text.trim(),
      'email': _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      'address': _addressCtrl.text.trim().isEmpty
          ? null
          : _addressCtrl.text.trim(),
      'city': _cityCtrl.text.trim().isEmpty ? null : _cityCtrl.text.trim(),
      'notes': _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    };

    try {
      final provider = context.read<CustomerProvider>();
      if (_isEdit) {
        await provider.update(widget.customerId!, data);
      } else {
        await provider.create(data);
      }

      if (mounted) {
        context.go('/customers');
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(buildErrorSnackBar('Müşteri kaydedilemedi'));
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Müşteriyi Düzenle' : 'Yeni Müşteri'),
      ),
      body: Form(
        key: _formKey,
        child: AppScrollableBody(
          maxWidth: 980,
          children: [
            AppPageIntro(
              badge: _isEdit ? 'Düzenleme Modu' : 'Yeni Kayıt',
              icon: _isEdit
                  ? Icons.person_pin_circle_outlined
                  : Icons.person_add_alt_1_rounded,
              title: _isEdit
                  ? 'Müşteri kaydını güncelleyin'
                  : 'Yeni müşteri profili oluşturun',
              subtitle:
                  'İletişim, adres ve not alanlarını düzenli tutarak teklif ve servis operasyonlarında veri kaybını önleyin.',
            ),
            const SizedBox(height: 20),
            AppSectionCard(
              icon: Icons.badge_outlined,
              title: 'Temel Bilgiler',
              description:
                  'İsim ve iletişim alanları listelerde, tekliflerde ve servis kayıtlarında kullanılır.',
              children: [
                TextFormField(
                  controller: _nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Ad Soyad',
                    hintText: 'Müşteri adı soyadı',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) => value!.isEmpty ? 'Zorunlu alan' : null,
                ),
                AdaptiveFieldRow(
                  children: [
                    TextFormField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Telefon',
                        hintText: '05xx xxx xx xx',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                    ),
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'E-posta',
                        hintText: 'ornek@firma.com',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            AppSectionCard(
              icon: Icons.location_on_outlined,
              title: 'Adres Bilgileri',
              description:
                  'Saha ziyaretleri ve servis planlaması için konum bilgisini net tutun.',
              children: [
                AdaptiveFieldRow(
                  minItemWidth: 260,
                  children: [
                    TextFormField(
                      controller: _cityCtrl,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Şehir',
                        hintText: 'İstanbul',
                        prefixIcon: Icon(Icons.location_city_outlined),
                      ),
                    ),
                    TextFormField(
                      controller: _addressCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Adres',
                        hintText: 'Mahalle, sokak, bina bilgisi',
                        prefixIcon: Icon(Icons.home_outlined),
                        alignLabelWithHint: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            AppSectionCard(
              icon: Icons.notes_outlined,
              title: 'Operasyon Notları',
              description:
                  'Ödeme alışkanlıkları, randevu detayları veya ekip içi notlar için kullanılabilir.',
              children: [
                TextFormField(
                  controller: _notesCtrl,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Notlar',
                    hintText: 'Müşteri ile ilgili operasyon notları',
                    prefixIcon: Icon(Icons.edit_note_outlined),
                    alignLabelWithHint: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _saving ? null : _submit,
              icon: _saving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(_isEdit ? Icons.save_outlined : Icons.person_add_alt),
              label: Text(
                _isEdit ? 'Değişiklikleri Kaydet' : 'Müşteriyi Kaydet',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
