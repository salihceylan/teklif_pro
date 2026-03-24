import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/product.dart';
import '../../providers/product_provider.dart';
import '../widgets/app_shell.dart';

class ProductFormScreen extends StatefulWidget {
  final int? productId;
  final String? returnTo;

  const ProductFormScreen({super.key, this.productId, this.returnTo});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _skuCtrl = TextEditingController();
  final _barcodeCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  final _brandCtrl = TextEditingController();
  final _servicePriceCtrl = TextEditingController();
  final _sitePriceCtrl = TextEditingController();
  final _vatRateCtrl = TextEditingController(text: '20');
  final _stockCtrl = TextEditingController(text: '0');
  final _reorderCtrl = TextEditingController(text: '0');
  final _descriptionCtrl = TextEditingController();

  String _productType = 'inventory';
  String _unit = 'Adet';
  bool _trackInventory = true;
  bool _isActive = true;
  bool _saving = false;
  Product? _currentProduct;

  static const _typeOptions = <DropdownMenuItem<String>>[
    DropdownMenuItem(value: 'inventory', child: Text('Stoklu Urun')),
    DropdownMenuItem(value: 'service', child: Text('Hizmet')),
    DropdownMenuItem(value: 'consumable', child: Text('Sarf Malzeme')),
    DropdownMenuItem(value: 'spare_part', child: Text('Yedek Parca')),
  ];

  static const _unitOptions = <String>[
    'Adet',
    'Metre',
    'Kg',
    'Litre',
    'Kutu',
    'Paket',
    'Takim',
    'Saat',
    'Gun',
  ];

