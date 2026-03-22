import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/app_theme.dart';
import '../../providers/quote_provider.dart';
import '../../providers/customer_provider.dart';
import '../../providers/invoice_provider.dart';
import '../widgets/app_drawer.dart';

class QuotesScreen extends StatefulWidget {
  const QuotesScreen({super.key});

  @override
  State<QuotesScreen> createState() => _QuotesScreenState();
}

class _QuotesScreenState extends State<QuotesScreen> {
  final _fmt = NumberFormat('#,##0.00', 'tr_TR');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QuoteProvider>().load();
      context.read<CustomerProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<QuoteProvider>();
    final customers = context.watch<CustomerProvider>().items;
    final invProv = context.read<InvoiceProvider>();

    String customerName(int id) =>
        customers.where((c) => c.id == id).firstOrNull?.fullName ?? '#$id';

    return Scaffold(
      appBar: AppBar(title: const Text('Teklifler')),
      drawer: const AppDrawer(currentRoute: '/quotes'),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/quotes/new'),
        child: const Icon(Icons.add),
      ),
      body: prov.loading
          ? const Center(child: CircularProgressIndicator())
          : prov.items.isEmpty
              ? _EmptyState(
                  icon: Icons.request_quote_outlined,
                  message: 'Henüz teklif oluşturulmadı',
                  actionLabel: 'Teklif Ekle',
                  onAction: () => context.go('/quotes/new'),
                )
              : RefreshIndicator(
                  onRefresh: prov.load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: prov.items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (ctx, i) {
                      final q = prov.items[i];
                      final color = AppTheme.statusColor(q.status);
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(Icons.request_quote_outlined,
                                    color: color, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      q.title,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textDark,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${customerName(q.customerId)}  •  ${_fmt.format(q.totalAmount)} ₺',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.textMedium),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              _StatusBadge(label: q.statusLabel, color: color),
                              PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert,
                                    size: 20, color: AppTheme.textLight),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                itemBuilder: (_) => [
                                  _menuItem(
                                      Icons.edit_outlined, 'Düzenle', 'edit'),
                                  _menuItem(Icons.receipt_long_outlined,
                                      'Fatura Oluştur', 'invoice'),
                                  _menuItem(Icons.delete_outline, 'Sil',
                                      'delete',
                                      color: const Color(0xFFEF4444)),
                                ],
                                onSelected: (v) async {
                                  if (v == 'edit') {
                                    context.go('/quotes/${q.id}/edit');
                                  } else if (v == 'invoice') {
                                    await invProv.createFromQuote(q.id);
                                    if (ctx.mounted) {
                                      ScaffoldMessenger.of(ctx).showSnackBar(
                                        _snackBar('Fatura oluşturuldu'),
                                      );
                                    }
                                  } else if (v == 'delete') {
                                    await prov.delete(q.id);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  PopupMenuItem<String> _menuItem(IconData icon, String label, String value,
      {Color? color}) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 18, color: color ?? AppTheme.textMedium),
          const SizedBox(width: 10),
          Text(label,
              style: TextStyle(
                  fontSize: 14,
                  color: color ?? AppTheme.textDark,
                  fontWeight: FontWeight.w500)),
        ],
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
        style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

SnackBar _snackBar(String msg) => SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );

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
          Text(message,
              style: const TextStyle(
                  color: AppTheme.textMedium, fontSize: 15)),
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
