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
import '../widgets/app_drawer.dart';
import '../widgets/destructive_confirm_dialog.dart';
import 'quote_ui_actions.dart';

class QuotesScreen extends StatefulWidget {
  const QuotesScreen({super.key});

  @override
  State<QuotesScreen> createState() => _QuotesScreenState();
}

class _QuotesScreenState extends State<QuotesScreen> {
  final _currency = NumberFormat('#,##0.00', 'tr_TR');
  final _date = DateFormat('dd.MM.yyyy', 'tr_TR');
  final _searchController = TextEditingController();
  String _query = '';
  String _status = 'all';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_handleSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QuoteProvider>().load();
      context.read<CustomerProvider>().load();
    });
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_handleSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _handleSearchChanged() {
    final next = _searchController.text.trim();
    if (next == _query) return;
    setState(() => _query = next);
  }

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _query = '';
      _status = 'all';
    });
  }

  bool get _hasActiveFilters => _query.isNotEmpty || _status != 'all';

  bool _matchesQuery(Quote q) {
    if (_query.isEmpty) return true;
    final haystack = [
      q.title,
      q.quoteCode ?? '',
      q.customerCompanyName ?? '',
    ].join(' ').toLowerCase();
    final tokens = _query.toLowerCase().split(RegExp(r'\s+')).where((t) => t.isNotEmpty);
    return tokens.every(haystack.contains);
  }

  List<Quote> _filtered(List<Quote> items) {
    return items.where((q) {
      if (_status != 'all' && q.status != _status) return false;
      if (!_matchesQuery(q)) return false;
      return true;
    }).toList();
  }

  Customer? _customerFor(List<Customer> customers, int id) =>
      customers.where((item) => item.id == id).firstOrNull;

  Future<void> _handleMenuAction(
    BuildContext context, {
    required String value,
    required Quote quote,
    required Customer? customer,
  }) async {
    final quotes = context.read<QuoteProvider>();
    final invoices = context.read<InvoiceProvider>();

    if (value == 'show') {
      if (context.mounted) context.push('/quotes/${quote.id}');
    } else if (value == 'print') {
      await QuoteUiActions.printQuote(context, quote: quote, customer: customer);
    } else if (value == 'mail') {
      await QuoteUiActions.showSendEmailDialog(context, quote: quote, customer: customer);
    } else if (value == 'edit') {
      if (context.mounted) context.go('/quotes/${quote.id}/edit');
    } else if (value == 'invoice') {
      await invoices.createFromQuote(quote.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Fatura oluşturuldu')));
      }
    } else if (value == 'delete') {
      final confirmed = await showDestructiveConfirmDialog(
        context,
        title: 'Teklifi Sil',
        message: '${quote.title} teklif kaydını silmek istediğinizden emin misiniz?',
      );
      if (!confirmed || !context.mounted) return;
      await quotes.delete(quote.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final quotes = context.watch<QuoteProvider>();
    final customers = context.watch<CustomerProvider>().items;
    final filteredItems = _filtered(quotes.items);

    return Scaffold(
      appBar: AppBar(title: const Text('Teklifler')),
      drawer: const AppDrawer(currentRoute: '/quotes'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/quotes/new'),
        icon: const Icon(Icons.note_add_outlined),
        label: const Text('Yeni Teklif'),
      ),
      body: quotes.loading
          ? const Center(child: CircularProgressIndicator())
          : quotes.items.isEmpty
          ? _EmptyState(
              icon: Icons.request_quote_outlined,
              message: 'Henüz teklif oluşturulmadı',
              actionLabel: 'Teklif Ekle',
              onAction: () => context.go('/quotes/new'),
            )
          : RefreshIndicator(
              onRefresh: quotes.load,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: filteredItems.length + 1,
                separatorBuilder: (_, index) =>
                    index == 0 ? const SizedBox(height: 12) : const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _FilterBar(
                      searchController: _searchController,
                      totalCount: quotes.items.length,
                      filteredCount: filteredItems.length,
                      selectedStatus: _status,
                      hasActiveFilters: _hasActiveFilters,
                      onStatusChanged: (v) => setState(() => _status = v),
                      onClear: _clearFilters,
                      entityLabel: 'teklif',
                      searchHint: 'Başlık, kod veya firma...',
                      statusOptions: const [
                        ('all', 'Tümü'),
                        ('draft', 'Taslak'),
                        ('sent', 'Gönderildi'),
                        ('accepted', 'Kabul Edildi'),
                        ('rejected', 'Reddedildi'),
                        ('expired', 'Süresi Doldu'),
                      ],
                    );
                  }
                  final quote = filteredItems[index - 1];
                  final customer = _customerFor(customers, quote.customerId);
                  final color = AppTheme.statusColor(quote.status);

                  return Card(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: () => context.push('/quotes/${quote.id}'),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 54,
                              height: 54,
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(Icons.request_quote_outlined, color: color),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      Text(
                                        quote.title,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.textDark,
                                        ),
                                      ),
                                      if ((quote.quoteCode ?? '').isNotEmpty)
                                        _Chip(label: quote.quoteCode!),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    quote.customerCompanyName ??
                                        customer?.companyName ??
                                        'Firma seçilmedi',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.textMedium,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 10,
                                    runSpacing: 6,
                                    children: [
                                      _meta(
                                        Icons.event_outlined,
                                        _date.format(quote.issuedAt ?? quote.createdAt),
                                      ),
                                      if (quote.validUntil != null)
                                        _meta(
                                          Icons.event_available_outlined,
                                          'Geçerlilik: ${_date.format(quote.validUntil!)}',
                                        ),
                                      _meta(
                                        Icons.payments_outlined,
                                        '${_currency.format(quote.totalAmount)} ₺',
                                      ),
                                      if (quote.totalAmountUsd > 0)
                                        _meta(
                                          Icons.attach_money_outlined,
                                          '${_currency.format(quote.totalAmountUsd)} USD',
                                        ),
                                      if (quote.hasExchangeRate)
                                        _meta(
                                          Icons.currency_exchange_outlined,
                                          'Kur ${_currency.format(quote.exchangeRate!)}',
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert_rounded),
                                  tooltip: 'Teklif işlemleri',
                                  onSelected: (selected) => _handleMenuAction(
                                    context,
                                    value: selected,
                                    quote: quote,
                                    customer: customer,
                                  ),
                                  itemBuilder: (_) => const [
                                    PopupMenuItem(
                                      value: 'show',
                                      child: ActionMenuRow(
                                        icon: Icons.visibility_outlined,
                                        label: 'Teklifi Göster',
                                      ),
                                    ),
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
                                _StatusBadge(label: quote.statusLabel, color: color),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }

  Widget _meta(IconData icon, String text) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 14, color: AppTheme.textLight),
      const SizedBox(width: 4),
      Text(text, style: const TextStyle(fontSize: 12, color: AppTheme.textMedium)),
    ],
  );
}

// ── Filter bar ────────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  final TextEditingController searchController;
  final int totalCount;
  final int filteredCount;
  final String selectedStatus;
  final bool hasActiveFilters;
  final ValueChanged<String> onStatusChanged;
  final VoidCallback onClear;
  final String entityLabel;
  final String searchHint;
  final List<(String, String)> statusOptions;

  const _FilterBar({
    required this.searchController,
    required this.totalCount,
    required this.filteredCount,
    required this.selectedStatus,
    required this.hasActiveFilters,
    required this.onStatusChanged,
    required this.onClear,
    required this.entityLabel,
    required this.searchHint,
    required this.statusOptions,
  });

  @override
  Widget build(BuildContext context) {
    final summaryColor =
        filteredCount == 0 ? AppTheme.danger : AppTheme.textMedium;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '$filteredCount sonuç  •  toplam $totalCount $entityLabel',
                    style: TextStyle(fontSize: 13, color: summaryColor),
                  ),
                ),
                if (hasActiveFilters)
                  TextButton.icon(
                    onPressed: onClear,
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Temizle'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.textMedium,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: searchController,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: searchHint,
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: searchController.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: onClear,
                        icon: const Icon(Icons.close_rounded),
                      ),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (value, label) in statusOptions)
                  _FilterChip(
                    label: label,
                    selected: selectedStatus == value,
                    onTap: () => onStatusChanged(value),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? color : color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? color : color.withValues(alpha: 0.2)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : color,
          ),
        ),
      ),
    );
  }
}

// ── Helper widgets ────────────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  final String label;
  const _Chip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppTheme.primary,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  const _EmptyState({
    required this.icon,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, size: 32, color: AppTheme.primary),
          ),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(color: AppTheme.textMedium, fontSize: 15)),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onAction,
            icon: const Icon(Icons.add, size: 18),
            label: Text(actionLabel),
            style: FilledButton.styleFrom(minimumSize: const Size(160, 44)),
          ),
        ],
      ),
    );
  }
}
