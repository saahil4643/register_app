import 'package:intl/intl.dart';

class PurchaseOrderItem {
  final String id;
  String name;
  String hsnCode;
  double quantity;
  String unit;
  double rate;
  double gstRate; // in percentage, e.g. 18.0
  double discount; // amount or percentage
  String discountType; // 'percentage' or 'amount'

  PurchaseOrderItem({
    required this.id,
    this.name = '',
    this.hsnCode = '',
    this.quantity = 1,
    this.unit = 'Nos',
    this.rate = 0.0,
    this.gstRate = 0.0,
    this.discount = 0.0,
    this.discountType = 'amount',
  });

  /// Base price before discount and tax
  double get baseAmount => quantity * rate;

  /// Calculated discount value
  double get discountAmount {
    if (discount <= 0) return 0.0;
    if (discountType == 'percentage') {
      return (baseAmount * (discount / 100)).clamp(0.0, baseAmount);
    }
    return discount.clamp(0.0, baseAmount);
  }

  /// Taxable amount after discount
  double get taxableAmount => (baseAmount - discountAmount).clamp(0.0, double.infinity);

  /// Calculated GST tax amount
  double get taxAmount => taxableAmount * (gstRate / 100);

  /// Total amount for this item
  double get totalAmount => taxableAmount + taxAmount;

  Map<String, dynamic> toJson() => {
        'id': id,
        'item_details': name,
        'name': name,
        'hsn_sac': hsnCode,
        'quantity': quantity,
        'unit': unit,
        'rate': rate,
        'gst_rate': gstRate,
        'discount': discount,
        'discount_type': discountType,
        'amount': totalAmount,
      };

  factory PurchaseOrderItem.fromJson(Map<String, dynamic> json) {
    final qty = (json['quantity'] as num?)?.toDouble() ?? (json['qty'] as num?)?.toDouble() ?? 1.0;
    final r = (json['rate'] as num?)?.toDouble() ?? 0.0;
    final disc = (json['discount'] as num?)?.toDouble() ?? 0.0;
    final discType = json['discount_type'] as String? ?? 'amount';
    final gst = (json['gst_rate'] as num?)?.toDouble() ?? (json['gst'] as num?)?.toDouble() ?? 0.0;

    return PurchaseOrderItem(
      id: json['id']?.toString() ?? 'item_${DateTime.now().microsecondsSinceEpoch}',
      name: json['item_details']?.toString() ?? json['name']?.toString() ?? '',
      hsnCode: json['hsn_sac']?.toString() ?? json['hsnCode']?.toString() ?? '',
      quantity: qty,
      unit: json['unit']?.toString() ?? 'Nos',
      rate: r,
      gstRate: gst,
      discount: disc,
      discountType: discType,
    );
  }

  PurchaseOrderItem copyWith({
    String? id,
    String? name,
    String? hsnCode,
    double? quantity,
    String? unit,
    double? rate,
    double? gstRate,
    double? discount,
    String? discountType,
  }) {
    return PurchaseOrderItem(
      id: id ?? this.id,
      name: name ?? this.name,
      hsnCode: hsnCode ?? this.hsnCode,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      rate: rate ?? this.rate,
      gstRate: gstRate ?? this.gstRate,
      discount: discount ?? this.discount,
      discountType: discountType ?? this.discountType,
    );
  }
}

class PurchaseOrder {
  final String id;
  final String poNumber;
  final String vendorId;
  final String vendorName;
  final String category;
  final DateTime purchaseDate;
  final DateTime? dueDate;
  final String referenceNumber;
  final List<PurchaseOrderItem> items;
  final String notes;
  final String internalNote;
  final String termsAndConditions;
  final List<String> attachments;
  final double subtotal;
  final double totalDiscount;
  final double totalTax;
  final double totalAmount;
  final double? gstRate;
  final String paymentMode;
  final String status; // 'DRAFT', 'PENDING', 'APPROVED', 'BILLED', 'CANCELLED'
  final String? convertedBillId;
  final DateTime createdAt;
  final DateTime? updatedAt;

  PurchaseOrder({
    required this.id,
    required this.poNumber,
    this.vendorId = '',
    required this.vendorName,
    required this.category,
    required this.purchaseDate,
    this.dueDate,
    this.referenceNumber = '',
    required this.items,
    this.notes = '',
    this.internalNote = '',
    this.termsAndConditions = '',
    this.attachments = const [],
    required this.subtotal,
    required this.totalDiscount,
    required this.totalTax,
    required this.totalAmount,
    this.gstRate,
    this.paymentMode = 'Bank Transfer',
    this.status = 'DRAFT',
    this.convertedBillId,
    required this.createdAt,
    this.updatedAt,
  });

