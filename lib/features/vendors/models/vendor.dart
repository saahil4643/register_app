class VendorContactPerson {
  final String salutation;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String mobile;
  final String designation;

  VendorContactPerson({
    this.salutation = 'Mr.',
    required this.firstName,
    this.lastName = '',
    this.email = '',
    this.phone = '',
    this.mobile = '',
    this.designation = '',
  });

  String get fullName => '$salutation $firstName $lastName'.trim();

  Map<String, dynamic> toJson() => {
        'salutation': salutation,
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'phone': phone,
        'mobile': mobile,
        'designation': designation,
      };

  factory VendorContactPerson.fromJson(Map<String, dynamic> json) =>
      VendorContactPerson(
        salutation: json['salutation']?.toString() ?? 'Mr.',
        firstName: json['first_name']?.toString() ?? json['firstName']?.toString() ?? '',
        lastName: json['last_name']?.toString() ?? json['lastName']?.toString() ?? '',
        email: json['email']?.toString() ?? '',
        phone: json['phone']?.toString() ?? '',
        mobile: json['mobile']?.toString() ?? '',
        designation: json['designation']?.toString() ?? '',
      );
}

class Vendor {
  final String id;
  final String? organization;
  final String displayName;
  final String companyName;
  final String firstName;
  final String lastName;
  final String email;
  final String primaryPhone;
  final String secondaryPhone;
  final String website;

  // Billing address
  final String billingAttention;
  final String billingAddressLine1;
  final String billingAddressLine2;
  final String billingCity;
  final String billingState;
  final String billingCountry;
  final String billingPostalCode;

  // Shipping address
  final bool shippingSameAsBilling;
  final String shippingAttention;
  final String shippingAddressLine1;
  final String shippingAddressLine2;
  final String shippingCity;
  final String shippingState;
  final String shippingCountry;
  final String shippingPostalCode;

  // Tax & Finance
  final String gstNumber;
  final String panNumber;
  final String taxPreference;
  final String currency;
  final String paymentTerms;
  final String notes;

  // Metadata / Compatibility fields
  final String salutation;
  final String phoneCountryCode;
  final String mobileCountryCode;
  final bool isMsmeRegistered;
  final String msmeRegistrationNumber;
  final String accountsPayable;
  final double openingBalance;
  final String socialLinks;
  final List<VendorContactPerson> contactPersons;
  final String? status;
  final String? createdBy;
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Vendor({
    required this.id,
    this.organization,
    required this.displayName,
    this.companyName = '',
    this.firstName = '',
    this.lastName = '',
    this.email = '',
    this.primaryPhone = '',
    this.secondaryPhone = '',
    this.website = '',
    this.billingAttention = '',
    this.billingAddressLine1 = '',
    this.billingAddressLine2 = '',
    this.billingCity = '',
    this.billingState = '',
    this.billingCountry = 'India',
    this.billingPostalCode = '',
    this.shippingSameAsBilling = true,
    this.shippingAttention = '',
    this.shippingAddressLine1 = '',
    this.shippingAddressLine2 = '',
    this.shippingCity = '',
    this.shippingState = '',
    this.shippingCountry = 'India',
    this.shippingPostalCode = '',
    this.gstNumber = '',
    this.panNumber = '',
    this.taxPreference = 'Taxable',
    this.currency = 'INR',
    this.paymentTerms = 'Net 30',
    this.notes = '',
    this.salutation = '',
    this.phoneCountryCode = '+91',
    this.mobileCountryCode = '+91',
    this.isMsmeRegistered = false,
    this.msmeRegistrationNumber = '',
    this.accountsPayable = 'Accounts Payable',
    this.openingBalance = 0.0,
    this.socialLinks = '',
    this.contactPersons = const [],
    this.status,
    this.createdBy,
    this.isDeleted = false,
    required this.createdAt,
    this.updatedAt,
  });

  // Backwards compatibility getters
  String get name => displayName.isNotEmpty
      ? displayName
      : '$firstName $lastName'.trim().isNotEmpty
          ? '$firstName $lastName'.trim()
          : companyName;

  String get phone => primaryPhone.isNotEmpty ? primaryPhone : secondaryPhone;
  String get mobile => secondaryPhone.isNotEmpty ? secondaryPhone : primaryPhone;
  String get gstin => gstNumber;
  String get remarks => notes;

