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
              supporting: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppIntroSectionLabel(
                    label: 'Anlık Durum',
                    icon: Icons.insights_outlined,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      AppIntroStatCard(
                        label: 'Müşteri',
                        value: '${customers.length}',
                        icon: Icons.people_alt_outlined,
                      ),
                      AppIntroStatCard(
                        label: 'Aktif Talep',
                        value: '$openRequests',
                        icon: Icons.build_circle_outlined,
                      ),
                      AppIntroStatCard(
                        label: 'Bekleyen Teklif',
                        value: '$pendingQuotes',
                        icon: Icons.request_quote_outlined,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            AppSectionCard(
              icon: Icons.rocket_launch_outlined,
              title: 'Hızlı Başlangıç',
              description:
                  'En sık kullanılan üç kayıt akışını tek dokunuşla başlatın.',
              children: [
                AdaptiveFieldRow(
                  maxColumns: 3,
                  minItemWidth: 230,
                  children: [
                    _LaunchPadCard(
                      icon: Icons.add_business_outlined,
                      title: 'Şirket Ekle',
                      description:
                          'Sadece şirket ünvanı ile hızlı kayıt açın, diğer bilgileri sonra düzenleyin.',
                      buttonLabel: 'Yeni Firma',
                      color: AppTheme.primary,
                      onTap: () => context.go('/customers/new'),
                    ),
                    _LaunchPadCard(
                      icon: Icons.request_quote_outlined,
                      title: 'Teklif Hazırla',
                      description:
                          'Kalemler, KDV, belge numarası ve çıktıyı tek formda yönetin.',
                      buttonLabel: 'Teklif Oluştur',
                      color: const Color(0xFF1F7A8C),
                      onTap: () => context.go('/quotes/new'),
                    ),
                    _LaunchPadCard(
                      icon: Icons.build_circle_outlined,
                      title: 'Servis Formu Hazırla',
                      description:
                          'Servis kaydı, malzeme ve işçilik toplamlarını tek ekranda toplayın.',
                      buttonLabel: 'Servis Formu',
                      color: const Color(0xFF0F766E),
                      onTap: () => context.go('/visits/new'),
                    ),
                  ],
                ),
              ],
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
                  _ActivityEmptyCard(
                    icon: Icons.event_busy_outlined,
                    message: 'Bu hafta planlanmış ziyaret yok.',
                    actionLabel: 'Ziyaret Ekle',
                    onAction: () => context.go('/visits/new'),
                  )
                else
                  AdaptiveFieldRow(
                    maxColumns: 2,
                    minItemWidth: 250,
                    children: [
                      for (final visit in upcomingVisits.take(4))
                        _VisitOverviewCard(
                          visit: visit,
                          customerName:
                              customers
                                  .where(
                                    (customer) =>
                                        customer.id == visit.customerId,
                                  )
                                  .firstOrNull
                                  ?.fullName ??
                              'Müşteri #${visit.customerId}',
                        ),
                    ],
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
                  _ActivityEmptyCard(
                    icon: Icons.build_outlined,
                    message: 'Henüz servis talebi bulunmuyor.',
                    actionLabel: 'Talep Ekle',
                    onAction: () => context.go('/service-requests/new'),
                  )
                else
                  AdaptiveFieldRow(
                    maxColumns: 2,
                    minItemWidth: 250,
                    children: [
                      for (final request in recentRequests.take(4))
                        _RequestOverviewCard(
                          title: request.title,
                          customerName:
                              customers
                                  .where(
                                    (customer) =>
                                        customer.id == request.customerId,
                                  )
                                  .firstOrNull
                                  ?.fullName ??
                              'Müşteri #${request.customerId}',
                          status: request.status,
                          statusLabel: request.statusLabel,
                          createdAt: request.createdAt,
                          onTap: () =>
                              context.push('/service-requests/${request.id}'),
                        ),
                    ],
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
                      icon: Icons.inventory_2_outlined,
                      label: 'Ürün Ekle',
                      onTap: () => context.go('/products/new'),
                    ),
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

class _VisitOverviewCard extends StatelessWidget {
  final dynamic visit;
  final String customerName;

  const _VisitOverviewCard({required this.visit, required this.customerName});

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.primary;
    final dateText = DateFormat('dd MMM', 'tr_TR').format(visit.scheduledDate);
    final timeText = DateFormat('HH:mm', 'tr_TR').format(visit.scheduledDate);

    return InkWell(
      onTap: () => context.push('/visits/${visit.id}'),
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
              child: Icon(
                Icons.event_available_outlined,
                color: color,
                size: 22,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              dateText,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              customerName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Saat $timeText',
              style: const TextStyle(fontSize: 12, color: AppTheme.textMedium),
            ),
            if (visit.notes != null && visit.notes!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                visit.notes!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textMedium,
                  height: 1.4,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RequestOverviewCard extends StatelessWidget {
  final String title;
  final String customerName;
  final String status;
  final String statusLabel;
  final DateTime createdAt;
  final VoidCallback onTap;

  const _RequestOverviewCard({
    required this.title,
    required this.customerName,
    required this.status,
    required this.statusLabel,
    required this.createdAt,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.statusColor(status);

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
              child: Icon(Icons.handyman_outlined, color: color, size: 22),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppTheme.textDark,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              customerName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: AppTheme.textMedium),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
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
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    DateFormat('dd.MM.yyyy', 'tr_TR').format(createdAt),
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textMedium,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityEmptyCard extends StatelessWidget {
  final IconData icon;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  const _ActivityEmptyCard({
    required this.icon,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.primary;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.16)),
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
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 14),
          Text(
            message,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.textMedium,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.tonalIcon(
            onPressed: onAction,
            icon: const Icon(Icons.arrow_forward_outlined, size: 18),
            label: Text(actionLabel),
            style: FilledButton.styleFrom(
              foregroundColor: color,
              backgroundColor: color.withValues(alpha: 0.12),
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
    return AppActionPill(icon: icon, label: label, onTap: onTap);
  }
}

class _LaunchPadCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String buttonLabel;
  final Color color;
  final VoidCallback onTap;

  const _LaunchPadCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.buttonLabel,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: color.withValues(alpha: 0.16)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textMedium,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.tonalIcon(
              onPressed: onTap,
              icon: const Icon(Icons.arrow_forward_outlined, size: 18),
              label: Text(buttonLabel),
              style: FilledButton.styleFrom(
                foregroundColor: color,
                backgroundColor: color.withValues(alpha: 0.12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
