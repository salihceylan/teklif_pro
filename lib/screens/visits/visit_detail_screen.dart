import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../models/customer.dart';
import '../../models/visit.dart';
import '../../providers/customer_provider.dart';
import '../../providers/visit_provider.dart';
import '../widgets/action_menu_row.dart';
import '../widgets/app_shell.dart';
import '../widgets/destructive_confirm_dialog.dart';
import 'visit_ui_actions.dart';

class VisitDetailScreen extends StatefulWidget {
  final int visitId;

  const VisitDetailScreen({super.key, required this.visitId});

  @override
  State<VisitDetailScreen> createState() => _VisitDetailScreenState();
}

class _VisitDetailScreenState extends State<VisitDetailScreen> {
  final _currency = NumberFormat('#,##0.00', 'tr_TR');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final visitProvider = context.read<VisitProvider>();
      final customerProvider = context.read<CustomerProvider>();
      if (visitProvider.items.isEmpty) {
        await visitProvider.load();
      }
      if (!mounted) return;
      if (customerProvider.items.isEmpty) {
        await customerProvider.load();
      }
    });
  }

  ServiceVisit? _visit(VisitProvider provider) =>
      provider.items.where((item) => item.id == widget.visitId).firstOrNull;

  Customer? _customer(List<Customer> customers, int id) =>
      customers.where((item) => item.id == id).firstOrNull;

  String _customerName(List<Customer> customers, int id) =>
      _customer(customers, id)?.companyName ?? 'Müşteri #$id';

  void _goBack() {
    if (Navigator.of(context).canPop()) {
      context.pop();
    } else {
      context.go('/visits');
    }
  }

  Future<void> _handleMenuAction(
    String value,
    ServiceVisit visit, {
    Customer? customer,
  }) async {
    if (value == 'print') {
      await VisitUiActions.previewVisit(
        context,
        visit: visit,
        customer: customer,
      );
      return;
    }

    if (value == 'mail') {
      await VisitUiActions.showSendEmailDialog(
        context,
        visit: visit,
        customer: customer,
      );
      return;
    }

    if (value == 'edit') {
      context.push('/visits/${visit.id}/edit');
      return;
    }

    if (value == 'delete') {
      final confirmed = await showDestructiveConfirmDialog(
        context,
        title: 'Servis Formunu Sil',
        message:
            '${visit.serviceCode ?? 'Bu'} servis formunu silmek istediğinizden emin misiniz?',
      );
      if (!confirmed || !mounted) {
        return;
      }
      await context.read<VisitProvider>().delete(visit.id);
      if (mounted) {
        _goBack();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final visitProvider = context.watch<VisitProvider>();
    final customerProvider = context.watch<CustomerProvider>();
    final visit = _visit(visitProvider);
    final customer = visit == null
        ? null
        : _customer(customerProvider.items, visit.customerId);

    if (visitProvider.loading && visit == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (visit == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: _goBack,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          title: const Text('Servis Formu Bulunamadi'),
        ),
        body: const Center(
          child: Text(
            'Servis formu bulunamadi',
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
        title: Text(visit.serviceCode ?? 'Servis Formu'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            tooltip: 'Servis formu işlemleri',
            onSelected: (value) =>
                _handleMenuAction(value, visit, customer: customer),
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'print',
                child: ActionMenuRow(
                  icon: Icons.print_outlined,
                  label: 'Servis Çıktısı',
                ),
              ),
              PopupMenuItem(
                value: 'mail',
                child: ActionMenuRow(
                  icon: Icons.email_outlined,
                  label: 'Mail Gönder',
                ),
              ),
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
        maxWidth: 1080,
        children: [
          AppPageIntro(
            badge: visit.statusLabel,
            icon: Icons.build_circle_outlined,
            title: _customerName(customerProvider.items, visit.customerId),
            subtitle:
                '${visit.serviceCode ?? 'Servis belgesi'} için operasyon ve maliyet özeti',
            supporting: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppIntroSectionLabel(
                  label: 'Servis Özeti',
                  icon: Icons.insights_outlined,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    AppIntroStatCard(
                      label: 'Toplam TL',
                      value: '${_currency.format(visit.grandTotal)} TL',
                    ),
                    AppIntroStatCard(
                      label: 'Toplam USD',
                      value: '${_currency.format(visit.grandTotalUsd)} USD',
                    ),
                  ],
                ),
              ],
            ),
            trailing: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppIntroSectionLabel(
                  label: 'Hızlı İşlemler',
                  icon: Icons.bolt_outlined,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    AppIntroActionButton(
                      icon: Icons.edit_outlined,
                      label: 'Düzenle',
                      onPressed: () =>
                          _handleMenuAction('edit', visit, customer: customer),
                    ),
                    AppIntroActionButton(
                      icon: Icons.print_outlined,
                      label: 'Yazdır',
                      onPressed: () =>
                          _handleMenuAction('print', visit, customer: customer),
                      emphasized: true,
                    ),
                    AppIntroActionButton(
                      icon: Icons.email_outlined,
                      label: 'Mail',
                      onPressed: () =>
                          _handleMenuAction('mail', visit, customer: customer),
                    ),
                    AppIntroActionButton(
                      icon: Icons.delete_outline,
                      label: 'Sil',
                      onPressed: () => _handleMenuAction(
                        'delete',
                        visit,
                        customer: customer,
                      ),
                      destructive: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          AppSectionCard(
            icon: Icons.event_note_outlined,
            title: 'Ziyaret Bilgileri',
            children: [
              AdaptiveFieldRow(
                maxColumns: 3,
                minItemWidth: 220,
                children: [
                  _InfoPanel(
                    label: 'Planlanan Tarih',
                    value: DateFormat(
                      'dd.MM.yyyy HH:mm',
                      'tr_TR',
                    ).format(visit.scheduledDate),
                  ),
                  _InfoPanel(
                    label: 'Gerçekleşen Tarih',
                    value: visit.actualDate == null
                        ? '-'
                        : DateFormat(
                            'dd.MM.yyyy HH:mm',
                            'tr_TR',
                          ).format(visit.actualDate!),
                  ),
                  _InfoPanel(label: 'Durum', value: visit.statusLabel),
                  _InfoPanel(
                    label: 'Teknik Personel',
                    value: visit.technicianName ?? '-',
                  ),
                  _InfoPanel(
                    label: 'Toplam TL',
                    value: '${_currency.format(visit.grandTotal)} TL',
                  ),
                  _InfoPanel(label: 'KDV Orani', value: '%${visit.vatRate}'),
                  _InfoPanel(
                    label: 'Toplam USD',
                    value: '${_currency.format(visit.grandTotalUsd)} USD',
                  ),
                  _InfoPanel(
                    label: 'TCMB USD/TRY',
                    value: visit.hasExchangeRate
                        ? _currency.format(visit.exchangeRate!)
                        : '-',
                  ),
                  _InfoPanel(
                    label: 'Kur Tarihi',
                    value: visit.exchangeRateDate == null
                        ? '-'
                        : DateFormat(
                            'dd.MM.yyyy',
                            'tr_TR',
                          ).format(visit.exchangeRateDate!),
                  ),
                ],
              ),
              _DetailLine('Şikayet / Talep', visit.complaint),
            ],
          ),
          const SizedBox(height: 20),
          AppSectionCard(
            icon: Icons.inventory_2_outlined,
            title: 'Malzeme Kalemleri',
            children: [
              for (final item in visit.items)
                Container(
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
                        item.materialName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _MiniPill('Kod ${item.productCode ?? '-'}'),
                          _MiniPill('Adet ${item.quantity}'),
                          _MiniPill(
                            'Birim ${_currency.format(item.unitPriceUsd)} USD',
                          ),
                          _MiniPill(
                            'Toplam ${_currency.format(item.totalPriceUsd)} USD',
                          ),
                          _MiniPill(
                            'TL Karşılık ${_currency.format(item.totalPrice)} TL',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF5FB),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    _SummaryRow(
                      'Malzeme (USD)',
                      '${_currency.format(visit.materialTotalUsd)} USD',
                    ),
                    const SizedBox(height: 8),
                    _SummaryRow(
                      'Malzeme (TL)',
                      '${_currency.format(visit.materialTotal)} TL',
                    ),
                    const SizedBox(height: 8),
                    _SummaryRow(
                      'İşçilik (USD)',
                      '${_currency.format(visit.laborAmountUsd)} USD',
                    ),
                    const SizedBox(height: 8),
                    _SummaryRow(
                      'İşçilik (TL)',
                      '${_currency.format(visit.laborAmount)} TL',
                    ),
                    const SizedBox(height: 8),
                    _SummaryRow(
                      'KDV (USD)',
                      '${_currency.format(visit.vatTotalUsd)} USD',
                    ),
                    const SizedBox(height: 8),
                    _SummaryRow(
                      'KDV (TL)',
                      '${_currency.format(visit.vatTotal)} TL',
                    ),
                    const Divider(height: 24),
                    _SummaryRow(
                      'Genel Toplam (USD)',
                      '${_currency.format(visit.grandTotalUsd)} USD',
                    ),
                    const Divider(height: 24),
                    _SummaryRow(
                      'Genel Toplam (TL)',
                      '${_currency.format(visit.grandTotal)} TL',
                      highlighted: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if ((visit.notes ?? '').isNotEmpty ||
              (visit.technicianNotes ?? '').isNotEmpty) ...[
            const SizedBox(height: 20),
            AppSectionCard(
              icon: Icons.notes_outlined,
              title: 'Notlar',
              children: [
                _DetailLine('Müşteri Notları', visit.notes),
                _DetailLine('Teknisyen Notları', visit.technicianNotes),
              ],
            ),
          ],
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

class _MiniPill extends StatelessWidget {
  final String text;

  const _MiniPill(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          color: AppTheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlighted;

  const _SummaryRow(this.label, this.value, {this.highlighted = false});

  @override
  Widget build(BuildContext context) {
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
          value,
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