  /// Exact API payload matching VendorRequest.java for POST & PUT
  Map<String, dynamic> toApiJson() {
    final Map<String, dynamic> data = {
      'display_name': displayName.trim(),
    };

    if (companyName.trim().isNotEmpty) data['company_name'] = companyName.trim();
    if (firstName.trim().isNotEmpty) data['first_name'] = firstName.trim();
    if (lastName.trim().isNotEmpty) data['last_name'] = lastName.trim();
    if (email.trim().isNotEmpty) data['email'] = email.trim();
    if (primaryPhone.trim().isNotEmpty) data['primary_phone'] = primaryPhone.trim();
    if (secondaryPhone.trim().isNotEmpty) data['secondary_phone'] = secondaryPhone.trim();
    if (website.trim().isNotEmpty) data['website'] = website.trim();

    if (billingAttention.trim().isNotEmpty) data['billing_attention'] = billingAttention.trim();
    if (billingAddressLine1.trim().isNotEmpty) data['billing_address_line_1'] = billingAddressLine1.trim();
    if (billingAddressLine2.trim().isNotEmpty) data['billing_address_line_2'] = billingAddressLine2.trim();
    if (billingCity.trim().isNotEmpty) data['billing_city'] = billingCity.trim();
    if (billingState.trim().isNotEmpty) data['billing_state'] = billingState.trim();
    if (billingCountry.trim().isNotEmpty) data['billing_country'] = billingCountry.trim();
    if (billingPostalCode.trim().isNotEmpty) data['billing_postal_code'] = billingPostalCode.trim();

    data['shipping_same_as_billing'] = shippingSameAsBilling;

    if (!shippingSameAsBilling) {
      if (shippingAttention.trim().isNotEmpty) data['shipping_attention'] = shippingAttention.trim();
      if (shippingAddressLine1.trim().isNotEmpty) data['shipping_address_line_1'] = shippingAddressLine1.trim();
      if (shippingAddressLine2.trim().isNotEmpty) data['shipping_address_line_2'] = shippingAddressLine2.trim();
      if (shippingCity.trim().isNotEmpty) data['shipping_city'] = shippingCity.trim();
      if (shippingState.trim().isNotEmpty) data['shipping_state'] = shippingState.trim();
      if (shippingCountry.trim().isNotEmpty) data['shipping_country'] = shippingCountry.trim();
      if (shippingPostalCode.trim().isNotEmpty) data['shipping_postal_code'] = shippingPostalCode.trim();
    } else {
      // Mirror billing to shipping if same
      if (billingAttention.trim().isNotEmpty) data['shipping_attention'] = billingAttention.trim();
      if (billingAddressLine1.trim().isNotEmpty) data['shipping_address_line_1'] = billingAddressLine1.trim();
      if (billingAddressLine2.trim().isNotEmpty) data['shipping_address_line_2'] = billingAddressLine2.trim();
      if (billingCity.trim().isNotEmpty) data['shipping_city'] = billingCity.trim();
      if (billingState.trim().isNotEmpty) data['shipping_state'] = billingState.trim();
      if (billingCountry.trim().isNotEmpty) data['shipping_country'] = billingCountry.trim();
      if (billingPostalCode.trim().isNotEmpty) data['shipping_postal_code'] = billingPostalCode.trim();
    }

    if (gstNumber.trim().isNotEmpty) data['gst_number'] = gstNumber.trim().toUpperCase();
    if (panNumber.trim().isNotEmpty) data['pan_number'] = panNumber.trim().toUpperCase();
    if (taxPreference.trim().isNotEmpty) data['tax_preference'] = taxPreference.trim();
    if (currency.trim().isNotEmpty) data['currency'] = currency.trim();
    if (paymentTerms.trim().isNotEmpty) data['payment_terms'] = paymentTerms.trim();
    if (notes.trim().isNotEmpty) data['notes'] = notes.trim();

    return data;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'organization': organization,
        'display_name': displayName,
        'company_name': companyName,
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'primary_phone': primaryPhone,
        'secondary_phone': secondaryPhone,
        'phone': primaryPhone,
        'mobile': secondaryPhone,
        'website': website,
        'billing_attention': billingAttention,
        'billing_address_line_1': billingAddressLine1,
        'billing_address_line_2': billingAddressLine2,
        'billing_city': billingCity,
        'billing_state': billingState,
        'billing_country': billingCountry,
        'billing_postal_code': billingPostalCode,
        'shipping_same_as_billing': shippingSameAsBilling,
        'shipping_attention': shippingAttention,
        'shipping_address_line_1': shippingAddressLine1,
        'shipping_address_line_2': shippingAddressLine2,
        'shipping_city': shippingCity,
        'shipping_state': shippingState,
        'shipping_country': shippingCountry,
        'shipping_postal_code': shippingPostalCode,
        'gst_number': gstNumber,
        'gstin': gstNumber,
        'pan_number': panNumber,
        'tax_preference': taxPreference,
        'currency': currency,
        'payment_terms': paymentTerms,
        'notes': notes,
        'remarks': notes,
        'status': status,
        'is_deleted': isDeleted,
        'created_by': createdBy,
        'salutation': salutation,
        'phone_country_code': phoneCountryCode,
        'mobile_country_code': mobileCountryCode,
        'is_msme_registered': isMsmeRegistered,
        'msme_registration_number': msmeRegistrationNumber,
        'accounts_payable': accountsPayable,
        'opening_balance': openingBalance,
        'social_links': socialLinks,
        'contact_persons': contactPersons.map((c) => c.toJson()).toList(),
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };

  factory Vendor.fromJson(Map<String, dynamic> json) {
    final rawPrimary = json['primary_phone'] ?? json['primaryPhone'] ?? json['phone'] ?? json['mobile'];
    final rawSecondary = json['secondary_phone'] ?? json['secondaryPhone'] ?? json['mobile'];
    final rawGst = json['gst_number'] ?? json['gstNumber'] ?? json['gstin'] ?? json['gst_no'] ?? json['gstNo'];
    final rawPan = json['pan_number'] ?? json['panNumber'] ?? json['pan'];
    final rawNotes = json['notes'] ?? json['remarks'];

    return Vendor(
      id: json['id']?.toString() ?? '',
      organization: json['organization']?.toString(),
      displayName: json['display_name']?.toString() ??
          json['displayName']?.toString() ??
          json['name']?.toString() ??
          '',
      companyName: json['company_name']?.toString() ??
          json['companyName']?.toString() ??
          '',
      firstName: json['first_name']?.toString() ??
          json['firstName']?.toString() ??
          '',
      lastName: json['last_name']?.toString() ??
          json['lastName']?.toString() ??
          '',
      email: json['email']?.toString() ?? '',
      primaryPhone: rawPrimary?.toString() ?? '',
      secondaryPhone: rawSecondary?.toString() ?? '',
      website: json['website']?.toString() ?? '',
      billingAttention: json['billing_attention']?.toString() ??
          json['billingAttention']?.toString() ??
          '',
      billingAddressLine1: json['billing_address_line_1']?.toString() ??
          json['billing_address_line1']?.toString() ??
          json['billingAddressLine1']?.toString() ??
          json['address']?.toString() ??
          '',
      billingAddressLine2: json['billing_address_line_2']?.toString() ??
          json['billing_address_line2']?.toString() ??
          json['billingAddressLine2']?.toString() ??
          '',
      billingCity: json['billing_city']?.toString() ??
          json['billingCity']?.toString() ??
          '',
      billingState: json['billing_state']?.toString() ??
          json['billingState']?.toString() ??
          '',
      billingCountry: json['billing_country']?.toString() ??
          json['billingCountry']?.toString() ??
          'India',
      billingPostalCode: json['billing_postal_code']?.toString() ??
          json['billingPostalCode']?.toString() ??
          json['pincode']?.toString() ??
          '',
      shippingSameAsBilling: json['shipping_same_as_billing'] != false &&
          json['shippingSameAsBilling'] != false,
      shippingAttention: json['shipping_attention']?.toString() ??
          json['shippingAttention']?.toString() ??
          '',
      shippingAddressLine1: json['shipping_address_line_1']?.toString() ??
          json['shipping_address_line1']?.toString() ??
          json['shippingAddressLine1']?.toString() ??
          '',
      shippingAddressLine2: json['shipping_address_line_2']?.toString() ??
          json['shipping_address_line2']?.toString() ??
          json['shippingAddressLine2']?.toString() ??
          '',
      shippingCity: json['shipping_city']?.toString() ??
          json['shippingCity']?.toString() ??
          '',
      shippingState: json['shipping_state']?.toString() ??
          json['shippingState']?.toString() ??
          '',
      shippingCountry: json['shipping_country']?.toString() ??
          json['shippingCountry']?.toString() ??
          'India',
      shippingPostalCode: json['shipping_postal_code']?.toString() ??
          json['shippingPostalCode']?.toString() ??
          '',
      gstNumber: rawGst?.toString() ?? '',
      panNumber: rawPan?.toString() ?? '',
      taxPreference: json['tax_preference']?.toString() ??
          json['taxPreference']?.toString() ??
          'Taxable',
      currency: json['currency']?.toString() ?? 'INR',
      paymentTerms: json['payment_terms']?.toString() ??
          json['paymentTerms']?.toString() ??
          'Net 30',
      notes: rawNotes?.toString() ?? '',
      salutation: json['salutation']?.toString() ?? '',
      phoneCountryCode: json['phone_country_code']?.toString() ?? '+91',
      mobileCountryCode: json['mobile_country_code']?.toString() ?? '+91',
      isMsmeRegistered: json['is_msme_registered'] == true ||
          json['isMsmeRegistered'] == true,
      msmeRegistrationNumber:
          json['msme_registration_number']?.toString() ?? '',
      accountsPayable:
          json['accounts_payable']?.toString() ?? 'Accounts Payable',
      openingBalance: (json['opening_balance'] ?? json['openingBalance'] ?? 0.0) is num
          ? (json['opening_balance'] ?? json['openingBalance'] ?? 0.0).toDouble()
          : double.tryParse(json['opening_balance']?.toString() ?? '0') ?? 0.0,
      socialLinks: json['social_links']?.toString() ?? '',
      contactPersons: (json['contact_persons'] is List)
          ? (json['contact_persons'] as List)
              .map((cp) => VendorContactPerson.fromJson(cp as Map<String, dynamic>))
              .toList()
          : [],
      status: json['status']?.toString(),
      createdBy: json['created_by']?.toString() ?? json['createdBy']?.toString(),
      isDeleted: json['is_deleted'] == true || json['isDeleted'] == true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  Vendor copyWith({
    String? id,
    String? organization,
    String? displayName,
    String? companyName,
    String? firstName,
    String? lastName,
    String? email,
    String? primaryPhone,
    String? secondaryPhone,
    String? website,
    String? billingAttention,
    String? billingAddressLine1,
    String? billingAddressLine2,
    String? billingCity,
    String? billingState,
    String? billingCountry,
    String? billingPostalCode,
    bool? shippingSameAsBilling,
    String? shippingAttention,
    String? shippingAddressLine1,
    String? shippingAddressLine2,
    String? shippingCity,
    String? shippingState,
    String? shippingCountry,
    String? shippingPostalCode,
    String? gstNumber,
    String? panNumber,
    String? taxPreference,
    String? currency,
    String? paymentTerms,
    String? notes,
    String? salutation,
    String? phoneCountryCode,
    String? mobileCountryCode,
    bool? isMsmeRegistered,
    String? msmeRegistrationNumber,
    String? accountsPayable,
    double? openingBalance,
    String? socialLinks,
    List<VendorContactPerson>? contactPersons,
    String? status,
    String? createdBy,
    bool? isDeleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Vendor(
      id: id ?? this.id,
      organization: organization ?? this.organization,
      displayName: displayName ?? this.displayName,
      companyName: companyName ?? this.companyName,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      primaryPhone: primaryPhone ?? this.primaryPhone,
      secondaryPhone: secondaryPhone ?? this.secondaryPhone,
      website: website ?? this.website,
      billingAttention: billingAttention ?? this.billingAttention,
      billingAddressLine1: billingAddressLine1 ?? this.billingAddressLine1,
      billingAddressLine2: billingAddressLine2 ?? this.billingAddressLine2,
      billingCity: billingCity ?? this.billingCity,
      billingState: billingState ?? this.billingState,
      billingCountry: billingCountry ?? this.billingCountry,
      billingPostalCode: billingPostalCode ?? this.billingPostalCode,
      shippingSameAsBilling: shippingSameAsBilling ?? this.shippingSameAsBilling,
      shippingAttention: shippingAttention ?? this.shippingAttention,
      shippingAddressLine1: shippingAddressLine1 ?? this.shippingAddressLine1,
      shippingAddressLine2: shippingAddressLine2 ?? this.shippingAddressLine2,
      shippingCity: shippingCity ?? this.shippingCity,
      shippingState: shippingState ?? this.shippingState,
      shippingCountry: shippingCountry ?? this.shippingCountry,
      shippingPostalCode: shippingPostalCode ?? this.shippingPostalCode,
      gstNumber: gstNumber ?? this.gstNumber,
      panNumber: panNumber ?? this.panNumber,
      taxPreference: taxPreference ?? this.taxPreference,
      currency: currency ?? this.currency,
      paymentTerms: paymentTerms ?? this.paymentTerms,
      notes: notes ?? this.notes,
      salutation: salutation ?? this.salutation,
      phoneCountryCode: phoneCountryCode ?? this.phoneCountryCode,
      mobileCountryCode: mobileCountryCode ?? this.mobileCountryCode,
      isMsmeRegistered: isMsmeRegistered ?? this.isMsmeRegistered,
      msmeRegistrationNumber: msmeRegistrationNumber ?? this.msmeRegistrationNumber,
      accountsPayable: accountsPayable ?? this.accountsPayable,
      openingBalance: openingBalance ?? this.openingBalance,
      socialLinks: socialLinks ?? this.socialLinks,
      contactPersons: contactPersons ?? this.contactPersons,
      status: status ?? this.status,
      createdBy: createdBy ?? this.createdBy,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
