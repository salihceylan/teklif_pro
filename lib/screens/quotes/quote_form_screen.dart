import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/customer.dart';
import '../../models/quote.dart';
import '../../providers/auth_provider.dart';
import '../../providers/customer_provider.dart';
import '../../providers/quote_provider.dart';
import '../../services/quote_document_service.dart';
import '../widgets/app_shell.dart';

class QuoteFormScreen extends StatefulWidget {
  final int? quoteId;

  const QuoteFormScreen({super.key, this.quoteId});

  @override
  State<QuoteFormScreen> createState() => _QuoteFormScreenState();
}

class _QuoteFormScreenState extends State<QuoteFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _deliveryCtrl = TextEditingController();
  final _paymentCtrl = TextEditingController();
  final _termsCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final List<_ItemRow> _items = [];

  int? _customerId;
  String _status = 'draft';
  DateTime _issuedAt = DateTime.now();
  DateTime? _validUntil = DateTime.now().add(const Duration(days: 7));
  bool _pricesIncludeVat = true;
  bool _saving = false;
  Quote? _loadedQuote;

  bool get _isEdit => widget.quoteId != null;
  final _fmt = NumberFormat('#,##0.00', 'tr_TR');

  double get _subtotal =>
      _items.fold(0, (sum, item) => sum + (item.quantity * item.unitPrice));
  double get _vatTotal => _items.fold(
        0,
        (sum, item) => sum + ((item.quantity * item.unitPrice) * item.vatRate / 100),
      );
  double get _grandTotal => _subtotal + _vatTotal;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final quote = context
            .read<QuoteProvider>()
            .items
            .where((item) => item.id == widget.quoteId)
            .firstOrNull;
        if (quote != null) {
          _bindQuote(quote);
        }
      });
    } else {
      _items.add(_ItemRow.empty());
    }
  }

  void _bindQuote(Quote quote) {
    setState(() {
      _loadedQuote = quote;
      _titleCtrl.text = quote.title;
      _descCtrl.text = quote.description ?? '';
      _deliveryCtrl.text = quote.deliveryTime ?? '';
      _paymentCtrl.text = quote.paymentTerms ?? '';
      _termsCtrl.text = quote.termsAndConditions ?? '';
      _notesCtrl.text = quote.notes ?? '';
      _customerId = quote.customerId;
      _status = quote.status;
      _issuedAt = quote.issuedAt ?? quote.createdAt;
      _validUntil = quote.validUntil;
      _pricesIncludeVat = quote.pricesIncludeVat;
      _items
        ..clear()
        ..addAll(
          quote.items.map(
            (item) => _ItemRow(
              codeCtrl: TextEditingController(text: item.productCode ?? ''),
              descCtrl: TextEditingController(text: item.description),
              qtyCtrl: TextEditingController(text: item.quantity.toString()),
              unitCtrl: TextEditingController(text: item.unit),
              priceCtrl: TextEditingController(text: item.unitPrice.toString()),
              vatCtrl: TextEditingController(text: item.vatRate.toString()),
            ),
          ),
        );
      if (_items.isEmpty) {
        _items.add(_ItemRow.empty());
      }
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _deliveryCtrl.dispose();
    _paymentCtrl.dispose();
    _termsCtrl.dispose();
    _notesCtrl.dispose();
    for (final row in _items) {
      row.dispose();
    }
    super.dispose();
  }

  Future<void> _pickIssueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _issuedAt,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _issuedAt = picked);
    }
  }

  Future<void> _pickValidUntilDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _validUntil ?? _issuedAt,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _validUntil = picked);
    }
  }

  void _addItem() {
    setState(() => _items.add(_ItemRow.empty()));
  }

  void _removeItem(int index) {
    final row = _items.removeAt(index);
    row.dispose();
    setState(() {});
  }

  Customer? _selectedCustomer(List<Customer> customers) {
    if (_customerId == null) return null;
    return customers.where((item) => item.id == _customerId).firstOrNull;
  }

  Quote _buildDraftQuote(Customer? customer) {
    final items = _items
        .where((item) => item.description.isNotEmpty)
        .map(
          (item) => QuoteItem(
            productCode: item.productCode.isEmpty ? null : item.productCode,
            description: item.description,
            quantity: item.quantity,
            unit: item.unit.isEmpty ? 'Adet' : item.unit,
            unitPrice: item.unitPrice,
            vatRate: item.vatRate,
            totalPrice: item.totalPrice,
          ),
        )
        .toList();

    return Quote(
      id: widget.quoteId ?? 0,
      customerId: _customerId ?? 0,
      serviceRequestId: _loadedQuote?.serviceRequestId,
      quoteCode: _loadedQuote?.quoteCode,
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      customerCompanyName: customer?.companyName,
      customerContactName: customer?.contactName,
      customerPhone: customer?.phone,
      customerAddress: customer?.address,
      subtotal: _subtotal,
      vatTotal: _vatTotal,
      totalAmount: _grandTotal,
      status: _status,
      issuedAt: _issuedAt,
      validUntil: _validUntil,
      deliveryTime:
          _deliveryCtrl.text.trim().isEmpty ? null : _deliveryCtrl.text.trim(),
      paymentTerms:
          _paymentCtrl.text.trim().isEmpty ? null : _paymentCtrl.text.trim(),
      termsAndConditions:
          _termsCtrl.text.trim().isEmpty ? null : _termsCtrl.text.trim(),
      pricesIncludeVat: _pricesIncludeVat,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      createdAt: _loadedQuote?.createdAt ?? DateTime.now(),
      items: items,
    );
  }

  Future<void> _printDraftQuote(List<Customer> customers) async {
    if (_customerId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(buildErrorSnackBar('Once bir firma secin'));
      return;
    }
    final quote = _buildDraftQuote(_selectedCustomer(customers));
    if (quote.items.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(buildErrorSnackBar('Teklifte en az bir kalem olmalidir'));
      return;
    }

    await QuoteDocumentService.printQuote(
      quote: quote,
      customer: _selectedCustomer(customers),
      user: context.read<AuthProvider>().user,
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_customerId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(buildErrorSnackBar('Firma secin'));
      return;
    }

    setState(() => _saving = true);
    final data = {
      'customer_id': _customerId,
      'title': _titleCtrl.text.trim(),
      'description': _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      'issued_at': _issuedAt.toIso8601String(),
      if (_validUntil != null) 'valid_until': _validUntil!.toIso8601String(),
      'delivery_time':
          _deliveryCtrl.text.trim().isEmpty ? null : _deliveryCtrl.text.trim(),
      'payment_terms':
          _paymentCtrl.text.trim().isEmpty ? null : _paymentCtrl.text.trim(),
      'terms_and_conditions':
          _termsCtrl.text.trim().isEmpty ? null : _termsCtrl.text.trim(),
      'prices_include_vat': _pricesIncludeVat,
      'notes': _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      'status': _status,
      'items': _items
          .map(
            (row) => {
              if (row.productCode.isNotEmpty) 'product_code': row.productCode,
              'description': row.description,
              'quantity': row.quantity,
              'unit': row.unit.isEmpty ? 'Adet' : row.unit,
              'unit_price': row.unitPrice,
              'vat_rate': row.vatRate,
            },
          )
          .toList(),
    };

    try {
      final provider = context.read<QuoteProvider>();
      if (_isEdit) {
        await provider.update(widget.quoteId!, data);
      } else {
        await provider.create(data);
      }

      if (mounted) {
        context.go('/quotes');
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(buildErrorSnackBar('Teklif kaydedilemedi'));
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final customers = context.watch<CustomerProvider>().items;
    final selectedCustomer = _selectedCustomer(customers);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Teklifi Duzenle' : 'Yeni Teklif'),
      ),
      body: Form(
        key: _formKey,
        child: AppScrollableBody(
          maxWidth: 1100,
          children: [
            AppPageIntro(
              badge: _loadedQuote?.quoteCode ?? 'Teklif Belgesi',
              icon: Icons.request_quote_outlined,
              title: _isEdit
                  ? 'Teklif belgesini guncelleyin'
                  : 'Yeni fiyat teklifi hazirlayin',
              subtitle:
                  'Belge numarasi, kalem listesi, KDV ve ticari kosullar tek akista yonetilir.',
              trailing: FilledButton.icon(
                onPressed: () => _printDraftQuote(customers),
                icon: const Icon(Icons.print_outlined),
                label: const Text('Teklif Ciktisi'),
              ),
            ),
            const SizedBox(height: 20),
            AppSectionCard(
              icon: Icons.description_outlined,
              title: 'Belge Bilgileri',
              description:
                  'Firma secimi, belge tarihi ve gecerlilik bilgileri teklif ust bilgisini olusturur.',
              children: [
                AdaptiveFieldRow(
                  maxColumns: 3,
                  minItemWidth: 220,
                  children: [
                    DropdownButtonFormField<int>(
                      key: ValueKey(_customerId),
                      initialValue: _customerId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Firma',
                        prefixIcon: Icon(Icons.business_outlined),
                      ),
                      items: customers
                          .map(
                            (customer) => DropdownMenuItem(
                              value: customer.id,
                              child: Text(
                                [
                                  customer.customerCode,
                                  customer.companyName,
                                ].whereType<String>().join('  •  '),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) => setState(() => _customerId = value),
                      validator: (value) => value == null ? 'Firma secin' : null,
                    ),
                    AppDatePickerField(
                      label: 'Teklif Tarihi',
                      icon: Icons.calendar_today_outlined,
                      value: DateFormat('dd.MM.yyyy').format(_issuedAt),
                      onTap: _pickIssueDate,
                    ),
                    AppDatePickerField(
                      label: 'Gecerlilik',
                      icon: Icons.event_available_outlined,
                      value: _validUntil == null
                          ? null
                          : DateFormat('dd.MM.yyyy').format(_validUntil!),
                      onTap: _pickValidUntilDate,
                      placeholder: 'Tarih secin',
                    ),
                  ],
                ),
                AdaptiveFieldRow(
                  maxColumns: 2,
                  minItemWidth: 260,
                  children: [
                    TextFormField(
                      controller: _titleCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Teklif Basligi',
                        prefixIcon: Icon(Icons.title_outlined),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                              ? 'Zorunlu alan'
                              : null,
                    ),
                    DropdownButtonFormField<String>(
                      key: ValueKey(_status),
                      initialValue: _status,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Durum',
                        prefixIcon: Icon(Icons.flag_outlined),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'draft', child: Text('Taslak')),
                        DropdownMenuItem(value: 'sent', child: Text('Gonderildi')),
                        DropdownMenuItem(
                          value: 'accepted',
                          child: Text('Kabul Edildi'),
                        ),
                        DropdownMenuItem(
                          value: 'rejected',
                          child: Text('Reddedildi'),
                        ),
                        DropdownMenuItem(
                          value: 'expired',
                          child: Text('Suresi Doldu'),
                        ),
                      ],
                      onChanged: (value) => setState(() => _status = value!),
                    ),
                  ],
                ),
                if (selectedCustomer != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F8FB),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFD8E3EE)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selectedCustomer.companyName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          [
                            if ((selectedCustomer.contactName ?? '').isNotEmpty)
                              selectedCustomer.contactName!,
                            if ((selectedCustomer.phone ?? '').isNotEmpty)
                              selectedCustomer.phone!,
                            if ((selectedCustomer.address ?? '').isNotEmpty)
                              selectedCustomer.address!,
                          ].join('  •  '),
                          style: const TextStyle(
                            color: Color(0xFF607085),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            AppSectionCard(
              icon: Icons.assignment_outlined,
              title: 'Kapsam ve Ticari Kosullar',
              description:
                  'Teklif aciklamasi, teslimat suresi ve odeme kosullari teklif belgesinde ayri bloklar olarak kullanilir.',
              children: [
                TextFormField(
                  controller: _descCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Teklif Aciklamasi',
                    alignLabelWithHint: true,
                    prefixIcon: Icon(Icons.notes_outlined),
                  ),
                ),
                AdaptiveFieldRow(
                  maxColumns: 2,
                  minItemWidth: 260,
                  children: [
                    TextFormField(
                      controller: _deliveryCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Teslimat Suresi',
                        prefixIcon: Icon(Icons.local_shipping_outlined),
                      ),
                    ),
                    TextFormField(
                      controller: _paymentCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Odeme Kosullari',
                        prefixIcon: Icon(Icons.payments_outlined),
                      ),
                    ),
                  ],
                ),
                SwitchListTile.adaptive(
                  value: _pricesIncludeVat,
                  onChanged: (value) => setState(() => _pricesIncludeVat = value),
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Fiyatlara KDV dahildir'),
                  subtitle: const Text(
                    'Cikti belgesindeki kosul satirina otomatik olarak yansitilir.',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            AppSectionCard(
              icon: Icons.view_list_outlined,
              title: 'Teklif Kalemleri',
              description:
                  'Kalem kodu, birim, KDV ve toplam tutar bilgileri fiyat teklif formuna uygun sekilde tutulur.',
              trailing: TextButton.icon(
                onPressed: _addItem,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Kalem Ekle'),
              ),
              children: [
                for (final entry in _items.asMap().entries)
                  _QuoteItemCard(
                    row: entry.value,
                    canDelete: _items.length > 1,
                    fmt: _fmt,
                    onDelete: () => _removeItem(entry.key),
                    onChanged: () => setState(() {}),
                  ),
                _SummaryPanel(
                  fmt: _fmt,
                  subtotal: _subtotal,
                  vatTotal: _vatTotal,
                  grandTotal: _grandTotal,
                ),
              ],
            ),
            const SizedBox(height: 20),
            AppSectionCard(
              icon: Icons.gavel_outlined,
              title: 'Ek Kosullar ve Notlar',
              description:
                  'Belgenin alt bolumunde yer alan aciklama ve kosul maddeleri burada tutulur.',
              children: [
                TextFormField(
                  controller: _termsCtrl,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Aciklamalar ve Kosullar',
                    alignLabelWithHint: true,
                    prefixIcon: Icon(Icons.rule_folder_outlined),
                  ),
                ),
                TextFormField(
                  controller: _notesCtrl,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Ek Notlar',
                    alignLabelWithHint: true,
                    prefixIcon: Icon(Icons.sticky_note_2_outlined),
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
                  : Icon(
                      _isEdit
                          ? Icons.save_outlined
                          : Icons.request_quote_outlined,
                    ),
              label: Text(_isEdit ? 'Teklifi Guncelle' : 'Teklifi Kaydet'),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuoteItemCard extends StatelessWidget {
  final _ItemRow row;
  final bool canDelete;
  final NumberFormat fmt;
  final VoidCallback onDelete;
  final VoidCallback onChanged;

  const _QuoteItemCard({
    required this.row,
    required this.canDelete,
    required this.fmt,
    required this.onDelete,
    required this.onChanged,
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 620;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: row.codeCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Kod',
                        prefixIcon: Icon(Icons.qr_code_2_outlined),
                      ),
                    ),
                  ),
                  if (canDelete) ...[
                    const SizedBox(width: 12),
                    IconButton.filledTonal(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: row.descCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Urun / Hizmet Adi',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.inventory_2_outlined),
                ),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Zorunlu alan' : null,
                onChanged: (_) => onChanged(),
              ),
              const SizedBox(height: 12),
              if (compact)
                Column(children: _compactValueFields(row, onChanged))
              else
                Row(children: _wideValueFields(row, onChanged)),
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F0FA),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Toplam: ${fmt.format(row.totalPrice)} ₺',
                    style: const TextStyle(
                      color: Color(0xFF1F5EA8),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _compactValueFields(_ItemRow row, VoidCallback onChanged) => [
        TextFormField(
          controller: row.qtyCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Miktar',
            prefixIcon: Icon(Icons.tag_outlined),
          ),
          onChanged: (_) => onChanged(),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: row.unitCtrl,
          decoration: const InputDecoration(
            labelText: 'Birim',
            prefixIcon: Icon(Icons.straighten_outlined),
          ),
          onChanged: (_) => onChanged(),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: row.priceCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Birim Fiyat',
            prefixIcon: Icon(Icons.payments_outlined),
          ),
          onChanged: (_) => onChanged(),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: row.vatCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'KDV %',
            prefixIcon: Icon(Icons.percent_outlined),
          ),
          onChanged: (_) => onChanged(),
        ),
      ];

  List<Widget> _wideValueFields(_ItemRow row, VoidCallback onChanged) {
    final children = <Widget>[
      Expanded(
        child: TextFormField(
          controller: row.qtyCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Miktar',
            prefixIcon: Icon(Icons.tag_outlined),
          ),
          onChanged: (_) => onChanged(),
        ),
      ),
      const SizedBox(width: 12, height: 12),
      Expanded(
        child: TextFormField(
          controller: row.unitCtrl,
          decoration: const InputDecoration(
            labelText: 'Birim',
            prefixIcon: Icon(Icons.straighten_outlined),
          ),
          onChanged: (_) => onChanged(),
        ),
      ),
      const SizedBox(width: 12, height: 12),
      Expanded(
        child: TextFormField(
          controller: row.priceCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Birim Fiyat',
            prefixIcon: Icon(Icons.payments_outlined),
          ),
          onChanged: (_) => onChanged(),
        ),
      ),
      const SizedBox(width: 12, height: 12),
      Expanded(
        child: TextFormField(
          controller: row.vatCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'KDV %',
            prefixIcon: Icon(Icons.percent_outlined),
          ),
          onChanged: (_) => onChanged(),
        ),
      ),
    ];

    return children;
  }
}

class _SummaryPanel extends StatelessWidget {
  final NumberFormat fmt;
  final double subtotal;
  final double vatTotal;
  final double grandTotal;

  const _SummaryPanel({
    required this.fmt,
    required this.subtotal,
    required this.vatTotal,
    required this.grandTotal,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF5FB),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          _summaryRow('Ara Toplam', subtotal),
          const SizedBox(height: 8),
          _summaryRow('Toplam KDV', vatTotal),
          const Divider(height: 24),
          _summaryRow('Genel Toplam', grandTotal, highlighted: true),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, double value, {bool highlighted = false}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: highlighted ? FontWeight.w800 : FontWeight.w600,
              color: highlighted ? const Color(0xFF17304C) : const Color(0xFF5A6B7F),
            ),
          ),
        ),
        Text(
          '${fmt.format(value)} ₺',
          style: TextStyle(
            fontSize: highlighted ? 18 : 14,
            fontWeight: highlighted ? FontWeight.w800 : FontWeight.w700,
            color: highlighted ? const Color(0xFF1F5EA8) : const Color(0xFF17304C),
          ),
        ),
      ],
    );
  }
}

