import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/app_theme.dart';
import '../../providers/service_request_provider.dart';
import '../../providers/customer_provider.dart';

class ServiceRequestFormScreen extends StatefulWidget {
  final int? requestId;
  const ServiceRequestFormScreen({super.key, this.requestId});

  @override
  State<ServiceRequestFormScreen> createState() =>
      _ServiceRequestFormScreenState();
}

class _ServiceRequestFormScreenState extends State<ServiceRequestFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  int? _customerId;
  String _status = 'new';
  String _priority = 'normal';
  DateTime? _scheduledDate;
  bool _saving = false;

  bool get _isEdit => widget.requestId != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final r = context
            .read<ServiceRequestProvider>()
            .items
            .where((e) => e.id == widget.requestId)
            .firstOrNull;
        if (r != null) {
          setState(() {
            _titleCtrl.text = r.title;
            _descCtrl.text = r.description ?? '';
            _locationCtrl.text = r.location ?? '';
            _customerId = r.customerId;
            _status = r.status;
            _priority = r.priority;
            _scheduledDate = r.scheduledDate;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _scheduledDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (d != null) setState(() => _scheduledDate = d);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final data = {
      'customer_id': _customerId,
      'title': _titleCtrl.text.trim(),
      'description':
          _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      'status': _status,
      'priority': _priority,
      'location': _locationCtrl.text.trim().isEmpty
          ? null
          : _locationCtrl.text.trim(),
      if (_scheduledDate != null)
        'scheduled_date': _scheduledDate!.toIso8601String(),
    };
    try {
      final prov = context.read<ServiceRequestProvider>();
      if (_isEdit) {
        await prov.update(widget.requestId!, data);
      } else {
        await prov.create(data);
      }
      if (mounted) context.go('/service-requests');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(_errorSnack('Hata oluştu'));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final customers = context.watch<CustomerProvider>().items;
    return Scaffold(
      appBar: AppBar(
          title: Text(_isEdit ? 'Talebi Düzenle' : 'Yeni Servis Talebi')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _Section(
              title: 'Temel Bilgiler',
              icon: Icons.build_circle_outlined,
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
                          value: c.id, child: Text(c.fullName, overflow: TextOverflow.ellipsis)))
                      .toList(),
                  onChanged: (v) => setState(() => _customerId = v),
                  validator: (v) => v == null ? 'Müşteri seçin' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _titleCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Başlık *',
                    prefixIcon: Icon(Icons.title_outlined),
                  ),
                  validator: (v) => v!.isEmpty ? 'Zorunlu alan' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descCtrl,
                  maxLines: 3,
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
            _Section(
              title: 'Detaylar',
              icon: Icons.tune_outlined,
              children: [
                TextFormField(
                  controller: _locationCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Konum',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _priority,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Öncelik',
                    prefixIcon: Icon(Icons.flag_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'low', child: Text('Düşük')),
                    DropdownMenuItem(value: 'normal', child: Text('Normal')),
                    DropdownMenuItem(value: 'high', child: Text('Yüksek')),
                    DropdownMenuItem(value: 'urgent', child: Text('Acil')),
                  ],
                  onChanged: (v) => setState(() => _priority = v!),
                ),
                if (_isEdit) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    key: ValueKey(_status),
                    initialValue: _status,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Durum',
                      prefixIcon: Icon(Icons.info_outline),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'new', child: Text('Yeni')),
                      DropdownMenuItem(
                          value: 'quoted', child: Text('Teklif Verildi')),
                      DropdownMenuItem(
                          value: 'in_progress', child: Text('Devam Ediyor')),
                      DropdownMenuItem(
                          value: 'completed', child: Text('Tamamlandı')),
                      DropdownMenuItem(
                          value: 'cancelled', child: Text('İptal')),
                    ],
                    onChanged: (v) => setState(() => _status = v!),
                  ),
                ],
                const SizedBox(height: 12),
                _DatePickerField(
                  label: 'Planlanan Tarih',
                  icon: Icons.calendar_today_outlined,
                  value: _scheduledDate == null
                      ? null
                      : DateFormat('dd.MM.yyyy').format(_scheduledDate!),
                  onTap: _pickDate,
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
          suffixIcon: const Icon(Icons.arrow_drop_down,
              color: AppTheme.textMedium),
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

SnackBar _errorSnack(String msg) => SnackBar(
      content: Text(msg),
      backgroundColor: const Color(0xFFEF4444),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
