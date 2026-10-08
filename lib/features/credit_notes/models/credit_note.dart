import 'package:intl/intl.dart';
import '../../customers/models/customer.dart';

enum CreditNoteStatus {
  open,
  partiallyApplied,
  refunded,
  closed,
  draft;

  String get displayName {
    switch (this) {
      case CreditNoteStatus.open:
        return 'Open (Unapplied)';
      case CreditNoteStatus.partiallyApplied:
        return 'Partially Applied';
      case CreditNoteStatus.refunded:
        return 'Refunded';
      case CreditNoteStatus.closed:
        return 'Closed';
      case CreditNoteStatus.draft:
        return 'Draft';
    }
  }

  String get toApiString {
    switch (this) {
      case CreditNoteStatus.open:
        return 'open';
      case CreditNoteStatus.partiallyApplied:
        return 'partially_applied';
      case CreditNoteStatus.refunded:
        return 'refunded';
      case CreditNoteStatus.closed:
        return 'closed';
      case CreditNoteStatus.draft:
        return 'draft';
    }
  }

  static CreditNoteStatus fromString(String? val) {
    if (val == null) return CreditNoteStatus.open;
    final lower = val.toLowerCase().trim();
    if (lower == 'draft') return CreditNoteStatus.draft;
    if (lower.contains('partially')) return CreditNoteStatus.partiallyApplied;
    if (lower.contains('refund')) return CreditNoteStatus.refunded;
    if (lower.contains('close')) return CreditNoteStatus.closed;
    if (lower == 'open') return CreditNoteStatus.open;
    return CreditNoteStatus.open;
  }
}

class CreditNoteItem {
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

