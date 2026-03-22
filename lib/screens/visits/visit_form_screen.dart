import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/app_theme.dart';
import '../../providers/visit_provider.dart';
import '../../providers/customer_provider.dart';

class VisitFormScreen extends StatefulWidget {
  final int? visitId;
  const VisitFormScreen({super.key, this.visitId});

  @override
  State<VisitFormScreen> createState() => _VisitFormScreenState();
}

class _VisitFormScreenState extends State<VisitFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesCtrl = TextEditingController();
  final _techNotesCtrl = TextEditingController();
  int? _customerId;
  DateTime? _scheduledDate;
  String _status = 'scheduled';
  bool _saving = false;

  bool get _isEdit => widget.visitId != null;
  final _fmt = DateFormat('dd.MM.yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final v = context
            .read<VisitProvider>()
            .items
            .where((e) => e.id == widget.visitId)
            .firstOrNull;
        if (v != null) {
          setState(() {
            _customerId = v.customerId;
            _scheduledDate = v.scheduledDate;
            _status = v.status;
            _notesCtrl.text = v.notes ?? '';
            _techNotesCtrl.text = v.technicianNotes ?? '';
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    _techNotesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _scheduledDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_scheduledDate ?? DateTime.now()),
    );
    if (time == null) return;
    setState(() => _scheduledDate =
        DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_scheduledDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        _errorSnack('Lütfen tarih ve saat seçin'),
      );
      return;
    }
    setState(() => _saving = true);
    final data = {
      'customer_id': _customerId,
      'scheduled_date': _scheduledDate!.toIso8601String(),
      'status': _status,
      'notes': _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      'technician_notes': _techNotesCtrl.text.trim().isEmpty
          ? null
          : _techNotesCtrl.text.trim(),
    };
    try {
      final prov = context.read<VisitProvider>();
      if (_isEdit) {
        await prov.update(widget.visitId!, data);
      } else {
        await prov.create(data);
      }
      if (mounted) context.go('/visits');
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
          AppBar(title: Text(_isEdit ? 'Ziyareti Düzenle' : 'Yeni Ziyaret')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _Section(
              title: 'Ziyaret Bilgileri',
              icon: Icons.calendar_month_outlined,
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
                _DatePickerField(
                  label: 'Tarih ve Saat *',
                  icon: Icons.schedule_outlined,
                  value: _scheduledDate == null
                      ? null
                      : _fmt.format(_scheduledDate!),
                  onTap: _pickDateTime,
                  hasError: _scheduledDate == null,
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
                      DropdownMenuItem(
                          value: 'scheduled', child: Text('Planlandı')),
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
              ],
            ),
            const SizedBox(height: 12),
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
                const SizedBox(height: 12),
                TextFormField(
                  controller: _techNotesCtrl,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Teknisyen Notları',
                    prefixIcon: Icon(Icons.engineering_outlined),
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

class _DatePickerField extends StatelessWidget {
  final String label;
  final IconData icon;
  final String? value;
  final VoidCallback onTap;
  final bool hasError;
  const _DatePickerField({
    required this.label,
    required this.icon,
    required this.value,
    required this.onTap,
    this.hasError = false,
  });

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
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
                color: hasError
                    ? const Color(0xFFEF4444)
                    : AppTheme.border),
          ),
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