  bool get _isEdit => widget.productId != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final provider = context.read<ProductProvider>();
        if (provider.items.isEmpty) {
          await provider.load();
        }
        if (!mounted) return;
        final product = provider.items
            .where((item) => item.id == widget.productId)
            .firstOrNull;
        if (product != null) {
          _bindProduct(product);
        }
      });
    }
  }

  void _bindProduct(Product product) {
    setState(() {
      _currentProduct = product;
      _nameCtrl.text = product.name;
      _skuCtrl.text = product.sku;
      _barcodeCtrl.text = product.barcode ?? '';
      _categoryCtrl.text = product.category ?? '';
      _brandCtrl.text = product.brand ?? '';
      _servicePriceCtrl.text = _formatNumber(product.servicePrice);
      _sitePriceCtrl.text = _formatNumber(product.sitePrice);
      _vatRateCtrl.text = _formatNumber(product.vatRate);
      _stockCtrl.text = _formatNumber(product.stockQuantity);
      _reorderCtrl.text = _formatNumber(product.reorderLevel);
      _descriptionCtrl.text = product.description ?? '';
      _productType = product.productType;
      _unit = product.unit;
      _trackInventory = product.trackInventory;
      _isActive = product.isActive;
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _skuCtrl.dispose();
    _barcodeCtrl.dispose();
    _categoryCtrl.dispose();
    _brandCtrl.dispose();
    _servicePriceCtrl.dispose();
    _sitePriceCtrl.dispose();
    _vatRateCtrl.dispose();
    _stockCtrl.dispose();
    _reorderCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return NumberFormat('0.##', 'en_US').format(value);
  }

  double _parseNumber(TextEditingController controller) {
    return double.tryParse(controller.text.trim().replaceAll(',', '.')) ?? 0;
  }

  String? _trimOrNull(TextEditingController controller) {
    final value = controller.text.trim();
    return value.isEmpty ? null : value;
  }

  String? _validateNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    return double.tryParse(value.trim().replaceAll(',', '.')) == null
        ? 'Gecerli bir sayi girin'
        : null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final data = {
      'name': _nameCtrl.text.trim(),
      'product_type': _productType,
      'sku': _trimOrNull(_skuCtrl),
      'barcode': _trimOrNull(_barcodeCtrl),
      'category': _trimOrNull(_categoryCtrl),
      'brand': _trimOrNull(_brandCtrl),
      'unit': _unit,
      'service_price': _parseNumber(_servicePriceCtrl),
      'site_price': _parseNumber(_sitePriceCtrl),
      'vat_rate': _parseNumber(_vatRateCtrl),
      'track_inventory': _trackInventory,
      'stock_quantity': _trackInventory ? _parseNumber(_stockCtrl) : 0,
      'reorder_level': _trackInventory ? _parseNumber(_reorderCtrl) : 0,
      'description': _trimOrNull(_descriptionCtrl),
      'is_active': _isActive,
    }..removeWhere((key, value) => value == null);

    try {
      final provider = context.read<ProductProvider>();
      if (_isEdit) {
        await provider.update(widget.productId!, data);
      } else {
        await provider.create(data);
      }

      if (mounted) {
        context.go(widget.returnTo ?? '/products');
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(buildErrorSnackBar('Urun kaydedilemedi'));
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Urunu Duzenle' : 'Yeni Urun')),
      body: Form(
        key: _formKey,
        child: AppScrollableBody(
          maxWidth: 1080,
          children: [
            AppPageIntro(
              badge: _currentProduct?.sku ?? 'Urun Yonetimi',
              icon: Icons.inventory_2_outlined,
              title: _isEdit
                  ? 'Urun kaydini guncelleyin'
                  : 'Yeni urun veya hizmet tanimlayin',
              subtitle:
                  'SKU, fiyat, KDV, stok seviyesi ve kritik stok esigi tek bir kayitta toplanir.',
              trailing: _currentProduct == null
                  ? null
                  : _CodeBadge(
                      label: 'Kayit Kodu',
                      value: _currentProduct!.sku,
                    ),
            ),
            const SizedBox(height: 20),
            AppSectionCard(
              icon: Icons.category_outlined,
              title: 'Temel Tanim',
              description:
                  'Kayit icin sadece urun adi zorunlu. Diger alanlari ihtiyaca gore doldurabilirsiniz.',
              children: [
                AdaptiveFieldRow(
                  maxColumns: 2,
                  minItemWidth: 260,
                  children: [
                    TextFormField(
                      controller: _nameCtrl,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Urun / Hizmet Adi',
                        prefixIcon: Icon(Icons.inventory_2_outlined),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Urun adi zorunlu'
                          : null,
                    ),
                    DropdownButtonFormField<String>(
                      key: ValueKey(_productType),
                      initialValue: _productType,
                      decoration: const InputDecoration(
                        labelText: 'Urun Tipi',
                        prefixIcon: Icon(Icons.widgets_outlined),
                      ),
                      items: _typeOptions,
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _productType = value;
                          if (value == 'service') {
                            _trackInventory = false;
                            _unit = _unit == 'Adet' ? 'Saat' : _unit;
                          }
                        });
                      },
                    ),
                  ],
                ),
                AdaptiveFieldRow(
                  maxColumns: 2,
                  minItemWidth: 260,
                  children: [
                    TextFormField(
                      controller: _categoryCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Kategori',
                        prefixIcon: Icon(Icons.segment_outlined),
                      ),
                    ),
                    TextFormField(
                      controller: _brandCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Marka / Seri',
                        prefixIcon: Icon(Icons.branding_watermark_outlined),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            AppSectionCard(
              icon: Icons.qr_code_2_outlined,
              title: 'Kodlama ve Birim',
              description:
                  'Resmi stok kodu ve barkod alanlari opsiyoneldir. SKU bos birakilirsa otomatik uretilir.',
              children: [
                AdaptiveFieldRow(
                  maxColumns: 3,
                  minItemWidth: 220,
                  children: [
                    TextFormField(
                      controller: _skuCtrl,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'SKU / Stok Kodu',
                        hintText: 'Bos birakilabilir',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                    ),
                    TextFormField(
                      controller: _barcodeCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Barkod / GTIN',
                        prefixIcon: Icon(Icons.qr_code_scanner_outlined),
                      ),
                    ),
                    DropdownButtonFormField<String>(
                      key: ValueKey(_unit),
                      initialValue: _unit,
                      decoration: const InputDecoration(
                        labelText: 'Birim',
                        prefixIcon: Icon(Icons.straighten_outlined),
                      ),
                      items: _unitOptions
                          .map(
                            (unit) => DropdownMenuItem(
                              value: unit,
                              child: Text(unit),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _unit = value);
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            AppSectionCard(
              icon: Icons.payments_outlined,
              title: 'Fiyat ve Vergi',
              description:
                  'Servis ve site fiyatlari KDV haric tutulur. Teklif ve servis formu kalemleri servis fiyatini kullanir.',
              children: [
                AdaptiveFieldRow(
                  maxColumns: 3,
                  minItemWidth: 220,
                  children: [
                    TextFormField(
                      controller: _servicePriceCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Servis Fiyati (KDV Haric)',
                        prefixIcon: Icon(Icons.handyman_outlined),
                      ),
                      validator: _validateNumber,
                    ),
                    TextFormField(
                      controller: _sitePriceCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Site Satis Fiyati (KDV Haric)',
                        prefixIcon: Icon(Icons.storefront_outlined),
                      ),
                      validator: _validateNumber,
                    ),
                    TextFormField(
                      controller: _vatRateCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'KDV Orani (%)',
                        prefixIcon: Icon(Icons.percent_outlined),
                      ),
                      validator: _validateNumber,
                    ),
                  ],
                ),
                SwitchListTile.adaptive(
                  value: _isActive,
                  onChanged: (value) => setState(() => _isActive = value),
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Urun aktif olarak kullanilsin'),
                  subtitle: const Text(
                    'Pasif urunler listede gorunur ancak yeni kayitlarda secilmez.',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            AppSectionCard(
              icon: Icons.inventory_outlined,
              title: 'Stok Yonetimi',
              description:
                  'Stoklu urunlerde mevcut miktar ve kritik seviye tutulur. Hizmet kalemlerinde takip kapatabilirsiniz.',
              children: [
                SwitchListTile.adaptive(
                  value: _trackInventory,
                  onChanged: (value) => setState(() => _trackInventory = value),
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Stok takibi acik'),
                  subtitle: const Text(
                    'Aciksa stok miktari ve kritik seviye panellerde takip edilir.',
                  ),
                ),
                if (_trackInventory)
                  AdaptiveFieldRow(
                    maxColumns: 2,
                    minItemWidth: 260,
                    children: [
                      TextFormField(
                        controller: _stockCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Mevcut Stok',
                          prefixIcon: Icon(Icons.inventory_2_outlined),
                        ),
                        validator: _validateNumber,
                      ),
                      TextFormField(
                        controller: _reorderCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Kritik Stok Seviyesi',
                          prefixIcon: Icon(Icons.warning_amber_outlined),
                        ),
                        validator: _validateNumber,
                      ),
                    ],
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F8FC),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFD9E5F0)),
                    ),
                    child: const Text(
                      'Bu kayit stoktan dusulmeyen bir hizmet veya serbest kalem olarak tutulacak.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF607085),
                        height: 1.45,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            AppSectionCard(
              icon: Icons.notes_outlined,
              title: 'Aciklama',
              description:
                  'Teklif kaleminde gorunsun istediginiz teknik notlari veya urun tanimini buraya ekleyin.',
              children: [
                TextFormField(
                  controller: _descriptionCtrl,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Aciklama',
                    alignLabelWithHint: true,
                    prefixIcon: Icon(Icons.edit_note_outlined),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _saving ? null : _submit,
              icon: _saving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      _isEdit
                          ? Icons.save_outlined
                          : Icons.inventory_2_outlined,
                    ),
              label: Text(_isEdit ? 'Urunu Guncelle' : 'Urunu Kaydet'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CodeBadge extends StatelessWidget {
  final String label;
  final String value;

  const _CodeBadge({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.72),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
