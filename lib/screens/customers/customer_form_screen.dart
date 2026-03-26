import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/customer.dart';
import '../../providers/customer_provider.dart';
import '../widgets/app_shell.dart';

class CustomerFormScreen extends StatefulWidget {
  final int? customerId;
  final String? returnTo;

  const CustomerFormScreen({super.key, this.customerId, this.returnTo});

  @override
  State<CustomerFormScreen> createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends State<CustomerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _companyCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _mersisCtrl = TextEditingController();
  final _taxNumberCtrl = TextEditingController();
  final _taxOfficeCtrl = TextEditingController();
  final _employeeCountCtrl = TextEditingController();
  final _ibanCtrl = TextEditingController();
  final _kepCtrl = TextEditingController();
  final _exporterCtrl = TextEditingController();
  final _hibCtrl = TextEditingController();
  final _naceCodeCtrl = TextEditingController();
  final _naceNameCtrl = TextEditingController();
  final _brandCtrl = TextEditingController();
  final _subSectorCtrl = TextEditingController();
  final _solutionCtrl = TextEditingController();
  final _targetCtrl = TextEditingController();
  final _salesChannelCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  DateTime? _foundationDate;
  bool _saving = false;
  bool _showAdvancedSections = false;
  Customer? _currentCustomer;

  bool get _isEdit => widget.customerId != null;
  bool get _hasReturnRoute =>
      widget.returnTo != null && widget.returnTo!.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _showAdvancedSections = _isEdit;

    if (_isEdit) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final provider = context.read<CustomerProvider>();
        if (provider.items.isEmpty) {
          await provider.load();
        }

