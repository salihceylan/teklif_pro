class Product {
  final int id;
  final String name;
  final String productType;
  final String sku;
  final String? barcode;
  final String? category;
  final String? brand;
  final String unit;
  final double servicePriceUsd;
  final double sitePriceUsd;
  final String priceCurrency;
  final double vatRate;
  final bool trackInventory;
  final double stockQuantity;
  final double reorderLevel;
  final String? description;
  final bool isActive;
  final DateTime createdAt;

  const Product({
    required this.id,
    required this.name,
    required this.productType,
    required this.sku,
    this.barcode,
    this.category,
    this.brand,
    required this.unit,
    required this.servicePriceUsd,
    required this.sitePriceUsd,
    required this.priceCurrency,
    required this.vatRate,
    required this.trackInventory,
    required this.stockQuantity,
    required this.reorderLevel,
    this.description,
    required this.isActive,
    required this.createdAt,
  });

  static const Map<String, String> typeLabels = {
    'inventory': 'Stoklu Ürün',
    'service': 'Hizmet',
    'consumable': 'Sarf Malzeme',
    'spare_part': 'Yedek Parça',
  };

  String get typeLabel => typeLabels[productType] ?? productType;

  bool get isLowStock => trackInventory && stockQuantity <= reorderLevel;
  double get servicePrice => servicePriceUsd;
  double get sitePrice => sitePriceUsd;
  bool get isUsdPricing => priceCurrency.toUpperCase() == 'USD';

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    id: json['id'] as int,
    name: (json['name'] ?? '') as String,
    productType: (json['product_type'] ?? 'inventory') as String,
    sku: (json['sku'] ?? '') as String,
    barcode: json['barcode'] as String?,
    category: json['category'] as String?,
    brand: json['brand'] as String?,
    unit: (json['unit'] ?? 'Adet') as String,
    servicePriceUsd:
        ((json['service_price_usd'] as num?) ??
                (json['service_price'] as num?) ??
                0)
            .toDouble(),
    sitePriceUsd:
        ((json['site_price_usd'] as num?) ?? (json['site_price'] as num?) ?? 0)
            .toDouble(),
    priceCurrency: (json['price_currency'] ?? 'USD') as String,
    vatRate: ((json['vat_rate'] as num?) ?? 20).toDouble(),
    trackInventory: (json['track_inventory'] ?? true) as bool,
    stockQuantity: ((json['stock_quantity'] as num?) ?? 0).toDouble(),
    reorderLevel: ((json['reorder_level'] as num?) ?? 0).toDouble(),
    description: json['description'] as String?,
    isActive: (json['is_active'] ?? true) as bool,
    createdAt: DateTime.parse(json['created_at'] as String),
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'product_type': productType,
    if (sku.trim().isNotEmpty) 'sku': sku.trim(),
    if (barcode != null && barcode!.trim().isNotEmpty)
      'barcode': barcode!.trim(),
    if (category != null && category!.trim().isNotEmpty)
      'category': category!.trim(),
    if (brand != null && brand!.trim().isNotEmpty) 'brand': brand!.trim(),
    'unit': unit,
    'service_price_usd': servicePriceUsd,
    'site_price_usd': sitePriceUsd,
    'price_currency': priceCurrency,
    'vat_rate': vatRate,
    'track_inventory': trackInventory,
    'stock_quantity': stockQuantity,
    'reorder_level': reorderLevel,
    if (description != null && description!.trim().isNotEmpty)
      'description': description!.trim(),
    'is_active': isActive,
  };
}
