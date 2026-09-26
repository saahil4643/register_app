class Payment {
  final String id;
  final String paymentNumber;
  final String customerId;
  final String customerName;
  final String? invoiceId; // Can be null if it's general account payment
  final double amount;
  final String paymentMode; // e.g. Cash, Bank Transfer, Cheque, UPI
  final DateTime paymentDate;
  final String reference;

  const Payment({
    required this.id,
    this.paymentNumber = '',
    this.customerId = '',
    this.customerName = '',
    this.invoiceId,
    required this.amount,
    required this.paymentMode,
    required this.paymentDate,
    this.reference = '',
  });

  // Backward compatibility getter
  String get referenceNumber => reference;

  factory Payment.fromJson(Map<String, dynamic> json) {
    double toDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val) ?? 0.0;
      return 0.0;
    }

    final dateStr = (json['paymentDate'] ?? json['payment_date'] ?? json['created_at'] ?? '').toString();

    return Payment(
      id: (json['id'] ?? '').toString(),
      paymentNumber: (json['paymentNumber'] ?? json['payment_number'] ?? '').toString(),
      customerId: (json['customerId'] ?? json['customer_id'] ?? json['customer'] ?? '').toString(),
      customerName: (json['customerName'] ?? json['customer_name'] ?? '').toString(),
      invoiceId: (json['invoiceId'] ?? json['invoice_id'] ?? json['invoice'])?.toString(),
      amount: toDouble(json['amount']),
      paymentMode: (json['paymentMode'] ?? json['payment_mode'] ?? json['payment_method'] ?? 'UPI').toString(),
      paymentDate: dateStr.isNotEmpty ? (DateTime.tryParse(dateStr) ?? DateTime.now()) : DateTime.now(),
      reference: (json['referenceNumber'] ?? json['reference_number'] ?? json['reference'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'paymentNumber': paymentNumber,
      'payment_number': paymentNumber,
      'customerId': customerId,
      'customer': customerId,
      'customerName': customerName,
      'invoiceId': invoiceId,
      'invoice': invoiceId,
      'amount': amount,
      'paymentMode': paymentMode,
      'payment_method': paymentMode,
      'paymentDate': paymentDate.toIso8601String(),
      'payment_date': paymentDate.toIso8601String().substring(0, 10),
      'reference': reference,
      'reference_number': reference,
      'referenceNumber': reference,
    };
  }

  Payment copyWith({
    String? id,
    String? paymentNumber,
    String? customerId,
    String? customerName,
    String? invoiceId,
    double? amount,
    String? paymentMode,
    DateTime? paymentDate,
    String? reference,
  }) {
    return Payment(
      id: id ?? this.id,
      paymentNumber: paymentNumber ?? this.paymentNumber,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      invoiceId: invoiceId ?? this.invoiceId,
      amount: amount ?? this.amount,
      paymentMode: paymentMode ?? this.paymentMode,
      paymentDate: paymentDate ?? this.paymentDate,
      reference: reference ?? this.reference,
    );
  }
}