        final customer = provider.items
            .where((item) => item.id == widget.customerId)
            .firstOrNull;
        if (customer != null) {
          _bindCustomer(customer);
        }
      });
    }
  }

  void _bindCustomer(Customer customer) {
    setState(() {
      _currentCustomer = customer;
      _companyCtrl.text = customer.companyName;
      _contactCtrl.text = customer.contactName ?? '';
      _emailCtrl.text = customer.email ?? '';
      _phoneCtrl.text = customer.phone ?? '';
      _websiteCtrl.text = customer.website ?? '';
      _addressCtrl.text = customer.address ?? '';
      _cityCtrl.text = customer.city ?? '';
      _mersisCtrl.text = customer.mersisNo ?? '';
      _taxNumberCtrl.text = customer.taxNumber ?? '';
      _taxOfficeCtrl.text = customer.taxOffice ?? '';
      _employeeCountCtrl.text = customer.employeeCount?.toString() ?? '';
      _ibanCtrl.text = customer.iban ?? '';
      _kepCtrl.text = customer.kepAddress ?? '';
      _exporterCtrl.text = customer.exporterUnions ?? '';
      _hibCtrl.text = customer.hibMembershipNo ?? '';
      _naceCodeCtrl.text = customer.naceCode ?? '';
      _naceNameCtrl.text = customer.naceName ?? '';
      _brandCtrl.text = customer.brandName ?? '';
      _subSectorCtrl.text = customer.subSector ?? '';
      _solutionCtrl.text = customer.offeredSolution ?? '';
      _targetCtrl.text = customer.targetCustomerGroup ?? '';
      _salesChannelCtrl.text = customer.salesChannel ?? '';
      _notesCtrl.text = customer.notes ?? '';
      _foundationDate = customer.foundationDate;
      _showAdvancedSections = true;
    });
  }

  @override
  void dispose() {
    for (final controller in [
      _companyCtrl,
      _contactCtrl,
      _emailCtrl,
      _phoneCtrl,
      _websiteCtrl,
      _addressCtrl,
      _cityCtrl,
      _mersisCtrl,
      _taxNumberCtrl,
      _taxOfficeCtrl,
      _employeeCountCtrl,
      _ibanCtrl,
      _kepCtrl,
      _exporterCtrl,
      _hibCtrl,
      _naceCodeCtrl,
      _naceNameCtrl,
      _brandCtrl,
      _subSectorCtrl,
      _solutionCtrl,
      _targetCtrl,
      _salesChannelCtrl,
      _notesCtrl,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickFoundationDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _foundationDate ?? DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _foundationDate = picked);
    }
  }

  String? _trimOrNull(TextEditingController controller) {
    final value = controller.text.trim();
    return value.isEmpty ? null : value;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final data = {
      'full_name': _companyCtrl.text.trim(),
      'contact_name': _trimOrNull(_contactCtrl),
      'email': _trimOrNull(_emailCtrl),
      'phone': _trimOrNull(_phoneCtrl),
      'website': _trimOrNull(_websiteCtrl),
      'address': _trimOrNull(_addressCtrl),
      'city': _trimOrNull(_cityCtrl),
      'mersis_no': _trimOrNull(_mersisCtrl),
      'tax_number': _trimOrNull(_taxNumberCtrl),
      'tax_office': _trimOrNull(_taxOfficeCtrl),
      'foundation_date': _foundationDate?.toIso8601String(),
      'employee_count': int.tryParse(_employeeCountCtrl.text.trim()),
      'iban': _trimOrNull(_ibanCtrl),
      'kep_address': _trimOrNull(_kepCtrl),
      'exporter_unions': _trimOrNull(_exporterCtrl),
      'hib_membership_no': _trimOrNull(_hibCtrl),
      'nace_code': _trimOrNull(_naceCodeCtrl),
      'nace_name': _trimOrNull(_naceNameCtrl),
      'brand_name': _trimOrNull(_brandCtrl),
      'sub_sector': _trimOrNull(_subSectorCtrl),
      'offered_solution': _trimOrNull(_solutionCtrl),
      'target_customer_group': _trimOrNull(_targetCtrl),
      'sales_channel': _trimOrNull(_salesChannelCtrl),
      'notes': _trimOrNull(_notesCtrl),
    }..removeWhere((key, value) => value == null);

    try {
      final provider = context.read<CustomerProvider>();
      if (_isEdit) {
        await provider.update(widget.customerId!, data);
      } else {
        await provider.create(data);
      }

      if (mounted) {
        context.go(widget.returnTo ?? '/customers');
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(buildErrorSnackBar('Firma kaydedilemedi'));
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Widget _buildBasicHint() {
    final text = _hasReturnRoute
        ? 'Sadece firma unvanı ile kaydı açın. Kaydet dediğinizde ilgili forma geri döneceksiniz.'
        : 'Sadece firma unvanı zorunlu. Diğer alanları daha sonra düzenleyebilirsiniz.';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F8FC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD9E5F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF1F5EA8).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.bolt_outlined, color: Color(0xFF1F5EA8)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Hızlı kayıt modu',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF607085),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedToggle() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        OutlinedButton.icon(
          onPressed: () {
            setState(() => _showAdvancedSections = !_showAdvancedSections);
          },
          icon: Icon(
            _showAdvancedSections
                ? Icons.unfold_less_outlined
                : Icons.tune_outlined,
          ),
          label: Text(
            _showAdvancedSections
                ? 'Detaylı alanları gizle'
                : 'Daha fazla bilgi ekle',
          ),
        ),
        if (!_isEdit)
          const Text(
            'İsterseniz şimdilik sadece şirket adını kaydedebilirsiniz.',
            style: TextStyle(fontSize: 12, color: Color(0xFF607085)),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = _foundationDate == null
        ? null
        : DateFormat('dd.MM.yyyy').format(_foundationDate!);

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Firmayı Düzenle' : 'Yeni Firma')),
      body: Form(
        key: _formKey,
        child: AppScrollableBody(
          maxWidth: 1080,
          children: [
            AppPageIntro(
              badge: _isEdit ? 'Firma Profili' : 'Hızlı Şirket Kaydı',
              icon: _isEdit
                  ? Icons.apartment_outlined
                  : Icons.add_business_outlined,
              title: _isEdit
                  ? 'Şirket profilini güncelleyin'
                  : 'Sadece şirket adıyla kayıt açın',
              subtitle: _isEdit
                  ? 'İletişim, vergi ve sektör bilgilerini istediğiniz zaman güncelleyebilirsiniz.'
                  : 'İlk adımda sadece şirket unvanı zorunlu. Diğer bilgileri ister şimdi, ister daha sonra düzenleyin.',
              trailing: _currentCustomer?.customerCode == null
                  ? null
                  : _CodeBadge(
                      label: 'Firma ID',
                      value: _currentCustomer!.customerCode!,
                    ),
            ),
            const SizedBox(height: 20),
            AppSectionCard(
              icon: Icons.apartment_outlined,
              title: 'Temel Kayıt',
              description:
                  'Teklif ve servis formlarında kullanılacak firma adını kaydedin.',
              children: [
                TextFormField(
                  controller: _companyCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Şirket Unvanı',
                    hintText: 'Orn. Gude Teknoloji',
                    prefixIcon: Icon(Icons.business_outlined),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Şirket unvanı zorunlu'
                      : null,
                ),
                if (!_showAdvancedSections) _buildBasicHint(),
                _buildAdvancedToggle(),
              ],
            ),
            if (_showAdvancedSections) ...[
              const SizedBox(height: 20),
              AppSectionCard(
                icon: Icons.contact_phone_outlined,
                title: 'İletişim Bilgileri',
                description:
                    'Yetkili kişi ve iletişim alanları opsiyoneldir. Sonradan da güncellenebilir.',
                children: [
                  AdaptiveFieldRow(
                    maxColumns: 2,
                    minItemWidth: 260,
                    children: [
                      TextFormField(
                        controller: _contactCtrl,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Yetkili Kişi',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                      ),
                      TextFormField(
                        controller: _phoneCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Telefon',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                      ),
                    ],
                  ),
                  AdaptiveFieldRow(
                    maxColumns: 2,
                    minItemWidth: 260,
                    children: [
                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'E-posta',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                      ),
                      TextFormField(
                        controller: _websiteCtrl,
                        keyboardType: TextInputType.url,
                        decoration: const InputDecoration(
                          labelText: 'Web Adresi',
                          prefixIcon: Icon(Icons.language_outlined),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              AppSectionCard(
                icon: Icons.badge_outlined,
                title: 'Resmi ve Finansal Bilgiler',
                description:
                    'Vergi, MERSIS, KEP ve banka bilgileri şirket künye bilgisini tamamlar.',
                children: [
                  AdaptiveFieldRow(
                    maxColumns: 4,
                    minItemWidth: 180,
                    children: [
                      TextFormField(
                        controller: _mersisCtrl,
                        decoration: const InputDecoration(
                          labelText: 'MERSIS No',
                          prefixIcon: Icon(Icons.numbers_outlined),
                        ),
                      ),
                      TextFormField(
                        controller: _taxNumberCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Vergi No',
                          prefixIcon: Icon(Icons.receipt_long_outlined),
                        ),
                      ),
                      TextFormField(
                        controller: _taxOfficeCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Vergi Dairesi',
                          prefixIcon: Icon(Icons.account_balance_outlined),
                        ),
                      ),
                      AppDatePickerField(
                        label: 'Kuruluş Tarihi',
                        icon: Icons.event_outlined,
                        value: dateLabel,
                        onTap: _pickFoundationDate,
                        placeholder: 'Tarih seçin',
                      ),
                    ],
                  ),
                  AdaptiveFieldRow(
                    maxColumns: 4,
                    minItemWidth: 180,
                    children: [
                      TextFormField(
                        controller: _employeeCountCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Personel Sayısı',
                          prefixIcon: Icon(Icons.groups_2_outlined),
                        ),
                      ),
                      TextFormField(
                        controller: _ibanCtrl,
                        decoration: const InputDecoration(
                          labelText: 'IBAN',
                          prefixIcon: Icon(
                            Icons.account_balance_wallet_outlined,
                          ),
                        ),
                      ),
                      TextFormField(
                        controller: _kepCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'KEP Adresi',
                          prefixIcon: Icon(Icons.mark_email_read_outlined),
                        ),
                      ),
                      TextFormField(
                        controller: _hibCtrl,
                        decoration: const InputDecoration(
                          labelText: 'HİB Üye No',
                          prefixIcon: Icon(Icons.verified_outlined),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              AppSectionCard(
                icon: Icons.location_on_outlined,
                title: 'Adres ve Sektör Bilgileri',
                description:
                    'Adres, faaliyet alanı ve sektör verilerini dilediğinizde ekleyin.',
                children: [
                  AdaptiveFieldRow(
                    maxColumns: 2,
                    minItemWidth: 260,
                    children: [
                      TextFormField(
                        controller: _cityCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Şehir',
                          prefixIcon: Icon(Icons.location_city_outlined),
                        ),
                      ),
                      TextFormField(
                        controller: _addressCtrl,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Merkez Adresi',
                          alignLabelWithHint: true,
                          prefixIcon: Icon(Icons.home_outlined),
                        ),
                      ),
                    ],
                  ),
                  AdaptiveFieldRow(
                    maxColumns: 3,
                    minItemWidth: 220,
                    children: [
                      TextFormField(
                        controller: _exporterCtrl,
                        decoration: const InputDecoration(
                          labelText: 'İhracatçı Birlikleri',
                          prefixIcon: Icon(Icons.public_outlined),
                        ),
                      ),
                      TextFormField(
                        controller: _naceCodeCtrl,
                        decoration: const InputDecoration(
                          labelText: 'NACE Kodu',
                          prefixIcon: Icon(Icons.qr_code_2_outlined),
                        ),
                      ),
                      TextFormField(
                        controller: _naceNameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'NACE Adı',
                          prefixIcon: Icon(Icons.schema_outlined),
                        ),
                      ),
                    ],
                  ),
                  AdaptiveFieldRow(
                    maxColumns: 3,
                    minItemWidth: 220,
                    children: [
                      TextFormField(
                        controller: _brandCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Marka',
                          prefixIcon: Icon(Icons.workspace_premium_outlined),
                        ),
                      ),
                      TextFormField(
                        controller: _subSectorCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Alt Sektör',
                          prefixIcon: Icon(Icons.hub_outlined),
                        ),
                      ),
                      TextFormField(
                        controller: _solutionCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Sunulan Çözüm',
                          prefixIcon: Icon(Icons.inventory_2_outlined),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              AppSectionCard(
                icon: Icons.tips_and_updates_outlined,
                title: 'Ticari Notlar',
                description:
                    'Hedef müşteri grubu, satış kanalı ve serbest notlar burada tutulur.',
                children: [
                  AdaptiveFieldRow(
                    maxColumns: 2,
                    minItemWidth: 260,
                    children: [
                      TextFormField(
                        controller: _targetCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Hedef Müşteri Grubu',
                          prefixIcon: Icon(Icons.groups_outlined),
                        ),
                      ),
                      TextFormField(
                        controller: _salesChannelCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Satış Kanalı / Platform',
                          prefixIcon: Icon(Icons.storefront_outlined),
                        ),
                      ),
                    ],
                  ),
                  TextFormField(
                    controller: _notesCtrl,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'Notlar',
                      alignLabelWithHint: true,
                      prefixIcon: Icon(Icons.edit_note_outlined),
                    ),
                  ),
                ],
              ),
            ],
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
                  : Icon(
                      _isEdit
                          ? Icons.save_outlined
                          : Icons.add_business_outlined,
                    ),
              label: Text(_isEdit ? 'Firmayı Güncelle' : 'Firmayı Kaydet'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CodeBadge extends StatelessWidget {
  final String label;
  final String value;

  const _CodeBadge({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.72),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
