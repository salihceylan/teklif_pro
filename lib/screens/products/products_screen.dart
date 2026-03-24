import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../models/product.dart';
import '../../providers/product_provider.dart';
import '../widgets/action_menu_row.dart';
import '../widgets/app_drawer.dart';

enum _ProductSort { newest, name, servicePrice, sitePrice, stock }

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final _money = NumberFormat('#,##0.00', 'tr_TR');
  final _qty = NumberFormat('#,##0.##', 'tr_TR');
  final _searchController = TextEditingController();

  String _query = '';
  String _selectedType = 'all';
  String _selectedStatus = 'all';
  String _selectedCategory = 'all';
  _ProductSort _sort = _ProductSort.newest;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_handleSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<ProductProvider>().load(),
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
    if (next == _query) {
      return;
    }
    setState(() => _query = next);
  }

  void _confirmDelete(Product product) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Ürünü Sil'),
        content: Text(
          '${product.name} ürün kaydını silmek istediğinizden emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
            ),
            onPressed: () async {
              Navigator.pop(context);
              await context.read<ProductProvider>().delete(product.id);
            },
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _query = '';
      _selectedType = 'all';
      _selectedStatus = 'all';
      _selectedCategory = 'all';
      _sort = _ProductSort.newest;
    });
  }

  bool get _hasActiveFilters =>
      _query.isNotEmpty ||
      _selectedType != 'all' ||
      _selectedStatus != 'all' ||
      _selectedCategory != 'all' ||
      _sort != _ProductSort.newest;

  int get _activeFilterCount {
    var count = 0;
    if (_query.isNotEmpty) count++;
    if (_selectedType != 'all') count++;
    if (_selectedStatus != 'all') count++;
    if (_selectedCategory != 'all') count++;
    if (_sort != _ProductSort.newest) count++;
    return count;
  }

  List<String> _categories(List<Product> items) {
    final values = items
        .map((item) => item.category?.trim() ?? '')
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return values;
  }

  bool _matchesQuery(Product product) {
    if (_query.isEmpty) {
      return true;
    }

    final haystack = [
      product.name,
      product.sku,
      product.barcode ?? '',
      product.category ?? '',
      product.brand ?? '',
      product.description ?? '',
      product.typeLabel,
    ].join(' ').toLowerCase();

    final tokens = _query
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((token) => token.isNotEmpty);

    return tokens.every(haystack.contains);
  }

  List<Product> _filteredProducts(List<Product> items) {
    final filtered = items.where((product) {
      if (!_matchesQuery(product)) {
        return false;
      }

      if (_selectedType != 'all' && product.productType != _selectedType) {
        return false;
      }

      if (_selectedCategory != 'all' &&
          (product.category?.trim() ?? '') != _selectedCategory) {
        return false;
      }

      if (_selectedStatus == 'active' && !product.isActive) {
        return false;
      }

      if (_selectedStatus == 'inactive' && product.isActive) {
        return false;
      }

      if (_selectedStatus == 'low_stock' && !product.isLowStock) {
        return false;
      }

      if (_selectedStatus == 'tracked' && !product.trackInventory) {
        return false;
      }

      return true;
    }).toList();

    if (_sort == _ProductSort.newest) {
      filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } else if (_sort == _ProductSort.name) {
      filtered.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
    } else if (_sort == _ProductSort.servicePrice) {
      filtered.sort((a, b) => b.servicePriceUsd.compareTo(a.servicePriceUsd));
    } else if (_sort == _ProductSort.sitePrice) {
      filtered.sort((a, b) => b.sitePriceUsd.compareTo(a.sitePriceUsd));
    } else {
      filtered.sort((a, b) => b.stockQuantity.compareTo(a.stockQuantity));
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductProvider>();
    final categories = _categories(provider.items);
    final filteredItems = _filteredProducts(provider.items);

    return Scaffold(
      appBar: AppBar(title: const Text('Ürünler')),
      drawer: const AppDrawer(currentRoute: '/products'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/products/new'),
        icon: const Icon(Icons.inventory_2_outlined),
        label: const Text('Yeni Ürün'),
      ),
      body: provider.loading
          ? const Center(child: CircularProgressIndicator())
          : provider.items.isEmpty
          ? _EmptyState(
              icon: Icons.inventory_2_outlined,
              message: 'Henüz ürün eklenmedi',
              actionLabel: 'Ürün Ekle',
              onAction: () => context.go('/products/new'),
            )
          : RefreshIndicator(
              onRefresh: provider.load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  _FilterCard(
                    searchController: _searchController,
                    totalCount: provider.items.length,
                    filteredCount: filteredItems.length,
                    selectedType: _selectedType,
                    selectedStatus: _selectedStatus,
                    selectedCategory: _selectedCategory,
                    sort: _sort,
                    categories: categories,
                    activeFilterCount: _activeFilterCount,
                    hasActiveFilters: _hasActiveFilters,
                    onTypeChanged: (value) =>
                        setState(() => _selectedType = value),
                    onStatusChanged: (value) =>
                        setState(() => _selectedStatus = value),
                    onCategoryChanged: (value) =>
                        setState(() => _selectedCategory = value),
                    onSortChanged: (value) => setState(() => _sort = value),
                    onClear: _clearFilters,
                  ),
                  const SizedBox(height: 14),
                  if (filteredItems.isEmpty)
                    _FilteredEmptyState(
                      hasActiveFilters: _hasActiveFilters,
                      onClear: _clearFilters,
                    )
                  else
                    ...List.generate(filteredItems.length, (index) {
                      final product = filteredItems[index];
                      final color = _typeColor(product.productType);
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: index == filteredItems.length - 1 ? 88 : 10,
                        ),
                        child: Card(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(24),
                            onTap: () => context.push('/products/${product.id}'),
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
                                      _typeIcon(product.productType),
                                      color: color,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          crossAxisAlignment:
                                              WrapCrossAlignment.center,
                                          children: [
                                            Text(
                                              product.name,
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w700,
                                                color: AppTheme.textDark,
                                              ),
                                            ),
                                            _ChipLabel(label: product.sku),
                                            if ((product.category ?? '')
                                                .isNotEmpty)
                                              _ChipLabel(
                                                label: product.category!,
                                                color: const Color(0xFF0F766E),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          [
                                            product.typeLabel,
                                            if ((product.brand ?? '').isNotEmpty)
                                              product.brand!,
                                            'Birim: ${product.unit}',
                                          ].join(' • '),
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppTheme.textMedium,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Wrap(
                                          spacing: 10,
                                          runSpacing: 6,
                                          children: [
                                            _meta(
                                              Icons.payments_outlined,
                                              'Servis: ${_money.format(product.servicePriceUsd)} USD',
                                            ),
                                            _meta(
                                              Icons.storefront_outlined,
                                              'Site: ${_money.format(product.sitePriceUsd)} USD',
                                            ),
                                            _meta(
                                              Icons.percent_outlined,
                                              'KDV %${_qty.format(product.vatRate)}',
                                            ),
                                            if (product.trackInventory)
                                              _meta(
                                                product.isLowStock
                                                    ? Icons.warning_amber_outlined
                                                    : Icons.inventory_outlined,
                                                'Stok: ${_qty.format(product.stockQuantity)}',
                                                color: product.isLowStock
                                                    ? const Color(0xFFEF4444)
                                                    : AppTheme.textMedium,
                                              )
                                            else
                                              _meta(
                                                Icons.inventory_2_outlined,
                                                'Stok takibi kapalı',
                                              ),
                                          ],
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
                                        tooltip: 'Ürün işlemleri',
                                        onSelected: (selected) {
                                          if (selected == 'show') {
                                            context.push(
                                              '/products/${product.id}',
                                            );
                                          } else if (selected == 'edit') {
                                            context.go(
                                              '/products/${product.id}/edit',
                                            );
                                          } else if (selected == 'delete') {
                                            _confirmDelete(product);
                                          }
                                        },
                                        itemBuilder: (_) => const [
                                          PopupMenuItem(
                                            value: 'show',
                                            child: ActionMenuRow(
                                              icon: Icons.visibility_outlined,
                                              label: 'Ürünü Göster',
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
                                      _StatusBadge(
                                        label: product.isActive
                                            ? 'Aktif'
                                            : 'Pasif',
                                        color: product.isActive
                                            ? AppTheme.success
                                            : AppTheme.textLight,
                                      ),
                                      if (product.isLowStock) ...[
                                        const SizedBox(height: 8),
                                        const _StatusBadge(
                                          label: 'Kritik Stok',
                                          color: Color(0xFFEF4444),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
    );
  }

  Widget _meta(IconData icon, String text, {Color? color}) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 14, color: color ?? AppTheme.textLight),
      const SizedBox(width: 4),
      Text(
        text,
        style: TextStyle(fontSize: 12, color: color ?? AppTheme.textMedium),
      ),
    ],
  );

  IconData _typeIcon(String type) => switch (type) {
    'service' => Icons.design_services_outlined,
    'consumable' => Icons.medical_services_outlined,
    'spare_part' => Icons.settings_input_component_outlined,
    _ => Icons.inventory_2_outlined,
  };

  Color _typeColor(String type) => switch (type) {
    'service' => const Color(0xFF1F7A8C),
    'consumable' => const Color(0xFF0F766E),
    'spare_part' => const Color(0xFFF59E0B),
    _ => AppTheme.primary,
  };
}

class _FilterCard extends StatelessWidget {
  final TextEditingController searchController;
  final int totalCount;
  final int filteredCount;
  final String selectedType;
  final String selectedStatus;
  final String selectedCategory;
  final _ProductSort sort;
  final List<String> categories;
  final int activeFilterCount;
  final bool hasActiveFilters;
  final ValueChanged<String> onTypeChanged;
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<_ProductSort> onSortChanged;
  final VoidCallback onClear;

  const _FilterCard({
    required this.searchController,
    required this.totalCount,
    required this.filteredCount,
    required this.selectedType,
    required this.selectedStatus,
    required this.selectedCategory,
    required this.sort,
    required this.categories,
    required this.activeFilterCount,
    required this.hasActiveFilters,
    required this.onTypeChanged,
    required this.onStatusChanged,
    required this.onCategoryChanged,
    required this.onSortChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final summaryColor = filteredCount == 0
        ? AppTheme.danger
        : AppTheme.textMedium;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Ürün Bul',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textDark,
                    ),
                  ),
                ),
                if (hasActiveFilters)
                  _ChipLabel(
                    label: '$activeFilterCount aktif filtre',
                    color: const Color(0xFF0F766E),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '$filteredCount sonuç gösteriliyor • toplam $totalCount ürün',
              style: TextStyle(fontSize: 13, color: summaryColor),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: searchController,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                labelText: 'Ürün ara',
                hintText: 'Ad, SKU, kategori, marka veya açıklama',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: searchController.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: onClear,
                        icon: const Icon(Icons.close_rounded),
                        tooltip: 'Filtreleri temizle',
                      ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Ürün Türü',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.textMedium,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _FilterChipButton(
                  label: 'Tümü',
                  selected: selectedType == 'all',
                  onSelected: () => onTypeChanged('all'),
                ),
                _FilterChipButton(
                  label: 'Stoklu Ürün',
                  selected: selectedType == 'inventory',
                  onSelected: () => onTypeChanged('inventory'),
                ),
                _FilterChipButton(
                  label: 'Hizmet',
                  selected: selectedType == 'service',
                  onSelected: () => onTypeChanged('service'),
                ),
                _FilterChipButton(
                  label: 'Sarf Malzeme',
                  selected: selectedType == 'consumable',
                  onSelected: () => onTypeChanged('consumable'),
                ),
                _FilterChipButton(
                  label: 'Yedek Parça',
                  selected: selectedType == 'spare_part',
                  onSelected: () => onTypeChanged('spare_part'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 760;
                final categoryItems = [
                  const DropdownMenuItem<String>(
                    value: 'all',
                    child: Text('Tüm kategoriler'),
                  ),
                  ...categories.map(
                    (category) => DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    ),
                  ),
                ];

                final statusItems = const [
                  DropdownMenuItem<String>(
                    value: 'all',
                    child: Text('Tüm durumlar'),
                  ),
                  DropdownMenuItem<String>(
                    value: 'active',
                    child: Text('Sadece aktif'),
                  ),
                  DropdownMenuItem<String>(
                    value: 'inactive',
                    child: Text('Sadece pasif'),
                  ),
                  DropdownMenuItem<String>(
                    value: 'low_stock',
                    child: Text('Kritik stok'),
                  ),
                  DropdownMenuItem<String>(
                    value: 'tracked',
                    child: Text('Stok takibi açık'),
                  ),
                ];

                final sortItems = const [
                  DropdownMenuItem<_ProductSort>(
                    value: _ProductSort.newest,
                    child: Text('Sıralama: Yeni eklenen'),
                  ),
                  DropdownMenuItem<_ProductSort>(
                    value: _ProductSort.name,
                    child: Text('Sıralama: Ada göre'),
                  ),
                  DropdownMenuItem<_ProductSort>(
                    value: _ProductSort.servicePrice,
                    child: Text('Sıralama: Servis fiyatı'),
                  ),
                  DropdownMenuItem<_ProductSort>(
                    value: _ProductSort.sitePrice,
                    child: Text('Sıralama: Site fiyatı'),
                  ),
                  DropdownMenuItem<_ProductSort>(
                    value: _ProductSort.stock,
                    child: Text('Sıralama: Stok miktarı'),
                  ),
                ];

                final fields = [
                  _FilterDropdown(
                    label: 'Kategori',
                    value: selectedCategory,
                    items: categoryItems,
                    onChanged: onCategoryChanged,
                  ),
                  _FilterDropdown(
                    label: 'Durum',
                    value: selectedStatus,
                    items: statusItems,
                    onChanged: onStatusChanged,
                  ),
                  _FilterDropdown<_ProductSort>(
                    label: 'Sıralama',
                    value: sort,
                    items: sortItems,
                    onChanged: onSortChanged,
                  ),
                ];

                if (compact) {
                  return Column(
                    children: [
                      for (var i = 0; i < fields.length; i++) ...[
                        fields[i],
                        if (i != fields.length - 1) const SizedBox(height: 12),
                      ],
                    ],
                  );
                }

                return Row(
                  children: [
                    for (var i = 0; i < fields.length; i++) ...[
                      Expanded(child: fields[i]),
                      if (i != fields.length - 1) const SizedBox(width: 12),
                    ],
                  ],
                );
              },
            ),
            if (hasActiveFilters) ...[
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onClear,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Filtreleri Temizle'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FilterDropdown<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T> onChanged;

  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: items,
      onChanged: (value) {
        if (value != null) {
          onChanged(value);
        }
      },
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const _FilterChipButton({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      showCheckmark: false,
      selectedColor: AppTheme.primary.withValues(alpha: 0.12),
      backgroundColor: const Color(0xFFF8FBFD),
      side: BorderSide(
        color: selected
            ? AppTheme.primary.withValues(alpha: 0.3)
            : AppTheme.border,
      ),
      labelStyle: TextStyle(
        color: selected ? AppTheme.primary : AppTheme.textMedium,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _ChipLabel extends StatelessWidget {
  final String label;
  final Color? color;

  const _ChipLabel({required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final accent = color ?? AppTheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: accent,
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

class _FilteredEmptyState extends StatelessWidget {
  final bool hasActiveFilters;
  final VoidCallback onClear;

  const _FilteredEmptyState({
    required this.hasActiveFilters,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 30,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Filtrelerle eşleşen ürün bulunamadı',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasActiveFilters
                  ? 'Arama metnini veya seçili filtreleri değiştirerek tekrar deneyin.'
                  : 'Henüz gösterilecek ürün bulunmuyor.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textMedium,
              ),
            ),
            if (hasActiveFilters) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onClear,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Filtreleri Temizle'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
