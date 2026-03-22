class ServiceVisit {
  final int id;
  final int customerId;
  final int? serviceRequestId;
  final DateTime scheduledDate;
  final DateTime? actualDate;
  final int? durationMinutes;
  final String status;
  final String? notes;
  final String? technicianNotes;
  final DateTime createdAt;

  ServiceVisit({
    required this.id,
    required this.customerId,
    this.serviceRequestId,
    required this.scheduledDate,
    this.actualDate,
    this.durationMinutes,
    required this.status,
    this.notes,
    this.technicianNotes,
    required this.createdAt,
  });

  factory ServiceVisit.fromJson(Map<String, dynamic> json) => ServiceVisit(
        id: json['id'],
        customerId: json['customer_id'],
        serviceRequestId: json['service_request_id'],
        scheduledDate: DateTime.parse(json['scheduled_date']),
        actualDate: json['actual_date'] != null
            ? DateTime.parse(json['actual_date'])
            : null,
        durationMinutes: json['duration_minutes'],
        status: json['status'],
        notes: json['notes'],
        technicianNotes: json['technician_notes'],
        createdAt: DateTime.parse(json['created_at']),
      );

  static const Map<String, String> statusLabels = {
    'scheduled': 'Planlandı',
    'in_progress': 'Devam Ediyor',
    'completed': 'Tamamlandı',
    'cancelled': 'İptal',
  };

  String get statusLabel => statusLabels[status] ?? status;
}
