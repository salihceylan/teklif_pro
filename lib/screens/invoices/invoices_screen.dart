import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../providers/customer_provider.dart';
import '../../providers/invoice_provider.dart';
import '../widgets/action_menu_row.dart';
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
              message: 'Henuz fatura olusturulmadi',
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
                  final invoice = prov.items[i];
                  final color = AppTheme.statusColor(invoice.status);
                  return Card(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTapDown: (details) =>
                          _showInvoiceMenu(details, invoice.id),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.receipt_long_outlined,
                                color: color,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    invoice.title,
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
                                    '${invoice.invoiceNumber}  •  ${customerName(invoice.customerId)}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textMedium,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${_fmt.format(invoice.totalAmount)} ₺',
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
                            _StatusBadge(
                              label: invoice.statusLabel,
                              color: color,
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

  Future<void> _showInvoiceMenu(TapDownDetails details, int invoiceId) async {
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final selected = await showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromLTWH(
          details.globalPosition.dx,
          details.globalPosition.dy,
          0,
          0,
        ),
        Offset.zero & overlay.size,
      ),
      items: const [
        PopupMenuItem(
          value: 'show',
          child: ActionMenuRow(
            icon: Icons.visibility_outlined,
            label: 'Faturayi Goster',
          ),
        ),
        PopupMenuItem(
          value: 'edit',
          child: ActionMenuRow(icon: Icons.edit_outlined, label: 'Duzenle'),
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
    );

    if (!mounted || selected == null) return;

    final prov = context.read<InvoiceProvider>();
    if (selected == 'show') {
      context.push('/invoices/$invoiceId');
    } else if (selected == 'edit') {
      context.go('/invoices/$invoiceId/edit');
    } else if (selected == 'paid') {
      await prov.update(invoiceId, {'status': 'paid'});
    } else if (selected == 'delete') {
      await prov.delete(invoiceId);
    }
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
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
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
          Text(
            message,
            style: const TextStyle(color: AppTheme.textMedium, fontSize: 15),
          ),
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
