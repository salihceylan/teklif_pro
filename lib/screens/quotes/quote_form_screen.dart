import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/app_theme.dart';
import '../../providers/quote_provider.dart';
import '../../providers/customer_provider.dart';

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

  double get _total => _items.fold(0, (s, e) => s + (e.qty * e.price));

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final q = context
            .read<QuoteProvider>()
            .items
            .where((e) => e.id == widget.quoteId)
            .firstOrNull;
        if (q != null) {
          setState(() {
            _titleCtrl.text = q.title;
            _descCtrl.text = q.description ?? '';
            _notesCtrl.text = q.notes ?? '';
            _customerId = q.customerId;
            _status = q.status;
            _validUntil = q.validUntil;
            _items.addAll(q.items.map((i) => _ItemRow(
                  descCtrl: TextEditingController(text: i.description),
                  qtyCtrl:
                      TextEditingController(text: i.quantity.toString()),
                  priceCtrl:
                      TextEditingController(text: i.unitPrice.toString()),
                )));
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
    for (final r in _items) {
      r.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final data = {
      'customer_id': _customerId,
      'title': _titleCtrl.text.trim(),
      'description':
          _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      'notes':
          _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      'status': _status,
      if (_validUntil != null)
        'valid_until': _validUntil!.toIso8601String(),
      'items': _items
          .map((r) => {
                'description': r.descCtrl.text.trim(),
                'quantity': r.qty,
                'unit_price': r.price,
              })
          .toList(),
    };
    try {
      final prov = context.read<QuoteProvider>();
      if (_isEdit) {
        await prov.update(widget.quoteId!, data);
      } else {
        await prov.create(data);
      }
      if (mounted) context.go('/quotes');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(_errorSnack('Hata oluştu'));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final customers = context.watch<CustomerProvider>().items;
    return Scaffold(
      appBar:
          AppBar(title: Text(_isEdit ? 'Teklifi Düzenle' : 'Yeni Teklif')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Temel bilgiler ────────────────────────────────────
            _Section(
              title: 'Temel Bilgiler',
              icon: Icons.request_quote_outlined,
              children: [
                DropdownButtonFormField<int>(
                  key: ValueKey(_customerId),
                  initialValue: _customerId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Müşteri *',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  items: customers
                      .map((c) => DropdownMenuItem(
                          value: c.id,
                          child: Text(c.fullName,
                              overflow: TextOverflow.ellipsis)))
                      .toList(),
                  onChanged: (v) => setState(() => _customerId = v),
                  validator: (v) => v == null ? 'Müşteri seçin' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _titleCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Teklif Başlığı *',
                    prefixIcon: Icon(Icons.title_outlined),
                  ),
                  validator: (v) => v!.isEmpty ? 'Zorunlu alan' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descCtrl,
                  maxLines: 2,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Açıklama',
                    prefixIcon: Icon(Icons.notes_outlined),
                    alignLabelWithHint: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Durum & tarih ─────────────────────────────────────
            _Section(
              title: 'Durum & Geçerlilik',
              icon: Icons.tune_outlined,
              children: [
                if (_isEdit) ...[
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
                          value: 'draft', child: Text('Taslak')),
                      DropdownMenuItem(
                          value: 'sent', child: Text('Gönderildi')),
                      DropdownMenuItem(
                          value: 'accepted', child: Text('Kabul Edildi')),
                      DropdownMenuItem(
                          value: 'rejected', child: Text('Reddedildi')),
                      DropdownMenuItem(
                          value: 'expired', child: Text('Süresi Doldu')),
                    ],
                    onChanged: (v) => setState(() => _status = v!),
                  ),
                  const SizedBox(height: 12),
                ],
                _DatePickerField(
                  label: 'Geçerlilik Tarihi',
                  icon: Icons.event_available_outlined,
                  value: _validUntil == null
                      ? null
                      : DateFormat('dd.MM.yyyy').format(_validUntil!),
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: _validUntil ??
                          DateTime.now().add(const Duration(days: 30)),
                      firstDate: DateTime.now(),
                      lastDate:
                          DateTime.now().add(const Duration(days: 365)),
                    );
                    if (d != null) setState(() => _validUntil = d);
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Kalemler ──────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.list_alt_outlined,
                                size: 16, color: AppTheme.primary),
                            SizedBox(width: 6),
                            Text('Kalemler',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.primary,
                                  letterSpacing: 0.3,
                                )),
                          ],
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Ekle'),
                          onPressed: () =>
                              setState(() => _items.add(_ItemRow.empty())),
                          style: TextButton.styleFrom(
                              foregroundColor: AppTheme.primary),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        ..._items.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final row = entry.value;
                          return _ItemCard(
                            row: row,
                            fmt: _fmt,
                            canDelete: _items.length > 1,
                            onDelete: () =>
                                setState(() => _items.removeAt(idx)),
                            onChanged: () => setState(() {}),
                          );
                        }),
                        const Divider(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Genel Toplam',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: AppTheme.textDark)),
                            Text(
                              '${_fmt.format(_total)} ₺',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Notlar ────────────────────────────────────────────
            _Section(
              title: 'Notlar',
              icon: Icons.notes_outlined,
              children: [
                TextFormField(
                  controller: _notesCtrl,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Notlar',
                    prefixIcon: Icon(Icons.edit_note_outlined),
                    alignLabelWithHint: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(_isEdit ? 'Güncelle' : 'Kaydet'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ── Kalem kartı ───────────────────────────────────────────────────

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
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: row.descCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Açıklama *',
                    isDense: true,
                  ),
                  validator: (v) => v!.isEmpty ? 'Zorunlu' : null,
                ),
              ),
              const SizedBox(width: 4),
              if (canDelete)
                IconButton(
                  icon: const Icon(Icons.close,
                      color: Color(0xFFEF4444), size: 20),
                  onPressed: onDelete,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                      minWidth: 32, minHeight: 32),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: row.qtyCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Adet',
                    isDense: true,
                  ),
                  onChanged: (_) => onChanged(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: row.priceCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Birim Fiyat (₺)',
                    isDense: true,
                  ),
                  onChanged: (_) => onChanged(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Toplam: ${fmt.format(row.qty * row.price)} ₺',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: AppTheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Yardımcı widget'lar ───────────────────────────────────────────

class _DatePickerField extends StatelessWidget {
  final String label;
  final IconData icon;
  final String? value;
  final VoidCallback onTap;
  const _DatePickerField(
      {required this.label,
      required this.icon,
      required this.value,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          suffixIcon:
              const Icon(Icons.arrow_drop_down, color: AppTheme.textMedium),
        ),
        child: Text(
          value ?? 'Seçilmedi',
          style: TextStyle(
            fontSize: 14,
            color: value == null ? AppTheme.textLight : AppTheme.textDark,
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  const _Section(
      {required this.title, required this.icon, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Icon(icon, size: 16, color: AppTheme.primary),
                const SizedBox(width: 6),
                Text(title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary,
                      letterSpacing: 0.3,
                    )),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemRow {
  final TextEditingController descCtrl;
  final TextEditingController qtyCtrl;
  final TextEditingController priceCtrl;

  _ItemRow(
      {required this.descCtrl,
      required this.qtyCtrl,
      required this.priceCtrl});

  factory _ItemRow.empty() => _ItemRow(
        descCtrl: TextEditingController(),
        qtyCtrl: TextEditingController(text: '1'),
        priceCtrl: TextEditingController(),
      );

  double get qty => double.tryParse(qtyCtrl.text) ?? 1;
  double get price => double.tryParse(priceCtrl.text) ?? 0;

  void dispose() {
    descCtrl.dispose();
    qtyCtrl.dispose();
    priceCtrl.dispose();
  }
}

SnackBar _errorSnack(String msg) => SnackBar(
      content: Text(msg),
      backgroundColor: const Color(0xFFEF4444),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
