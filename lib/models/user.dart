class User {
  final int id;
  final String email;
  final String fullName;
  final String? phone;
  final String? companyName;

  User({
    required this.id,
    required this.email,
    required this.fullName,
    this.phone,
    this.companyName,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'],
    email: json['email'],
    fullName: json['full_name'],
    phone: json['phone'],
    companyName: json['company_name'],
  );
}
