import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/customer_provider.dart';
import '../../providers/visit_provider.dart';
import '../widgets/app_shell.dart';

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
        final visit = context
            .read<VisitProvider>()
            .items
            .where((item) => item.id == widget.visitId)
            .firstOrNull;
        if (visit != null) {
          setState(() {
            _customerId = visit.customerId;
            _scheduledDate = visit.scheduledDate;
            _status = visit.status;
            _notesCtrl.text = visit.notes ?? '';
            _techNotesCtrl.text = visit.technicianNotes ?? '';
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

    setState(
      () => _scheduledDate = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_scheduledDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(buildErrorSnackBar('Lütfen tarih ve saat seçin'));
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
        ).showSnackBar(buildErrorSnackBar('Ziyaret kaydedilemedi'));
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
      appBar: AppBar(
        title: Text(_isEdit ? 'Ziyareti Düzenle' : 'Yeni Ziyaret'),
      ),
      body: Form(
        key: _formKey,
        child: AppScrollableBody(
          maxWidth: 980,
          children: [
            AppPageIntro(
              badge: _isEdit ? 'Düzenleme Modu' : 'Yeni Ziyaret',
              icon: _isEdit ? Icons.calendar_month_outlined : Icons.event_note,
              title: _isEdit
                  ? 'Ziyaret detaylarını güncelleyin'
                  : 'Yeni ziyaret planlayın',
              subtitle:
                  'Müşteri seçimi, randevu tarihi ve teknisyen notları aynı ekranda okunabilir şekilde düzenlenir.',
            ),
            const SizedBox(height: 20),
            AppSectionCard(
              icon: Icons.schedule_outlined,
              title: 'Ziyaret Planı',
              description:
                  'Randevu zamanı ve ilgili müşteri bilgisini ekleyerek saha akışını kesinleştirin.',
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
                    AppDatePickerField(
                      label: 'Tarih ve Saat',
                      icon: Icons.schedule_outlined,
                      value: _scheduledDate == null
                          ? null
                          : _fmt.format(_scheduledDate!),
                      onTap: _pickDateTime,
                      placeholder: 'Tarih ve saat seçin',
                      hasError: _scheduledDate == null,
                    ),
                  ],
                ),
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
                        value: 'scheduled',
                        child: Text('Planlandı'),
                      ),
                      DropdownMenuItem(
                        value: 'in_progress',
                        child: Text('Devam Ediyor'),
                      ),
                      DropdownMenuItem(
                        value: 'completed',
                        child: Text('Tamamlandı'),
                      ),
                      DropdownMenuItem(
                        value: 'cancelled',
                        child: Text('İptal'),
                      ),
                    ],
                    onChanged: (value) => setState(() => _status = value!),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            AppSectionCard(
              icon: Icons.notes_outlined,
              title: 'Ziyaret Notları',
              description:
                  'Müşteri bilgilendirmeleri ve teknik ekip notlarını ayrı alanlarda yönetin.',
              children: [
                TextFormField(
                  controller: _notesCtrl,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Müşteri Notları',
                    hintText:
                        'Ziyaret öncesi veya sonrası görünmesi gereken notlar',
                    prefixIcon: Icon(Icons.edit_note_outlined),
                    alignLabelWithHint: true,
                  ),
                ),
                TextFormField(
                  controller: _techNotesCtrl,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Teknisyen Notları',
                    hintText: 'Teknik değerlendirme veya ekip içi açıklamalar',
                    prefixIcon: Icon(Icons.engineering_outlined),
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
                  : Icon(_isEdit ? Icons.save_outlined : Icons.event_available),
              label: Text(_isEdit ? 'Ziyareti Güncelle' : 'Ziyareti Kaydet'),
            ),
          ],
        ),
      ),
    );
  }
}
