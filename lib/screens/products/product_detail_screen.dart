import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../models/product.dart';
import '../../providers/product_provider.dart';
import '../widgets/action_menu_row.dart';
import '../widgets/app_shell.dart';

class ProductDetailScreen extends StatefulWidget {
  final int productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final _money = NumberFormat('#,##0.00', 'tr_TR');
  final _qty = NumberFormat('#,##0.##', 'tr_TR');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<ProductProvider>();
      if (provider.items.isEmpty) {
        await provider.load();
      }
    });
  }

  Product? _product(ProductProvider provider) =>
      provider.items.where((item) => item.id == widget.productId).firstOrNull;

  void _goBack() {
    if (Navigator.of(context).canPop()) {
      context.pop();
    } else {
      context.go('/products');
    }
  }

  Future<void> _handleMenuAction(String value, Product product) async {
    if (value == 'edit') {
      context.push('/products/${product.id}/edit');
    } else if (value == 'delete') {
      await context.read<ProductProvider>().delete(product.id);
      if (mounted) {
        _goBack();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductProvider>();
    final product = _product(provider);

    if (provider.loading && product == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (product == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: _goBack,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          title: const Text('Ürün Bulunamadı'),
        ),
        body: const Center(
          child: Text(
            'Ürün kaydı bulunamadı',
            style: TextStyle(color: AppTheme.textMedium),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: _goBack,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(product.name),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(value, product),
            itemBuilder: (_) => const [
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
      body: AppScrollableBody(
        maxWidth: 1080,
        children: [
          AppPageIntro(
            badge: product.sku,
            icon: Icons.inventory_2_outlined,
            title: product.name,
            subtitle:
                '${product.typeLabel} • ${product.category ?? 'Kategori belirtilmedi'}',
            trailing: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HeroBadge(
                  label: product.isActive ? 'Aktif Kayıt' : 'Pasif Kayıt',
                ),
                const SizedBox(height: 10),
                if (product.trackInventory)
                  _HeroBadge(
                    label: product.isLowStock
                        ? 'Kritik Stok'
                        : 'Stok: ${_qty.format(product.stockQuantity)} ${product.unit}',
                  )
                else
                  const _HeroBadge(label: 'Stok Takibi Kapalı'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          AppSectionCard(
            icon: Icons.category_outlined,
            title: 'Temel Bilgiler',
            children: [
              AdaptiveFieldRow(
                maxColumns: 3,
                minItemWidth: 220,
                children: [
                  _InfoPanel(label: 'SKU', value: product.sku),
                  _InfoPanel(label: 'Ürün Tipi', value: product.typeLabel),
                  _InfoPanel(label: 'Birim', value: product.unit),
                  _InfoPanel(label: 'Kategori', value: product.category ?? '-'),
                  _InfoPanel(label: 'Marka', value: product.brand ?? '-'),
                  _InfoPanel(label: 'Barkod', value: product.barcode ?? '-'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          AppSectionCard(
            icon: Icons.payments_outlined,
            title: 'Fiyatlandirma',
            children: [
              AdaptiveFieldRow(
                maxColumns: 3,
                minItemWidth: 220,
                children: [
                  _InfoPanel(
                    label: 'Servis Fiyatı (USD, KDV Hariç)',
                    value: '${_money.format(product.servicePriceUsd)} USD',
                  ),
                  _InfoPanel(
                    label: 'Site Satış Fiyatı (USD, KDV Hariç)',
                    value: '${_money.format(product.sitePriceUsd)} USD',
                  ),
                  _InfoPanel(
                    label: 'KDV Oranı',
                    value: '%${_qty.format(product.vatRate)}',
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          AppSectionCard(
            icon: Icons.inventory_outlined,
            title: 'Stok Durumu',
            children: [
              AdaptiveFieldRow(
                maxColumns: 3,
                minItemWidth: 220,
                children: [
                  _InfoPanel(
                    label: 'Stok Takibi',
                    value: product.trackInventory ? 'Açık' : 'Kapalı',
                  ),
                  _InfoPanel(
                    label: 'Mevcut Stok',
                    value: product.trackInventory
                        ? '${_qty.format(product.stockQuantity)} ${product.unit}'
                        : '-',
                  ),
                  _InfoPanel(
                    label: 'Kritik Seviye',
                    value: product.trackInventory
                        ? '${_qty.format(product.reorderLevel)} ${product.unit}'
                        : '-',
                  ),
                ],
              ),
            ],
          ),
          if ((product.description ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 20),
            AppSectionCard(
              icon: Icons.notes_outlined,
              title: 'Açıklama',
              children: [_DetailLine('Ürün Açıklaması', product.description)],
            ),
          ],
        ],
      ),
    );
  }
}

class _HeroBadge extends StatelessWidget {
  final String label;

  const _HeroBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _InfoPanel extends StatelessWidget {
  final String label;
  final String value;

  const _InfoPanel({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFD),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD8E3EE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textMedium,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textDark,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  final String label;
  final String? value;

  const _DetailLine(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final text = (value ?? '').trim();
    if (text.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFD),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD8E3EE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textMedium,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textDark,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
