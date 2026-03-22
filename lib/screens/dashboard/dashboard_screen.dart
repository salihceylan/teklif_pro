import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/customer_provider.dart';
import '../../providers/invoice_provider.dart';
import '../../providers/quote_provider.dart';
import '../../providers/service_request_provider.dart';
import '../../providers/visit_provider.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_shell.dart';

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

    final paidTotal = invoices
        .where((invoice) => invoice.status == 'paid')
        .fold(0.0, (sum, invoice) => sum + invoice.totalAmount);
    final pendingTotal = invoices
        .where((invoice) => invoice.status == 'sent')
        .fold(0.0, (sum, invoice) => sum + invoice.totalAmount);
    final overdueTotal = invoices
        .where((invoice) => invoice.status == 'overdue')
        .fold(0.0, (sum, invoice) => sum + invoice.totalAmount);

    final openRequests = requests
        .where(
          (request) =>
              request.status == 'new' || request.status == 'in_progress',
        )
        .length;
    final pendingQuotes = quotes
        .where((quote) => quote.status == 'draft' || quote.status == 'sent')
        .length;
    final acceptedQuotes = quotes
        .where((quote) => quote.status == 'accepted')
        .length;

    final now = DateTime.now();
    final weekLater = now.add(const Duration(days: 7));
    final upcomingVisits =
        visits
            .where(
              (visit) =>
                  visit.status == 'scheduled' &&
                  visit.scheduledDate.isAfter(now) &&
                  visit.scheduledDate.isBefore(weekLater),
            )
            .toList()
          ..sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));

    final recentRequests = [...requests]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Scaffold(
      appBar: AppBar(
        title: Text(user?.companyName ?? 'Teklif Pro'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadAll),
        ],
      ),
      drawer: const AppDrawer(currentRoute: '/panel'),
      body: RefreshIndicator(
        onRefresh: _loadAll,
        child: AppScrollableBody(
          maxWidth: 1120,
          children: [
            AppPageIntro(
              badge: _greeting(),
              icon: Icons.dashboard_customize_rounded,
              title: user?.fullName ?? 'Panel',
              subtitle:
                  '${user?.companyName ?? 'Teklif Pro'} için müşteri, servis ve finansal akışı tek ekrandan takip edin.',
              trailing: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _MetricPill(
                    label: 'Müşteri',
                    value: '${customers.length}',
                    icon: Icons.people_alt_outlined,
                  ),
                  _MetricPill(
                    label: 'Aktif Talep',
                    value: '$openRequests',
                    icon: Icons.build_circle_outlined,
                  ),
                  _MetricPill(
                    label: 'Bekleyen Teklif',
                    value: '$pendingQuotes',
                    icon: Icons.request_quote_outlined,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            AppSectionCard(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Finansal Görünüm',
              description:
                  'Tahsil edilen, bekleyen ve gecikmiş tutarları tek alanda izleyin.',
              trailing: TextButton(
                onPressed: () => context.go('/invoices'),
                child: const Text('Faturalar'),
              ),
              children: [
                AdaptiveFieldRow(
                  maxColumns: 3,
                  minItemWidth: 220,
                  children: [
                    _FinanceCard(
                      label: 'Tahsil Edilen',
                      amount: paidTotal,
                      fmt: _moneyFmt,
                      color: AppTheme.success,
                      icon: Icons.check_circle_outline,
                    ),
                    _FinanceCard(
                      label: 'Bekleyen',
                      amount: pendingTotal,
                      fmt: _moneyFmt,
                      color: const Color(0xFFF59E0B),
                      icon: Icons.hourglass_empty,
                    ),
                    _FinanceCard(
                      label: 'Gecikmiş',
                      amount: overdueTotal,
                      fmt: _moneyFmt,
                      color: AppTheme.danger,
                      icon: Icons.warning_amber_outlined,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            AppSectionCard(
              icon: Icons.insights_outlined,
              title: 'Operasyon Özeti',
              description:
                  'Açık talepler, bekleyen teklifler ve kabul edilen teklifler anlık olarak görünür.',
              children: [
                AdaptiveFieldRow(
                  maxColumns: 3,
                  minItemWidth: 220,
                  children: [
                    _StatusCard(
                      icon: Icons.build_outlined,
                      label: 'Açık Talep',
                      count: openRequests,
                      total: requests.length,
                      color: const Color(0xFFF59E0B),
                      onTap: () => context.go('/service-requests'),
                    ),
                    _StatusCard(
                      icon: Icons.description_outlined,
                      label: 'Bekleyen Teklif',
                      count: pendingQuotes,
                      total: quotes.length,
                      color: AppTheme.primary,
                      onTap: () => context.go('/quotes'),
                    ),
                    _StatusCard(
                      icon: Icons.thumb_up_outlined,
                      label: 'Onaylanan',
                      count: acceptedQuotes,
                      total: quotes.length,
                      color: AppTheme.success,
                      onTap: () => context.go('/quotes'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            AppSectionCard(
              icon: Icons.calendar_month_outlined,
              title: 'Bu Hafta Ziyaretler',
              description:
                  'Önümüzdeki yedi gün içindeki planlı ziyaretleri takip edin.',
              trailing: TextButton(
                onPressed: () => context.go('/visits'),
                child: const Text('Tümünü Gör'),
              ),
              children: [
                if (upcomingVisits.isEmpty)
                  _InlineEmptyState(
                    icon: Icons.event_busy_outlined,
                    message: 'Bu hafta planlanmış ziyaret yok.',
                    actionLabel: 'Ziyaret Ekle',
                    onAction: () => context.go('/visits/new'),
                  )
                else
                  for (final visit in upcomingVisits.take(4))
                    _VisitTile(
                      visit: visit,
                      customerName:
                          customers
                              .where(
                                (customer) => customer.id == visit.customerId,
                              )
                              .firstOrNull
                              ?.fullName ??
                          'Müşteri #${visit.customerId}',
                    ),
              ],
            ),
            const SizedBox(height: 20),
            AppSectionCard(
              icon: Icons.pending_actions_outlined,
              title: 'Son Servis Talepleri',
              description:
                  'Yeni açılan veya son güncellenen servis taleplerini buradan izleyin.',
              trailing: TextButton(
                onPressed: () => context.go('/service-requests'),
                child: const Text('Tümünü Gör'),
              ),
              children: [
                if (recentRequests.isEmpty)
                  _InlineEmptyState(
                    icon: Icons.build_outlined,
                    message: 'Henüz servis talebi bulunmuyor.',
                    actionLabel: 'Talep Ekle',
                    onAction: () => context.go('/service-requests/new'),
                  )
                else
                  for (final request in recentRequests.take(5))
                    _RequestTile(
                      title: request.title,
                      customerName:
                          customers
                              .where(
                                (customer) => customer.id == request.customerId,
                              )
                              .firstOrNull
                              ?.fullName ??
                          'Müşteri #${request.customerId}',
                      status: request.status,
                      statusLabel: request.statusLabel,
                      onTap: () =>
                          context.go('/service-requests/${request.id}/edit'),
                    ),
              ],
            ),
            const SizedBox(height: 20),
            AppSectionCard(
              icon: Icons.flash_on_outlined,
              title: 'Hızlı Eylemler',
              description:
                  'Yeni kayıt açmak için en sık kullanılan işlemler burada yer alır.',
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _QuickAction(
                      icon: Icons.person_add_alt_1_outlined,
                      label: 'Müşteri Ekle',
                      onTap: () => context.go('/customers/new'),
                    ),
                    _QuickAction(
                      icon: Icons.add_task_outlined,
                      label: 'Talep Oluştur',
                      onTap: () => context.go('/service-requests/new'),
                    ),
                    _QuickAction(
                      icon: Icons.note_add_outlined,
                      label: 'Teklif Hazırla',
                      onTap: () => context.go('/quotes/new'),
                    ),
                    _QuickAction(
                      icon: Icons.event_available_outlined,
                      label: 'Ziyaret Planla',
                      onTap: () => context.go('/visits/new'),
                    ),
                    _QuickAction(
                      icon: Icons.add_card_outlined,
                      label: 'Fatura Kes',
                      onTap: () => context.go('/invoices/new'),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _greeting() {
    final hour = TimeOfDay.now().hour;
    if (hour < 12) return 'Günaydın';
    if (hour < 18) return 'İyi günler';
    return 'İyi akşamlar';
  }
}

class _MetricPill extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _MetricPill({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.78),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 16),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.textMedium,
            ),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              '${fmt.format(amount)} ₺',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
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
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.18)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 14),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.textMedium,
              ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: total == 0 ? 0 : count / total,
                backgroundColor: color.withValues(alpha: 0.12),
                valueColor: AlwaysStoppedAnimation(color),
                minHeight: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VisitTile extends StatelessWidget {
  final dynamic visit;
  final String customerName;

  const _VisitTile({required this.visit, required this.customerName});

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.primary;
    return InkWell(
      onTap: () => context.go('/visits/${visit.id}/edit'),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('dd').format(visit.scheduledDate),
                    style: const TextStyle(
                      color: AppTheme.primary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    DateFormat('MMM', 'tr').format(visit.scheduledDate),
                    style: const TextStyle(
                      color: AppTheme.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customerName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat(
                      'dd MMMM yyyy, HH:mm',
                      'tr_TR',
                    ).format(visit.scheduledDate),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textMedium,
                    ),
                  ),
                  if (visit.notes != null && visit.notes!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      visit.notes!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textMedium,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            const Icon(Icons.chevron_right, color: AppTheme.textLight),
          ],
        ),
      ),
    );
  }
}

class _RequestTile extends StatelessWidget {
  final String title;
  final String customerName;
  final String status;
  final String statusLabel;
  final VoidCallback onTap;

  const _RequestTile({
    required this.title,
    required this.customerName,
    required this.status,
    required this.statusLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.statusColor(status);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.handyman_outlined, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    customerName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textMedium,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                statusLabel,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineEmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  const _InlineEmptyState({
    required this.icon,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFD),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppTheme.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textMedium,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(onPressed: onAction, child: Text(actionLabel)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 18, color: AppTheme.primary),
      label: Text(label),
      onPressed: onTap,
      backgroundColor: AppTheme.primary.withValues(alpha: 0.08),
      side: BorderSide(color: AppTheme.primary.withValues(alpha: 0.12)),
      labelStyle: const TextStyle(
        color: AppTheme.primary,
        fontWeight: FontWeight.w700,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    );
  }
}
