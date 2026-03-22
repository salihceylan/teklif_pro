import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/customer_provider.dart';
import '../../providers/service_request_provider.dart';
import '../../providers/quote_provider.dart';
import '../../providers/visit_provider.dart';
import '../../providers/invoice_provider.dart';
import '../widgets/app_drawer.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _moneyFmt = NumberFormat('#,##0', 'tr_TR');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAll());
  }

  Future<void> _loadAll() async {
    await Future.wait([
      context.read<CustomerProvider>().load(),
      context.read<ServiceRequestProvider>().load(),
      context.read<QuoteProvider>().load(),
      context.read<VisitProvider>().load(),
      context.read<InvoiceProvider>().load(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final customers = context.watch<CustomerProvider>().items;
    final requests = context.watch<ServiceRequestProvider>().items;
    final quotes = context.watch<QuoteProvider>().items;
    final visits = context.watch<VisitProvider>().items;
    final invoices = context.watch<InvoiceProvider>().items;

    // Finansal hesaplamalar
    final paidTotal = invoices
        .where((i) => i.status == 'paid')
        .fold(0.0, (s, i) => s + i.totalAmount);
    final pendingTotal = invoices
        .where((i) => i.status == 'sent')
        .fold(0.0, (s, i) => s + i.totalAmount);
    final overdueTotal = invoices
        .where((i) => i.status == 'overdue')
        .fold(0.0, (s, i) => s + i.totalAmount);

    // Aktif iş sayıları
    final openRequests =
        requests.where((r) => r.status == 'new' || r.status == 'in_progress').length;
    final pendingQuotes =
        quotes.where((q) => q.status == 'draft' || q.status == 'sent').length;
    final acceptedQuotes = quotes.where((q) => q.status == 'accepted').length;

    // Yaklaşan ziyaretler (bugünden itibaren 7 gün)
    final now = DateTime.now();
    final weekLater = now.add(const Duration(days: 7));
    final upcomingVisits = visits
        .where((v) =>
            v.status == 'scheduled' &&
            v.scheduledDate.isAfter(now) &&
            v.scheduledDate.isBefore(weekLater))
        .toList()
      ..sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));

    // Son 5 servis talebi
    final recentRequests = requests.take(5).toList();

    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(user?.companyName ?? 'Teklif Pro'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAll,
          ),
        ],
      ),
      drawer: const AppDrawer(currentRoute: '/'),
      body: RefreshIndicator(
        onRefresh: _loadAll,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Karşılama
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _greeting(),
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: Colors.grey[600]),
                      ),
                      Text(
                        user?.fullName ?? '',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _SmallStatBadge(
                    label: 'Müşteri', count: customers.length, color: scheme.primary),
              ],
            ),
            const SizedBox(height: 20),

            // Finansal Özet Başlığı
            _SectionTitle(
              title: 'Finansal Durum',
              action: TextButton(
                onPressed: () => context.go('/invoices'),
                child: const Text('Tümü'),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _FinanceCard(
                    label: 'Tahsil Edilen',
                    amount: paidTotal,
                    fmt: _moneyFmt,
                    color: Colors.green,
                    icon: Icons.check_circle_outline,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _FinanceCard(
                    label: 'Bekleyen',
                    amount: pendingTotal,
                    fmt: _moneyFmt,
                    color: Colors.orange,
                    icon: Icons.hourglass_empty,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _FinanceCard(
                    label: 'Gecikmiş',
                    amount: overdueTotal,
                    fmt: _moneyFmt,
                    color: Colors.red,
                    icon: Icons.warning_amber_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // İş Durumu
            _SectionTitle(title: 'İş Durumu'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _StatusCard(
                    icon: Icons.build,
                    label: 'Açık Talep',
                    count: openRequests,
                    total: requests.length,
                    color: Colors.orange,
                    onTap: () => context.go('/service-requests'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatusCard(
                    icon: Icons.description,
                    label: 'Bekleyen Teklif',
                    count: pendingQuotes,
                    total: quotes.length,
                    color: Colors.blue,
                    onTap: () => context.go('/quotes'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatusCard(
                    icon: Icons.thumb_up_outlined,
                    label: 'Onaylanan',
                    count: acceptedQuotes,
                    total: quotes.length,
                    color: Colors.green,
                    onTap: () => context.go('/quotes'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Yaklaşan Ziyaretler
            _SectionTitle(
              title: 'Bu Hafta Ziyaretler',
              action: TextButton(
                onPressed: () => context.go('/visits'),
                child: const Text('Tümü'),
              ),
            ),
            const SizedBox(height: 8),
            if (upcomingVisits.isEmpty)
              _EmptyCard(
                icon: Icons.calendar_today_outlined,
                message: 'Bu hafta planlanmış ziyaret yok',
                actionLabel: 'Ziyaret Ekle',
                onAction: () => context.go('/visits/new'),
              )
            else
              ...upcomingVisits.take(3).map((v) {
                final customer = customers
                    .where((c) => c.id == v.customerId)
                    .firstOrNull;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.purple.withAlpha(30),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            DateFormat('dd').format(v.scheduledDate),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.purple),
                          ),
                          Text(
                            DateFormat('MMM', 'tr').format(v.scheduledDate),
                            style: const TextStyle(
                                fontSize: 10, color: Colors.purple),
                          ),
                        ],
                      ),
                    ),
                    title: Text(customer?.fullName ?? 'Müşteri #${v.customerId}'),
                    subtitle: Text(
                        DateFormat('HH:mm').format(v.scheduledDate) +
                            (v.notes != null ? ' • ${v.notes}' : ''),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.go('/visits/${v.id}/edit'),
                  ),
                );
              }),
            const SizedBox(height: 20),

            // Son Talepler
            _SectionTitle(
              title: 'Son Servis Talepleri',
              action: TextButton(
                onPressed: () => context.go('/service-requests'),
                child: const Text('Tümü'),
              ),
            ),
            const SizedBox(height: 8),
            if (recentRequests.isEmpty)
              _EmptyCard(
                icon: Icons.build_outlined,
                message: 'Henüz servis talebi yok',
                actionLabel: 'Talep Ekle',
                onAction: () => context.go('/service-requests/new'),
              )
            else
              ...recentRequests.map((r) {
                final customer = customers
                    .where((c) => c.id == r.customerId)
                    .firstOrNull;
                final statusColor = _statusColor(r.status);
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: statusColor.withAlpha(30),
                      child: Icon(_statusIcon(r.status),
                          color: statusColor, size: 20),
                    ),
                    title: Text(r.title,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(customer?.fullName ?? ''),
                    trailing: Chip(
                      label: Text(r.statusLabel,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 10)),
                      backgroundColor: statusColor,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: EdgeInsets.zero,
                    ),
                    onTap: () => context.go('/service-requests/${r.id}/edit'),
                  ),
                );
              }),
            const SizedBox(height: 20),

            // Hızlı Eylemler
            _SectionTitle(title: 'Hızlı Ekle'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _QuickAction(
                    icon: Icons.person_add,
                    label: 'Müşteri',
                    onTap: () => context.go('/customers/new')),
                _QuickAction(
                    icon: Icons.add_task,
                    label: 'Talep',
                    onTap: () => context.go('/service-requests/new')),
                _QuickAction(
                    icon: Icons.note_add,
                    label: 'Teklif',
                    onTap: () => context.go('/quotes/new')),
                _QuickAction(
                    icon: Icons.event,
                    label: 'Ziyaret',
                    onTap: () => context.go('/visits/new')),
                _QuickAction(
                    icon: Icons.add_card,
                    label: 'Fatura',
                    onTap: () => context.go('/invoices/new')),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  String _greeting() {
    final h = TimeOfDay.now().hour;
    if (h < 12) return 'Günaydın,';
    if (h < 18) return 'İyi günler,';
    return 'İyi akşamlar,';
  }

  Color _statusColor(String status) {
    return switch (status) {
      'new' => Colors.blue,
      'quoted' => Colors.orange,
      'in_progress' => Colors.purple,
      'completed' => Colors.green,
      _ => Colors.grey,
    };
  }

  IconData _statusIcon(String status) {
    return switch (status) {
      'new' => Icons.fiber_new,
      'quoted' => Icons.description,
      'in_progress' => Icons.construction,
      'completed' => Icons.check_circle,
      _ => Icons.cancel,
    };
  }
}

// ── Yardımcı Widget'lar ──────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  final Widget? action;
  const _SectionTitle({required this.title, this.action});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        ?action,
      ],
    );
  }
}

