import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../providers/customer_provider.dart';
import '../../providers/service_request_provider.dart';
import '../widgets/action_menu_row.dart';
import '../widgets/app_drawer.dart';

class ServiceRequestsScreen extends StatefulWidget {
  const ServiceRequestsScreen({super.key});

  @override
  State<ServiceRequestsScreen> createState() => _ServiceRequestsScreenState();
}

class _ServiceRequestsScreenState extends State<ServiceRequestsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ServiceRequestProvider>().load();
      context.read<CustomerProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ServiceRequestProvider>();
    final customers = context.watch<CustomerProvider>().items;

    String customerName(int id) =>
        customers.where((c) => c.id == id).firstOrNull?.fullName ?? '#$id';

    return Scaffold(
      appBar: AppBar(title: const Text('Servis Talepleri')),
      drawer: const AppDrawer(currentRoute: '/service-requests'),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/service-requests/new'),
        child: const Icon(Icons.add),
      ),
      body: prov.loading
          ? const Center(child: CircularProgressIndicator())
          : prov.items.isEmpty
          ? _EmptyState(
              icon: Icons.build_circle_outlined,
              message: 'Henuz servis talebi yok',
              actionLabel: 'Talep Ekle',
              onAction: () => context.go('/service-requests/new'),
            )
          : RefreshIndicator(
              onRefresh: prov.load,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: prov.items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (ctx, i) {
                  final request = prov.items[i];
                  final color = AppTheme.statusColor(request.status);
                  return Card(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTapDown: (details) =>
                          _showRequestMenu(details, request.id),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
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
                                Icons.build_outlined,
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
                                    request.title,
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
                                    customerName(request.customerId),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textMedium,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            _StatusBadge(
                              label: request.statusLabel,
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

  Future<void> _showRequestMenu(TapDownDetails details, int requestId) async {
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
            label: 'Talebi Goster',
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
      context.push('/service-requests/$requestId');
    } else if (selected == 'edit') {
      context.go('/service-requests/$requestId/edit');
    } else if (selected == 'delete') {
      await context.read<ServiceRequestProvider>().delete(requestId);
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
