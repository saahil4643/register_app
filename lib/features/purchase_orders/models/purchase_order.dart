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
  final String paymentMode;
  final String status; // 'Pending', 'Approved', 'Ordered', 'Received', 'Cancelled'
  final DateTime createdAt;
  final DateTime? updatedAt;

  PurchaseOrder({
    required this.id,
    required this.poNumber,
    this.vendorId = '',
    required this.vendorName,
    required this.category,
    required this.purchaseDate,
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
    this.paymentMode = 'Bank Transfer',
    this.status = 'Pending',
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'purchase_order_number': poNumber,
        'po_number': poNumber,
        'vendor_id': vendorId,
        'vendor_name': vendorName,
        'category': category,
        'purchase_date': purchaseDate.toIso8601String(),
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
        'payment_mode': paymentMode,
        'status': status,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };

  factory PurchaseOrder.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    final parsedItems = rawItems
        .whereType<Map<String, dynamic>>()
        .map((item) => PurchaseOrderItem.fromJson(item))
        .toList();

    return PurchaseOrder(
      id: json['id']?.toString() ?? '',
      poNumber: json['purchase_order_number']?.toString() ??
          json['po_number']?.toString() ??
          'PUR-001',
      vendorId: json['vendor_id']?.toString() ?? '',
      vendorName: json['vendor_name']?.toString() ??
          json['vendor']?.toString() ??
          'Unnamed Vendor',
      category: json['category']?.toString() ?? 'General',
      purchaseDate: json['purchase_date'] != null
          ? DateTime.tryParse(json['purchase_date'].toString()) ?? DateTime.now()
          : DateTime.now(),
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

  PurchaseOrder copyWith({
    String? id,
    String? poNumber,
    String? vendorId,
    String? vendorName,
    String? category,
    DateTime? purchaseDate,
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
    String? paymentMode,
    String? status,
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
      paymentMode: paymentMode ?? this.paymentMode,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
