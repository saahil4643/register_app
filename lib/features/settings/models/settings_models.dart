class CompanySettings {
  final String companyName;
  final String legalName;
  final String website;
  final String email;
  final String phone;
  final String gstNumber;
  final String panNumber;
  final String currency;
  final String timezone;
  final String country;
  final String state;
  final String city;
  final String address;
  final String postalCode;
  final String financialYear;
  final String language;
  final String dateFormat;
  final String timeFormat;
  final String? companyLogo;

  CompanySettings({
    required this.companyName,
    required this.legalName,
    required this.website,
    required this.email,
    required this.phone,
    required this.gstNumber,
    required this.panNumber,
    required this.currency,
    required this.timezone,
    required this.country,
    required this.state,
    required this.city,
    required this.address,
    required this.postalCode,
    required this.financialYear,
    required this.language,
    required this.dateFormat,
    required this.timeFormat,
    this.companyLogo,
  });

  factory CompanySettings.fromJson(Map<String, dynamic> json) {
    return CompanySettings(
      companyName: json['companyName'] ?? json['company_name'] ?? '',
      legalName: json['legalName'] ?? json['legal_name'] ?? json['companyName'] ?? json['company_name'] ?? '',
      website: json['website'] ?? json['websiteUrl'] ?? '',
      email: json['email'] ?? json['businessEmail'] ?? '',
      phone: json['phone'] ?? json['businessPhone'] ?? '',
      gstNumber: json['gstinOrg'] ?? json['gstin'] ?? json['taxId'] ?? json['gst_number'] ?? '',
      panNumber: json['panNumber'] ?? json['pan_number'] ?? '',
      currency: json['currency'] ?? 'INR',
      timezone: json['timeZone'] ?? json['time_zone'] ?? json['timezone'] ?? 'UTC',
      country: json['country'] ?? 'India',
      state: json['state'] ?? '',
      city: json['city'] ?? '',
      address: json['address'] ?? json['streetAddress'] ?? '',
      postalCode: json['postalCode'] ?? json['zipCode'] ?? json['postal_code'] ?? '',
      financialYear: json['financialYear'] ?? json['financial_year'] ?? 'April - March',
      language: json['language'] ?? 'en',
      dateFormat: json['dateFormat'] ?? json['date_format'] ?? 'YYYY-MM-DD',
      timeFormat: json['timeFormat'] ?? json['time_format'] ?? 'HH:mm:ss',
      companyLogo: json['companyLogo'] ?? json['company_logo'] ?? json['logo'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'companyName': companyName,
      'company_name': companyName,
      'legalName': legalName.isNotEmpty ? legalName : companyName,
      'legal_name': legalName.isNotEmpty ? legalName : companyName,
      'website': website,
      'websiteUrl': website,
      'email': email,
      'businessEmail': email,
      'phone': phone,
      'businessPhone': phone,
      'gstinOrg': gstNumber,
      'gstin': gstNumber,
      'gst_number': gstNumber,
      'panNumber': panNumber,
      'pan_number': panNumber,
      'currency': currency,
      'timeZone': timezone,
      'timezone': timezone,
      'country': country,
      'state': state,
      'city': city,
      'address': address,
      'streetAddress': address,
      'postalCode': postalCode,
      'zipCode': postalCode,
      'postal_code': postalCode,
      'financialYear': financialYear,
      'financial_year': financialYear,
      'language': language,
      'dateFormat': dateFormat,
      'date_format': dateFormat,
      'timeFormat': timeFormat,
      'time_format': timeFormat,
      if (companyLogo != null && companyLogo!.isNotEmpty) 'companyLogo': companyLogo,
    };
  }

  Map<String, dynamic> toOrganizationJson() {
    return {
      'companyName': companyName,
      'email': email,
      'phone': phone,
      'address': address,
      'city': city,
      'state': state,
      'postalCode': postalCode,
      'website': website,
      'gstinOrg': gstNumber,
      if (companyLogo != null && companyLogo!.isNotEmpty) 'companyLogo': companyLogo,
    };
  }
}

class FinancialSettings {
  final String baseCurrency;
  final String currencySymbol;
  final int decimalPlaces;
  final String defaultPaymentTerms;
  final String invoicePrefix;
  final String quotationPrefix;
  final String estimatePrefix;
  final String purchasePrefix;
  final String creditNotePrefix;
  final String debitNotePrefix;
  final String defaultDiscountType;
  final bool taxInclusive;
  final bool roundOff;
  final bool autoNumberGeneration;
  final String invoiceNumberFormat;
  final int invoiceStartingNumber;
  final int invoiceNumberPadding;

  FinancialSettings({
    required this.baseCurrency,
    required this.currencySymbol,
    required this.decimalPlaces,
    required this.defaultPaymentTerms,
    required this.invoicePrefix,
    required this.quotationPrefix,
    required this.estimatePrefix,
    required this.purchasePrefix,
    required this.creditNotePrefix,
    required this.debitNotePrefix,
    required this.defaultDiscountType,
    required this.taxInclusive,
    required this.roundOff,
    required this.autoNumberGeneration,
    required this.invoiceNumberFormat,
    required this.invoiceStartingNumber,
    required this.invoiceNumberPadding,
  });

  factory FinancialSettings.fromJson(Map<String, dynamic> json) {
    return FinancialSettings(
      baseCurrency: json['base_currency'] ?? 'INR',
      currencySymbol: json['currency_symbol'] ?? '₹',
      decimalPlaces: json['decimal_places'] ?? 2,
      defaultPaymentTerms: json['default_payment_terms'] ?? 'Immediate',
      invoicePrefix: json['invoice_prefix'] ?? 'INV',
      quotationPrefix: json['quotation_prefix'] ?? 'QTN',
      estimatePrefix: json['estimate_prefix'] ?? 'EST',
      purchasePrefix: json['purchase_prefix'] ?? 'PO',
      creditNotePrefix: json['credit_note_prefix'] ?? 'CN',
      debitNotePrefix: json['debit_note_prefix'] ?? 'DN',
      defaultDiscountType: json['default_discount_type'] ?? 'flat',
      taxInclusive: json['tax_inclusive'] ?? false,
      roundOff: json['round_off'] ?? true,
      autoNumberGeneration: json['auto_number_generation'] ?? true,
      invoiceNumberFormat: json['invoice_number_format'] ?? 'prefix_dashed_number',
      invoiceStartingNumber: json['invoice_starting_number'] ?? 1,
      invoiceNumberPadding: json['invoice_number_padding'] ?? 3,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'base_currency': baseCurrency,
      'currency_symbol': currencySymbol,
      'decimal_places': decimalPlaces,
      'default_payment_terms': defaultPaymentTerms,
      'invoice_prefix': invoicePrefix,
      'quotation_prefix': quotationPrefix,
      'estimate_prefix': estimatePrefix,
      'purchase_prefix': purchasePrefix,
      'credit_note_prefix': creditNotePrefix,
      'debit_note_prefix': debitNotePrefix,
      'default_discount_type': defaultDiscountType,
      'tax_inclusive': taxInclusive,
      'round_off': roundOff,
      'auto_number_generation': autoNumberGeneration,
      'invoice_number_format': invoiceNumberFormat,
      'invoice_starting_number': invoiceStartingNumber,
      'invoice_number_padding': invoiceNumberPadding,
    };
  }
}

class TaxSettings {
  final String taxName;
  final String taxType;
  final double taxPercentage;
  final bool hsnEnabled;
  final bool sacEnabled;
  final bool reverseCharge;
  final bool defaultTax;

  TaxSettings({
    required this.taxName,
    required this.taxType,
    required this.taxPercentage,
    required this.hsnEnabled,
    required this.sacEnabled,
    required this.reverseCharge,
    required this.defaultTax,
  });

  factory TaxSettings.fromJson(Map<String, dynamic> json) {
    return TaxSettings(
      taxName: json['tax_name'] ?? '',
      taxType: json['tax_type'] ?? 'GST',
      taxPercentage: (json['tax_percentage'] ?? 0.0).toDouble(),
      hsnEnabled: json['hsn_enabled'] ?? true,
      sacEnabled: json['sac_enabled'] ?? true,
      reverseCharge: json['reverse_charge'] ?? false,
      defaultTax: json['default_tax'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tax_name': taxName,
      'tax_type': taxType,
      'tax_percentage': taxPercentage,
      'hsn_enabled': hsnEnabled,
      'sac_enabled': sacEnabled,
      'reverse_charge': reverseCharge,
      'default_tax': defaultTax,
    };
  }
}

class EmailSettings {
  final String smtpHost;
  final int smtpPort;
  final String username;
  final String password;
  final String encryptionType;
  final String senderEmail;
  final String senderName;
  final String replyEmail;
  final bool passwordConfigured;

  EmailSettings({
    required this.smtpHost,
    required this.smtpPort,
    required this.username,
    required this.password,
    required this.encryptionType,
    required this.senderEmail,
    required this.senderName,
    required this.replyEmail,
    required this.passwordConfigured,
  });

  factory EmailSettings.fromJson(Map<String, dynamic> json) {
    return EmailSettings(
      smtpHost: json['smtp_host'] ?? '',
      smtpPort: json['smtp_port'] ?? 587,
      username: json['username'] ?? '',
      password: json['password'] ?? '',
      encryptionType: json['encryption_type'] ?? 'TLS',
      senderEmail: json['sender_email'] ?? '',
      senderName: json['sender_name'] ?? '',
      replyEmail: json['reply_email'] ?? '',
      passwordConfigured: json['password_configured'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'smtp_host': smtpHost,
      'smtp_port': smtpPort,
      'username': username,
      'encryption_type': encryptionType,
      'sender_email': senderEmail,
      'sender_name': senderName,
      'reply_email': replyEmail,
    };
    if (password.isNotEmpty) {
      data['password'] = password;
    }
    return data;
  }
}

class BackupHistory {
  final String id;
  final String backupName;
  final String status;
  final int fileSize;
  final String createdAt;

  BackupHistory({
    required this.id,
    required this.backupName,
    required this.status,
    required this.fileSize,
    required this.createdAt,
  });

  factory BackupHistory.fromJson(Map<String, dynamic> json) {
    return BackupHistory(
      id: json['id'] ?? '',
      backupName: json['backup_name'] ?? '',
      status: json['status'] ?? 'pending',
      fileSize: json['file_size'] ?? 0,
      createdAt: json['created_at'] ?? '',
    );
  }
}

class IntegrationSettings {
  final bool razorpayEnabled;
  final String razorpayKeyId;
  final String razorpayKeySecret;
  final bool stripeEnabled;
  final String stripePublishableKey;
  final String stripeSecretKey;
  final bool paypalEnabled;
  final String paypalClientId;
  final String paypalClientSecret;

  IntegrationSettings({
    required this.razorpayEnabled,
    required this.razorpayKeyId,
    required this.razorpayKeySecret,
    required this.stripeEnabled,
    required this.stripePublishableKey,
    required this.stripeSecretKey,
    required this.paypalEnabled,
    required this.paypalClientId,
    required this.paypalClientSecret,
  });

  factory IntegrationSettings.fromJson(Map<String, dynamic> json) {
    return IntegrationSettings(
      razorpayEnabled: json['razorpay_enabled'] ?? false,
      razorpayKeyId: json['razorpay_key_id'] ?? '',
      razorpayKeySecret: json['razorpay_key_secret'] ?? '',
      stripeEnabled: json['stripe_enabled'] ?? false,
      stripePublishableKey: json['stripe_publishable_key'] ?? '',
      stripeSecretKey: json['stripe_secret_key'] ?? '',
      paypalEnabled: json['paypal_enabled'] ?? false,
      paypalClientId: json['paypal_client_id'] ?? '',
      paypalClientSecret: json['paypal_client_secret'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'razorpay_enabled': razorpayEnabled,
      'razorpay_key_id': razorpayKeyId,
      'razorpay_key_secret': razorpayKeySecret,
      'stripe_enabled': stripeEnabled,
      'stripe_publishable_key': stripePublishableKey,
      'stripe_secret_key': stripeSecretKey,
      'paypal_enabled': paypalEnabled,
      'paypal_client_id': paypalClientId,
      'paypal_client_secret': paypalClientSecret,
    };
  }
}

class SystemPreferences {
  final bool maintenanceMode;
  final bool debugMode;
  final String applicationVersion;
  final int defaultPagination;
  final String timezone;
  final String language;

  SystemPreferences({
    required this.maintenanceMode,
    required this.debugMode,
    required this.applicationVersion,
    required this.defaultPagination,
    required this.timezone,
    required this.language,
  });

  factory SystemPreferences.fromJson(Map<String, dynamic> json) {
    return SystemPreferences(
      maintenanceMode: json['maintenance_mode'] ?? false,
      debugMode: json['debug_mode'] ?? false,
      applicationVersion: json['application_version'] ?? '1.0.0',
      defaultPagination: json['default_pagination'] ?? 10,
      timezone: json['timezone'] ?? 'UTC',
      language: json['language'] ?? 'en',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'maintenance_mode': maintenanceMode,
      'debug_mode': debugMode,
      'application_version': applicationVersion,
      'default_pagination': defaultPagination,
      'timezone': timezone,
      'language': language,
    };
  }
}

class StaffUser {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String role;
  final String status;
  final String lastLogin;

  StaffUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.status,
    required this.lastLogin,
  });

  factory StaffUser.fromJson(Map<String, dynamic> json) {
    return StaffUser(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      role: json['role'] ?? 'User',
      status: json['status'] ?? 'Active',
      lastLogin: json['last_login'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'status': status,
    };
  }
}

class PaymentMethod {
  final String id;
  final String name;
  final String status;
  final bool isDefault;
  final Map<String, dynamic> accountDetails;

  PaymentMethod({
    required this.id,
    required this.name,
    required this.status,
    required this.isDefault,
    required this.accountDetails,
  });

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      status: json['status'] ?? 'active',
      isDefault: json['is_default'] ?? json['default'] ?? false,
      accountDetails: json['account_details'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'status': status,
      'is_default': isDefault,
      'default': isDefault,
      'account_details': accountDetails,
    };
  }
}

class TaxRate {
  final String id;
  final String taxName;
  final double percentage;
  final bool isDefault;
  final bool isActive;

  TaxRate({
    required this.id,
    required this.taxName,
    required this.percentage,
    required this.isDefault,
    required this.isActive,
  });

  factory TaxRate.fromJson(Map<String, dynamic> json) {
    return TaxRate(
      id: json['id'] ?? '',
      taxName: json['tax_name'] ?? '',
      percentage: double.tryParse(json['percentage']?.toString() ?? '0.0') ?? 0.0,
      isDefault: json['default'] ?? json['is_default'] ?? false,
      isActive: json['active'] ?? json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tax_name': taxName,
      'percentage': percentage.toStringAsFixed(2),
      'default': isDefault,
      'active': isActive,
    };
  }
}
