import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../providers/customer_provider.dart';
import '../../providers/quote_provider.dart';
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
  final _notesCtrl = TextEditingController();
  int? _customerId;
  String _status = 'draft';
  DateTime? _validUntil;
  final List<_ItemRow> _items = [];
  bool _saving = false;

  bool get _isEdit => widget.quoteId != null;
  final _fmt = NumberFormat('#,##0.00', 'tr_TR');

  double get _total =>
      _items.fold(0, (sum, item) => sum + (item.qty * item.price));

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
          setState(() {
            _titleCtrl.text = quote.title;
            _descCtrl.text = quote.description ?? '';
            _notesCtrl.text = quote.notes ?? '';
            _customerId = quote.customerId;
            _status = quote.status;
            _validUntil = quote.validUntil;
            _items
              ..clear()
              ..addAll(
                quote.items.map(
                  (item) => _ItemRow(
                    descCtrl: TextEditingController(text: item.description),
                    qtyCtrl: TextEditingController(
                      text: item.quantity.toString(),
                    ),
                    priceCtrl: TextEditingController(
                      text: item.unitPrice.toString(),
                    ),
                  ),
                ),
              );
            if (_items.isEmpty) {
              _items.add(_ItemRow.empty());
            }
          });
        }
      });
    } else {
      _items.add(_ItemRow.empty());
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _notesCtrl.dispose();
    for (final row in _items) {
      row.dispose();
    }
    super.dispose();
  }

  void _addItem() {
    setState(() => _items.add(_ItemRow.empty()));
  }

  void _removeItem(int index) {
    final row = _items.removeAt(index);
    row.dispose();
    setState(() {});
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    final data = {
      'customer_id': _customerId,
      'title': _titleCtrl.text.trim(),
      'description': _descCtrl.text.trim().isEmpty
          ? null
          : _descCtrl.text.trim(),
      'notes': _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      'status': _status,
      if (_validUntil != null) 'valid_until': _validUntil!.toIso8601String(),
      'items': _items
          .map(
            (row) => {
              'description': row.descCtrl.text.trim(),
              'quantity': row.qty,
              'unit_price': row.price,
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

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Teklifi Düzenle' : 'Yeni Teklif')),
      body: Form(
        key: _formKey,
        child: AppScrollableBody(
          maxWidth: 1020,
          children: [
            AppPageIntro(
              badge: _isEdit ? 'Düzenleme Modu' : 'Yeni Teklif',
              icon: _isEdit
                  ? Icons.request_quote_outlined
                  : Icons.note_add_outlined,
              title: _isEdit
                  ? 'Teklif kaydını güncelleyin'
                  : 'Yeni teklif hazırlayın',
              subtitle:
                  'Müşteri seçimi, geçerlilik tarihi ve teklif kalemlerini aynı akışta yöneterek profesyonel bir teklif çıktısı hazırlayın.',
            ),
            const SizedBox(height: 20),
            AppSectionCard(
              icon: Icons.description_outlined,
              title: 'Teklif Özeti',
              description:
                  'Teklif başlığını, müşteriyi ve açıklamayı net tutarak takip sürecini kolaylaştırın.',
              children: [
                AdaptiveFieldRow(
                  children: [
                    DropdownButtonFormField<int>(
                      key: ValueKey(_customerId),
                      initialValue: _customerId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Müşteri',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      items: customers
                          .map(
                            (customer) => DropdownMenuItem(
                              value: customer.id,
                              child: Text(
                                customer.fullName,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) => setState(() => _customerId = value),
                      validator: (value) =>
                          value == null ? 'Müşteri seçin' : null,
                    ),
                    TextFormField(
                      controller: _titleCtrl,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Teklif Başlığı',
                        hintText: 'Örn. Yıllık bakım hizmeti',
                        prefixIcon: Icon(Icons.title_outlined),
                      ),
                      validator: (value) =>
                          value!.isEmpty ? 'Zorunlu alan' : null,
                    ),
                  ],
                ),
                TextFormField(
                  controller: _descCtrl,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Açıklama',
                    hintText: 'Teklif kapsamı ve teslim koşulları',
                    prefixIcon: Icon(Icons.notes_outlined),
                    alignLabelWithHint: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            AppSectionCard(
              icon: Icons.tune_outlined,
              title: 'Durum ve Geçerlilik',
              description:
                  'Teklif yaşam döngüsünü ve müşteriye sunulan son geçerlilik tarihini belirleyin.',
              children: [
                AdaptiveFieldRow(
                  children: [
                    if (_isEdit)
                      DropdownButtonFormField<String>(
                        key: ValueKey(_status),
                        initialValue: _status,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Durum',
                          prefixIcon: Icon(Icons.info_outline),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'draft',
                            child: Text('Taslak'),
                          ),
                          DropdownMenuItem(
                            value: 'sent',
                            child: Text('Gönderildi'),
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
                            child: Text('Süresi Doldu'),
                          ),
                        ],
                        onChanged: (value) => setState(() => _status = value!),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppTheme.primary.withValues(alpha: 0.14),
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline, color: AppTheme.primary),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Yeni oluşturulan teklifler varsayılan olarak taslak durumda başlar.',
                                style: TextStyle(
                                  color: AppTheme.textMedium,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    AppDatePickerField(
                      label: 'Geçerlilik Tarihi',
                      icon: Icons.event_available_outlined,
                      value: _validUntil == null
                          ? null
                          : DateFormat('dd.MM.yyyy').format(_validUntil!),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate:
                              _validUntil ??
                              DateTime.now().add(const Duration(days: 30)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                        );
                        if (picked != null) {
                          setState(() => _validUntil = picked);
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            AppSectionCard(
              icon: Icons.list_alt_outlined,
              title: 'Teklif Kalemleri',
              description:
                  'Kalemler toplam tutarı otomatik hesaplar. Dar ekranda alanlar alta taşınarak okunabilir kalır.',
              trailing: TextButton.icon(
                onPressed: _addItem,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Kalem Ekle'),
              ),
              children: [
                for (final entry in _items.asMap().entries)
                  _ItemCard(
                    row: entry.value,
                    fmt: _fmt,
                    canDelete: _items.length > 1,
                    onDelete: () => _removeItem(entry.key),
                    onChanged: () => setState(() {}),
                  ),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Genel Toplam',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textDark,
                          ),
                        ),
                      ),
                      Text(
                        '${_fmt.format(_total)} ₺',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            AppSectionCard(
              icon: Icons.sticky_note_2_outlined,
              title: 'Ek Notlar',
              description:
                  'Teslim süresi, özel şartlar veya müşteri için ek açıklamaları burada tutun.',
              children: [
                TextFormField(
                  controller: _notesCtrl,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Notlar',
                    hintText: 'Ek açıklamalar ve teklif notları',
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
                  : Icon(
                      _isEdit
                          ? Icons.save_outlined
                          : Icons.request_quote_outlined,
                    ),
              label: Text(_isEdit ? 'Teklifi Güncelle' : 'Teklifi Kaydet'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  final _ItemRow row;
  final NumberFormat fmt;
  final bool canDelete;
  final VoidCallback onDelete;
  final VoidCallback onChanged;

  const _ItemCard({
    required this.row,
    required this.fmt,
    required this.canDelete,
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
        border: Border.all(color: AppTheme.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 520;
          final valueFields = compact
              ? Column(
                  children: [
                    TextFormField(
                      controller: row.qtyCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Adet',
                        prefixIcon: Icon(Icons.tag_outlined),
                      ),
                      onChanged: (_) => onChanged(),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: row.priceCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Birim Fiyat',
                        hintText: '0.00',
                        prefixIcon: Icon(Icons.payments_outlined),
                      ),
                      onChanged: (_) => onChanged(),
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: row.qtyCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Adet',
                          prefixIcon: Icon(Icons.tag_outlined),
                        ),
                        onChanged: (_) => onChanged(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: row.priceCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Birim Fiyat',
                          hintText: '0.00',
                          prefixIcon: Icon(Icons.payments_outlined),
                        ),
                        onChanged: (_) => onChanged(),
                      ),
                    ),
                  ],
                );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: row.descCtrl,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Açıklama',
                        hintText: 'Hizmet veya ürün açıklaması',
                        prefixIcon: Icon(Icons.notes_outlined),
                      ),
                      validator: (value) =>
                          value!.isEmpty ? 'Zorunlu alan' : null,
                    ),
                  ),
                  if (canDelete) ...[
                    const SizedBox(width: 12),
                    IconButton.filledTonal(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline),
                      style: IconButton.styleFrom(
                        foregroundColor: AppTheme.danger,
                        backgroundColor: AppTheme.danger.withValues(
                          alpha: 0.08,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 14),
              valueFields,
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Toplam: ${fmt.format(row.qty * row.price)} ₺',
                    style: const TextStyle(
                      color: AppTheme.primary,
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
}

class _ItemRow {
  final TextEditingController descCtrl;
  final TextEditingController qtyCtrl;
  final TextEditingController priceCtrl;

  _ItemRow({
    required this.descCtrl,
    required this.qtyCtrl,
    required this.priceCtrl,
  });

  factory _ItemRow.empty() => _ItemRow(
    descCtrl: TextEditingController(),
    qtyCtrl: TextEditingController(text: '1'),
    priceCtrl: TextEditingController(),
  );

  double get qty => double.tryParse(qtyCtrl.text.replaceAll(',', '.')) ?? 1;
  double get price => double.tryParse(priceCtrl.text.replaceAll(',', '.')) ?? 0;

  void dispose() {
    descCtrl.dispose();
    qtyCtrl.dispose();
    priceCtrl.dispose();
  }
}
