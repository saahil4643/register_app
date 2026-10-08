import 'package:intl/intl.dart';
import '../../customers/models/customer.dart';

enum ProformaStatus {
  draft,
  sent,
  invoiced,
  expired,
  approved,
  cancelled;

  String get displayName {
    switch (this) {
      case ProformaStatus.draft:
        return 'Draft';
      case ProformaStatus.sent:
        return 'Sent';
      case ProformaStatus.invoiced:
        return 'Invoiced';
      case ProformaStatus.expired:
        return 'Expired';
      case ProformaStatus.approved:
        return 'Approved';
      case ProformaStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get toApiString {
    switch (this) {
      case ProformaStatus.draft:
        return 'draft';
      case ProformaStatus.sent:
        return 'sent';
      case ProformaStatus.invoiced:
        return 'invoiced';
      case ProformaStatus.expired:
        return 'expired';
      case ProformaStatus.approved:
        return 'approved';
      case ProformaStatus.cancelled:
        return 'cancelled';
    }
  }

  static ProformaStatus fromString(String? val) {
    if (val == null) return ProformaStatus.draft;
    final lower = val.toLowerCase().trim();
    if (lower == 'sent') return ProformaStatus.sent;
    if (lower == 'invoiced' || lower == 'converted') return ProformaStatus.invoiced;
    if (lower == 'expired') return ProformaStatus.expired;
    if (lower == 'approved' || lower == 'accepted') return ProformaStatus.approved;
    if (lower == 'cancelled' || lower == 'declined' || lower == 'rejected') return ProformaStatus.cancelled;
    return ProformaStatus.draft;
  }
}

class ProformaItem {
  final String id;
  final String? productId;
  final String name;
  final String description;
  final String hsnSac;
  final double quantity;
  final String unit;
  final double unitPrice;
  final double gstRate;
  final double discount;
  final String discountType; // '%' or '₹'

  const ProformaItem({
    required this.id,
    this.productId,
    required this.name,
    this.description = '',
    this.hsnSac = '',
    this.quantity = 1.0,
    this.unit = 'Nos',
    this.unitPrice = 0.0,
    this.gstRate = 18.0,
    this.discount = 0.0,
    this.discountType = '%',
  });

  double get subtotal => unitPrice * quantity;

  double get discountAmount {
    if (discount <= 0) return 0.0;
    if (discountType == '₹') {
      return discount.clamp(0.0, subtotal);
    }
    return (subtotal * (discount / 100)).clamp(0.0, subtotal);
  }

  double get taxableAmount => (subtotal - discountAmount).clamp(0.0, double.infinity);

  double get taxAmount => taxableAmount * (gstRate / 100);

  double get total => taxableAmount + taxAmount;

  ProformaItem copyWith({
    String? id,
    String? productId,
    String? name,
    String? description,
    String? hsnSac,
    double? quantity,
    String? unit,
    double? unitPrice,
    double? gstRate,
    double? discount,
    String? discountType,
  }) {
    return ProformaItem(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      name: name ?? this.name,
      description: description ?? this.description,
      hsnSac: hsnSac ?? this.hsnSac,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      unitPrice: unitPrice ?? this.unitPrice,
      gstRate: gstRate ?? this.gstRate,
      discount: discount ?? this.discount,
      discountType: discountType ?? this.discountType,
    );
  }

  factory ProformaItem.fromJson(Map<String, dynamic> json) {
    double toDouble(dynamic val, [double def = 0.0]) {
      if (val == null) return def;
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val) ?? def;
      return def;
    }

    String? prodId = json['product_id']?.toString() ?? json['productId']?.toString();
    String prodName = (json['name'] ?? json['item_name'] ?? json['product_name'] ?? '').toString();
    String prodDesc = (json['description'] ?? json['item_description'] ?? '').toString();

    if (json['product'] is Map<String, dynamic>) {
      final pMap = json['product'] as Map<String, dynamic>;
      prodId = pMap['id']?.toString() ?? prodId;
      if (prodName.isEmpty) {
        prodName = (pMap['name'] ?? '').toString();
      }
    } else if (json['product'] is String) {
      prodId = json['product'] as String;
    }

    if (prodName.isEmpty && prodDesc.isNotEmpty) {
      prodName = prodDesc;
    }

    return ProformaItem(
      id: json['id']?.toString() ?? DateTime.now().microsecondsSinceEpoch.toString(),
      productId: prodId,
      name: prodName,
      description: prodDesc,
      hsnSac: (json['hsn_sac'] ?? json['hsn'] ?? json['hsn_code'] ?? '').toString(),
      quantity: toDouble(json['quantity'] ?? json['qty'], 1.0),
      unit: (json['unit'] ?? json['uom'] ?? 'Nos').toString(),
      unitPrice: toDouble(json['unit_price'] ?? json['price'] ?? json['rate']),
      gstRate: toDouble(json['tax'] ?? json['gst_rate'] ?? json['tax_rate'] ?? json['gst_percentage'], 18.0),
      discount: toDouble(json['discount'] ?? json['discount_value']),
      discountType: (json['discount_type'] ?? '%').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'name': name,
      'description': description,
      'hsn_sac': hsnSac,
      'quantity': quantity,
      'unit': unit,
      'unit_price': unitPrice,
      'gst_rate': gstRate,
      'discount': discount,
      'discount_type': discountType,
      'subtotal': subtotal,
      'taxable_amount': taxableAmount,
      'tax_amount': taxAmount,
      'total': total,
    };
  }

  Map<String, dynamic> toCreateItemPayload() {
    final uuidRegex = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');
    final validProductId = (productId != null && uuidRegex.hasMatch(productId!)) ? productId : null;

    return {
      'product': ?validProductId,
      'description': description.isNotEmpty ? description : (name.isNotEmpty ? name : 'Item'),
      'quantity': quantity > 0 ? quantity : 1.0,
      'unit_price': unitPrice,
      'discount': discountAmount,
      'tax': gstRate,
    };
  }
}

class ProformaInvoice {
  final String id;
  final String proformaNumber;
  final Customer? customer;
  final String? customerId;
  final String customerType; // 'Customer' or 'Business'
  final String businessName;
  final String mobileNumber;
  final String gstin;
  final String email;
  final String billingAddress;
  final String shippingAddress;
  final bool shippingSameAsBilling;
  final DateTime proformaDate;
  final DateTime dueDate;
  final String salesperson;
  final String referenceNumber;
  final List<ProformaItem> items;
  final String notes;
  final String internalNotes;
  final String termsAndConditions;
  final ProformaStatus status;
  final bool isRoundOff;
  final double roundOff;
  final double subtotalAmount;
  final double discountTotal;
  final double taxTotal;
  final double grandTotal;
  final String currency;
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const ProformaInvoice({
    required this.id,
    required this.proformaNumber,
    this.customer,
    this.customerId,
    this.customerType = 'Business',
    this.businessName = '',
    this.mobileNumber = '',
    this.gstin = '',
    this.email = '',
    this.billingAddress = '',
    this.shippingAddress = '',
    this.shippingSameAsBilling = true,
    required this.proformaDate,
    required this.dueDate,
    this.salesperson = '',
    this.referenceNumber = '',
    this.items = const [],
    this.notes = '',
    this.internalNotes = '',
    this.termsAndConditions = '',
    this.status = ProformaStatus.draft,
    this.isRoundOff = true,
    this.roundOff = 0.0,
    this.subtotalAmount = 0.0,
    this.discountTotal = 0.0,
    this.taxTotal = 0.0,
    this.grandTotal = 0.0,
    this.currency = 'INR',
    this.isDeleted = false,
    required this.createdAt,
    this.updatedAt,
  });