  static String normalizePaymentModeForApi(String mode) {
    final upper = mode.trim().toUpperCase().replaceAll(' ', '_');
    if (upper.contains('BANK')) return 'BANK_TRANSFER';
    if (upper.contains('CREDIT')) return 'CREDIT_CARD';
    if (upper.contains('UPI')) return 'UPI';
    if (upper.contains('CASH')) return 'CASH';
    if (upper.contains('CHEQUE')) return 'CHEQUE';
    if (upper.contains('NET')) return 'NET_BANKING';
    return upper.isNotEmpty ? upper : 'BANK_TRANSFER';
  }

  static String normalizeStatusForApi(String s) {
    final upper = s.trim().toUpperCase();
    if (upper == 'DRAFT') return 'DRAFT';
    if (upper == 'ORDERED' || upper == 'PENDING') return 'PENDING';
    if (upper == 'RECEIVED' || upper == 'APPROVED') return 'APPROVED';
    if (upper == 'BILLED') return 'BILLED';
    if (upper == 'CANCELLED') return 'CANCELLED';
    return upper.isNotEmpty ? upper : 'DRAFT';
  }

  static String displayPaymentMode(String mode) {
    final upper = mode.trim().toUpperCase().replaceAll(' ', '_');
    if (upper == 'BANK_TRANSFER') return 'Bank Transfer';
    if (upper == 'CREDIT_CARD') return 'Credit Card';
    if (upper == 'NET_BANKING') return 'Net Banking';
    if (upper == 'UPI') return 'UPI';
    if (upper == 'CASH') return 'Cash';
    if (upper == 'CHEQUE') return 'Cheque';
    return mode;
  }

  static String displayStatus(String st) {
    final upper = st.trim().toUpperCase();
    if (upper == 'DRAFT') return 'Draft';
    if (upper == 'PENDING') return 'Pending';
    if (upper == 'APPROVED') return 'Approved';
    if (upper == 'BILLED') return 'Billed';
    if (upper == 'CANCELLED') return 'Cancelled';
    if (upper == 'ORDERED') return 'Ordered';
    if (upper == 'RECEIVED') return 'Received';
    return st;
  }

  /// Exact JSON serialization matching PurchaseOrderRequest.java
  Map<String, dynamic> toApiJson() {
    final map = <String, dynamic>{
      'date': DateFormat('yyyy-MM-dd').format(purchaseDate),
      'vendor': vendorName,
      'category': category,
      'amount': subtotal > 0 ? subtotal : (totalAmount - totalTax),
      'total': totalAmount,
      'status': normalizeStatusForApi(status),
    };

    if (poNumber.trim().isNotEmpty) {
      map['po_number'] = poNumber.trim();
    }
    if (referenceNumber.trim().isNotEmpty) {
      map['reference'] = referenceNumber.trim();
    }
    if (paymentMode.trim().isNotEmpty) {
      map['payment_mode'] = normalizePaymentModeForApi(paymentMode);
    }
    if (gstRate != null && gstRate! > 0) {
      map['gst_rate'] = gstRate!.round();
    } else if (items.isNotEmpty && items.first.gstRate > 0) {
      map['gst_rate'] = items.first.gstRate.round();
    }
    if (totalTax > 0) {
      map['tax'] = totalTax;
    }
    if (notes.trim().isNotEmpty) {
      map['notes'] = notes.trim();
    }
    return map;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'purchase_order_number': poNumber,
        'po_number': poNumber,
        'vendor_id': vendorId,
        'vendor_name': vendorName,
        'vendor': vendorName,
        'category': category,
        'date': DateFormat('yyyy-MM-dd').format(purchaseDate),
        'purchase_date': purchaseDate.toIso8601String(),
        'due_date': dueDate?.toIso8601String(),
        'reference_number': referenceNumber,
        'reference': referenceNumber,
        'items': items.map((i) => i.toJson()).toList(),
        'notes': notes,
        'internal_note': internalNote,
        'terms_and_conditions': termsAndConditions,
        'attachments': attachments,
        'amount': subtotal,
        'subtotal': subtotal,
        'total_discount': totalDiscount,
        'tax': totalTax,
        'total_tax': totalTax,
        'total': totalAmount,
        'grand_total': totalAmount,
        'total_amount': totalAmount,
        'gst_rate': gstRate,
        'payment_mode': paymentMode,
        'status': status,
        'converted_bill_id': convertedBillId,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };

