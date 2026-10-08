import 'package:intl/intl.dart';
import '../../customers/models/customer.dart';

enum QuotationStatus {
  draft,
  sent,
  accepted,
  rejected,
  expired,
  converted;

  String get displayName {
    switch (this) {
      case QuotationStatus.draft:
        return 'Draft';
      case QuotationStatus.sent:
        return 'Sent';
      case QuotationStatus.accepted:
        return 'Accepted';
      case QuotationStatus.rejected:
        return 'Rejected';
      case QuotationStatus.expired:
        return 'Expired';
      case QuotationStatus.converted:
        return 'Converted';
    }
  }

  String get apiValue {
    switch (this) {
      case QuotationStatus.draft:
        return 'DRAFT';
      case QuotationStatus.sent:
        return 'SENT';
      case QuotationStatus.accepted:
        return 'ACCEPTED';
      case QuotationStatus.rejected:
        return 'REJECTED';
      case QuotationStatus.expired:
        return 'EXPIRED';
      case QuotationStatus.converted:
        return 'CONVERTED';
    }
  }

  static QuotationStatus fromString(String? val) {
    if (val == null) return QuotationStatus.draft;
    final upper = val.toUpperCase().trim();
    switch (upper) {
      case 'SENT':
        return QuotationStatus.sent;
      case 'ACCEPTED':
      case 'APPROVED':
        return QuotationStatus.accepted;
      case 'REJECTED':
      case 'DECLINED':
        return QuotationStatus.rejected;
      case 'EXPIRED':
        return QuotationStatus.expired;
      case 'CONVERTED':
      case 'INVOICED':
        return QuotationStatus.converted;
      case 'DRAFT':
      default:
        return QuotationStatus.draft;
    }
  }
}

class QuotationItem {
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

