class Customer {
  final String id;
  final String customerType;
  final String displayName;
  final String companyName;
  final String firstName;
  final String lastName;
  final String email;
  final String primaryPhone;
  final String secondaryPhone;
  final String website;
  final String gstNumber;
  final String panNumber;
  final String taxPreference;
  final String currency;
  final String paymentTerms;
  final double creditLimit;
  final double outstanding;
  final String status;
  final String billingAttention;
  final String billingAddressLine1;
  final String billingCity;
  final String billingState;
  final String billingPostalCode;
  final String billingCountry;
  final bool shippingSameAsBilling;
  final String shippingAddressLine1;
  final String shippingCity;
  final String shippingState;
  final String shippingPostalCode;
  final String shippingCountry;
  final String route;
  final String notes;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isDeleted;

  Customer({
    required this.id,
    this.customerType = 'business',
    String? displayName,
    String? name,
    String? companyName,
    String? company,
    this.firstName = '',
    this.lastName = '',
    this.email = '',
    String? primaryPhone,
    String? phone,
    this.secondaryPhone = '',
    String? alternatePhone,
    this.website = '',
    String? gstNumber,
    String? gstNo,
    String? taxNumber,
    this.panNumber = '',
    this.taxPreference = 'taxable',
    this.currency = 'INR',
    this.paymentTerms = 'Due on Receipt',
    this.creditLimit = 50000.0,
    this.outstanding = 0.0,
    this.status = 'active',
    this.billingAttention = '',
    String? billingAddressLine1,
    String? address,
    this.billingCity = '',
    this.billingState = '',
    this.billingPostalCode = '',
    this.billingCountry = 'India',
    this.shippingSameAsBilling = true,
    this.shippingAddressLine1 = '',
    this.shippingCity = '',
    this.shippingState = '',
    this.shippingPostalCode = '',
    this.shippingCountry = 'India',
    this.route = '',
    this.notes = '',
    required this.createdAt,
    this.updatedAt,
    this.isDeleted = false,
  })  : displayName = displayName ?? name ?? '',
        companyName = companyName ?? company ?? '',
        primaryPhone = primaryPhone ?? phone ?? '',
        gstNumber = gstNumber ?? gstNo ?? taxNumber ?? '',
        billingAddressLine1 = billingAddressLine1 ?? address ?? '';

  // Backward-compatibility getters
  String get name => displayName.isNotEmpty ? displayName : '$firstName $lastName'.trim();
  String get phone => primaryPhone;
  String get alternatePhone => secondaryPhone;
  String get company => companyName;
  String get gstNo => gstNumber;
  String get taxNumber => gstNumber;
  String get address {
    if (billingAddressLine1.isNotEmpty) {
      final parts = [
        billingAddressLine1,
        billingCity,
        if (billingState.isNotEmpty || billingPostalCode.isNotEmpty)
          '${billingState.isNotEmpty ? billingState : ''}${billingState.isNotEmpty && billingPostalCode.isNotEmpty ? ' - ' : ''}${billingPostalCode.isNotEmpty ? billingPostalCode : ''}'
      ].where((p) => p.trim().isNotEmpty).toList();
      return parts.join(', ');
    }
    return '';
  }

