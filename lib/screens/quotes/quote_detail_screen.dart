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
        ).showSnackBar(const SnackBar(content: Text('Fatura oluşturuldu')));
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
          title: const Text('Teklif Bulunamadı'),
        ),
        body: const Center(
          child: Text(
            'Teklif kaydı bulunamadı',
            style: TextStyle(color: AppTheme.textMedium),
          ),
        ),
      );
    }

    final statusColor = AppTheme.statusColor(quote.status);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: _goBack,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(quote.title),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            tooltip: 'Teklif işlemleri',
            onSelected: (value) =>
                _handleMenuAction(value, quote: quote, customer: customer),
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'print',
                child: ActionMenuRow(
                  icon: Icons.print_outlined,
                  label: 'Teklif Çıktısı',
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
                value: 'invoice',
                child: ActionMenuRow(
                  icon: Icons.receipt_long_outlined,
                  label: 'Fatura Oluştur',
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
                '${customer?.companyName ?? quote.customerCompanyName ?? 'Firma seçilmedi'} için hazırlanan teklif belgesi.',
            trailing: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    AppIntroActionButton(
                      icon: Icons.print_outlined,
                      label: 'Çıktı',
                      onPressed: () => _handleMenuAction(
                        'print',
                        quote: quote,
                        customer: customer,
                      ),
                      emphasized: true,
                    ),
                    AppIntroActionButton(
                      icon: Icons.email_outlined,
                      label: 'Mail',
                      onPressed: () => _handleMenuAction(
                        'mail',
                        quote: quote,
                        customer: customer,
                      ),
                    ),
                    AppIntroActionButton(
                      icon: Icons.edit_outlined,
                      label: 'Düzenle',
                      onPressed: () => _handleMenuAction(
                        'edit',
                        quote: quote,
                        customer: customer,
                      ),
                    ),
                    AppIntroActionButton(
                      icon: Icons.receipt_long_outlined,
                      label: 'Fatura',
                      onPressed: () => _handleMenuAction(
                        'invoice',
                        quote: quote,
                        customer: customer,
                      ),
                    ),
                    AppIntroActionButton(
                      icon: Icons.delete_outline,
                      label: 'Sil',
                      onPressed: () => _handleMenuAction(
                        'delete',
                        quote: quote,
                        customer: customer,
                      ),
                      destructive: true,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _MetricPill(
                      label: 'Durum',
                      value: quote.statusLabel,
                      color: statusColor,
                    ),
                    _MetricPill(
                      label: 'Toplam TL',
                      value: '${_currency.format(quote.totalAmount)} ₺',
                      color: Colors.white,
                    ),
                    _MetricPill(
                      label: 'Toplam USD',
                      value: '${_currency.format(quote.totalAmountUsd)} USD',
                      color: Colors.white,
                    ),
                  ],
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
            title: 'Belge Özeti',
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
                    label: 'Geçerlilik',
                    value: quote.validUntil == null
                        ? '-'
                        : _date.format(quote.validUntil!),
                  ),
                  _InfoPanel(label: 'Durum', value: quote.statusLabel),
                  _InfoPanel(
                    label: 'Teslimat',
                    value: quote.deliveryTime ?? '-',
                  ),
                  _InfoPanel(label: 'Ödeme', value: quote.paymentTerms ?? '-'),
                  _InfoPanel(
                    label: 'KDV Dahil',
                    value: quote.pricesIncludeVat ? 'Evet' : 'Hayır',
                  ),
                  _InfoPanel(
                    label: 'TCMB USD/TRY',
                    value: quote.hasExchangeRate
                        ? _currency.format(quote.exchangeRate!)
                        : '-',
                  ),
                  _InfoPanel(
                    label: 'Kur Tarihi',
                    value: quote.exchangeRateDate == null
                        ? '-'
                        : _date.format(quote.exchangeRateDate!),
                  ),
                  _InfoPanel(
                    label: 'Kur Kaynağı',
                    value: quote.exchangeRateSource ?? '-',
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
                            'Birim ${_currency.format(item.unitPriceUsd)} USD',
                          ),
                          _MiniPill('KDV %${item.vatRate}'),
                          _MiniPill(
                            'Toplam ${_currency.format(item.totalPriceUsd)} USD',
                          ),
                          _MiniPill(
                            'TL Karşılık ${_currency.format(item.totalPrice)} ₺',
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
                      'Ara Toplam (USD)',
                      '${_currency.format(quote.subtotalUsd)} USD',
                    ),
                    const SizedBox(height: 8),
                    _SummaryRow(
                      'Ara Toplam (TL)',
                      '${_currency.format(quote.subtotal)} ₺',
                    ),
                    const SizedBox(height: 8),
                    _SummaryRow(
                      'KDV (USD)',
                      '${_currency.format(quote.vatTotalUsd)} USD',
                    ),
                    const SizedBox(height: 8),
                    _SummaryRow(
                      'KDV (TL)',
                      '${_currency.format(quote.vatTotal)} ₺',
                    ),
                    const Divider(height: 24),
                    _SummaryRow(
                      'Genel Toplam (USD)',
                      '${_currency.format(quote.totalAmountUsd)} USD',
                    ),
                    const Divider(height: 24),
                    _SummaryRow(
                      'Genel Toplam (TL)',
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
              title: 'Açıklamalar',
              children: [
                _InfoLine('Teklif Açıklaması', quote.description),
                _InfoLine('Koşullar', quote.termsAndConditions),
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
