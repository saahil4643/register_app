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
        salutation: json['salutation'] ?? 'Mr.',
        firstName: json['first_name'] ?? json['firstName'] ?? '',
        lastName: json['last_name'] ?? json['lastName'] ?? '',
        email: json['email'] ?? '',
        phone: json['phone'] ?? '',
        mobile: json['mobile'] ?? '',
        designation: json['designation'] ?? '',
      );
}

class Vendor {
  final String id;
  final String salutation;
  final String firstName;
  final String lastName;
  final String companyName;
  final String displayName;
  final String email;
  final String phone;
  final String mobile;
  final String phoneCountryCode;
  final String mobileCountryCode;
  final String gstin;
  final bool isMsmeRegistered;
  final String msmeRegistrationNumber;
  final String currency;
  final String accountsPayable;
  final double openingBalance;
  final String paymentTerms;
  final String website;
  final String socialLinks;
  final String billingAttention;
  final String billingAddressLine1;
  final String billingCity;
  final String billingState;
  final String billingPostalCode;
  final String billingCountry;
  final bool shippingSameAsBilling;
  final String shippingAttention;
  final String shippingAddressLine1;
  final String shippingCity;
  final String shippingState;
  final String shippingPostalCode;
  final String shippingCountry;
  final List<VendorContactPerson> contactPersons;
  final String remarks;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Vendor({
    required this.id,
    this.salutation = '',
    this.firstName = '',
    this.lastName = '',
    this.companyName = '',
    required this.displayName,
    this.email = '',
    this.phone = '',
    this.mobile = '',
    this.gstin = '',
    this.phoneCountryCode = '+91',
    this.mobileCountryCode = '+91',
    this.isMsmeRegistered = false,
    this.msmeRegistrationNumber = '',
    this.currency = 'INR',
    this.accountsPayable = 'Accounts Payable',
    this.openingBalance = 0.0,
    this.paymentTerms = 'Due on Receipt',
    this.website = '',
    this.socialLinks = '',
    this.billingAttention = '',
    this.billingAddressLine1 = '',
    this.billingCity = '',
    this.billingState = '',
    this.billingPostalCode = '',
    this.billingCountry = 'India',
    this.shippingSameAsBilling = true,
    this.shippingAttention = '',
    this.shippingAddressLine1 = '',
    this.shippingCity = '',
    this.shippingState = '',
    this.shippingPostalCode = '',
    this.shippingCountry = 'India',
    this.contactPersons = const [],
    this.remarks = '',
    required this.createdAt,
    this.updatedAt,
  });

  String get name => displayName.isNotEmpty
      ? displayName
      : '$firstName $lastName'.trim().isNotEmpty
          ? '$firstName $lastName'.trim()
          : companyName;

  Map<String, dynamic> toJson() => {
        'id': id,
        'salutation': salutation,
        'first_name': firstName,
        'last_name': lastName,
        'company_name': companyName,
        'display_name': displayName,
        'email': email,
        'phone': phone,
        'mobile': mobile,
        'gstin': gstin,
        'gst_no': gstin,
        'phone_country_code': phoneCountryCode,
        'mobile_country_code': mobileCountryCode,
        'is_msme_registered': isMsmeRegistered,
        'msme_registration_number': msmeRegistrationNumber,
        'currency': currency,
        'accounts_payable': accountsPayable,
        'opening_balance': openingBalance,
        'payment_terms': paymentTerms,
        'website': website,
        'social_links': socialLinks,
        'billing_attention': billingAttention,
        'billing_address_line1': billingAddressLine1,
        'billing_city': billingCity,
        'billing_state': billingState,
        'billing_postal_code': billingPostalCode,
        'billing_country': billingCountry,
        'shipping_same_as_billing': shippingSameAsBilling,
        'shipping_attention': shippingAttention,
        'shipping_address_line1': shippingAddressLine1,
        'shipping_city': shippingCity,
        'shipping_state': shippingState,
        'shipping_postal_code': shippingPostalCode,
        'shipping_country': shippingCountry,
        'contact_persons': contactPersons.map((c) => c.toJson()).toList(),
        'remarks': remarks,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };

  factory Vendor.fromJson(Map<String, dynamic> json) {
    return Vendor(
      id: json['id']?.toString() ?? '',
      salutation: json['salutation']?.toString() ?? '',
      firstName: json['first_name']?.toString() ?? json['firstName']?.toString() ?? '',
      lastName: json['last_name']?.toString() ?? json['lastName']?.toString() ?? '',
      companyName: json['company_name']?.toString() ?? json['companyName']?.toString() ?? json['name']?.toString() ?? '',
      displayName: json['display_name']?.toString() ?? json['displayName']?.toString() ?? json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      mobile: json['mobile']?.toString() ?? '',
      gstin: json['gstin']?.toString() ?? json['gst_no']?.toString() ?? json['gstNo']?.toString() ?? '',
      phoneCountryCode: json['phone_country_code']?.toString() ?? '+91',
      mobileCountryCode: json['mobile_country_code']?.toString() ?? '+91',
      isMsmeRegistered: json['is_msme_registered'] == true || json['isMsmeRegistered'] == true,
      msmeRegistrationNumber: json['msme_registration_number']?.toString() ?? '',
      currency: json['currency']?.toString() ?? 'INR',
      accountsPayable: json['accounts_payable']?.toString() ?? 'Accounts Payable',
      openingBalance: (json['opening_balance'] ?? json['openingBalance'] ?? 0.0) is num
          ? (json['opening_balance'] ?? json['openingBalance'] ?? 0.0).toDouble()
          : double.tryParse(json['opening_balance']?.toString() ?? '0') ?? 0.0,
      paymentTerms: json['payment_terms']?.toString() ?? json['paymentTerms']?.toString() ?? 'Due on Receipt',
      website: json['website']?.toString() ?? '',
      socialLinks: json['social_links']?.toString() ?? '',
      billingAttention: json['billing_attention']?.toString() ?? '',
      billingAddressLine1: json['billing_address_line1']?.toString() ?? json['address']?.toString() ?? '',
      billingCity: json['billing_city']?.toString() ?? '',
      billingState: json['billing_state']?.toString() ?? '',
      billingPostalCode: json['billing_postal_code']?.toString() ?? '',
      billingCountry: json['billing_country']?.toString() ?? 'India',
      shippingSameAsBilling: json['shipping_same_as_billing'] != false,
      shippingAttention: json['shipping_attention']?.toString() ?? '',
      shippingAddressLine1: json['shipping_address_line1']?.toString() ?? '',
      shippingCity: json['shipping_city']?.toString() ?? '',
      shippingState: json['shipping_state']?.toString() ?? '',
      shippingPostalCode: json['shipping_postal_code']?.toString() ?? '',
      shippingCountry: json['shipping_country']?.toString() ?? 'India',
      contactPersons: (json['contact_persons'] is List)
          ? (json['contact_persons'] as List)
              .map((cp) => VendorContactPerson.fromJson(cp as Map<String, dynamic>))
              .toList()
          : [],
      remarks: json['remarks']?.toString() ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }
}