  factory PurchaseOrder.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    final parsedItems = rawItems
        .whereType<Map<String, dynamic>>()
        .map((item) => PurchaseOrderItem.fromJson(item))
        .toList();

    final id = json['id']?.toString() ?? json['db_id']?.toString() ?? '';
    final poNum = json['po_number']?.toString() ??
        json['purchase_order_number']?.toString() ??
        '';
    final vendor = json['vendor']?.toString() ??
        json['vendor_name']?.toString() ??
        json['supplier']?.toString() ??
        'Unnamed Vendor';
    final cat = json['category']?.toString() ?? 'General';

    DateTime pDate = DateTime.now();
    if (json['date'] != null) {
      pDate = DateTime.tryParse(json['date'].toString()) ?? DateTime.now();
    } else if (json['purchase_date'] != null) {
      pDate = DateTime.tryParse(json['purchase_date'].toString()) ?? DateTime.now();
    } else if (json['created_at'] != null) {
      pDate = DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now();
    }

    DateTime? dDate;
    if (json['due_date'] != null) {
      dDate = DateTime.tryParse(json['due_date'].toString());
    }

    final ref = json['reference']?.toString() ??
        json['reference_number']?.toString() ??
        '';

    final subtotal = (json['amount'] as num?)?.toDouble() ??
        (json['subtotal'] as num?)?.toDouble() ??
        0.0;
    final tax = (json['tax'] as num?)?.toDouble() ??
        (json['total_tax'] as num?)?.toDouble() ??
        0.0;
    final total = (json['total'] as num?)?.toDouble() ??
        (json['grand_total'] as num?)?.toDouble() ??
        (json['total_amount'] as num?)?.toDouble() ??
        (subtotal + tax);

    final rawGstRate = (json['gst_rate'] as num?)?.toDouble();
    final convertedBillId = json['converted_bill_id']?.toString();
    final rawStatus = json['status']?.toString() ?? 'DRAFT';
    final rawPayment = json['payment_mode']?.toString() ?? 'Bank Transfer';

    return PurchaseOrder(
      id: id,
      poNumber: poNum,
      vendorId: json['vendor_id']?.toString() ?? '',
      vendorName: vendor,
      category: cat,
      purchaseDate: pDate,
      dueDate: dDate,
      referenceNumber: ref,
      items: parsedItems,
      notes: json['notes']?.toString() ?? '',
      internalNote: json['internal_note']?.toString() ?? '',
      termsAndConditions: json['terms_and_conditions']?.toString() ?? '',
      attachments: (json['attachments'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      subtotal: subtotal,
      totalDiscount: (json['total_discount'] as num?)?.toDouble() ?? 0.0,
      totalTax: tax,
      totalAmount: total,
      gstRate: rawGstRate,
      paymentMode: displayPaymentMode(rawPayment),
      status: normalizeStatusForApi(rawStatus),
      convertedBillId: convertedBillId,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  PurchaseOrder copyWith({
    String? id,
    String? poNumber,
    String? vendorId,
    String? vendorName,
    String? category,
    DateTime? purchaseDate,
    DateTime? dueDate,
    String? referenceNumber,
    List<PurchaseOrderItem>? items,
    String? notes,
    String? internalNote,
    String? termsAndConditions,
    List<String>? attachments,
    double? subtotal,
    double? totalDiscount,
    double? totalTax,
    double? totalAmount,
    double? gstRate,
    String? paymentMode,
    String? status,
    String? convertedBillId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PurchaseOrder(
      id: id ?? this.id,
      poNumber: poNumber ?? this.poNumber,
      vendorId: vendorId ?? this.vendorId,
      vendorName: vendorName ?? this.vendorName,
      category: category ?? this.category,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      dueDate: dueDate ?? this.dueDate,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      items: items ?? this.items,
      notes: notes ?? this.notes,
      internalNote: internalNote ?? this.internalNote,
      termsAndConditions: termsAndConditions ?? this.termsAndConditions,
      attachments: attachments ?? this.attachments,
      subtotal: subtotal ?? this.subtotal,
      totalDiscount: totalDiscount ?? this.totalDiscount,
      totalTax: totalTax ?? this.totalTax,
      totalAmount: totalAmount ?? this.totalAmount,
      gstRate: gstRate ?? this.gstRate,
      paymentMode: paymentMode ?? this.paymentMode,
      status: status ?? this.status,
      convertedBillId: convertedBillId ?? this.convertedBillId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