  double get subtotal => items.isNotEmpty ? items.fold(0.0, (sum, item) => sum + item.subtotal) : subtotalAmount;
  double get totalDiscount => items.isNotEmpty ? items.fold(0.0, (sum, item) => sum + item.discountAmount) : discountTotal;
  double get taxableAmount => items.isNotEmpty ? items.fold(0.0, (sum, item) => sum + item.taxableAmount) : subtotalAmount - discountTotal;
  double get totalGst => items.isNotEmpty ? items.fold(0.0, (sum, item) => sum + item.taxAmount) : taxTotal;

  double get computedGrandTotal {
    final raw = taxableAmount + totalGst;
    if (isRoundOff) {
      return raw.roundToDouble();
    }
    return raw;
  }

  double get computedRoundOffDiff {
    final raw = taxableAmount + totalGst;
    if (isRoundOff) {
      return raw.roundToDouble() - raw;
    }
    return 0.0;
  }

  ProformaInvoice copyWith({
    String? id,
    String? proformaNumber,
    Customer? customer,
    String? customerId,
    String? customerType,
    String? businessName,
    String? mobileNumber,
    String? gstin,
    String? email,
    String? billingAddress,
    String? shippingAddress,
    bool? shippingSameAsBilling,
    DateTime? proformaDate,
    DateTime? dueDate,
    String? salesperson,
    String? referenceNumber,
    List<ProformaItem>? items,
    String? notes,
    String? internalNotes,
    String? termsAndConditions,
    ProformaStatus? status,
    bool? isRoundOff,
    double? roundOff,
    double? subtotalAmount,
    double? discountTotal,
    double? taxTotal,
    double? grandTotal,
    String? currency,
    bool? isDeleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProformaInvoice(
      id: id ?? this.id,
      proformaNumber: proformaNumber ?? this.proformaNumber,
      customer: customer ?? this.customer,
      customerId: customerId ?? this.customerId,
      customerType: customerType ?? this.customerType,
      businessName: businessName ?? this.businessName,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      gstin: gstin ?? this.gstin,
      email: email ?? this.email,
      billingAddress: billingAddress ?? this.billingAddress,
      shippingAddress: shippingAddress ?? this.shippingAddress,
      shippingSameAsBilling: shippingSameAsBilling ?? this.shippingSameAsBilling,
      proformaDate: proformaDate ?? this.proformaDate,
      dueDate: dueDate ?? this.dueDate,
      salesperson: salesperson ?? this.salesperson,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      items: items ?? this.items,
      notes: notes ?? this.notes,
      internalNotes: internalNotes ?? this.internalNotes,
      termsAndConditions: termsAndConditions ?? this.termsAndConditions,
      status: status ?? this.status,
      isRoundOff: isRoundOff ?? this.isRoundOff,
      roundOff: roundOff ?? this.roundOff,
      subtotalAmount: subtotalAmount ?? this.subtotalAmount,
      discountTotal: discountTotal ?? this.discountTotal,
      taxTotal: taxTotal ?? this.taxTotal,
      grandTotal: grandTotal ?? this.grandTotal,
      currency: currency ?? this.currency,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory ProformaInvoice.fromJson(Map<String, dynamic> json) {
    Customer? cust;
    String custName = '';
    String? custId = json['customer_id']?.toString();
    String custEmail = (json['email'] ?? '').toString();

    if (json['customer'] is Map<String, dynamic>) {
      final cMap = json['customer'] as Map<String, dynamic>;
      cust = Customer.fromJson(cMap);
      custId = cMap['id']?.toString() ?? custId;
      custName = (cMap['name'] ?? custName).toString();
      if (custEmail.isEmpty && cMap['email'] != null) {
        custEmail = cMap['email'].toString();
      }
    } else if (json['customer'] is String) {
      custName = json['customer'] as String;
    }

    if (custName.isEmpty) {
      custName = (json['customer_name'] ?? json['business_name'] ?? cust?.name ?? '').toString();
    }

    final itemsRaw = json['items'] ?? json['line_items'] ?? json['proforma_items'];
    final List<ProformaItem> itemsList = [];
    if (itemsRaw is List) {
      for (final item in itemsRaw) {
        if (item is Map<String, dynamic>) {
          itemsList.add(ProformaItem.fromJson(item));
        }
      }
    }

    DateTime parseDate(dynamic d, [DateTime? fallback]) {
      if (d == null) return fallback ?? DateTime.now();
      if (d is DateTime) return d;
      return DateTime.tryParse(d.toString()) ?? fallback ?? DateTime.now();
    }

    double toDouble(dynamic val, [double def = 0.0]) {
      if (val == null) return def;
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val) ?? def;
      return def;
    }

    return ProformaInvoice(
      id: (json['id'] ?? '').toString(),
      proformaNumber: (json['proforma_invoice_number'] ?? json['proforma_number'] ?? json['invoice_number'] ?? json['proformaNumber'] ?? '').toString(),
      customer: cust,
      customerId: custId,
      customerType: (json['customer_type'] ?? json['customerType'] ?? 'Business').toString(),
      businessName: custName,
      mobileNumber: (json['mobile_number'] ?? json['phone'] ?? cust?.phone ?? '').toString(),
      gstin: (json['gstin'] ?? json['gst_number'] ?? cust?.gstNumber ?? '').toString(),
      email: custEmail.isNotEmpty ? custEmail : (cust?.email ?? ''),
      billingAddress: (json['billing_address'] ?? json['address'] ?? cust?.address ?? '').toString(),
      shippingAddress: (json['shipping_address'] ?? '').toString(),
      shippingSameAsBilling: json['shipping_same_as_billing'] == true || json['shippingSameAsBilling'] == true || json['shipping_address'] == null,
      proformaDate: parseDate(json['proforma_invoice_date'] ?? json['invoice_date'] ?? json['proforma_date'] ?? json['date']),
      dueDate: parseDate(json['due_date'] ?? json['valid_until'] ?? json['expiry_date'], DateTime.now().add(const Duration(days: 30))),
      salesperson: (json['salesperson'] ?? json['sales_person'] ?? '').toString(),
      referenceNumber: (json['reference_number'] ?? json['reference_no'] ?? '').toString(),
      items: itemsList,
      notes: (json['notes'] ?? json['customer_notes'] ?? '').toString(),
      internalNotes: (json['internal_notes'] ?? json['internal_note'] ?? '').toString(),
      termsAndConditions: (json['terms_and_conditions'] ?? json['terms'] ?? '').toString(),
      status: ProformaStatus.fromString(json['status']?.toString()),
      isRoundOff: json['is_round_off'] ?? json['round_off_applied'] ?? true,
      roundOff: toDouble(json['round_off']),
      subtotalAmount: toDouble(json['subtotal']),
      discountTotal: toDouble(json['discount_total']),
      taxTotal: toDouble(json['tax_total']),
      grandTotal: toDouble(json['grand_total'] ?? json['total']),
      currency: (json['currency'] ?? 'INR').toString(),
      isDeleted: json['is_deleted'] == true,
      createdAt: parseDate(json['created_at'], DateTime.now()),
      updatedAt: json['updated_at'] != null ? parseDate(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'proforma_invoice_number': proformaNumber,
      'customer_id': customerId ?? customer?.id,
      'customer_type': customerType,
      'business_name': businessName,
      'mobile_number': mobileNumber,
      'gstin': gstin,
      'email': email,
      'billing_address': billingAddress,
      'shipping_address': shippingAddress,
      'shipping_same_as_billing': shippingSameAsBilling,
      'invoice_date': proformaDate.toIso8601String(),
      'due_date': dueDate.toIso8601String(),
      'salesperson': salesperson,
      'reference_number': referenceNumber,
      'items': items.map((e) => e.toJson()).toList(),
      'notes': notes,
      'internal_notes': internalNotes,
      'terms_and_conditions': termsAndConditions,
      'status': status.toApiString,
      'subtotal': subtotal,
      'taxable_amount': taxableAmount,
      'total_gst': totalGst,
      'is_round_off': isRoundOff,
      'round_off': roundOff,
      'grand_total': grandTotal,
      'currency': currency,
      'is_deleted': isDeleted,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toCreatePayload() {
    final uuidRegex = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');
    String? custUuid;
    if (customer?.id != null && uuidRegex.hasMatch(customer!.id)) {
      custUuid = customer!.id;
    } else if (customerId != null && uuidRegex.hasMatch(customerId!)) {
      custUuid = customerId;
    }

    return {
      'customer': ?custUuid,
      'invoice_date': DateFormat('yyyy-MM-dd').format(proformaDate),
      'due_date': DateFormat('yyyy-MM-dd').format(dueDate),
      'currency': currency.isNotEmpty ? currency : 'INR',
      if (notes.isNotEmpty)
        'notes': notes.length > 250 ? notes.substring(0, 250) : notes,
      if (termsAndConditions.isNotEmpty)
        'terms_and_conditions': termsAndConditions.length > 250
            ? termsAndConditions.substring(0, 250)
            : termsAndConditions,
      'items': items.map((i) => i.toCreateItemPayload()).toList(),
    };
  }

  Map<String, dynamic> toUpdatePayload() {
    return {
      ...toCreatePayload(),
      'status': status.toApiString,
    };
  }
}

