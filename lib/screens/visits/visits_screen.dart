import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../models/visit.dart' show ServiceVisit;
import '../../providers/customer_provider.dart';
import '../../providers/visit_provider.dart';
import '../widgets/action_menu_row.dart';
import '../widgets/app_drawer.dart';
import '../widgets/destructive_confirm_dialog.dart';

class VisitsScreen extends StatefulWidget {
  const VisitsScreen({super.key});

  @override
  State<VisitsScreen> createState() => _VisitsScreenState();
}

class _VisitsScreenState extends State<VisitsScreen> {
  final _date = DateFormat('dd.MM.yyyy HH:mm', 'tr_TR');
  final _currency = NumberFormat('#,##0.00', 'tr_TR');
  final _searchController = TextEditingController();
  String _query = '';
  String _status = 'all';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_handleSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VisitProvider>().load();
      context.read<CustomerProvider>().load();
    });
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_handleSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _handleSearchChanged() {
    final next = _searchController.text.trim();
    if (next == _query) return;
    setState(() => _query = next);
  }

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _query = '';
      _status = 'all';
    });
  }

  bool get _hasActiveFilters => _query.isNotEmpty || _status != 'all';

  bool _matchesQuery(ServiceVisit v) {
    if (_query.isEmpty) return true;
    final haystack = [
      v.customerCompanyName ?? '',
      v.serviceCode ?? '',
      v.complaint ?? '',
    ].join(' ').toLowerCase();
    final tokens = _query.toLowerCase().split(RegExp(r'\s+')).where((t) => t.isNotEmpty);
    return tokens.every(haystack.contains);
  }

  List<ServiceVisit> _filtered(List<ServiceVisit> items) {
    return items.where((v) {
      if (_status != 'all' && v.status != _status) return false;
      if (!_matchesQuery(v)) return false;
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final visits = context.watch<VisitProvider>();
    final filteredItems = _filtered(visits.items);

    return Scaffold(
      appBar: AppBar(title: const Text('Servis Formları')),
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
              message: 'Henüz servis formu oluşturulmadı',
              actionLabel: 'Form Ekle',
              onAction: () => context.go('/visits/new'),
            )
          : RefreshIndicator(
              onRefresh: visits.load,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: filteredItems.length + 1,
                separatorBuilder: (_, index) =>
                    index == 0 ? const SizedBox(height: 12) : const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _FilterBar(
                      searchController: _searchController,
                      totalCount: visits.items.length,
                      filteredCount: filteredItems.length,
                      selectedStatus: _status,
                      hasActiveFilters: _hasActiveFilters,
                      onStatusChanged: (v) => setState(() => _status = v),
                      onClear: _clearFilters,
                      entityLabel: 'servis formu',
                      searchHint: 'Firma, kod veya şikayet...',
                      statusOptions: const [
                        ('all', 'Tümü'),
                        ('scheduled', 'Planlandı'),
                        ('in_progress', 'Devam Ediyor'),
                        ('completed', 'Tamamlandı'),
                        ('cancelled', 'İptal'),
                      ],
                    );
                  }
                  final visit = filteredItems[index - 1];
                  final color = AppTheme.statusColor(visit.status);

                  return Card(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => context.push('/visits/${visit.id}'),
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
                              child: Icon(Icons.assignment_turned_in_outlined, color: color),
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
                                        visit.customerCompanyName ?? 'Servis Formu',
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
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert_rounded),
                                  tooltip: 'Servis formu işlemleri',
                                  onSelected: (selected) async {
                                    if (selected == 'show') {
                                      context.push('/visits/${visit.id}');
                                    } else if (selected == 'edit') {
                                      context.go('/visits/${visit.id}/edit');
                                    } else if (selected == 'delete') {
                                      final confirmed = await showDestructiveConfirmDialog(
                                        context,
                                        title: 'Servis Formunu Sil',
                                        message:
                                            '${visit.serviceCode ?? 'Bu'} servis formunu silmek istediğinizden emin misiniz?',
                                      );
                                      if (!confirmed || !context.mounted) return;
                                      await context.read<VisitProvider>().delete(visit.id);
                                    }
                                  },
                                  itemBuilder: (_) => const [
                                    PopupMenuItem(
                                      value: 'show',
                                      child: ActionMenuRow(
                                        icon: Icons.visibility_outlined,
                                        label: 'Servis Formunu Göster',
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'edit',
                                      child: ActionMenuRow(
                                        icon: Icons.edit_outlined,
                                        label: 'Düzenle',
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
                                ),
                                _StatusBadge(label: visit.statusLabel, color: color),
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
}

// ── Filter bar ────────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  final TextEditingController searchController;
  final int totalCount;
  final int filteredCount;
  final String selectedStatus;
  final bool hasActiveFilters;
  final ValueChanged<String> onStatusChanged;
  final VoidCallback onClear;
  final String entityLabel;
  final String searchHint;
  final List<(String, String)> statusOptions;

  const _FilterBar({
    required this.searchController,
    required this.totalCount,
    required this.filteredCount,
    required this.selectedStatus,
    required this.hasActiveFilters,
    required this.onStatusChanged,
    required this.onClear,
    required this.entityLabel,
    required this.searchHint,
    required this.statusOptions,
  });

  @override
  Widget build(BuildContext context) {
    final summaryColor =
        filteredCount == 0 ? AppTheme.danger : AppTheme.textMedium;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '$filteredCount sonuç  •  toplam $totalCount $entityLabel',
                    style: TextStyle(fontSize: 13, color: summaryColor),
                  ),
                ),
                if (hasActiveFilters)
                  TextButton.icon(
                    onPressed: onClear,
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Temizle'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.textMedium,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: searchController,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: searchHint,
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: searchController.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: onClear,
                        icon: const Icon(Icons.close_rounded),
                      ),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (value, label) in statusOptions)
                  _FilterChip(
                    label: label,
                    selected: selectedStatus == value,
                    onTap: () => onStatusChanged(value),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? color : color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? color : color.withValues(alpha: 0.2)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : color,
          ),
        ),
      ),
    );
  }
}

// ── Helper widgets ────────────────────────────────────────────────────────────

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
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
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
          Text(message, style: const TextStyle(color: AppTheme.textMedium, fontSize: 15)),
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
