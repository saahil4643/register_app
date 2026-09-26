class Payment {
  final String id;
  final String customerId;
  final String? invoiceId; // Can be null if it's general account payment
  final double amount;
  final String paymentMode; // e.g. Cash, Bank Transfer, Cheque, UPI
  final DateTime paymentDate;
  final String reference;

  const Payment({
    required this.id,
    required this.customerId,
    this.invoiceId,
    required this.amount,
    required this.paymentMode,
    required this.paymentDate,
    required this.reference,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    double toDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val) ?? 0.0;
      return 0.0;
    }

    return Payment(
      id: (json['id'] ?? '') as String,
      customerId: (json['customerId'] ?? json['customer'] ?? '') as String,
      invoiceId: (json['invoiceId'] ?? json['invoice']?.toString()) as String?,
      amount: toDouble(json['amount']),
      paymentMode: (json['paymentMode'] ?? json['payment_method'] ?? 'cash') as String,
      paymentDate: json['paymentDate'] != null || json['payment_date'] != null
          ? DateTime.parse((json['paymentDate'] ?? json['payment_date']) as String)
          : DateTime.now(),
      reference: (json['reference'] ?? json['reference_number'] ?? '') as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerId': customerId,
      'customer': customerId,
      'invoiceId': invoiceId,
      'invoice': invoiceId,
      'amount': amount,
      'paymentMode': paymentMode,
      'payment_method': paymentMode,
      'paymentDate': paymentDate.toIso8601String(),
      'payment_date': paymentDate.toIso8601String().substring(0, 10),
      'reference': reference,
      'reference_number': reference,
    };
  }

  Payment copyWith({
    String? id,
    String? customerId,
    String? invoiceId,
    double? amount,
    String? paymentMode,
    DateTime? paymentDate,
    String? reference,
  }) {
    return Payment(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      invoiceId: invoiceId ?? this.invoiceId,
      amount: amount ?? this.amount,
      paymentMode: paymentMode ?? this.paymentMode,
      paymentDate: paymentDate ?? this.paymentDate,
      reference: reference ?? this.reference,
    );
  }
}
