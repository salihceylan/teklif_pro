import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../models/customer.dart';
import '../../models/exchange_rate_snapshot.dart';
import '../../models/product.dart';
import '../../models/quote.dart';
import '../../providers/auth_provider.dart';
import '../../providers/customer_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/quote_provider.dart';
import '../../services/exchange_rate_service.dart';
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
  final _exchangeRateService = ExchangeRateService();

  int? _customerId;
  String _status = 'draft';
  DateTime _issuedAt = DateTime.now();
  DateTime? _validUntil = DateTime.now().add(const Duration(days: 7));
  bool _pricesIncludeVat = true;
  bool _saving = false;
  bool _rateLoading = false;
  String? _rateError;
  Quote? _loadedQuote;
  ExchangeRateSnapshot? _exchangeRate;

  bool get _isEdit => widget.quoteId != null;
  final _fmt = NumberFormat('#,##0.00', 'tr_TR');
  double get _activeRate => _exchangeRate?.rate ?? 0;

  double get _subtotalUsd =>
      _items.fold(0, (sum, item) => sum + (item.quantity * item.unitPriceUsd));
  double get _vatTotalUsd => _items.fold(
    0,
    (sum, item) =>
        sum + ((item.quantity * item.unitPriceUsd) * item.vatRate / 100),
  );
  double get _grandTotalUsd => _subtotalUsd + _vatTotalUsd;
  double get _subtotalTry => _subtotalUsd * _activeRate;
  double get _vatTotalTry => _vatTotalUsd * _activeRate;
  double get _grandTotalTry => _grandTotalUsd * _activeRate;

  @override
  void initState() {
    super.initState();
    if (!_isEdit) {
      _items.add(_ItemRow.empty());
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final customerProvider = context.read<CustomerProvider>();
      final productProvider = context.read<ProductProvider>();
      if (customerProvider.items.isEmpty) {
        await customerProvider.load();
      }
      if (productProvider.items.isEmpty) {
        await productProvider.load();
      }
      if (!mounted) return;

      if (_isEdit) {
        final quoteProvider = context.read<QuoteProvider>();
        if (quoteProvider.items.isEmpty) {
          await quoteProvider.load();
        }
        if (!mounted) return;

        final quote = quoteProvider.items
            .where((item) => item.id == widget.quoteId)
            .firstOrNull;
        if (quote != null) {
          _bindQuote(quote, productProvider.items);
        } else {
          await _loadExchangeRate();
        }
      } else {
        await _loadExchangeRate();
      }
    });
  }

  void _bindQuote(Quote quote, List<Product> products) {
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
      if (quote.hasExchangeRate && quote.exchangeRateDate != null) {
        _exchangeRate = ExchangeRateSnapshot(
          baseCurrency: quote.baseCurrency,
          quoteCurrency: quote.displayCurrency,
          rate: quote.exchangeRate!,
          rateDate: quote.exchangeRateDate!,
          source: quote.exchangeRateSource ?? 'TCMB',
        );
      }
      _items
        ..clear()
        ..addAll(
          quote.items.map(
            (item) => _ItemRow(
              codeCtrl: TextEditingController(text: item.productCode ?? ''),
              descCtrl: TextEditingController(text: item.description),
              qtyCtrl: TextEditingController(text: item.quantity.toString()),
              unitCtrl: TextEditingController(text: item.unit),
              priceCtrl: TextEditingController(
                text: item.unitPriceUsd.toString(),
              ),
              vatCtrl: TextEditingController(text: item.vatRate.toString()),
              selectedProductId: products
                  .where((product) => product.sku == item.productCode)
                  .firstOrNull
                  ?.id,
            ),
          ),
        );
      if (_items.isEmpty) {
        _items.add(_ItemRow.empty());
      }
    });
  }

  Future<void> _loadExchangeRate() async {
    setState(() {
      _rateLoading = true;
      _rateError = null;
    });

    try {
      final rate = await _exchangeRateService.getUsdTry();
      if (!mounted) return;
      setState(() {
        _exchangeRate = rate;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _rateError = 'TCMB kuru alinamadi. Baglantiyi kontrol edip tekrar deneyin.';
      });
    } finally {
      if (mounted) {
        setState(() => _rateLoading = false);
      }
    }
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

  String get _customerCreateRoute {
    final destination = _isEdit
        ? '/quotes/${widget.quoteId}/edit'
        : '/quotes/new';
    return '/customers/new?returnTo=${Uri.encodeComponent(destination)}';
  }

  String get _productCreateRoute {
    final destination = _isEdit
        ? '/quotes/${widget.quoteId}/edit'
        : '/quotes/new';
    return '/products/new?returnTo=${Uri.encodeComponent(destination)}';
  }

  String _formatProductNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value
        .toStringAsFixed(2)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  void _applyProductToRow(_ItemRow row, Product? product) {
    setState(() {
      row.selectedProductId = product?.id;
      if (product == null) return;
      row.codeCtrl.text = product.sku;
      row.descCtrl.text = product.name;
      row.unitCtrl.text = product.unit;
      row.priceCtrl.text = _formatProductNumber(product.servicePriceUsd);
      row.vatCtrl.text = _formatProductNumber(product.vatRate);
    });
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
            unitPriceUsd: item.unitPriceUsd,
            unitPrice: item.unitPriceTry(_activeRate),
            vatRate: item.vatRate,
            totalPriceUsd: item.totalPriceUsd,
            totalPrice: item.totalPriceTry(_activeRate),
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
      subtotalUsd: _subtotalUsd,
      subtotal: _subtotalTry,
      vatTotalUsd: _vatTotalUsd,
      vatTotal: _vatTotalTry,
      totalAmountUsd: _grandTotalUsd,
      totalAmount: _grandTotalTry,
      exchangeRate: _exchangeRate?.rate,
      exchangeRateDate: _exchangeRate?.rateDate,
      exchangeRateSource: _exchangeRate?.source,
      baseCurrency: _exchangeRate?.baseCurrency ?? 'USD',
      displayCurrency: _exchangeRate?.quoteCurrency ?? 'TRY',
      status: _status,
      issuedAt: _issuedAt,
      validUntil: _validUntil,
      deliveryTime: _deliveryCtrl.text.trim().isEmpty
          ? null
          : _deliveryCtrl.text.trim(),
      paymentTerms: _paymentCtrl.text.trim().isEmpty
          ? null
          : _paymentCtrl.text.trim(),
      termsAndConditions: _termsCtrl.text.trim().isEmpty
          ? null
          : _termsCtrl.text.trim(),
      pricesIncludeVat: _pricesIncludeVat,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      createdAt: _loadedQuote?.createdAt ?? DateTime.now(),
      items: items,
    );
  }

  Future<void> _printDraftQuote(List<Customer> customers) async {
    if (_exchangeRate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        buildErrorSnackBar('Yazdirmadan once TCMB kurunu yukleyin'),
      );
      return;
    }
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
    if (_exchangeRate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        buildErrorSnackBar('Teklif icin TCMB USD/TRY kuru gerekli'),
      );
      return;
    }
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
      'description': _descCtrl.text.trim().isEmpty
          ? null
          : _descCtrl.text.trim(),
      'issued_at': _issuedAt.toIso8601String(),
      if (_validUntil != null) 'valid_until': _validUntil!.toIso8601String(),
      'delivery_time': _deliveryCtrl.text.trim().isEmpty
          ? null
          : _deliveryCtrl.text.trim(),
      'payment_terms': _paymentCtrl.text.trim().isEmpty
          ? null
          : _paymentCtrl.text.trim(),
      'terms_and_conditions': _termsCtrl.text.trim().isEmpty
          ? null
          : _termsCtrl.text.trim(),
      'prices_include_vat': _pricesIncludeVat,
      'notes': _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      'status': _status,
      'exchange_rate': _exchangeRate!.rate,
      'exchange_rate_date': _exchangeRate!.rateDate.toIso8601String(),
      'exchange_rate_source': _exchangeRate!.source,
      'items': _items
          .map(
            (row) => {
              if (row.productCode.isNotEmpty) 'product_code': row.productCode,
              'description': row.description,
              'quantity': row.quantity,
              'unit': row.unit.isEmpty ? 'Adet' : row.unit,
              'unit_price_usd': row.unitPriceUsd,
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
    final customerProvider = context.watch<CustomerProvider>();
    final productProvider = context.watch<ProductProvider>();
    final customers = customerProvider.items;
    final products = productProvider.items
        .where((item) => item.isActive)
        .toList();
    final selectedCustomer = _selectedCustomer(customers);

    if (customerProvider.loading && customers.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(_isEdit ? 'Teklifi Duzenle' : 'Yeni Teklif'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (!_isEdit && customers.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Yeni Teklif')),
        body: AppScrollableBody(
          maxWidth: 920,
          children: [
            AppPageIntro(
              badge: 'Teklif Hazirlama',
              icon: Icons.request_quote_outlined,
              title: 'Teklif icin once firma ekleyin',
              subtitle:
                  'Teklif belgesi bir firma kaydina bagli calisir. Sadece sirket unvani ile hizli kayit acabilirsiniz.',
            ),
            const SizedBox(height: 20),
            AppSectionCard(
              icon: Icons.add_business_outlined,
              title: 'Gerekli ilk adim',
              description:
                  'Firma kaydi acildiktan sonra teklif formuna otomatik olarak geri donebilirsiniz.',
              children: [
                FilledButton.icon(
                  onPressed: () => context.go(_customerCreateRoute),
                  icon: const Icon(Icons.add_business_outlined),
                  label: const Text('Firma Ekle ve Teklife Don'),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Teklifi Duzenle' : 'Yeni Teklif')),
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
                  'Urun fiyatlari USD net tutulur; teklifte kullanilan TCMB USD/TRY kuru ve TL karsiliklari belgeye snapshot olarak yazilir.',
              trailing: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  FilledButton.tonalIcon(
                    onPressed: () => context.go(_customerCreateRoute),
                    icon: const Icon(Icons.add_business_outlined),
                    label: const Text('Yeni Firma'),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: () => context.go(_productCreateRoute),
                    icon: const Icon(Icons.inventory_2_outlined),
                    label: const Text('Yeni Urun'),
                  ),
                  FilledButton.icon(
                    onPressed: () => _printDraftQuote(customers),
                    icon: const Icon(Icons.print_outlined),
                    label: const Text('Teklif Ciktisi'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            AppSectionCard(
              icon: Icons.currency_exchange_outlined,
              title: 'TCMB Kur Bilgisi',
              description:
                  'Formdaki TL karsiliklar gosterilen TCMB USD doviz satis kuru ile hesaplanir.',
              trailing: FilledButton.tonalIcon(
                onPressed: _rateLoading ? null : _loadExchangeRate,
                icon: _rateLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh_outlined),
                label: const Text('Kuru Yenile'),
              ),
              children: [
                if (_rateError != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF4E5),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFF4C26B)),
                    ),
                    child: Text(
                      _rateError!,
                      style: const TextStyle(
                        color: Color(0xFF8A5A00),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                else if (_exchangeRate != null)
                  AdaptiveFieldRow(
                    maxColumns: 3,
                    minItemWidth: 220,
                    children: [
                      _RateInfoPanel(
                        label: 'USD/TRY Kuru',
                        value: _fmt.format(_exchangeRate!.rate),
                      ),
                      _RateInfoPanel(
                        label: 'Bulten Tarihi',
                        value: DateFormat(
                          'dd.MM.yyyy',
                          'tr_TR',
                        ).format(_exchangeRate!.rateDate),
                      ),
                      _RateInfoPanel(
                        label: 'Kaynak',
                        value: _exchangeRate!.source,
                      ),
                    ],
                  )
                else
                  const SizedBox.shrink(),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7E8),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFF5D18C)),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: Color(0xFF9A6A00),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Kaydetmeden once kur degisirse teklifte gorunen TL fiyatlar da degisir. Teklif kaydedildiginde kullanilan TCMB kuru bu belgeye sabit snapshot olarak yazilir.',
                          style: TextStyle(
                            color: Color(0xFF6F4B00),
                            fontSize: 13,
                            height: 1.45,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            AppSectionCard(
              icon: Icons.description_outlined,
              title: 'Belge Bilgileri',
              description:
                  'Firma secimi, belge tarihi ve gecerlilik bilgileri teklif ust bilgisini olusturur.',
              trailing: TextButton.icon(
                onPressed: () => context.go(_customerCreateRoute),
                icon: const Icon(Icons.add_business_outlined, size: 18),
                label: const Text('Firma Ekle'),
              ),
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
                      validator: (value) =>
                          value == null ? 'Firma secin' : null,
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
                        DropdownMenuItem(
                          value: 'sent',
                          child: Text('Gonderildi'),
                        ),
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
                  'Teklif aciklamasi, teslimat suresi ve odeme kosullari belgeyle birlikte kur snapshot notuna da eklenir.',
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
                  onChanged: (value) =>
                      setState(() => _pricesIncludeVat = value),
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
                  'Kalemler USD ve KDV haric girilir; TL karsiliklar aktif TCMB kuru ile anlik hesaplanir.',
              trailing: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  TextButton.icon(
                    onPressed: () => context.go(_productCreateRoute),
                    icon: const Icon(Icons.inventory_2_outlined, size: 18),
                    label: const Text('Yeni Urun'),
                  ),
                  TextButton.icon(
                    onPressed: _addItem,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Kalem Ekle'),
                  ),
                ],
              ),
              children: [
                for (final entry in _items.asMap().entries)
                  _QuoteItemCard(
                    row: entry.value,
                    products: products,
                    canDelete: _items.length > 1,
                    fmt: _fmt,
                    exchangeRate: _activeRate,
                    onDelete: () => _removeItem(entry.key),
                    onChanged: () => setState(() {}),
                    onProductSelected: (productId) => _applyProductToRow(
                      entry.value,
                      products
                          .where((item) => item.id == productId)
                          .firstOrNull,
                    ),
                  ),
                _SummaryPanel(
                  fmt: _fmt,
                  subtotalUsd: _subtotalUsd,
                  subtotalTry: _subtotalTry,
                  vatTotalUsd: _vatTotalUsd,
                  vatTotalTry: _vatTotalTry,
                  grandTotalUsd: _grandTotalUsd,
                  grandTotalTry: _grandTotalTry,
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
  final List<Product> products;
  final bool canDelete;
  final NumberFormat fmt;
  final double exchangeRate;
  final VoidCallback onDelete;
  final VoidCallback onChanged;
  final ValueChanged<int?> onProductSelected;

  const _QuoteItemCard({
    required this.row,
    required this.products,
    required this.canDelete,
    required this.fmt,
    required this.exchangeRate,
    required this.onDelete,
    required this.onChanged,
    required this.onProductSelected,
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
                  Expanded(child: _buildProductSelector()),
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
                controller: row.codeCtrl,
                decoration: const InputDecoration(
                  labelText: 'Kod',
                  prefixIcon: Icon(Icons.qr_code_2_outlined),
                ),
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
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Zorunlu alan'
                    : null,
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F0FA),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    exchangeRate > 0
                        ? 'Toplam: ${fmt.format(row.totalPriceUsd)} USD  •  ${fmt.format(row.totalPriceTry(exchangeRate))} ₺'
                        : 'Toplam: ${fmt.format(row.totalPriceUsd)} USD',
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

  Widget _buildProductSelector() {
    if (products.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F8FC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFD8E3EE)),
        ),
        child: const Row(
          children: [
            Icon(Icons.inventory_2_outlined, color: AppTheme.textMedium),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Kayitli urun yok. Kalemi manuel girebilir veya once urun ekleyebilirsiniz.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textMedium,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return DropdownButtonFormField<int?>(
      key: ValueKey(row.selectedProductId),
      initialValue: row.selectedProductId,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Kayitli Urun',
        prefixIcon: Icon(Icons.inventory_2_outlined),
      ),
      items: [
        const DropdownMenuItem<int?>(
          value: null,
          child: Text('Manuel kalem gir'),
        ),
        ...products.map(
          (product) => DropdownMenuItem<int?>(
            value: product.id,
            child: Text(
              '${product.sku} • ${product.name}',
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
      onChanged: onProductSelected,
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
        labelText: 'Birim Fiyat (USD)',
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
            labelText: 'Birim Fiyat (USD)',
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
  final double subtotalUsd;
  final double subtotalTry;
  final double vatTotalUsd;
  final double vatTotalTry;
  final double grandTotalUsd;
  final double grandTotalTry;

  const _SummaryPanel({
    required this.fmt,
    required this.subtotalUsd,
    required this.subtotalTry,
    required this.vatTotalUsd,
    required this.vatTotalTry,
    required this.grandTotalUsd,
    required this.grandTotalTry,
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
          _summaryRow('Ara Toplam (USD)', subtotalUsd, currency: 'USD'),
          const SizedBox(height: 8),
          _summaryRow('Ara Toplam (TL)', subtotalTry),
          const SizedBox(height: 8),
          _summaryRow('Toplam KDV (USD)', vatTotalUsd, currency: 'USD'),
          const SizedBox(height: 8),
          _summaryRow('Toplam KDV (TL)', vatTotalTry),
          const Divider(height: 24),
          _summaryRow('Genel Toplam (USD)', grandTotalUsd, currency: 'USD'),
          const Divider(height: 24),
          _summaryRow('Genel Toplam (TL)', grandTotalTry, highlighted: true),
        ],
      ),
    );
  }

  Widget _summaryRow(
    String label,
    double value, {
    bool highlighted = false,
    String currency = 'TRY',
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: highlighted ? FontWeight.w800 : FontWeight.w600,
              color: highlighted
                  ? const Color(0xFF17304C)
                  : const Color(0xFF5A6B7F),
            ),
          ),
        ),
        Text(
          '${fmt.format(value)} ${currency == 'USD' ? 'USD' : '₺'}',
          style: TextStyle(
            fontSize: highlighted ? 18 : 14,
            fontWeight: highlighted ? FontWeight.w800 : FontWeight.w700,
            color: highlighted
                ? const Color(0xFF1F5EA8)
                : const Color(0xFF17304C),
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
  int? selectedProductId;

  _ItemRow({
    required this.codeCtrl,
    required this.descCtrl,
    required this.qtyCtrl,
    required this.unitCtrl,
    required this.priceCtrl,
    required this.vatCtrl,
    this.selectedProductId,
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
  double get quantity =>
      double.tryParse(qtyCtrl.text.replaceAll(',', '.')) ?? 1;
  String get unit => unitCtrl.text.trim();
  double get unitPriceUsd =>
      double.tryParse(priceCtrl.text.replaceAll(',', '.')) ?? 0;
  double get vatRate =>
      double.tryParse(vatCtrl.text.replaceAll(',', '.')) ?? 20;
  double get totalPriceUsd => quantity * unitPriceUsd * (1 + (vatRate / 100));
  double unitPriceTry(double exchangeRate) => unitPriceUsd * exchangeRate;
  double totalPriceTry(double exchangeRate) =>
      totalPriceUsd * exchangeRate;

  void dispose() {
    codeCtrl.dispose();
    descCtrl.dispose();
    qtyCtrl.dispose();
    unitCtrl.dispose();
    priceCtrl.dispose();
    vatCtrl.dispose();
  }
}

class _RateInfoPanel extends StatelessWidget {
  final String label;
  final String value;

  const _RateInfoPanel({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFD),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD8E3EE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textMedium,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textDark,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