  const QuotationItem({
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

  QuotationItem copyWith({
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
    return QuotationItem(
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

  factory QuotationItem.fromJson(Map<String, dynamic> json) {
    double toDouble(dynamic val, [double def = 0.0]) {
      if (val == null) return def;
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val) ?? def;
      return def;
    }

    return QuotationItem(
      id: json['id']?.toString() ?? DateTime.now().microsecondsSinceEpoch.toString(),
      productId: json['product_id']?.toString() ?? json['productId']?.toString(),
      name: (json['product'] ?? json['item_name'] ?? json['product_name'] ?? json['name'] ?? '').toString(),
      description: (json['description'] ?? json['item_description'] ?? '').toString(),
      hsnSac: (json['hsn_sac'] ?? json['hsn'] ?? json['hsn_code'] ?? '').toString(),
      quantity: toDouble(json['quantity'] ?? json['qty'], 1.0),
      unit: (json['unit'] ?? json['uom'] ?? 'Nos').toString(),
      unitPrice: toDouble(json['unit_price'] ?? json['price'] ?? json['rate']),
      gstRate: toDouble(json['tax'] ?? json['gst_rate'] ?? json['tax_rate'] ?? json['gst_percentage'], 18.0),
      discount: toDouble(json['discount'] ?? json['discount_value']),
      discountType: (json['discount_type'] ?? (json['discount'] != null && toDouble(json['discount']) > 100 ? '₹' : '%')).toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product': name,
      'item_name': name,
      if (productId != null && productId!.isNotEmpty) 'product_id': productId,
      'quantity': quantity,
      'unit_price': unitPrice,
      'unit': unit,
      'discount': discount,
      'discount_type': discountType,
      'tax': gstRate,
      'gst_rate': gstRate,
      'hsn_sac': hsnSac,
      'description': description,
      'line_total': total,
      'subtotal': subtotal,
      'taxable_amount': taxableAmount,
    };
  }
}

class Quotation {
  final String id;
  final String quotationNumber;
  final String? customerId;
  final Customer? customer;
  final String customerType; // 'Customer' or 'Business'
  final String businessName;
  final String mobileNumber;
  final String gstin;
  final String email;
  final String billingAddress;
  final String shippingAddress;
  final bool shippingSameAsBilling;
  final DateTime quotationDate;
  final DateTime expiryDate;
  final String salesperson;
  final String referenceNumber;
  final List<QuotationItem> items;
  final String notes;
  final String internalNotes;
  final String termsAndConditions;
  final QuotationStatus status;
  final bool isRoundOff;
  final double roundOff;
  final double grandTotal;
  final String currency;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Quotation({
    required this.id,
    required this.quotationNumber,
    this.customerId,
    this.customer,
    this.customerType = 'Business',
    this.businessName = '',
    this.mobileNumber = '',
    this.gstin = '',
    this.email = '',
    this.billingAddress = '',
    this.shippingAddress = '',
    this.shippingSameAsBilling = true,
    required this.quotationDate,
    required this.expiryDate,
    this.salesperson = '',
    this.referenceNumber = '',
    this.items = const [],
    this.notes = '',
    this.internalNotes = '',
    this.termsAndConditions = '',
    this.status = QuotationStatus.draft,
    this.isRoundOff = true,
    this.roundOff = 0.0,
    this.grandTotal = 0.0,
    this.currency = 'INR',
    required this.createdAt,
    this.updatedAt,
  });

  double get subtotal => items.fold(0.0, (sum, item) => sum + item.subtotal);
  double get totalDiscount => items.fold(0.0, (sum, item) => sum + item.discountAmount);
  double get taxableAmount => items.fold(0.0, (sum, item) => sum + item.taxableAmount);
  double get totalGst => items.fold(0.0, (sum, item) => sum + item.taxAmount);

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

  Quotation copyWith({
    String? id,
    String? quotationNumber,
    String? customerId,
    Customer? customer,
    String? customerType,
    String? businessName,
    String? mobileNumber,
    String? gstin,
    String? email,
    String? billingAddress,
    String? shippingAddress,
    bool? shippingSameAsBilling,
    DateTime? quotationDate,
    DateTime? expiryDate,
    String? salesperson,
    String? referenceNumber,
    List<QuotationItem>? items,
    String? notes,
    String? internalNotes,
    String? termsAndConditions,
    QuotationStatus? status,
    bool? isRoundOff,
    double? roundOff,
    double? grandTotal,
    String? currency,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Quotation(
      id: id ?? this.id,
      quotationNumber: quotationNumber ?? this.quotationNumber,
      customerId: customerId ?? this.customerId,
      customer: customer ?? this.customer,
      customerType: customerType ?? this.customerType,
      businessName: businessName ?? this.businessName,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      gstin: gstin ?? this.gstin,
      email: email ?? this.email,
      billingAddress: billingAddress ?? this.billingAddress,
      shippingAddress: shippingAddress ?? this.shippingAddress,
      shippingSameAsBilling: shippingSameAsBilling ?? this.shippingSameAsBilling,
      quotationDate: quotationDate ?? this.quotationDate,
      expiryDate: expiryDate ?? this.expiryDate,
      salesperson: salesperson ?? this.salesperson,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      items: items ?? this.items,
      notes: notes ?? this.notes,
      internalNotes: internalNotes ?? this.internalNotes,
      termsAndConditions: termsAndConditions ?? this.termsAndConditions,
      status: status ?? this.status,
      isRoundOff: isRoundOff ?? this.isRoundOff,
      roundOff: roundOff ?? this.roundOff,
      grandTotal: grandTotal ?? this.grandTotal,
      currency: currency ?? this.currency,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Quotation.fromJson(Map<String, dynamic> json) {
    Customer? cust;
    if (json['customer'] is Map<String, dynamic>) {
      cust = Customer.fromJson(json['customer'] as Map<String, dynamic>);
    }

    final itemsRaw = json['items'] ?? json['line_items'] ?? json['quotation_items'];
    final List<QuotationItem> itemsList = [];
    if (itemsRaw is List) {
      for (final item in itemsRaw) {
        if (item is Map<String, dynamic>) {
          itemsList.add(QuotationItem.fromJson(item));
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

    final customerNameStr = (json['customer_name'] ??
            (json['customer'] is String ? json['customer'] : null) ??
            json['business_name'] ??
            cust?.name ??
            '')
        .toString();

    final custId = (json['customer_id'] ?? cust?.id)?.toString();

    return Quotation(
      id: (json['id'] ?? '').toString(),
      quotationNumber: (json['estimate_number'] ?? json['quotation_number'] ?? json['quotationNumber'] ?? '').toString(),
      customerId: custId,
      customer: cust,
      customerType: (json['customer_type'] ?? json['customerType'] ?? 'Business').toString(),
      businessName: customerNameStr,
      mobileNumber: (json['mobile_number'] ?? json['phone'] ?? cust?.phone ?? '').toString(),
      gstin: (json['gstin'] ?? json['gst_number'] ?? cust?.gstNumber ?? '').toString(),
      email: (json['email'] ?? cust?.email ?? '').toString(),
      billingAddress: (json['billing_address'] ?? json['address'] ?? cust?.address ?? '').toString(),
      shippingAddress: (json['shipping_address'] ?? '').toString(),
      shippingSameAsBilling: json['shipping_same_as_billing'] == true ||
          json['shippingSameAsBilling'] == true ||
          json['shipping_address'] == null,
      quotationDate: parseDate(json['estimate_date'] ?? json['quotation_date'] ?? json['date']),
      expiryDate: parseDate(
          json['expiry_date'] ?? json['valid_until'] ?? json['due_date'], DateTime.now().add(const Duration(days: 30))),
      salesperson: (json['sales_person'] ?? json['salesperson'] ?? '').toString(),
      referenceNumber: (json['reference_no'] ?? json['reference_number'] ?? '').toString(),
      items: itemsList,
      notes: (json['notes'] ?? json['customer_notes'] ?? '').toString(),
      internalNotes: (json['internal_notes'] ?? json['internal_note'] ?? '').toString(),
      termsAndConditions: (json['terms_and_conditions'] ?? json['terms'] ?? '').toString(),
      status: QuotationStatus.fromString(json['status']?.toString()),
      isRoundOff: json['is_round_off'] ?? json['round_off_applied'] ?? true,
      roundOff: toDouble(json['round_off']),
      grandTotal: toDouble(json['grand_total'] ?? json['total']),
      currency: (json['currency'] ?? 'INR').toString(),
      createdAt: parseDate(json['created_at'], DateTime.now()),
      updatedAt: json['updated_at'] != null ? parseDate(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    final dateFmt = DateFormat('yyyy-MM-dd');
    final custName = businessName.isNotEmpty
        ? businessName
        : (customer?.companyName.isNotEmpty == true ? customer!.companyName : customer?.name ?? '');
    final cId = customerId ?? customer?.id;

    return {
      if (quotationNumber.trim().isNotEmpty) 'estimate_number': quotationNumber.trim(),
      'customer': custName,
      if (cId != null && cId.isNotEmpty) 'customer_id': cId,
      'customer_name': custName,
      'status': status.apiValue,
      'estimate_date': dateFmt.format(quotationDate),
      'expiry_date': dateFmt.format(expiryDate),
      'currency': currency,
      'sales_person': salesperson,
      'reference_no': referenceNumber,
      'customer_type': customerType.toUpperCase(),
      'mobile_number': mobileNumber,
      'gstin': gstin,
      'email': email,
      'billing_address': billingAddress,
      'shipping_address': shippingAddress,
      'shipping_same_as_billing': shippingSameAsBilling,
      'notes': notes,
      'terms_and_conditions': termsAndConditions,
      'items': items.map((e) => e.toJson()).toList(),
      'subtotal': subtotal,
      'discount_total': totalDiscount,
      'taxable_amount': taxableAmount,
      'tax_total': totalGst,
      'round_off': roundOff,
      'grand_total': grandTotal,
    };
  }
}
