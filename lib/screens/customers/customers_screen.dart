import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../models/customer.dart';
import '../../providers/customer_provider.dart';
import '../../services/customer_delete_service.dart';
import '../../services/customer_delete_verification_service.dart';
import '../widgets/action_menu_row.dart';
import '../widgets/app_drawer.dart';
import '../widgets/destructive_confirm_dialog.dart';
import 'customer_delete_verification_dialog.dart';

enum _Sort { newest, az, za }

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  _Sort _sort = _Sort.newest;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_handleSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<CustomerProvider>().load(),
    );
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
      _sort = _Sort.newest;
    });
  }

  bool get _hasActiveFilters =>
      _query.isNotEmpty || _sort != _Sort.newest;

  bool _matchesQuery(Customer c) {
    if (_query.isEmpty) return true;
    final haystack = [
      c.companyName,
      c.customerCode ?? '',
      c.contactName ?? '',
      c.phone ?? '',
      c.email ?? '',
      c.taxNumber ?? '',
      c.city ?? '',
    ].join(' ').toLowerCase();
    final tokens = _query
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty);
    return tokens.every(haystack.contains);
  }

  List<Customer> _filtered(List<Customer> items) {
    final list = items.where(_matchesQuery).toList();
    if (_sort == _Sort.az) {
      list.sort((a, b) =>
          a.companyName.toLowerCase().compareTo(b.companyName.toLowerCase()));
    } else if (_sort == _Sort.za) {
      list.sort((a, b) =>
          b.companyName.toLowerCase().compareTo(a.companyName.toLowerCase()));
    }
    return list;
  }

  String _buildDeleteMessage(String companyName, CustomerDeleteImpact impact) {
    final deletionMessage = impact.hasDependencies
        ? '$companyName firmasını silerseniz bu firmaya bağlı ${_dependencyParts(impact).join(', ')} kayıtları da kalıcı olarak silinecek.'
        : '$companyName firma kaydını silmek istediğinizden emin misiniz?';
    return '$deletionMessage Bu işlem geri alınamaz.\n\nDevam ederseniz hesabınızın e-posta adresine 4 haneli doğrulama kodu gönderilecek.';
  }

  List<String> _dependencyParts(CustomerDeleteImpact impact) {
    return [
      if (impact.quoteCount > 0) '${impact.quoteCount} teklif',
      if (impact.invoiceCount > 0) '${impact.invoiceCount} fatura',
      if (impact.serviceRequestCount > 0)
        '${impact.serviceRequestCount} servis talebi',
      if (impact.visitCount > 0) '${impact.visitCount} servis formu',
    ];
  }

  Future<void> _confirmDelete(Customer customer) async {
    final provider = context.read<CustomerProvider>();
    final impact = await provider.inspectDeleteImpact(customer.id);
    if (!mounted) return;

    final confirmed = await showDestructiveConfirmDialog(
      context,
      title: 'Firmayı Sil',
      message: _buildDeleteMessage(customer.companyName, impact),
      confirmLabel: 'Kodu Gönder',
    );
    if (!confirmed || !mounted) return;

    final result = await _requestVerification(customer);
    if (!mounted || result == null) return;

    final message = result.hasDependencies
        ? 'Firma ve bağlı kayıtlar silindi'
        : 'Firma silindi';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<CustomerDeleteImpact?> _requestVerification(Customer customer) async {
    final provider = context.read<CustomerProvider>();
    try {
      return await showCustomerDeleteVerificationDialog(
        context,
        customerId: customer.id,
        companyName: customer.companyName,
        onVerified: (requestId, code) => provider.deleteWithVerification(
          id: customer.id,
          requestId: requestId,
          code: code,
        ),
      );
    } on CustomerDeleteVerificationException catch (error) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
      return null;
    } catch (_) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Doğrulama kodu gönderilemedi')),
      );
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CustomerProvider>();
    final filteredItems = _filtered(provider.items);

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
              message: 'Henüz firma eklenmedi',
              actionLabel: 'Firma Ekle',
              onAction: () => context.go('/customers/new'),
            )
          : RefreshIndicator(
              onRefresh: provider.load,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: filteredItems.length + 1,
                separatorBuilder: (_, index) =>
                    index == 0 ? const SizedBox(height: 12) : const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _FilterBar(
                      searchController: _searchController,
                      totalCount: provider.items.length,
                      filteredCount: filteredItems.length,
                      sort: _sort,
                      hasActiveFilters: _hasActiveFilters,
                      onSortChanged: (v) => setState(() => _sort = v),
                      onClear: _clearFilters,
                      entityLabel: 'firma',
                      searchHint: 'Ad, yetkili, telefon, şehir...',
                    );
                  }
                  final customer = filteredItems[index - 1];
                  return Card(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: () => context.push('/customers/${customer.id}'),
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
                                      if ((customer.customerCode ?? '').isNotEmpty)
                                        _ChipLabel(
                                          label: 'ID ${customer.customerCode!}',
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    [
                                      if ((customer.contactName ?? '').isNotEmpty)
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
                                          if ((customer.taxNumber ?? '').isNotEmpty)
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
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert_rounded),
                              tooltip: 'Firma işlemleri',
                              onSelected: (selected) {
                                if (selected == 'show') {
                                  context.push('/customers/${customer.id}');
                                } else if (selected == 'edit') {
                                  context.go('/customers/${customer.id}/edit');
                                } else if (selected == 'delete') {
                                  _confirmDelete(customer);
                                }
                              },
                              itemBuilder: (_) => const [
                                PopupMenuItem(
                                  value: 'show',
                                  child: ActionMenuRow(
                                    icon: Icons.visibility_outlined,
                                    label: 'Firmayı Göster',
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

// ── Shared filter bar ─────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  final TextEditingController searchController;
  final int totalCount;
  final int filteredCount;
  final _Sort sort;
  final bool hasActiveFilters;
  final ValueChanged<_Sort> onSortChanged;
  final VoidCallback onClear;
  final String entityLabel;
  final String searchHint;

  const _FilterBar({
    required this.searchController,
    required this.totalCount,
    required this.filteredCount,
    required this.sort,
    required this.hasActiveFilters,
    required this.onSortChanged,
    required this.onClear,
    required this.entityLabel,
    required this.searchHint,
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
                    '${filteredCount} sonuç  •  toplam $totalCount $entityLabel',
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
            const SizedBox(height: 10),
            DropdownButtonFormField<_Sort>(
              initialValue: sort,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Sıralama',
                isDense: true,
              ),
              items: const [
                DropdownMenuItem(
                  value: _Sort.newest,
                  child: Text('Yeni eklenen'),
                ),
                DropdownMenuItem(value: _Sort.az, child: Text('A → Z')),
                DropdownMenuItem(value: _Sort.za, child: Text('Z → A')),
              ],
              onChanged: (v) { if (v != null) onSortChanged(v); },
            ),
          ],
        ),
      ),
    );
  }
}

// ── Helper widgets ────────────────────────────────────────────────────────────

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
