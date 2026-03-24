import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../models/service_request.dart';
import '../../providers/customer_provider.dart';
import '../../providers/service_request_provider.dart';
import '../widgets/action_menu_row.dart';
import '../widgets/app_shell.dart';

class ServiceRequestDetailScreen extends StatefulWidget {
  final int requestId;

  const ServiceRequestDetailScreen({super.key, required this.requestId});

  @override
  State<ServiceRequestDetailScreen> createState() =>
      _ServiceRequestDetailScreenState();
}

class _ServiceRequestDetailScreenState
    extends State<ServiceRequestDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final requestProvider = context.read<ServiceRequestProvider>();
      final customerProvider = context.read<CustomerProvider>();
      if (requestProvider.items.isEmpty) {
        await requestProvider.load();
      }
      if (!mounted) return;
      if (customerProvider.items.isEmpty) {
        await customerProvider.load();
      }
    });
  }

  ServiceRequest? _request(ServiceRequestProvider provider) =>
      provider.items.where((item) => item.id == widget.requestId).firstOrNull;

  String _customerName(List<dynamic> customers, int id) =>
      customers.where((item) => item.id == id).firstOrNull?.companyName ??
      'Müşteri #$id';

  void _goBack() {
    if (Navigator.of(context).canPop()) {
      context.pop();
    } else {
      context.go('/service-requests');
    }
  }

  Future<void> _handleMenuAction(String value, ServiceRequest request) async {
    if (value == 'edit') {
      context.push('/service-requests/${request.id}/edit');
    } else if (value == 'delete') {
      await context.read<ServiceRequestProvider>().delete(request.id);
      if (mounted) {
        _goBack();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final requestProvider = context.watch<ServiceRequestProvider>();
    final customerProvider = context.watch<CustomerProvider>();
    final request = _request(requestProvider);

    if (requestProvider.loading && request == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (request == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: _goBack,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          title: const Text('Talep Bulunamadı'),
        ),
        body: const Center(
          child: Text(
            'Servis talebi bulunamadı',
            style: TextStyle(color: AppTheme.textMedium),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: _goBack,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(request.title),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            tooltip: 'Talep işlemleri',
            onSelected: (value) => _handleMenuAction(value, request),
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'edit',
                child: ActionMenuRow(
                  icon: Icons.edit_outlined,
                  label: 'Düzenle',
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: ActionMenuRow(
                  icon: Icons.delete_outline,
                  label: 'Sil',
                  color: Color(0xFFEF4444),
                ),
              ),
            ],
          ),
        ],
      ),
      body: AppScrollableBody(
        maxWidth: 960,
        children: [
          AppPageIntro(
            badge: request.statusLabel,
            icon: Icons.handyman_outlined,
            title: request.title,
            subtitle:
                '${_customerName(customerProvider.items, request.customerId)} için açılan servis talebi',
            trailing: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                AppIntroActionButton(
                  icon: Icons.edit_outlined,
                  label: 'Düzenle',
                  onPressed: () => _handleMenuAction('edit', request),
                  emphasized: true,
                ),
                AppIntroActionButton(
                  icon: Icons.delete_outline,
                  label: 'Sil',
                  onPressed: () => _handleMenuAction('delete', request),
                  destructive: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          AppSectionCard(
            icon: Icons.info_outline,
            title: 'Talep Bilgileri',
            children: [
              AdaptiveFieldRow(
                maxColumns: 3,
                minItemWidth: 220,
                children: [
                  _InfoPanel(
                    label: 'Müşteri',
                    value: _customerName(
                      customerProvider.items,
                      request.customerId,
                    ),
                  ),
                  _InfoPanel(label: 'Durum', value: request.statusLabel),
                  _InfoPanel(label: 'Öncelik', value: request.priority),
                  _InfoPanel(
                    label: 'Planlanan Tarih',
                    value: request.scheduledDate == null
                        ? '-'
                        : DateFormat(
                            'dd.MM.yyyy HH:mm',
                            'tr_TR',
                          ).format(request.scheduledDate!),
                  ),
                  _InfoPanel(label: 'Lokasyon', value: request.location ?? '-'),
                  _InfoPanel(
                    label: 'Oluşturma',
                    value: DateFormat(
                      'dd.MM.yyyy',
                      'tr_TR',
                    ).format(request.createdAt),
                  ),
                ],
              ),
              _DetailLine('Açıklama', request.description),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoPanel extends StatelessWidget {
  final String label;
  final String value;

  const _InfoPanel({required this.label, required this.value});

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

class _DetailLine extends StatelessWidget {
  final String label;
  final String? value;

  const _DetailLine(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final text = (value ?? '').trim();
    if (text.isEmpty) {
      return const SizedBox.shrink();
    }

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
            text,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textDark,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
