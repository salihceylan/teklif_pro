class ServiceVisitItem {
  final int? id;
  final String? productCode;
  final String materialName;
  final double quantity;
  final double unitPrice;
  final double totalPrice;

  const ServiceVisitItem({
    this.id,
    this.productCode,
    required this.materialName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  factory ServiceVisitItem.fromJson(Map<String, dynamic> json) =>
      ServiceVisitItem(
        id: json['id'],
        productCode: json['product_code'],
        materialName: json['material_name'],
        quantity: (json['quantity'] as num).toDouble(),
        unitPrice: (json['unit_price'] as num).toDouble(),
        totalPrice: (json['total_price'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        if (productCode != null && productCode!.isNotEmpty)
          'product_code': productCode,
        'material_name': materialName,
        'quantity': quantity,
        'unit_price': unitPrice,
      };
}

class ServiceVisit {
  final int id;
  final int customerId;
  final int? serviceRequestId;
  final String? serviceCode;
  final DateTime scheduledDate;
  final DateTime? actualDate;
  final int? durationMinutes;
  final String status;
  final String? customerCompanyName;
  final String? customerContactName;
  final String? customerPhone;
  final String? customerAddress;
  final String? complaint;
  final String? technicianName;
  final double laborAmount;
  final double vatRate;
  final double materialTotal;
  final double vatTotal;
  final double grandTotal;
  final String? notes;
  final String? technicianNotes;
  final DateTime createdAt;
  final List<ServiceVisitItem> items;

  const ServiceVisit({
    required this.id,
    required this.customerId,
    this.serviceRequestId,
    this.serviceCode,
    required this.scheduledDate,
    this.actualDate,
    this.durationMinutes,
    required this.status,
    this.customerCompanyName,
    this.customerContactName,
    this.customerPhone,
    this.customerAddress,
    this.complaint,
    this.technicianName,
    required this.laborAmount,
    required this.vatRate,
    required this.materialTotal,
    required this.vatTotal,
    required this.grandTotal,
    this.notes,
    this.technicianNotes,
    required this.createdAt,
    required this.items,
  });

  factory ServiceVisit.fromJson(Map<String, dynamic> json) => ServiceVisit(
        id: json['id'],
        customerId: json['customer_id'],
        serviceRequestId: json['service_request_id'],
        serviceCode: json['service_code'],
        scheduledDate: DateTime.parse(json['scheduled_date']),
        actualDate: json['actual_date'] != null
            ? DateTime.parse(json['actual_date'])
            : null,
        durationMinutes: json['duration_minutes'],
        status: json['status'],
        customerCompanyName: json['customer_company_name'],
        customerContactName: json['customer_contact_name'],
        customerPhone: json['customer_phone'],
        customerAddress: json['customer_address'],
        complaint: json['complaint'],
        technicianName: json['technician_name'],
        laborAmount: ((json['labor_amount'] as num?) ?? 0).toDouble(),
        vatRate: ((json['vat_rate'] as num?) ?? 20).toDouble(),
        materialTotal: ((json['material_total'] as num?) ?? 0).toDouble(),
        vatTotal: ((json['vat_total'] as num?) ?? 0).toDouble(),
        grandTotal: ((json['grand_total'] as num?) ?? 0).toDouble(),
        notes: json['notes'],
        technicianNotes: json['technician_notes'],
        createdAt: DateTime.parse(json['created_at']),
        items: (json['items'] as List? ?? [])
            .map((e) => ServiceVisitItem.fromJson(e))
            .toList(),
      );

  static const Map<String, String> statusLabels = {
    'scheduled': 'Planlandi',
    'in_progress': 'Devam Ediyor',
    'completed': 'Tamamlandi',
    'cancelled': 'Iptal',
  };

  String get statusLabel => statusLabels[status] ?? status;
}
