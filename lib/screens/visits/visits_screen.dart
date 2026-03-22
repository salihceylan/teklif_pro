import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/app_theme.dart';
import '../../providers/visit_provider.dart';
import '../../providers/customer_provider.dart';
import '../widgets/app_drawer.dart';

class VisitsScreen extends StatefulWidget {
  const VisitsScreen({super.key});

  @override
  State<VisitsScreen> createState() => _VisitsScreenState();
}

class _VisitsScreenState extends State<VisitsScreen> {
  final _timeFmt = DateFormat('HH:mm');

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
    final prov = context.watch<VisitProvider>();
    final customers = context.watch<CustomerProvider>().items;

    String customerName(int id) =>
        customers.where((c) => c.id == id).firstOrNull?.fullName ?? '#$id';

    return Scaffold(
      appBar: AppBar(title: const Text('Servis Ziyaretleri')),
      drawer: const AppDrawer(currentRoute: '/visits'),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/visits/new'),
        child: const Icon(Icons.add),
      ),
      body: prov.loading
          ? const Center(child: CircularProgressIndicator())
          : prov.items.isEmpty
              ? _EmptyState(
                  icon: Icons.calendar_month_outlined,
                  message: 'Henüz ziyaret planlanmadı',
                  actionLabel: 'Ziyaret Ekle',
                  onAction: () => context.go('/visits/new'),
                )
              : RefreshIndicator(
                  onRefresh: prov.load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: prov.items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (ctx, i) {
                      final v = prov.items[i];
                      final color = AppTheme.statusColor(v.status);
                      return Card(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () =>
                              context.go('/visits/${v.id}/edit'),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                // Tarih kutusu
                                Container(
                                  width: 48,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary
                                        .withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        DateFormat('dd')
                                            .format(v.scheduledDate),
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.primary,
                                          height: 1,
                                        ),
                                      ),
                                      Text(
                                        DateFormat('MMM', 'tr_TR')
                                            .format(v.scheduledDate),
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        customerName(v.customerId),
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.textDark,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          const Icon(
                                              Icons.access_time_outlined,
                                              size: 12,
                                              color: AppTheme.textLight),
                                          const SizedBox(width: 3),
                                          Text(
                                            _timeFmt.format(v.scheduledDate),
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: AppTheme.textMedium),
                                          ),
                                          if (v.notes != null) ...[
                                            const Text('  •  ',
                                                style: TextStyle(
                                                    color:
                                                        AppTheme.textLight)),
                                            Expanded(
                                              child: Text(
                                                v.notes!,
                                                style: const TextStyle(
                                                    fontSize: 12,
                                                    color:
                                                        AppTheme.textMedium),
                                                maxLines: 1,
                                                overflow:
                                                    TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _StatusBadge(
                                    label: v.statusLabel, color: color),
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
