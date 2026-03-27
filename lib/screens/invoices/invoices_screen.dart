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
import '../widgets/app_drawer.dart';
import '../widgets/destructive_confirm_dialog.dart';

class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({super.key});

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  final _currency = NumberFormat('#,##0.00', 'tr_TR');
  final _searchController = TextEditingController();
  String _query = '';
  String _status = 'all';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_handleSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InvoiceProvider>().load();
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

  bool _matchesQuery(Invoice inv, String customerName) {
    if (_query.isEmpty) return true;
    final haystack = [
      inv.title,
      inv.invoiceNumber,
      customerName,
    ].join(' ').toLowerCase();
    final tokens = _query.toLowerCase().split(RegExp(r'\s+')).where((t) => t.isNotEmpty);
    return tokens.every(haystack.contains);
  }

  List<Invoice> _filtered(List<Invoice> items, List<Customer> customers) {
    String customerName(int id) =>
        customers.where((c) => c.id == id).firstOrNull?.companyName ?? '';

    return items.where((inv) {
      if (_status != 'all' && inv.status != _status) return false;
      if (!_matchesQuery(inv, customerName(inv.customerId))) return false;
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InvoiceProvider>();
    final customers = context.watch<CustomerProvider>().items;
    final filteredItems = _filtered(provider.items, customers);

    String customerName(int id) =>
        customers.where((c) => c.id == id).firstOrNull?.companyName ?? '#$id';

    return Scaffold(
      appBar: AppBar(title: const Text('Faturalar')),
      drawer: const AppDrawer(currentRoute: '/invoices'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/invoices/new'),
        icon: const Icon(Icons.receipt_long_outlined),
        label: const Text('Yeni Fatura'),
      ),
      body: provider.loading
          ? const Center(child: CircularProgressIndicator())
          : provider.items.isEmpty
          ? _EmptyState(
              icon: Icons.receipt_long_outlined,
              message: 'Henüz fatura oluşturulmadı',
              actionLabel: 'Fatura Ekle',
              onAction: () => context.go('/invoices/new'),
            )
          : RefreshIndicator(
              onRefresh: provider.load,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: filteredItems.length + 1,
                separatorBuilder: (_, index) =>
                    index == 0 ? const SizedBox(height: 12) : const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _FilterBar(
                      searchController: _searchController,
                      totalCount: provider.items.length,
                      filteredCount: filteredItems.length,
                      selectedStatus: _status,
                      hasActiveFilters: _hasActiveFilters,
                      onStatusChanged: (v) => setState(() => _status = v),
                      onClear: _clearFilters,
                      entityLabel: 'fatura',
                      searchHint: 'Başlık, fatura no veya firma...',
                      statusOptions: const [
                        ('all', 'Tümü'),
                        ('draft', 'Taslak'),
                        ('sent', 'Gönderildi'),
                        ('paid', 'Ödendi'),
                        ('overdue', 'Gecikmiş'),
                        ('cancelled', 'İptal'),
                      ],
                    );
                  }
                  final invoice = filteredItems[index - 1];
                  final color = AppTheme.statusColor(invoice.status);

                  return Card(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => context.push('/invoices/${invoice.id}'),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(Icons.receipt_long_outlined, color: color),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    invoice.title,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${invoice.invoiceNumber} • ${customerName(invoice.customerId)}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.textMedium,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${_currency.format(invoice.totalAmount)} ₺',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: color,
                                    ),
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
                                  tooltip: 'Fatura işlemleri',
                                  onSelected: (selected) async {
                                    final invoices = context.read<InvoiceProvider>();
                                    if (selected == 'show') {
                                      context.push('/invoices/${invoice.id}');
                                    } else if (selected == 'edit') {
                                      context.go('/invoices/${invoice.id}/edit');
                                    } else if (selected == 'paid') {
                                      await invoices.update(invoice.id, {'status': 'paid'});
                                    } else if (selected == 'delete') {
                                      final confirmed = await showDestructiveConfirmDialog(
                                        context,
                                        title: 'Faturayı Sil',
                                        message:
                                            '${invoice.title} faturasını silmek istediğinizden emin misiniz?',
                                      );
                                      if (!confirmed || !context.mounted) return;
                                      await invoices.delete(invoice.id);
                                    }
                                  },
                                  itemBuilder: (_) => const [
                                    PopupMenuItem(
                                      value: 'show',
                                      child: ActionMenuRow(
                                        icon: Icons.visibility_outlined,
                                        label: 'Faturayı Göster',
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
                                      value: 'paid',
                                      child: ActionMenuRow(
                                        icon: Icons.check_circle_outlined,
                                        label: 'Ödendi İşaretle',
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
                                _StatusBadge(label: invoice.statusLabel, color: color),
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
