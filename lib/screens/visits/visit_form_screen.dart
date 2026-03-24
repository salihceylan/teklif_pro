import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../models/exchange_rate_snapshot.dart';
import '../../models/product.dart';
import '../../models/visit.dart';
import '../../providers/customer_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/visit_provider.dart';
import '../../services/exchange_rate_service.dart';
import '../widgets/app_shell.dart';

class VisitFormScreen extends StatefulWidget {
  final int? visitId;

  const VisitFormScreen({super.key, this.visitId});

  @override
  State<VisitFormScreen> createState() => _VisitFormScreenState();
}

class _VisitFormScreenState extends State<VisitFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _complaintCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _techNotesCtrl = TextEditingController();
  final _technicianCtrl = TextEditingController();
  final _laborCtrl = TextEditingController(text: '0');
  final _vatCtrl = TextEditingController(text: '20');
  final List<_MaterialRow> _items = [];
  final _exchangeRateService = ExchangeRateService();

  int? _customerId;
  DateTime? _scheduledDate;
  DateTime? _actualDate;
  String _status = 'scheduled';
  bool _saving = false;
  bool _rateLoading = false;
  String? _rateError;
  ServiceVisit? _loadedVisit;
  ExchangeRateSnapshot? _exchangeRate;
  final _fmt = NumberFormat('#,##0.00', 'tr_TR');
  double get _activeRate => _exchangeRate?.rate ?? 0;

  bool get _isEdit => widget.visitId != null;

  double get _materialTotalUsd =>
      _items.fold(0, (sum, item) => sum + item.totalPriceUsd);
  double get _laborAmountUsd =>
      double.tryParse(_laborCtrl.text.replaceAll(',', '.')) ?? 0;
  double get _vatRate =>
      double.tryParse(_vatCtrl.text.replaceAll(',', '.')) ?? 20;
  double get _vatTotalUsd => (_materialTotalUsd + _laborAmountUsd) * _vatRate / 100;
  double get _grandTotalUsd => _materialTotalUsd + _laborAmountUsd + _vatTotalUsd;
  double get _materialTotalTry => _materialTotalUsd * _activeRate;
  double get _laborAmountTry => _laborAmountUsd * _activeRate;
  double get _vatTotalTry => _vatTotalUsd * _activeRate;
  double get _grandTotalTry => _grandTotalUsd * _activeRate;

  @override
  void initState() {
    super.initState();
    if (!_isEdit) {
      _items.add(_MaterialRow.empty());
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
        final visitProvider = context.read<VisitProvider>();
        if (visitProvider.items.isEmpty) {
          await visitProvider.load();
        }
        if (!mounted) return;

        final visit = visitProvider.items
            .where((item) => item.id == widget.visitId)
            .firstOrNull;
        if (visit != null) {
          _bindVisit(visit, productProvider.items);
        } else {
          await _loadExchangeRate();
        }
      } else {
        await _loadExchangeRate();
      }
    });
  }

  void _bindVisit(ServiceVisit visit, List<Product> products) {
    setState(() {
      _loadedVisit = visit;
      _customerId = visit.customerId;
      _scheduledDate = visit.scheduledDate;
      _actualDate = visit.actualDate;
      _status = visit.status;
      _complaintCtrl.text = visit.complaint ?? '';
      _notesCtrl.text = visit.notes ?? '';
      _techNotesCtrl.text = visit.technicianNotes ?? '';
      _technicianCtrl.text = visit.technicianName ?? '';
      _laborCtrl.text = visit.laborAmountUsd.toString();
      _vatCtrl.text = visit.vatRate.toString();
      if (visit.hasExchangeRate && visit.exchangeRateDate != null) {
        _exchangeRate = ExchangeRateSnapshot(
          baseCurrency: visit.baseCurrency,
          quoteCurrency: visit.displayCurrency,
          rate: visit.exchangeRate!,
          rateDate: visit.exchangeRateDate!,
          source: visit.exchangeRateSource ?? 'TCMB',
        );
      }
      _items
        ..clear()
        ..addAll(
          visit.items.map(
            (item) => _MaterialRow(
              codeCtrl: TextEditingController(text: item.productCode ?? ''),
              nameCtrl: TextEditingController(text: item.materialName),
              qtyCtrl: TextEditingController(text: item.quantity.toString()),
              priceCtrl: TextEditingController(
                text: item.unitPriceUsd.toString(),
              ),
              selectedProductId: products
                  .where((product) => product.sku == item.productCode)
                  .firstOrNull
                  ?.id,
            ),
          ),
        );
      if (_items.isEmpty) {
        _items.add(_MaterialRow.empty());
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
    _complaintCtrl.dispose();
    _notesCtrl.dispose();
    _techNotesCtrl.dispose();
    _technicianCtrl.dispose();
    _laborCtrl.dispose();
    _vatCtrl.dispose();
    for (final row in _items) {
      row.dispose();
    }
    super.dispose();
  }

  Future<DateTime?> _pickDateTime(DateTime? initial) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 3650)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (date == null || !mounted) return null;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial ?? DateTime.now()),
    );
    if (time == null) return null;

    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _selectScheduledDate() async {
    final picked = await _pickDateTime(_scheduledDate);
    if (picked != null) {
      setState(() => _scheduledDate = picked);
    }
  }

  Future<void> _selectActualDate() async {
    final picked = await _pickDateTime(_actualDate ?? _scheduledDate);
    if (picked != null) {
      setState(() => _actualDate = picked);
    }
  }

  void _addItem() {
    setState(() => _items.add(_MaterialRow.empty()));
  }

  void _removeItem(int index) {
    final row = _items.removeAt(index);
    row.dispose();
    setState(() {});
  }

  String get _customerCreateRoute {
    final destination = _isEdit
        ? '/visits/${widget.visitId}/edit'
        : '/visits/new';
    return '/customers/new?returnTo=${Uri.encodeComponent(destination)}';
  }

  String get _productCreateRoute {
    final destination = _isEdit
        ? '/visits/${widget.visitId}/edit'
        : '/visits/new';
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

  void _applyProductToRow(_MaterialRow row, Product? product) {
    setState(() {
      row.selectedProductId = product?.id;
      if (product == null) return;
      row.codeCtrl.text = product.sku;
      row.nameCtrl.text = product.name;
      row.priceCtrl.text = _formatProductNumber(product.servicePriceUsd);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_exchangeRate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        buildErrorSnackBar('Servis formu icin TCMB USD/TRY kuru gerekli'),
      );
      return;
    }
    if (_scheduledDate == null || _customerId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(buildErrorSnackBar('Firma ve planlanan tarih zorunludur'));
      return;
    }

    setState(() => _saving = true);
    final data = {
      'customer_id': _customerId,
      'scheduled_date': _scheduledDate!.toIso8601String(),
      if (_actualDate != null) 'actual_date': _actualDate!.toIso8601String(),
      'status': _status,
      'complaint': _complaintCtrl.text.trim().isEmpty
          ? null
          : _complaintCtrl.text.trim(),
      'technician_name': _technicianCtrl.text.trim().isEmpty
          ? null
          : _technicianCtrl.text.trim(),
      'notes': _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      'technician_notes': _techNotesCtrl.text.trim().isEmpty
          ? null
          : _techNotesCtrl.text.trim(),
      'exchange_rate': _exchangeRate!.rate,
      'exchange_rate_date': _exchangeRate!.rateDate.toIso8601String(),
      'exchange_rate_source': _exchangeRate!.source,
      'labor_amount_usd': _laborAmountUsd,
      'vat_rate': _vatRate,
      'items': _items
          .map(
            (row) => {
              if (row.productCode.isNotEmpty) 'product_code': row.productCode,
              'material_name': row.materialName,
              'quantity': row.quantity,
              'unit_price_usd': row.unitPriceUsd,
            },
          )
          .toList(),
    };

    try {
      final provider = context.read<VisitProvider>();
      if (_isEdit) {
        await provider.update(widget.visitId!, data);
      } else {
        await provider.create(data);
      }

      if (mounted) {
        context.go('/visits');
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(buildErrorSnackBar('Servis formu kaydedilemedi'));
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
    final dateFormatter = DateFormat('dd.MM.yyyy HH:mm');

    if (customerProvider.loading && customers.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(_isEdit ? 'Servis Formunu Duzenle' : 'Yeni Servis Formu'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (!_isEdit && customers.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Yeni Servis Formu')),
        body: AppScrollableBody(
          maxWidth: 920,
          children: [
            AppPageIntro(
              badge: 'Servis Formu',
              icon: Icons.build_circle_outlined,
              title: 'Servis formu icin once firma ekleyin',
              subtitle:
                  'Servis kaydi bir firma ile baslar. Sadece sirket unvani ile hizli kayit acabilirsiniz.',
            ),
            const SizedBox(height: 20),
            AppSectionCard(
              icon: Icons.add_business_outlined,
              title: 'Gerekli ilk adim',
              description:
                  'Firma kaydini actiktan sonra servis formuna otomatik olarak geri donebilirsiniz.',
              children: [
                FilledButton.icon(
                  onPressed: () => context.go(_customerCreateRoute),
                  icon: const Icon(Icons.add_business_outlined),
                  label: const Text('Firma Ekle ve Servis Formuna Don'),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Servis Formunu Duzenle' : 'Yeni Servis Formu'),
      ),
      body: Form(
        key: _formKey,
        child: AppScrollableBody(
          maxWidth: 1080,
          children: [
            AppPageIntro(
              badge: _loadedVisit?.serviceCode ?? 'Servis Belgesi',
              icon: Icons.build_circle_outlined,
              title: _isEdit
                  ? 'Servis formunu guncelleyin'
                  : 'Yeni servis formu olusturun',
              subtitle:
                  'Malzeme ve iscilik USD net tutulur; TL karsiliklar belgeye kullanilan TCMB kuru ile snapshot olarak yazilir.',
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
                ],
              ),
            ),
            const SizedBox(height: 20),
            AppSectionCard(
              icon: Icons.currency_exchange_outlined,
              title: 'TCMB Kur Bilgisi',
              description:
                  'Servis formundaki TL karsiliklar gosterilen TCMB USD doviz satis kuru ile hesaplanir.',
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
                      _VisitRateInfoPanel(
                        label: 'USD/TRY Kuru',
                        value: _fmt.format(_exchangeRate!.rate),
                      ),
                      _VisitRateInfoPanel(
                        label: 'Bulten Tarihi',
                        value: DateFormat(
                          'dd.MM.yyyy',
                          'tr_TR',
                        ).format(_exchangeRate!.rateDate),
                      ),
                      _VisitRateInfoPanel(
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
                          'Kaydetmeden once kur degisirse serviste gorunen TL maliyetler de degisir. Kayıt anındaki TCMB kuru servis formuna sabit olarak yazilir.',
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
              icon: Icons.event_note_outlined,
              title: 'Musteri ve Ziyaret Bilgileri',
              description:
                  'Belge ust bolumunde yer alan firma, tarih ve durum bilgileri burada tutulur.',
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
                      label: 'Planlanan Tarih',
                      icon: Icons.schedule_outlined,
                      value: _scheduledDate == null
                          ? null
                          : dateFormatter.format(_scheduledDate!),
                      onTap: _selectScheduledDate,
                      placeholder: 'Tarih secin',
                      hasError: _scheduledDate == null,
                    ),
                    AppDatePickerField(
                      label: 'Gerceklesen Tarih',
                      icon: Icons.access_time_outlined,
                      value: _actualDate == null
                          ? null
                          : dateFormatter.format(_actualDate!),
                      onTap: _selectActualDate,
                      placeholder: 'Opsiyonel',
                    ),
                  ],
                ),
                AdaptiveFieldRow(
                  maxColumns: 2,
                  minItemWidth: 260,
                  children: [
                    DropdownButtonFormField<String>(
                      key: ValueKey(_status),
                      initialValue: _status,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Durum',
                        prefixIcon: Icon(Icons.flag_outlined),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'scheduled',
                          child: Text('Planlandi'),
                        ),
                        DropdownMenuItem(
                          value: 'in_progress',
                          child: Text('Devam Ediyor'),
                        ),
                        DropdownMenuItem(
                          value: 'completed',
                          child: Text('Tamamlandi'),
                        ),
                        DropdownMenuItem(
                          value: 'cancelled',
                          child: Text('Iptal'),
                        ),
                      ],
                      onChanged: (value) => setState(() => _status = value!),
                    ),
                    TextFormField(
                      controller: _technicianCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Teknik Personel',
                        prefixIcon: Icon(Icons.engineering_outlined),
                      ),
                    ),
                  ],
                ),
                TextFormField(
                  controller: _complaintCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Sikayet / Talep',
                    alignLabelWithHint: true,
                    prefixIcon: Icon(Icons.report_problem_outlined),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            AppSectionCard(
              icon: Icons.inventory_2_outlined,
              title: 'Malzeme ve Hizmet Kalemleri',
              description:
                  'Kod, malzeme adi, adet ve USD birim fiyat bilgileri servis formu tablosuna uygun tutulur.',
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
                  _MaterialCard(
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
              ],
            ),
            const SizedBox(height: 20),
            AppSectionCard(
              icon: Icons.calculate_outlined,
              title: 'Toplamlar',
              description:
                  'Malzeme ve iscilik USD net hesaplanir; belgeye yazilan TL toplamlari aktif TCMB kuru ile uretilir.',
              children: [
                AdaptiveFieldRow(
                  maxColumns: 2,
                  minItemWidth: 260,
                  children: [
                    TextFormField(
                      controller: _laborCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Iscilik Toplami (USD)',
                        prefixIcon: Icon(Icons.handyman_outlined),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    TextFormField(
                      controller: _vatCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'KDV Orani (%)',
                        prefixIcon: Icon(Icons.percent_outlined),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ],
                ),
                _VisitSummaryCard(
                  fmt: _fmt,
                  materialTotalUsd: _materialTotalUsd,
                  materialTotalTry: _materialTotalTry,
                  laborAmountUsd: _laborAmountUsd,
                  laborAmountTry: _laborAmountTry,
                  vatTotalUsd: _vatTotalUsd,
                  vatTotalTry: _vatTotalTry,
                  grandTotalUsd: _grandTotalUsd,
                  grandTotalTry: _grandTotalTry,
                ),
              ],
            ),
            const SizedBox(height: 20),
            AppSectionCard(
              icon: Icons.notes_outlined,
              title: 'Aciklamalar',
              description:
                  'Musteri notu ve teknisyen degerlendirmesi ayri alanlarda tutulur.',
              children: [
                TextFormField(
                  controller: _notesCtrl,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Musteri Notlari',
                    alignLabelWithHint: true,
                    prefixIcon: Icon(Icons.edit_note_outlined),
                  ),
                ),
                TextFormField(
                  controller: _techNotesCtrl,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Teknisyen Notlari',
                    alignLabelWithHint: true,
                    prefixIcon: Icon(Icons.fact_check_outlined),
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
                  : Icon(_isEdit ? Icons.save_outlined : Icons.build_outlined),
              label: Text(
                _isEdit ? 'Servis Formunu Guncelle' : 'Servis Formunu Kaydet',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MaterialCard extends StatelessWidget {
  final _MaterialRow row;
  final List<Product> products;
  final bool canDelete;
  final NumberFormat fmt;
  final double exchangeRate;
  final VoidCallback onDelete;
  final VoidCallback onChanged;
  final ValueChanged<int?> onProductSelected;

  const _MaterialCard({
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
                  labelText: 'Kod No',
                  prefixIcon: Icon(Icons.qr_code_2_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: row.nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Malzemenin Adi',
                  prefixIcon: Icon(Icons.widgets_outlined),
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

  List<Widget> _compactValueFields(_MaterialRow row, VoidCallback onChanged) =>
      [
        TextFormField(
          controller: row.qtyCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Adet',
            prefixIcon: Icon(Icons.format_list_numbered_outlined),
          ),
          onChanged: (_) => onChanged(),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: row.priceCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Birim Fiyati (USD)',
            prefixIcon: Icon(Icons.payments_outlined),
          ),
          onChanged: (_) => onChanged(),
        ),
      ];

  List<Widget> _wideValueFields(_MaterialRow row, VoidCallback onChanged) => [
    Expanded(
      child: TextFormField(
        controller: row.qtyCtrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(
          labelText: 'Adet',
          prefixIcon: Icon(Icons.format_list_numbered_outlined),
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
          labelText: 'Birim Fiyati (USD)',
          prefixIcon: Icon(Icons.payments_outlined),
        ),
        onChanged: (_) => onChanged(),
      ),
    ),
  ];
}

class _VisitSummaryCard extends StatelessWidget {
  final NumberFormat fmt;
  final double materialTotalUsd;
  final double materialTotalTry;
  final double laborAmountUsd;
  final double laborAmountTry;
  final double vatTotalUsd;
  final double vatTotalTry;
  final double grandTotalUsd;
  final double grandTotalTry;

  const _VisitSummaryCard({
    required this.fmt,
    required this.materialTotalUsd,
    required this.materialTotalTry,
    required this.laborAmountUsd,
    required this.laborAmountTry,
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
          _row('Malzeme Toplami (USD)', materialTotalUsd, currency: 'USD'),
          const SizedBox(height: 8),
          _row('Malzeme Toplami (TL)', materialTotalTry),
          const SizedBox(height: 8),
          _row('Iscilik Toplami (USD)', laborAmountUsd, currency: 'USD'),
          const SizedBox(height: 8),
          _row('Iscilik Toplami (TL)', laborAmountTry),
          const SizedBox(height: 8),
          _row('KDV (USD)', vatTotalUsd, currency: 'USD'),
          const SizedBox(height: 8),
          _row('KDV (TL)', vatTotalTry),
          const Divider(height: 24),
          _row('Genel Toplam (USD)', grandTotalUsd, currency: 'USD'),
          const Divider(height: 24),
          _row('Genel Toplam (TL)', grandTotalTry, highlighted: true),
        ],
      ),
    );
  }

  Widget _row(
    String label,
    double value, {
    bool highlighted = false,
    String currency = 'TRY',
  }) => Row(
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

class _MaterialRow {
  final TextEditingController codeCtrl;
  final TextEditingController nameCtrl;
  final TextEditingController qtyCtrl;
  final TextEditingController priceCtrl;
  int? selectedProductId;

  _MaterialRow({
    required this.codeCtrl,
    required this.nameCtrl,
    required this.qtyCtrl,
    required this.priceCtrl,
    this.selectedProductId,
  });

  factory _MaterialRow.empty() => _MaterialRow(
    codeCtrl: TextEditingController(),
    nameCtrl: TextEditingController(),
    qtyCtrl: TextEditingController(text: '1'),
    priceCtrl: TextEditingController(),
  );

  String get productCode => codeCtrl.text.trim();
  String get materialName => nameCtrl.text.trim();
  double get quantity =>
      double.tryParse(qtyCtrl.text.replaceAll(',', '.')) ?? 1;
  double get unitPriceUsd =>
      double.tryParse(priceCtrl.text.replaceAll(',', '.')) ?? 0;
  double get totalPriceUsd => quantity * unitPriceUsd;
  double unitPriceTry(double exchangeRate) => unitPriceUsd * exchangeRate;
  double totalPriceTry(double exchangeRate) =>
      totalPriceUsd * exchangeRate;

  void dispose() {
    codeCtrl.dispose();
    nameCtrl.dispose();
    qtyCtrl.dispose();
    priceCtrl.dispose();
  }
}

class _VisitRateInfoPanel extends StatelessWidget {
  final String label;
  final String value;

  const _VisitRateInfoPanel({required this.label, required this.value});

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