  const CreditNoteItem({
    required this.id,
    this.productId,
    required this.name,
    this.description = '',
    this.hsnSac = '',
    this.quantity = 1.0,
    this.unit = 'Nos',
    this.unitPrice = 0.0,
    this.gstRate = 0.0,
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

  CreditNoteItem copyWith({
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
    return CreditNoteItem(
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

  factory CreditNoteItem.fromJson(Map<String, dynamic> json) {
    double toDouble(dynamic val, [double def = 0.0]) {
      if (val == null) return def;
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val) ?? def;
      return def;
    }

    String? prodId = json['product_id']?.toString() ?? json['productId']?.toString();
    String prodName = (json['name'] ?? json['item_name'] ?? '').toString();
    String prodDesc = (json['description'] ?? json['item_description'] ?? '').toString();

    if (json['product'] is Map<String, dynamic>) {
      final pMap = json['product'] as Map<String, dynamic>;
      prodId = pMap['id']?.toString() ?? prodId;
      if (prodName.isEmpty) {
        prodName = (pMap['name'] ?? '').toString();
      }
    }

    if (prodName.isEmpty && prodDesc.isNotEmpty) {
      prodName = prodDesc;
    }

    return CreditNoteItem(
      id: json['id']?.toString() ?? DateTime.now().microsecondsSinceEpoch.toString(),
      productId: prodId,
      name: prodName,
      description: prodDesc,
      hsnSac: (json['hsn_sac'] ?? json['hsn'] ?? '').toString(),
      quantity: toDouble(json['quantity'] ?? json['qty'], 1.0),
      unit: (json['unit'] ?? 'Nos').toString(),
      unitPrice: toDouble(json['unit_price'] ?? json['price'] ?? json['rate']),
      gstRate: toDouble(json['tax'] ?? json['tax_rate'] ?? json['gst_rate'], 0.0),
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
      'product_id': ?validProductId,
      'description': description.isNotEmpty ? description : (name.isNotEmpty ? name : 'Returned Item'),
      'hsn_sac': hsnSac,
      'unit': unit.isNotEmpty ? unit : 'Nos',
      'quantity': quantity > 0 ? quantity : 1.0,
      'unit_price': unitPrice,
      'discount': discountAmount,
      'tax': gstRate,
    };
  }
}

class CreditNote {
  final String id;
  final String creditNoteNumber;
  final Customer? customer;
  final String? customerId;
  final String customerType; // 'Customer' or 'Business'
  final String customerName;
  final String mobileNumber;
  final String gstin;
  final String email;
  final String billingAddress;
  final String shippingAddress;
  final bool shippingSameAsBilling;
  final DateTime creditNoteDate;
  final String? invoiceId;
  final String referenceInvoice;
  final String salesperson;
  final String referenceNumber;
  final String reason;
  final List<CreditNoteItem> items;
  final String notes;
  final String internalNotes;
  final String termsAndConditions;
  final CreditNoteStatus status;
  final bool isRoundOff;
  final double roundOff;
  final double totalAmount;
  final String currency;
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const CreditNote({
    required this.id,
    required this.creditNoteNumber,
    this.customer,
    this.customerId,
    this.customerType = 'Customer',
    this.customerName = '',
    this.mobileNumber = '',
    this.gstin = '',
    this.email = '',
    this.billingAddress = '',
    this.shippingAddress = '',
    this.shippingSameAsBilling = true,
    required this.creditNoteDate,
    this.invoiceId,
    this.referenceInvoice = '',
    this.salesperson = '',
    this.referenceNumber = '',
    this.reason = 'Damaged goods return',
    this.items = const [],
    this.notes = '',
    this.internalNotes = '',
    this.termsAndConditions = '',
    this.status = CreditNoteStatus.open,
    this.isRoundOff = true,
    this.roundOff = 0.0,
    this.totalAmount = 0.0,
    this.currency = 'INR',
    this.isDeleted = false,
    required this.createdAt,
    this.updatedAt,
  });

  double get subtotal => items.fold(0.0, (sum, item) => sum + item.subtotal);
  double get totalDiscount => items.fold(0.0, (sum, item) => sum + item.discountAmount);
  double get taxableAmount => items.fold(0.0, (sum, item) => sum + item.taxableAmount);
  double get totalGst => items.fold(0.0, (sum, item) => sum + item.taxAmount);

  double get computedTotal {
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

  CreditNote copyWith({
    String? id,
    String? creditNoteNumber,
    Customer? customer,
    String? customerId,
    String? customerType,
    String? customerName,
    String? mobileNumber,
    String? gstin,
    String? email,
    String? billingAddress,
    String? shippingAddress,
    bool? shippingSameAsBilling,
    DateTime? creditNoteDate,
    String? invoiceId,
    String? referenceInvoice,
    String? salesperson,
    String? referenceNumber,
    String? reason,
    List<CreditNoteItem>? items,
    String? notes,
    String? internalNotes,
    String? termsAndConditions,
    CreditNoteStatus? status,
    bool? isRoundOff,
    double? roundOff,
    double? totalAmount,
    String? currency,
    bool? isDeleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CreditNote(
      id: id ?? this.id,
      creditNoteNumber: creditNoteNumber ?? this.creditNoteNumber,
      customer: customer ?? this.customer,
      customerId: customerId ?? this.customerId,
      customerType: customerType ?? this.customerType,
      customerName: customerName ?? this.customerName,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      gstin: gstin ?? this.gstin,
      email: email ?? this.email,
      billingAddress: billingAddress ?? this.billingAddress,
      shippingAddress: shippingAddress ?? this.shippingAddress,
      shippingSameAsBilling: shippingSameAsBilling ?? this.shippingSameAsBilling,
      creditNoteDate: creditNoteDate ?? this.creditNoteDate,
      invoiceId: invoiceId ?? this.invoiceId,
      referenceInvoice: referenceInvoice ?? this.referenceInvoice,
      salesperson: salesperson ?? this.salesperson,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      reason: reason ?? this.reason,
      items: items ?? this.items,
      notes: notes ?? this.notes,
      internalNotes: internalNotes ?? this.internalNotes,
      termsAndConditions: termsAndConditions ?? this.termsAndConditions,
      status: status ?? this.status,
      isRoundOff: isRoundOff ?? this.isRoundOff,
      roundOff: roundOff ?? this.roundOff,
      totalAmount: totalAmount ?? this.totalAmount,
      currency: currency ?? this.currency,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory CreditNote.fromJson(Map<String, dynamic> json) {
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
      custName = (json['customer_name'] ?? cust?.name ?? '').toString();
    }

    final itemsRaw = json['items'] ?? json['line_items'] ?? json['returned_items'];
    final List<CreditNoteItem> itemsList = [];
    if (itemsRaw is List) {
      for (final item in itemsRaw) {
        if (item is Map<String, dynamic>) {
          itemsList.add(CreditNoteItem.fromJson(item));
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

    return CreditNote(
      id: (json['id'] ?? '').toString(),
      creditNoteNumber: (json['credit_note_number'] ?? json['number'] ?? json['creditNoteNumber'] ?? '').toString(),
      customer: cust,
      customerId: custId,
      customerType: (json['customer_type'] ?? json['customerType'] ?? 'Customer').toString(),
      customerName: custName,
      mobileNumber: (json['mobile_number'] ?? json['phone'] ?? cust?.phone ?? '').toString(),
      gstin: (json['gstin'] ?? json['gst_number'] ?? cust?.gstNumber ?? '').toString(),
      email: custEmail.isNotEmpty ? custEmail : (cust?.email ?? ''),
      billingAddress: (json['billing_address'] ?? json['address'] ?? cust?.address ?? '').toString(),
      shippingAddress: (json['shipping_address'] ?? '').toString(),
      shippingSameAsBilling: json['shipping_same_as_billing'] == true || json['shippingSameAsBilling'] == true || json['shipping_address'] == null,
      creditNoteDate: parseDate(json['credit_note_date'] ?? json['date']),
      invoiceId: json['invoice_id']?.toString() ?? json['invoice']?.toString(),
      referenceInvoice: (json['invoice_number'] ?? json['reference_invoice'] ?? '').toString(),
      salesperson: (json['sales_person'] ?? json['salesperson'] ?? '').toString(),
      referenceNumber: (json['reference_no'] ?? json['reference_number'] ?? '').toString(),
      reason: (json['reason'] ?? 'Damaged goods return').toString(),
      items: itemsList,
      notes: (json['notes'] ?? json['customer_notes'] ?? '').toString(),
      internalNotes: (json['internal_notes'] ?? json['internal_note'] ?? '').toString(),
      termsAndConditions: (json['terms_and_conditions'] ?? json['terms'] ?? '').toString(),
      status: CreditNoteStatus.fromString(json['status']?.toString()),
      isRoundOff: json['is_round_off'] == true || json['is_round_off'] == 1,
      roundOff: toDouble(json['round_off']),
      totalAmount: toDouble(json['grand_total'] ?? json['total_amount'] ?? json['amount'] ?? json['total']),
      currency: (json['currency'] ?? 'INR').toString(),
      isDeleted: json['is_deleted'] == true,
      createdAt: parseDate(json['created_at'], DateTime.now()),
      updatedAt: json['updated_at'] != null ? parseDate(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'credit_note_number': creditNoteNumber,
      'customer_id': customerId ?? customer?.id,
      'customer_type': customerType,
      'customer_name': customerName,
      'mobile_number': mobileNumber,
      'gstin': gstin,
      'email': email,
      'billing_address': billingAddress,
      'shipping_address': shippingAddress,
      'shipping_same_as_billing': shippingSameAsBilling,
      'credit_note_date': creditNoteDate.toIso8601String(),
      'invoice_id': invoiceId,
      'reference_invoice': referenceInvoice,
      'salesperson': salesperson,
      'reference_number': referenceNumber,
      'reason': reason,
      'items': items.map((e) => e.toJson()).toList(),
      'notes': notes,
      'internal_notes': internalNotes,
      'terms_and_conditions': termsAndConditions,
      'status': status.displayName.toLowerCase(),
      'subtotal': subtotal,
      'taxable_amount': taxableAmount,
      'total_gst': totalGst,
      'is_round_off': isRoundOff,
      'round_off': roundOff,
      'total_amount': totalAmount,
      'currency': currency,
      'is_deleted': isDeleted,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toCreatePayload() {
    final uuidRegex = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');

    // Customer UUID
    String? custUuid;
    if (customer?.id != null && uuidRegex.hasMatch(customer!.id)) {
      custUuid = customer!.id;
    } else if (customerId != null && uuidRegex.hasMatch(customerId!)) {
      custUuid = customerId;
    }

    // Invoice UUID
    String? invUuid;
    if (invoiceId != null && uuidRegex.hasMatch(invoiceId!)) {
      invUuid = invoiceId;
    } else if (referenceInvoice.isNotEmpty && uuidRegex.hasMatch(referenceInvoice)) {
      invUuid = referenceInvoice;
    }

    return {
      'customer': ?custUuid,
      'invoice': ?invUuid,
      if (creditNoteNumber.trim().isNotEmpty) 'credit_note_number': creditNoteNumber.trim(),
      'credit_note_date': DateFormat('yyyy-MM-dd').format(creditNoteDate),
      'currency': currency.isNotEmpty ? currency : 'INR',
      'status': status.toApiString,
      'reason': reason,
      if (salesperson.isNotEmpty) 'sales_person': salesperson,
      if (referenceNumber.isNotEmpty) 'reference_no': referenceNumber,
      if (notes.isNotEmpty) 'notes': notes,
      if (internalNotes.isNotEmpty) 'internal_notes': internalNotes,
      if (termsAndConditions.isNotEmpty) 'terms_and_conditions': termsAndConditions,
      'round_off': roundOff,
      'is_round_off': isRoundOff,
      'items': items.map((i) => i.toCreateItemPayload()).toList(),
    };
  }

  Map<String, dynamic> toUpdatePayload() {
    return toCreatePayload();
  }
}

