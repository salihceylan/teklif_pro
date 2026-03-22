import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/app_theme.dart';
import '../../providers/invoice_provider.dart';
import '../../providers/customer_provider.dart';
import '../widgets/app_drawer.dart';

class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({super.key});

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  final _fmt = NumberFormat('#,##0.00', 'tr_TR');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InvoiceProvider>().load();
      context.read<CustomerProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<InvoiceProvider>();
    final customers = context.watch<CustomerProvider>().items;

    String customerName(int id) =>
        customers.where((c) => c.id == id).firstOrNull?.fullName ?? '#$id';

    return Scaffold(
      appBar: AppBar(title: const Text('Faturalar')),
      drawer: const AppDrawer(currentRoute: '/invoices'),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/invoices/new'),
        child: const Icon(Icons.add),
      ),
      body: prov.loading
          ? const Center(child: CircularProgressIndicator())
          : prov.items.isEmpty
              ? _EmptyState(
                  icon: Icons.receipt_long_outlined,
                  message: 'Henüz fatura oluşturulmadı',
                  actionLabel: 'Fatura Ekle',
                  onAction: () => context.go('/invoices/new'),
                )
              : RefreshIndicator(
                  onRefresh: prov.load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: prov.items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (ctx, i) {
                      final inv = prov.items[i];
                      final color = AppTheme.statusColor(inv.status);
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
                                child: Icon(Icons.receipt_long_outlined,
                                    color: color, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      inv.title,
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
                                      '${inv.invoiceNumber}  •  ${customerName(inv.customerId)}',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.textMedium),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${_fmt.format(inv.totalAmount)} ₺',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
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
                                  _StatusBadge(
                                      label: inv.statusLabel, color: color),
                                  const SizedBox(height: 4),
                                  PopupMenuButton<String>(
                                    icon: const Icon(Icons.more_vert,
                                        size: 20, color: AppTheme.textLight),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                    itemBuilder: (_) => [
                                      _menuItem(Icons.edit_outlined,
                                          'Düzenle', 'edit'),
                                      _menuItem(Icons.check_circle_outlined,
                                          'Ödendi İşaretle', 'paid',
                                          color: const Color(0xFF10B981)),
                                      _menuItem(Icons.delete_outline,
                                          'Sil', 'delete',
                                          color: const Color(0xFFEF4444)),
                                    ],
                                    onSelected: (v) async {
                                      if (v == 'edit') {
                                        context
                                            .go('/invoices/${inv.id}/edit');
                                      } else if (v == 'paid') {
                                        await prov.update(
                                            inv.id, {'status': 'paid'});
                                      } else if (v == 'delete') {
                                        await prov.delete(inv.id);
                                      }
                                    },
                                  ),
                                ],
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