class _FinanceCard extends StatelessWidget {
  final String label;
  final double amount;
  final NumberFormat fmt;
  final Color color;
  final IconData icon;

  const _FinanceCard({
    required this.label,
    required this.amount,
    required this.fmt,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              '${fmt.format(amount)}₺',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: color),
            ),
          ),
          Text(label,
              style: TextStyle(fontSize: 10, color: Colors.grey[600])),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final int total;
  final Color color;
  final VoidCallback onTap;

  const _StatusCard({
    required this.icon,
    required this.label,
    required this.count,
    required this.total,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withAlpha(15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(50)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              '$count',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color),
            ),
            Text(label,
                style: TextStyle(fontSize: 10, color: Colors.grey[600])),
            if (total > 0)
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: count / total,
                  backgroundColor: color.withAlpha(30),
                  valueColor: AlwaysStoppedAnimation(color),
                  minHeight: 3,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SmallStatBadge extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _SmallStatBadge(
      {required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.people, size: 14, color: color),
          const SizedBox(width: 4),
          Text('$count $label',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color)),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  const _EmptyCard({
    required this.icon,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withAlpha(50)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey, size: 28),
          const SizedBox(width: 12),
          Expanded(
              child:
                  Text(message, style: TextStyle(color: Colors.grey[600]))),
          TextButton(onPressed: onAction, child: Text(actionLabel)),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickAction(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
      onPressed: onTap,
    );
  }
}
