import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../models/customer.dart';
import '../../models/quote.dart';
import '../../providers/customer_provider.dart';
import '../../providers/invoice_provider.dart';
import '../../providers/quote_provider.dart';
import '../widgets/action_menu_row.dart';
import '../widgets/app_shell.dart';
import 'quote_ui_actions.dart';

class QuoteDetailScreen extends StatefulWidget {
  final int quoteId;

  const QuoteDetailScreen({super.key, required this.quoteId});

  @override
  State<QuoteDetailScreen> createState() => _QuoteDetailScreenState();
}

class _QuoteDetailScreenState extends State<QuoteDetailScreen> {
  final _currency = NumberFormat('#,##0.00', 'tr_TR');
  final _date = DateFormat('dd.MM.yyyy', 'tr_TR');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final quoteProvider = context.read<QuoteProvider>();
      final customerProvider = context.read<CustomerProvider>();
      if (quoteProvider.items.isEmpty) {
        await quoteProvider.load();
      }
      if (!mounted) return;
      if (customerProvider.items.isEmpty) {
        await customerProvider.load();
      }
    });
  }

  Quote? _quote(QuoteProvider provider) =>
      provider.items.where((item) => item.id == widget.quoteId).firstOrNull;

  Customer? _customer(List<Customer> customers, int id) =>
      customers.where((item) => item.id == id).firstOrNull;

  void _goBack() {
    if (Navigator.of(context).canPop()) {
      context.pop();
    } else {
      context.go('/quotes');
    }
  }

  Future<void> _handleMenuAction(
    String value, {
    required Quote quote,
    required Customer? customer,
  }) async {
    final quotes = context.read<QuoteProvider>();
    final invoices = context.read<InvoiceProvider>();

    if (value == 'print') {
      await QuoteUiActions.printQuote(
        context,
        quote: quote,
        customer: customer,
      );
    } else if (value == 'mail') {
      await QuoteUiActions.showSendEmailDialog(
        context,
        quote: quote,
        customer: customer,
      );
    } else if (value == 'edit') {
      context.push('/quotes/${quote.id}/edit');
    } else if (value == 'invoice') {
      await invoices.createFromQuote(quote.id);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Fatura olusturuldu')));
      }
    } else if (value == 'delete') {
      await quotes.delete(quote.id);
      if (mounted) {
        _goBack();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final quoteProvider = context.watch<QuoteProvider>();
    final customerProvider = context.watch<CustomerProvider>();
    final quote = _quote(quoteProvider);
    final customer = quote == null
        ? null
        : _customer(customerProvider.items, quote.customerId);

    if (quoteProvider.loading && quote == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (quote == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: _goBack,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          title: const Text('Teklif Bulunamadi'),
        ),
        body: const Center(
          child: Text(
            'Teklif kaydi bulunamadi',
            style: TextStyle(color: AppTheme.textMedium),
          ),
        ),
      );
    }

    final color = AppTheme.statusColor(quote.status);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: _goBack,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(quote.title),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) =>
                _handleMenuAction(value, quote: quote, customer: customer),
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'print',
                child: ActionMenuRow(
                  icon: Icons.print_outlined,
                  label: 'Teklif Ciktisi',
                ),
              ),
              PopupMenuItem(
                value: 'mail',
                child: ActionMenuRow(
                  icon: Icons.email_outlined,
                  label: 'Mail Gonder',
                ),
              ),
              PopupMenuItem(
                value: 'edit',
                child: ActionMenuRow(
                  icon: Icons.edit_outlined,
                  label: 'Duzenle',
                ),
              ),
              PopupMenuItem(
                value: 'invoice',
                child: ActionMenuRow(
                  icon: Icons.receipt_long_outlined,
                  label: 'Fatura Olustur',
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
            badge: quote.quoteCode ?? 'Teklif',
            icon: Icons.request_quote_outlined,
            title: quote.title,
            subtitle:
                '${customer?.companyName ?? quote.customerCompanyName ?? 'Firma secilmedi'} icin hazirlanan teklif belgesi.',
            trailing: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _MetricPill(
                  label: 'Durum',
                  value: quote.statusLabel,
                  color: color,
                ),
                _MetricPill(
                  label: 'Toplam',
                  value: '${_currency.format(quote.totalAmount)} ₺',
                  color: Colors.white,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          AppSectionCard(
            icon: Icons.business_outlined,
            title: 'Firma Bilgileri',
            children: [
              _InfoLine(
                'Firma',
                customer?.companyName ?? quote.customerCompanyName,
              ),
              _InfoLine(
                'Yetkili',
                customer?.contactName ?? quote.customerContactName,
              ),
              _InfoLine('Telefon', customer?.phone ?? quote.customerPhone),
              _InfoLine('Adres', customer?.address ?? quote.customerAddress),
            ],
          ),
          const SizedBox(height: 20),
          AppSectionCard(
            icon: Icons.description_outlined,
            title: 'Belge Ozeti',
            children: [
              AdaptiveFieldRow(
                maxColumns: 3,
                minItemWidth: 220,
                children: [
                  _InfoPanel(
                    label: 'Teklif Tarihi',
                    value: _date.format(quote.issuedAt ?? quote.createdAt),
                  ),
                  _InfoPanel(
                    label: 'Gecerlilik',
                    value: quote.validUntil == null
                        ? '-'
                        : _date.format(quote.validUntil!),
                  ),
                  _InfoPanel(label: 'Durum', value: quote.statusLabel),
                  _InfoPanel(
                    label: 'Teslimat',
                    value: quote.deliveryTime ?? '-',
                  ),
                  _InfoPanel(label: 'Odeme', value: quote.paymentTerms ?? '-'),
                  _InfoPanel(
                    label: 'KDV Dahil',
                    value: quote.pricesIncludeVat ? 'Evet' : 'Hayir',
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          AppSectionCard(
            icon: Icons.view_list_outlined,
            title: 'Teklif Kalemleri',
            children: [
              for (final item in quote.items)
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
                          _MiniPill('Kod ${item.productCode ?? '-'}'),
                          _MiniPill('Miktar ${item.quantity} ${item.unit}'),
                          _MiniPill(
                            'Birim ${_currency.format(item.unitPrice)} ₺',
                          ),
                          _MiniPill('KDV %${item.vatRate}'),
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
                child: Column(
                  children: [
                    _SummaryRow('Ara Toplam', _currency.format(quote.subtotal)),
                    const SizedBox(height: 8),
                    _SummaryRow('KDV', _currency.format(quote.vatTotal)),
                    const Divider(height: 24),
                    _SummaryRow(
                      'Genel Toplam',
                      '${_currency.format(quote.totalAmount)} ₺',
                      highlighted: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if ((quote.description ?? '').isNotEmpty ||
              (quote.notes ?? '').isNotEmpty ||
              (quote.termsAndConditions ?? '').isNotEmpty) ...[
            const SizedBox(height: 20),
            AppSectionCard(
              icon: Icons.sticky_note_2_outlined,
              title: 'Aciklamalar',
              children: [
                _InfoLine('Teklif Aciklamasi', quote.description),
                _InfoLine('Kosullar', quote.termsAndConditions),
                _InfoLine('Notlar', quote.notes),
              ],
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
  final Color color;

  const _MetricPill({
    required this.label,
    required this.value,
    required this.color,
  });

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
            style: TextStyle(
              fontSize: 14,
              color: color,
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
    final visibleValue = (value ?? '').trim();
    if (visibleValue.isEmpty) {
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
            visibleValue,
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