  // Safely parses a value that may be a num or a String
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static bool _parseBool(dynamic value, {bool fallback = false}) {
    if (value == null) return fallback;
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final lower = value.toLowerCase().trim();
      return lower == 'true' || lower == '1' || lower == 'yes';
    }
    return fallback;
  }

  factory Customer.fromJson(Map<String, dynamic> json) {
    final displayName = (json['display_name'] ?? json['name'] ?? '').toString();
    final addressLine1 = (json['billing_address_line_1'] ?? json['billing_address'] ?? json['address'] ?? '').toString();
    final phone = (json['primary_phone'] ?? json['phone'] ?? '').toString();
    final secPhone = (json['secondary_phone'] ?? json['alternate_phone'] ?? json['alternatePhone'] ?? '').toString();
    final comp = (json['company_name'] ?? json['company'] ?? '').toString();
    final gst = (json['gst_number'] ?? json['gstNo'] ?? json['taxNumber'] ?? '').toString();
    final sameShipping = _parseBool(json['shipping_same_as_billing'], fallback: true);

    return Customer(
      id: (json['id'] ?? '').toString(),
      customerType: (json['customer_type'] ?? 'business').toString(),
      displayName: displayName,
      companyName: comp,
      firstName: (json['first_name'] ?? '').toString(),
      lastName: (json['last_name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      primaryPhone: phone,
      secondaryPhone: secPhone,
      website: (json['website'] ?? '').toString(),
      gstNumber: gst,
      panNumber: (json['pan_number'] ?? '').toString(),
      taxPreference: (json['tax_preference'] ?? 'taxable').toString(),
      currency: (json['currency'] ?? 'INR').toString(),
      paymentTerms: (json['payment_terms'] ?? 'Due on Receipt').toString(),
      creditLimit: _parseDouble(json['credit_limit'] ?? json['creditLimit']) ?? 50000.0,
      outstanding: _parseDouble(json['outstanding'] ?? json['outstanding_balance']) ?? 0.0,
      status: (json['status'] ?? 'active').toString(),
      billingAttention: (json['billing_attention'] ?? displayName).toString(),
      billingAddressLine1: addressLine1,
      billingCity: (json['billing_city'] ?? '').toString(),
      billingState: (json['billing_state'] ?? '').toString(),
      billingPostalCode: (json['billing_postal_code'] ?? '').toString(),
      billingCountry: (json['billing_country'] ?? 'India').toString(),
      shippingSameAsBilling: sameShipping,
      shippingAddressLine1: (json['shipping_address_line_1'] ?? (sameShipping ? addressLine1 : '')).toString(),
      shippingCity: (json['shipping_city'] ?? (sameShipping ? (json['billing_city'] ?? '') : '')).toString(),
      shippingState: (json['shipping_state'] ?? (sameShipping ? (json['billing_state'] ?? '') : '')).toString(),
      shippingPostalCode: (json['shipping_postal_code'] ?? (sameShipping ? (json['billing_postal_code'] ?? '') : '')).toString(),
      shippingCountry: (json['shipping_country'] ?? 'India').toString(),
      route: (json['route'] ?? json['beat'] ?? '').toString(),
      notes: (json['notes'] ?? json['internal_notes'] ?? '').toString(),
      createdAt: json['created_at'] != null || json['createdAt'] != null
          ? DateTime.tryParse((json['created_at'] ?? json['createdAt']).toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
      isDeleted: _parseBool(json['is_deleted']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'customer_type': customerType,
      'display_name': displayName.isNotEmpty ? displayName : name,
      'company_name': companyName,
      if (firstName.isNotEmpty) 'first_name': firstName,
      if (lastName.isNotEmpty) 'last_name': lastName,
      'email': email,
      'primary_phone': primaryPhone,
      if (secondaryPhone.isNotEmpty) 'secondary_phone': secondaryPhone,
      if (website.isNotEmpty) 'website': website,
      if (gstNumber.isNotEmpty) 'gst_number': gstNumber,
      if (panNumber.isNotEmpty) 'pan_number': panNumber,
      'tax_preference': taxPreference,
      'currency': currency,
      'payment_terms': paymentTerms,
      'credit_limit': creditLimit,
      'status': status,
      if (billingAttention.isNotEmpty) 'billing_attention': billingAttention,
      'billing_address_line_1': billingAddressLine1.isNotEmpty ? billingAddressLine1 : address,
      if (billingCity.isNotEmpty) 'billing_city': billingCity,
      if (billingState.isNotEmpty) 'billing_state': billingState,
      if (billingPostalCode.isNotEmpty) 'billing_postal_code': billingPostalCode,
      'billing_country': billingCountry,
      'shipping_same_as_billing': shippingSameAsBilling,
      'shipping_address_line_1': shippingSameAsBilling ? (billingAddressLine1.isNotEmpty ? billingAddressLine1 : address) : shippingAddressLine1,
      'shipping_city': shippingSameAsBilling ? billingCity : shippingCity,
      'shipping_state': shippingSameAsBilling ? billingState : shippingState,
      'shipping_postal_code': shippingSameAsBilling ? billingPostalCode : shippingPostalCode,
      'shipping_country': shippingCountry,
      if (route.isNotEmpty) 'route': route,
      if (notes.isNotEmpty) 'notes': notes,
      'created_at': createdAt.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      'is_deleted': isDeleted,
      // Compatibility aliases
      'name': displayName.isNotEmpty ? displayName : name,
      'phone': primaryPhone,
      'address': billingAddressLine1.isNotEmpty ? billingAddressLine1 : address,
      'company': companyName,
      'gstNo': gstNumber,
    };
  }

  Customer copyWith({
    String? id,
    String? customerType,
    String? displayName,
    String? companyName,
    String? firstName,
    String? lastName,
    String? email,
    String? primaryPhone,
    String? secondaryPhone,
    String? website,
    String? gstNumber,
    String? panNumber,
    String? taxPreference,
    String? currency,
    String? paymentTerms,
    double? creditLimit,
    double? outstanding,
    String? status,
    String? billingAttention,
    String? billingAddressLine1,
    String? billingCity,
    String? billingState,
    String? billingPostalCode,
    String? billingCountry,
    bool? shippingSameAsBilling,
    String? shippingAddressLine1,
    String? shippingCity,
    String? shippingState,
    String? shippingPostalCode,
    String? shippingCountry,
    String? route,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDeleted,
  }) {
    return Customer(
      id: id ?? this.id,
      customerType: customerType ?? this.customerType,
      displayName: displayName ?? this.displayName,
      companyName: companyName ?? this.companyName,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      primaryPhone: primaryPhone ?? this.primaryPhone,
      secondaryPhone: secondaryPhone ?? this.secondaryPhone,
      website: website ?? this.website,
      gstNumber: gstNumber ?? this.gstNumber,
      panNumber: panNumber ?? this.panNumber,
      taxPreference: taxPreference ?? this.taxPreference,
      currency: currency ?? this.currency,
      paymentTerms: paymentTerms ?? this.paymentTerms,
      creditLimit: creditLimit ?? this.creditLimit,
      outstanding: outstanding ?? this.outstanding,
      status: status ?? this.status,
      billingAttention: billingAttention ?? this.billingAttention,
      billingAddressLine1: billingAddressLine1 ?? this.billingAddressLine1,
      billingCity: billingCity ?? this.billingCity,
      billingState: billingState ?? this.billingState,
      billingPostalCode: billingPostalCode ?? this.billingPostalCode,
      billingCountry: billingCountry ?? this.billingCountry,
      shippingSameAsBilling: shippingSameAsBilling ?? this.shippingSameAsBilling,
      shippingAddressLine1: shippingAddressLine1 ?? this.shippingAddressLine1,
      shippingCity: shippingCity ?? this.shippingCity,
      shippingState: shippingState ?? this.shippingState,
      shippingPostalCode: shippingPostalCode ?? this.shippingPostalCode,
      shippingCountry: shippingCountry ?? this.shippingCountry,
      route: route ?? this.route,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}
