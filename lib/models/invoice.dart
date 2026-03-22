class InvoiceItem {
  final int? id;
  final String description;
  final double quantity;
  final double unitPrice;
  final double totalPrice;

  InvoiceItem({
    this.id,
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  factory InvoiceItem.fromJson(Map<String, dynamic> json) => InvoiceItem(
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

class Invoice {
  final int id;
  final int customerId;
  final int? quoteId;
  final String invoiceNumber;
  final String title;
  final String status;
  final DateTime? dueDate;
  final double totalAmount;
  final String? notes;
  final DateTime createdAt;
  final List<InvoiceItem> items;

  Invoice({
    required this.id,
    required this.customerId,
    this.quoteId,
    required this.invoiceNumber,
    required this.title,
    required this.status,
    this.dueDate,
    required this.totalAmount,
    this.notes,
    required this.createdAt,
    required this.items,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) => Invoice(
        id: json['id'],
        customerId: json['customer_id'],
        quoteId: json['quote_id'],
        invoiceNumber: json['invoice_number'],
        title: json['title'],
        status: json['status'],
        dueDate:
            json['due_date'] != null ? DateTime.parse(json['due_date']) : null,
        totalAmount: (json['total_amount'] as num).toDouble(),
        notes: json['notes'],
        createdAt: DateTime.parse(json['created_at']),
        items: (json['items'] as List? ?? [])
            .map((e) => InvoiceItem.fromJson(e))
            .toList(),
      );

  static const Map<String, String> statusLabels = {
    'draft': 'Taslak',
    'sent': 'Gönderildi',
    'paid': 'Ödendi',
    'overdue': 'Gecikmiş',
    'cancelled': 'İptal',
  };

  String get statusLabel => statusLabels[status] ?? status;
}
