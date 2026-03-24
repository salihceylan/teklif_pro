import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../providers/customer_provider.dart';
import '../../providers/visit_provider.dart';
import '../widgets/action_menu_row.dart';
import '../widgets/app_drawer.dart';

class VisitsScreen extends StatefulWidget {
  const VisitsScreen({super.key});

  @override
  State<VisitsScreen> createState() => _VisitsScreenState();
}

class _VisitsScreenState extends State<VisitsScreen> {
  final _date = DateFormat('dd.MM.yyyy HH:mm', 'tr_TR');
  final _currency = NumberFormat('#,##0.00', 'tr_TR');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VisitProvider>().load();
      context.read<CustomerProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final visits = context.watch<VisitProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Servis Formlari')),
      drawer: const AppDrawer(currentRoute: '/visits'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/visits/new'),
        icon: const Icon(Icons.build_circle_outlined),
        label: const Text('Yeni Form'),
      ),
      body: visits.loading
          ? const Center(child: CircularProgressIndicator())
          : visits.items.isEmpty
          ? _EmptyState(
              icon: Icons.build_circle_outlined,
              message: 'Henuz servis formu olusturulmadi',
              actionLabel: 'Form Ekle',
              onAction: () => context.go('/visits/new'),
            )
          : RefreshIndicator(
              onRefresh: visits.load,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: visits.items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final visit = visits.items[index];
                  final color = AppTheme.statusColor(visit.status);

                  return Card(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTapDown: (details) => _showVisitMenu(details, visit.id),
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
                              child: Icon(
                                Icons.assignment_turned_in_outlined,
                                color: color,
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
                                    children: [
                                      Text(
                                        visit.customerCompanyName ??
                                            'Servis Formu',
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.textDark,
                                        ),
                                      ),
                                      if ((visit.serviceCode ?? '').isNotEmpty)
                                        _Chip(label: visit.serviceCode!),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _date.format(visit.scheduledDate),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textMedium,
                                    ),
                                  ),
                                  if ((visit.complaint ?? '').isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Text(
                                        visit.complaint!,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.textLight,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                _StatusBadge(
                                  label: visit.statusLabel,
                                  color: color,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  '${_currency.format(visit.grandTotal)} ₺',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.primary,
                                  ),
                                ),
                                if (visit.grandTotalUsd > 0) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    '${_currency.format(visit.grandTotalUsd)} USD',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textMedium,
                                    ),
                                  ),
                                ],
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

  Future<void> _showVisitMenu(TapDownDetails details, int visitId) async {
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
            label: 'Servis Formunu Goster',
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
      context.push('/visits/$visitId');
    } else if (selected == 'edit') {
      context.go('/visits/$visitId/edit');
    } else if (selected == 'delete') {
      await context.read<VisitProvider>().delete(visitId);
    }
  }
}

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
