class Customer {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String alternatePhone;
  final String address;
  final String company;
  final String gstNo;
  final double creditLimit;
  final double outstanding;
  final String notes;
  final DateTime createdAt;

  const Customer({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.alternatePhone = '',
    required this.address,
    required this.company,
    required this.gstNo,
    this.creditLimit = 50000.0,
    this.outstanding = 0.0,
    this.notes = '',
    required this.createdAt,
  });

  // Getter to prevent breaking any legacy code referencing taxNumber
  String get taxNumber => gstNo;

  // Safely parses a value that may be a num or a String (Django DecimalField
  // serialises as string by default, e.g. "50000.00").
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] as String,
      name: (json['name'] ?? json['display_name'] ?? '') as String,
      email: (json['email'] ?? '') as String,
      phone: (json['phone'] ?? json['primary_phone'] ?? '') as String,
      alternatePhone: (json['secondary_phone'] ?? json['alternate_phone'] ?? json['alternatePhone'] ?? '') as String,
      address: (json['address'] ?? json['billing_address'] ?? json['billing_address_line_1'] ?? '').toString(),
      company: (json['company'] ?? json['company_name'] ?? '') as String,
      gstNo: (json['gstNo'] ?? json['gst_number'] ?? json['taxNumber'] ?? '') as String,
      creditLimit: _parseDouble(json['creditLimit'] ?? json['credit_limit']) ?? 50000.0,
      outstanding: _parseDouble(json['outstanding'] ?? json['outstanding_balance']) ?? 0.0,
      notes: (json['notes'] ?? json['internal_notes'] ?? '').toString(),
      createdAt: json['createdAt'] != null || json['created_at'] != null
          ? DateTime.parse((json['createdAt'] ?? json['created_at']) as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'display_name': name,
      'name': name,
      'email': email,
      'primary_phone': phone,
      'phone': phone,
      'secondary_phone': alternatePhone,
      'alternate_phone': alternatePhone,
      'alternatePhone': alternatePhone,
      'billing_address': address,
      'address': address,
      'company_name': company,
      'company': company,
      'gst_number': gstNo,
      'gstNo': gstNo,
      'taxNumber': gstNo,
      'credit_limit': creditLimit,
      'creditLimit': creditLimit,
      'outstanding': outstanding,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  Customer copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? alternatePhone,
    String? address,
    String? company,
    String? gstNo,
    double? creditLimit,
    double? outstanding,
    String? notes,
    DateTime? createdAt,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      alternatePhone: alternatePhone ?? this.alternatePhone,
      address: address ?? this.address,
      company: company ?? this.company,
      gstNo: gstNo ?? this.gstNo,
      creditLimit: creditLimit ?? this.creditLimit,
      outstanding: outstanding ?? this.outstanding,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
