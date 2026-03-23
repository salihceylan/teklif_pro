import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../models/customer.dart';
import '../../models/invoice.dart';
import '../../providers/customer_provider.dart';
import '../../providers/invoice_provider.dart';
import '../widgets/action_menu_row.dart';
import '../widgets/app_shell.dart';

class InvoiceDetailScreen extends StatefulWidget {
  final int invoiceId;

  const InvoiceDetailScreen({super.key, required this.invoiceId});

  @override
  State<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends State<InvoiceDetailScreen> {
  final _currency = NumberFormat('#,##0.00', 'tr_TR');
  final _date = DateFormat('dd.MM.yyyy', 'tr_TR');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final invoiceProvider = context.read<InvoiceProvider>();
      final customerProvider = context.read<CustomerProvider>();
      if (invoiceProvider.items.isEmpty) {
        await invoiceProvider.load();
      }
      if (!mounted) return;
      if (customerProvider.items.isEmpty) {
        await customerProvider.load();
      }
    });
  }

  Invoice? _invoice(InvoiceProvider provider) =>
      provider.items.where((item) => item.id == widget.invoiceId).firstOrNull;

  Customer? _customer(List<Customer> customers, int id) =>
      customers.where((item) => item.id == id).firstOrNull;

  void _goBack() {
    if (Navigator.of(context).canPop()) {
      context.pop();
    } else {
      context.go('/invoices');
    }
  }

  Future<void> _handleMenuAction(String value, Invoice invoice) async {
    final invoices = context.read<InvoiceProvider>();

    if (value == 'edit') {
      context.push('/invoices/${invoice.id}/edit');
    } else if (value == 'paid') {
      await invoices.update(invoice.id, {'status': 'paid'});
    } else if (value == 'delete') {
      await invoices.delete(invoice.id);
      if (mounted) {
        _goBack();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final invoiceProvider = context.watch<InvoiceProvider>();
    final customerProvider = context.watch<CustomerProvider>();
    final invoice = _invoice(invoiceProvider);
    final customer = invoice == null
        ? null
        : _customer(customerProvider.items, invoice.customerId);

    if (invoiceProvider.loading && invoice == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (invoice == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: _goBack,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          title: const Text('Fatura Bulunamadi'),
        ),
        body: const Center(
          child: Text(
            'Fatura kaydi bulunamadi',
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
        title: Text(invoice.title),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(value, invoice),
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'edit',
                child: ActionMenuRow(
                  icon: Icons.edit_outlined,
                  label: 'Duzenle',
                ),
              ),
              PopupMenuItem(
                value: 'paid',
                child: ActionMenuRow(
                  icon: Icons.check_circle_outlined,
                  label: 'Odendi Isaretle',
                  color: Color(0xFF10B981),
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
            badge: invoice.invoiceNumber,
            icon: Icons.receipt_long_outlined,
            title: invoice.title,
            subtitle:
                '${customer?.companyName ?? 'Firma secilmedi'} icin hazirlanan fatura dokumu.',
            trailing: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _MetricPill(label: 'Durum', value: invoice.statusLabel),
                _MetricPill(
                  label: 'Toplam',
                  value: '${_currency.format(invoice.totalAmount)} ₺',
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          AppSectionCard(
            icon: Icons.business_outlined,
            title: 'Firma Bilgileri',
            children: [
              _InfoLine('Firma', customer?.companyName),
              _InfoLine('Yetkili', customer?.contactName),
              _InfoLine('Telefon', customer?.phone),
              _InfoLine('E-posta', customer?.email),
              _InfoLine('Adres', customer?.address),
            ],
          ),
          const SizedBox(height: 20),
          AppSectionCard(
            icon: Icons.description_outlined,
            title: 'Fatura Ozeti',
            children: [
              AdaptiveFieldRow(
                maxColumns: 3,
                minItemWidth: 220,
                children: [
                  _InfoPanel(label: 'Fatura No', value: invoice.invoiceNumber),
                  _InfoPanel(label: 'Durum', value: invoice.statusLabel),
                  _InfoPanel(
                    label: 'Olusturma',
                    value: _date.format(invoice.createdAt),
                  ),
                  _InfoPanel(
                    label: 'Son Odeme',
                    value: invoice.dueDate == null
                        ? '-'
                        : _date.format(invoice.dueDate!),
                  ),
                  _InfoPanel(
                    label: 'Ilgili Teklif',
                    value: invoice.quoteId?.toString() ?? '-',
                  ),
                  _InfoPanel(
                    label: 'Kalem Sayisi',
                    value: invoice.items.length.toString(),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          AppSectionCard(
            icon: Icons.view_list_outlined,
            title: 'Fatura Kalemleri',
            children: [
              for (final item in invoice.items)
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
                        item.description,
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
                          _MiniPill('Miktar ${item.quantity}'),
                          _MiniPill(
                            'Birim ${_currency.format(item.unitPrice)} ₺',
                          ),
                          _MiniPill(
                            'Toplam ${_currency.format(item.totalPrice)} ₺',
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
                child: _SummaryRow(
                  'Genel Toplam',
                  '${_currency.format(invoice.totalAmount)} ₺',
                ),
              ),
            ],
          ),
          if ((invoice.notes ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 20),
            AppSectionCard(
              icon: Icons.notes_outlined,
              title: 'Notlar',
              children: [_InfoLine('Fatura Notu', invoice.notes)],
            ),
          ],
        ],
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  final String label;
  final String value;

  const _MetricPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.74),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
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

class _InfoLine extends StatelessWidget {
  final String label;
  final String? value;

  const _InfoLine(this.label, this.value);

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

  const _SummaryRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: Color(0xFF17304C),
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1F5EA8),
          ),
        ),
      ],
    );
  }
}
