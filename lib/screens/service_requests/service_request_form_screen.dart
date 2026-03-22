import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/customer_provider.dart';
import '../../providers/service_request_provider.dart';
import '../widgets/app_shell.dart';

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
        final request = context
            .read<ServiceRequestProvider>()
            .items
            .where((item) => item.id == widget.requestId)
            .firstOrNull;
        if (request != null) {
          setState(() {
            _titleCtrl.text = request.title;
            _descCtrl.text = request.description ?? '';
            _locationCtrl.text = request.location ?? '';
            _customerId = request.customerId;
            _status = request.status;
            _priority = request.priority;
            _scheduledDate = request.scheduledDate;
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
    final picked = await showDatePicker(
      context: context,
      initialDate: _scheduledDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _scheduledDate = picked);
    }
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
      'status': _status,
      'priority': _priority,
      'location': _locationCtrl.text.trim().isEmpty
          ? null
          : _locationCtrl.text.trim(),
      if (_scheduledDate != null)
        'scheduled_date': _scheduledDate!.toIso8601String(),
    };

    try {
      final provider = context.read<ServiceRequestProvider>();
      if (_isEdit) {
        await provider.update(widget.requestId!, data);
      } else {
        await provider.create(data);
      }

      if (mounted) {
        context.go('/service-requests');
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(buildErrorSnackBar('Servis talebi kaydedilemedi'));
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
        title: Text(_isEdit ? 'Talebi Düzenle' : 'Yeni Servis Talebi'),
      ),
      body: Form(
        key: _formKey,
        child: AppScrollableBody(
          maxWidth: 980,
          children: [
            AppPageIntro(
              badge: _isEdit ? 'Düzenleme Modu' : 'Yeni Talep',
              icon: _isEdit
                  ? Icons.build_circle_outlined
                  : Icons.add_task_rounded,
              title: _isEdit
                  ? 'Servis talebini güncelleyin'
                  : 'Yeni servis talebi oluşturun',
              subtitle:
                  'Talep başlığı, müşteri seçimi, öncelik ve planlanan tarih tek akışta kalır. Bu yapı ekip koordinasyonunu kolaylaştırır.',
            ),
            const SizedBox(height: 20),
            AppSectionCard(
              icon: Icons.assignment_outlined,
              title: 'Talep Özeti',
              description:
                  'Talebin hangi müşteri için açıldığını ve hangi konuyu kapsadığını belirleyin.',
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
                    DropdownButtonFormField<String>(
                      initialValue: _priority,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Öncelik',
                        prefixIcon: Icon(Icons.flag_outlined),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'low', child: Text('Düşük')),
                        DropdownMenuItem(
                          value: 'normal',
                          child: Text('Normal'),
                        ),
                        DropdownMenuItem(value: 'high', child: Text('Yüksek')),
                        DropdownMenuItem(value: 'urgent', child: Text('Acil')),
                      ],
                      onChanged: (value) => setState(() => _priority = value!),
                    ),
                  ],
                ),
                TextFormField(
                  controller: _titleCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Başlık',
                    hintText: 'Örn. Klima bakım talebi',
                    prefixIcon: Icon(Icons.title_outlined),
                  ),
                  validator: (value) => value!.isEmpty ? 'Zorunlu alan' : null,
                ),
                TextFormField(
                  controller: _descCtrl,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Açıklama',
                    hintText: 'Talep kapsamı, arıza veya servis detayları',
                    prefixIcon: Icon(Icons.notes_outlined),
                    alignLabelWithHint: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            AppSectionCard(
              icon: Icons.tune_outlined,
              title: 'Planlama Detayları',
              description:
                  'Saha ekibinin planlama yapabilmesi için konum, tarih ve durum alanlarını yönetin.',
              children: [
                AdaptiveFieldRow(
                  children: [
                    TextFormField(
                      controller: _locationCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Konum',
                        hintText: 'İlçe, tesis veya adres bilgisi',
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                    ),
                    AppDatePickerField(
                      label: 'Planlanan Tarih',
                      icon: Icons.calendar_today_outlined,
                      value: _scheduledDate == null
                          ? null
                          : DateFormat('dd.MM.yyyy').format(_scheduledDate!),
                      onTap: _pickDate,
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
                      DropdownMenuItem(value: 'new', child: Text('Yeni')),
                      DropdownMenuItem(
                        value: 'quoted',
                        child: Text('Teklif Verildi'),
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
                      _isEdit ? Icons.save_outlined : Icons.add_task_outlined,
                    ),
              label: Text(
                _isEdit ? 'Talebi Güncelle' : 'Servis Talebini Kaydet',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
