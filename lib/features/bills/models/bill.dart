class BillItem {
  final String id;
  String name;
  String hsnCode;
  double quantity;
  String unit;
  double rate;
  double gstRate; // in percentage, e.g. 18.0
  double discount; // amount or percentage
  String discountType; // 'amount' or 'percentage'

  BillItem({
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

  factory BillItem.fromJson(Map<String, dynamic> json) {
    final qty = (json['quantity'] as num?)?.toDouble() ?? (json['qty'] as num?)?.toDouble() ?? 1.0;
    final r = (json['rate'] as num?)?.toDouble() ?? 0.0;
    final disc = (json['discount'] as num?)?.toDouble() ?? 0.0;
    final discType = json['discount_type'] as String? ?? 'amount';
    final gst = (json['gst_rate'] as num?)?.toDouble() ?? (json['gst'] as num?)?.toDouble() ?? 0.0;

    return BillItem(
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

  BillItem copyWith({
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
    return BillItem(
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

class Bill {
  final String id;
  final String billNumber;
  final String vendorId;
  final String vendorName;
  final String category;
  final DateTime billDate;
  final DateTime? dueDate;
  final String referenceNumber;
  final List<BillItem> items;
  final String notes;
  final String internalNote;
  final String termsAndConditions;
  final List<String> attachments;
  final double subtotal;
  final double totalDiscount;
  final double totalTax;
  final double totalAmount;
  final double paidAmount;
  final String paymentMode;
  final String status; // 'Pending', 'Paid', 'Partially Paid', 'Overdue', 'Draft', 'Cancelled'
  final DateTime createdAt;
  final DateTime? updatedAt;

  Bill({
    required this.id,
    required this.billNumber,
    this.vendorId = '',
    required this.vendorName,
    required this.category,
    required this.billDate,
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
    this.paidAmount = 0.0,
    this.paymentMode = 'Bank Transfer',
    this.status = 'Pending',
    required this.createdAt,
    this.updatedAt,
  });

  double get balanceDue => (totalAmount - paidAmount).clamp(0.0, double.infinity);

  Map<String, dynamic> toJson() => {
        'id': id,
        'bill_number': billNumber,
        'vendor_id': vendorId,
        'vendor_name': vendorName,
        'category': category,
        'bill_date': billDate.toIso8601String(),
        'due_date': dueDate?.toIso8601String(),
        'reference_number': referenceNumber,
        'items': items.map((i) => i.toJson()).toList(),
        'notes': notes,
        'internal_note': internalNote,
        'terms_and_conditions': termsAndConditions,
        'attachments': attachments,
        'subtotal': subtotal,
        'total_discount': totalDiscount,
        'total_tax': totalTax,
        'total_amount': totalAmount,
        'paid_amount': paidAmount,
        'payment_mode': paymentMode,
        'status': status,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };

  factory Bill.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    final parsedItems = rawItems
        .whereType<Map<String, dynamic>>()
        .map((item) => BillItem.fromJson(item))
        .toList();

    return Bill(
      id: json['id']?.toString() ?? '',
      billNumber: json['bill_number']?.toString() ??
          json['bill_no']?.toString() ??
          'BILL-001',
      vendorId: json['vendor_id']?.toString() ?? '',
      vendorName: json['vendor_name']?.toString() ??
          json['vendor']?.toString() ??
          'Unnamed Vendor',
      category: json['category']?.toString() ?? 'General',
      billDate: json['bill_date'] != null
          ? DateTime.tryParse(json['bill_date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      dueDate: json['due_date'] != null
          ? DateTime.tryParse(json['due_date'].toString())
          : null,
      referenceNumber: json['reference_number']?.toString() ??
          json['reference']?.toString() ??
          '',
      items: parsedItems,
      notes: json['notes']?.toString() ?? '',
      internalNote: json['internal_note']?.toString() ?? '',
      termsAndConditions: json['terms_and_conditions']?.toString() ?? '',
      attachments: (json['attachments'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      totalDiscount: (json['total_discount'] as num?)?.toDouble() ?? 0.0,
      totalTax: (json['total_tax'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      paidAmount: (json['paid_amount'] as num?)?.toDouble() ?? 0.0,
      paymentMode: json['payment_mode']?.toString() ?? 'Bank Transfer',
      status: json['status']?.toString() ?? 'Pending',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  Bill copyWith({
    String? id,
    String? billNumber,
    String? vendorId,
    String? vendorName,
    String? category,
    DateTime? billDate,
    DateTime? dueDate,
    String? referenceNumber,
    List<BillItem>? items,
    String? notes,
    String? internalNote,
    String? termsAndConditions,
    List<String>? attachments,
    double? subtotal,
    double? totalDiscount,
    double? totalTax,
    double? totalAmount,
    double? paidAmount,
    String? paymentMode,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Bill(
      id: id ?? this.id,
      billNumber: billNumber ?? this.billNumber,
      vendorId: vendorId ?? this.vendorId,
      vendorName: vendorName ?? this.vendorName,
      category: category ?? this.category,
      billDate: billDate ?? this.billDate,
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
      paidAmount: paidAmount ?? this.paidAmount,
      paymentMode: paymentMode ?? this.paymentMode,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
