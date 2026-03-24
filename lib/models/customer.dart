class Customer {
  final int id;
  final String fullName;
  final String? customerCode;
  final String? contactName;
  final String? email;
  final String? phone;
  final String? address;
  final String? city;
  final String? mersisNo;
  final String? taxNumber;
  final String? taxOffice;
  final DateTime? foundationDate;
  final int? employeeCount;
  final String? iban;
  final String? kepAddress;
  final String? website;
  final String? exporterUnions;
  final String? hibMembershipNo;
  final String? naceCode;
  final String? naceName;
  final String? brandName;
  final String? subSector;
  final String? offeredSolution;
  final String? targetCustomerGroup;
  final String? salesChannel;
  final String? notes;

  const Customer({
    required this.id,
    required this.fullName,
    this.customerCode,
    this.contactName,
    this.email,
    this.phone,
    this.address,
    this.city,
    this.mersisNo,
    this.taxNumber,
    this.taxOffice,
    this.foundationDate,
    this.employeeCount,
    this.iban,
    this.kepAddress,
    this.website,
    this.exporterUnions,
    this.hibMembershipNo,
    this.naceCode,
    this.naceName,
    this.brandName,
    this.subSector,
    this.offeredSolution,
    this.targetCustomerGroup,
    this.salesChannel,
    this.notes,
  });

  String get companyName => fullName;

  factory Customer.fromJson(Map<String, dynamic> json) => Customer(
    id: json['id'],
    fullName: (json['company_name'] ?? json['full_name'] ?? '') as String,
    customerCode: json['customer_code'],
    contactName: json['contact_name'],
    email: json['email'],
    phone: json['phone'],
    address: json['address'],
    city: json['city'],
    mersisNo: json['mersis_no'],
    taxNumber: json['tax_number'],
    taxOffice: json['tax_office'],
    foundationDate: json['foundation_date'] != null
        ? DateTime.parse(json['foundation_date'])
        : null,
    employeeCount: json['employee_count'],
    iban: json['iban'],
    kepAddress: json['kep_address'],
    website: json['website'],
    exporterUnions: json['exporter_unions'],
    hibMembershipNo: json['hib_membership_no'],
    naceCode: json['nace_code'],
    naceName: json['nace_name'],
    brandName: json['brand_name'],
    subSector: json['sub_sector'],
    offeredSolution: json['offered_solution'],
    targetCustomerGroup: json['target_customer_group'],
    salesChannel: json['sales_channel'],
    notes: json['notes'],
  );

  Map<String, dynamic> toJson() => {
    'full_name': fullName,
    if (contactName != null) 'contact_name': contactName,
    if (email != null) 'email': email,
    if (phone != null) 'phone': phone,
    if (address != null) 'address': address,
    if (city != null) 'city': city,
    if (mersisNo != null) 'mersis_no': mersisNo,
    if (taxNumber != null) 'tax_number': taxNumber,
    if (taxOffice != null) 'tax_office': taxOffice,
    if (foundationDate != null)
      'foundation_date': foundationDate!.toIso8601String(),
    if (employeeCount != null) 'employee_count': employeeCount,
    if (iban != null) 'iban': iban,
    if (kepAddress != null) 'kep_address': kepAddress,
    if (website != null) 'website': website,
    if (exporterUnions != null) 'exporter_unions': exporterUnions,
    if (hibMembershipNo != null) 'hib_membership_no': hibMembershipNo,
    if (naceCode != null) 'nace_code': naceCode,
    if (naceName != null) 'nace_name': naceName,
    if (brandName != null) 'brand_name': brandName,
    if (subSector != null) 'sub_sector': subSector,
    if (offeredSolution != null) 'offered_solution': offeredSolution,
    if (targetCustomerGroup != null)
      'target_customer_group': targetCustomerGroup,
    if (salesChannel != null) 'sales_channel': salesChannel,
    if (notes != null) 'notes': notes,
  };
}
