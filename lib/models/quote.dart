class QuoteItem {
  final int? id;
  final String? productCode;
  final String description;
  final double quantity;
  final String unit;
  final double unitPrice;
  final double vatRate;
  final double totalPrice;

  const QuoteItem({
    this.id,
    this.productCode,
    required this.description,
    required this.quantity,
    required this.unit,
    required this.unitPrice,
    required this.vatRate,
    required this.totalPrice,
  });

  double get subtotal => quantity * unitPrice;
  double get vatAmount => totalPrice - subtotal;

  factory QuoteItem.fromJson(Map<String, dynamic> json) => QuoteItem(
        id: json['id'],
        productCode: json['product_code'],
        description: json['description'],
        quantity: (json['quantity'] as num).toDouble(),
        unit: (json['unit'] ?? 'Adet') as String,
        unitPrice: (json['unit_price'] as num).toDouble(),
        vatRate: ((json['vat_rate'] as num?) ?? 20).toDouble(),
        totalPrice: (json['total_price'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        if (productCode != null && productCode!.isNotEmpty)
          'product_code': productCode,
        'description': description,
        'quantity': quantity,
        'unit': unit,
        'unit_price': unitPrice,
        'vat_rate': vatRate,
      };
}

class Quote {
  final int id;
  final int customerId;
  final int? serviceRequestId;
  final String? quoteCode;
  final String title;
  final String? description;
  final String? customerCompanyName;
  final String? customerContactName;
  final String? customerPhone;
  final String? customerAddress;
  final double subtotal;
  final double vatTotal;
  final double totalAmount;
  final String status;
  final DateTime? issuedAt;
  final DateTime? validUntil;
  final String? deliveryTime;
  final String? paymentTerms;
  final String? termsAndConditions;
  final bool pricesIncludeVat;
  final String? notes;
  final DateTime createdAt;
  final List<QuoteItem> items;

  const Quote({
    required this.id,
    required this.customerId,
    this.serviceRequestId,
    this.quoteCode,
    required this.title,
    this.description,
    this.customerCompanyName,
    this.customerContactName,
    this.customerPhone,
    this.customerAddress,
    required this.subtotal,
    required this.vatTotal,
    required this.totalAmount,
    required this.status,
    this.issuedAt,
    this.validUntil,
    this.deliveryTime,
    this.paymentTerms,
    this.termsAndConditions,
    required this.pricesIncludeVat,
    this.notes,
    required this.createdAt,
    required this.items,
  });

  factory Quote.fromJson(Map<String, dynamic> json) => Quote(
        id: json['id'],
        customerId: json['customer_id'],
        serviceRequestId: json['service_request_id'],
        quoteCode: json['quote_code'],
        title: json['title'],
        description: json['description'],
        customerCompanyName: json['customer_company_name'],
        customerContactName: json['customer_contact_name'],
        customerPhone: json['customer_phone'],
        customerAddress: json['customer_address'],
        subtotal: ((json['subtotal'] as num?) ?? json['total_amount']).toDouble(),
        vatTotal: ((json['vat_total'] as num?) ?? 0).toDouble(),
        totalAmount: (json['total_amount'] as num).toDouble(),
        status: json['status'],
        issuedAt: json['issued_at'] != null
            ? DateTime.parse(json['issued_at'])
            : null,
        validUntil: json['valid_until'] != null
            ? DateTime.parse(json['valid_until'])
            : null,
        deliveryTime: json['delivery_time'],
        paymentTerms: json['payment_terms'],
        termsAndConditions: json['terms_and_conditions'],
        pricesIncludeVat: json['prices_include_vat'] ?? true,
        notes: json['notes'],
        createdAt: DateTime.parse(json['created_at']),
        items: (json['items'] as List? ?? [])
            .map((e) => QuoteItem.fromJson(e))
            .toList(),
      );

  static const Map<String, String> statusLabels = {
    'draft': 'Taslak',
    'sent': 'Gonderildi',
    'accepted': 'Kabul Edildi',
    'rejected': 'Reddedildi',
    'expired': 'Suresi Doldu',
  };

  String get statusLabel => statusLabels[status] ?? status;
}
