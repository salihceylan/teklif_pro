class ServiceRequest {
  final int id;
  final int customerId;
  final String title;
  final String? description;
  final String status;
  final String priority;
  final String? location;
  final DateTime? scheduledDate;
  final DateTime createdAt;

  ServiceRequest({
    required this.id,
    required this.customerId,
    required this.title,
    this.description,
    required this.status,
    required this.priority,
    this.location,
    this.scheduledDate,
    required this.createdAt,
  });

  factory ServiceRequest.fromJson(Map<String, dynamic> json) => ServiceRequest(
    id: json['id'],
    customerId: json['customer_id'],
    title: json['title'],
    description: json['description'],
    status: json['status'],
    priority: json['priority'] ?? 'normal',
    location: json['location'],
    scheduledDate: json['scheduled_date'] != null
        ? DateTime.parse(json['scheduled_date'])
        : null,
    createdAt: DateTime.parse(json['created_at']),
  );

  static const Map<String, String> statusLabels = {
    'new': 'Yeni',
    'quoted': 'Teklif Verildi',
    'in_progress': 'Devam Ediyor',
    'completed': 'Tamamlandı',
    'cancelled': 'İptal',
  };

  String get statusLabel => statusLabels[status] ?? status;
}
