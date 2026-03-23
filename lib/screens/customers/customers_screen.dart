import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../providers/customer_provider.dart';
import '../widgets/action_menu_row.dart';
import '../widgets/app_drawer.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<CustomerProvider>().load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CustomerProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Firmalar')),
      drawer: const AppDrawer(currentRoute: '/customers'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/customers/new'),
        icon: const Icon(Icons.add_business_outlined),
        label: const Text('Yeni Firma'),
      ),
      body: provider.loading
          ? const Center(child: CircularProgressIndicator())
          : provider.items.isEmpty
          ? _EmptyState(
              icon: Icons.apartment_outlined,
              message: 'Henuz firma eklenmedi',
              actionLabel: 'Firma Ekle',
              onAction: () => context.go('/customers/new'),
            )
          : RefreshIndicator(
              onRefresh: provider.load,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: provider.items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final customer = provider.items[index];
                  return Card(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTapDown: (details) =>
                          _showCustomerMenu(details, customer.id),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Center(
                                child: Text(
                                  customer.customerCode ??
                                      customer.companyName[0],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.primary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      Text(
                                        customer.companyName,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.textDark,
                                        ),
                                      ),
                                      if ((customer.customerCode ?? '')
                                          .isNotEmpty)
                                        _ChipLabel(
                                          label: 'ID ${customer.customerCode!}',
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    [
                                      if ((customer.contactName ?? '')
                                          .isNotEmpty)
                                        customer.contactName!,
                                      if ((customer.phone ?? '').isNotEmpty)
                                        customer.phone!,
                                      if ((customer.email ?? '').isNotEmpty)
                                        customer.email!,
                                    ].join('  •  '),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textMedium,
                                    ),
                                  ),
                                  if ((customer.taxNumber ?? '').isNotEmpty ||
                                      (customer.city ?? '').isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Text(
                                        [
                                          if ((customer.taxNumber ?? '')
                                              .isNotEmpty)
                                            'Vergi No: ${customer.taxNumber}',
                                          if ((customer.city ?? '').isNotEmpty)
                                            customer.city!,
                                        ].join('  •  '),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.textLight,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
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

  Future<void> _showCustomerMenu(TapDownDetails details, int customerId) async {
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
            label: 'Firmayi Goster',
          ),
        ),
        PopupMenuItem(
          value: 'edit',
          child: ActionMenuRow(icon: Icons.edit_outlined, label: 'Duzenle'),
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

    if (selected == 'show') {
      context.push('/customers/$customerId');
    } else if (selected == 'edit') {
      context.go('/customers/$customerId/edit');
    } else if (selected == 'delete') {
      _confirmDelete(context, customerId);
    }
  }

  void _confirmDelete(BuildContext context, int id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Firmayi Sil'),
        content: const Text(
          'Bu firma kaydini silmek istediginizden emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Iptal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
            ),
            onPressed: () {
              Navigator.pop(context);
              context.read<CustomerProvider>().delete(id);
            },
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }
}

class _ChipLabel extends StatelessWidget {
  final String label;

  const _ChipLabel({required this.label});

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
