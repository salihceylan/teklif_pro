import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import '../../providers/customer_provider.dart';
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
        (_) => context.read<CustomerProvider>().load());
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<CustomerProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Müşteriler')),
      drawer: const AppDrawer(currentRoute: '/customers'),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/customers/new'),
        child: const Icon(Icons.add),
      ),
      body: prov.loading
          ? const Center(child: CircularProgressIndicator())
          : prov.items.isEmpty
              ? _EmptyState(
                  icon: Icons.people_alt_outlined,
                  message: 'Henüz müşteri eklenmedi',
                  actionLabel: 'Müşteri Ekle',
                  onAction: () => context.go('/customers/new'),
                )
              : RefreshIndicator(
                  onRefresh: prov.load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: prov.items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (ctx, i) {
                      final c = prov.items[i];
                      final color = AppTheme.avatarColor(c.fullName);
                      return Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          leading: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                c.fullName[0].toUpperCase(),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: color,
                                ),
                              ),
                            ),
                          ),
                          title: Text(c.fullName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 15)),
                          subtitle: Text(
                            [
                              if (c.phone != null) c.phone!,
                              if (c.email != null) c.email!,
                            ].join(' • '),
                            style: const TextStyle(
                                fontSize: 12, color: AppTheme.textMedium),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _IconBtn(
                                icon: Icons.edit_outlined,
                                color: AppTheme.primary,
                                onTap: () =>
                                    context.go('/customers/${c.id}/edit'),
                              ),
                              const SizedBox(width: 4),
                              _IconBtn(
                                icon: Icons.delete_outline,
                                color: const Color(0xFFEF4444),
                                onTap: () => _confirmDelete(context, c.id),
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

  void _confirmDelete(BuildContext context, int id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Müşteriyi Sil'),
        content: const Text('Bu müşteriyi silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444)),
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

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _IconBtn(
      {required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 17, color: color),
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
            style: FilledButton.styleFrom(
                minimumSize: const Size(160, 44)),
          ),
        ],
      ),
    );
  }
}
