class Customer {
  final int id;
  final String fullName;
  final String? email;
  final String? phone;
  final String? address;
  final String? city;
  final String? notes;

  Customer({
    required this.id,
    required this.fullName,
    this.email,
    this.phone,
    this.address,
    this.city,
    this.notes,
  });

  factory Customer.fromJson(Map<String, dynamic> json) => Customer(
        id: json['id'],
        fullName: json['full_name'],
        email: json['email'],
        phone: json['phone'],
        address: json['address'],
        city: json['city'],
        notes: json['notes'],
      );

  Map<String, dynamic> toJson() => {
        'full_name': fullName,
        if (email != null) 'email': email,
        if (phone != null) 'phone': phone,
        if (address != null) 'address': address,
        if (city != null) 'city': city,
        if (notes != null) 'notes': notes,
      };
}