class _ItemRow {
  final TextEditingController codeCtrl;
  final TextEditingController descCtrl;
  final TextEditingController qtyCtrl;
  final TextEditingController unitCtrl;
  final TextEditingController priceCtrl;
  final TextEditingController vatCtrl;

  _ItemRow({
    required this.codeCtrl,
    required this.descCtrl,
    required this.qtyCtrl,
    required this.unitCtrl,
    required this.priceCtrl,
    required this.vatCtrl,
  });

  factory _ItemRow.empty() => _ItemRow(
        codeCtrl: TextEditingController(),
        descCtrl: TextEditingController(),
        qtyCtrl: TextEditingController(text: '1'),
        unitCtrl: TextEditingController(text: 'Adet'),
        priceCtrl: TextEditingController(),
        vatCtrl: TextEditingController(text: '20'),
      );

  String get productCode => codeCtrl.text.trim();
  String get description => descCtrl.text.trim();
  double get quantity => double.tryParse(qtyCtrl.text.replaceAll(',', '.')) ?? 1;
  String get unit => unitCtrl.text.trim();
  double get unitPrice =>
      double.tryParse(priceCtrl.text.replaceAll(',', '.')) ?? 0;
  double get vatRate => double.tryParse(vatCtrl.text.replaceAll(',', '.')) ?? 20;
  double get totalPrice => quantity * unitPrice * (1 + (vatRate / 100));

  void dispose() {
    codeCtrl.dispose();
    descCtrl.dispose();
    qtyCtrl.dispose();
    unitCtrl.dispose();
    priceCtrl.dispose();
    vatCtrl.dispose();
  }
}
