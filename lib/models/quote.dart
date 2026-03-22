class QuoteItem {
  final int? id;
  final String description;
  final double quantity;
  final double unitPrice;
  final double totalPrice;

  QuoteItem({
    this.id,
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  factory QuoteItem.fromJson(Map<String, dynamic> json) => QuoteItem(
        id: json['id'],
        description: json['description'],
        quantity: (json['quantity'] as num).toDouble(),
        unitPrice: (json['unit_price'] as num).toDouble(),
        totalPrice: (json['total_price'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'description': description,
        'quantity': quantity,
        'unit_price': unitPrice,
      };
}

class Quote {
  final int id;
  final int customerId;
  final int? serviceRequestId;
  final String title;
  final String? description;
  final double totalAmount;
  final String status;
  final DateTime? validUntil;
  final String? notes;
  final DateTime createdAt;
  final List<QuoteItem> items;

  Quote({
    required this.id,
    required this.customerId,
    this.serviceRequestId,
    required this.title,
    this.description,
    required this.totalAmount,
    required this.status,
    this.validUntil,
    this.notes,
    required this.createdAt,
    required this.items,
  });

  factory Quote.fromJson(Map<String, dynamic> json) => Quote(
        id: json['id'],
        customerId: json['customer_id'],
        serviceRequestId: json['service_request_id'],
        title: json['title'],
        description: json['description'],
        totalAmount: (json['total_amount'] as num).toDouble(),
        status: json['status'],
        validUntil: json['valid_until'] != null
            ? DateTime.parse(json['valid_until'])
            : null,
        notes: json['notes'],
        createdAt: DateTime.parse(json['created_at']),
        items: (json['items'] as List? ?? [])
            .map((e) => QuoteItem.fromJson(e))
            .toList(),
      );

  static const Map<String, String> statusLabels = {
    'draft': 'Taslak',
    'sent': 'Gönderildi',
    'accepted': 'Kabul Edildi',
    'rejected': 'Reddedildi',
    'expired': 'Süresi Doldu',
  };

  String get statusLabel => statusLabels[status] ?? status;
}
