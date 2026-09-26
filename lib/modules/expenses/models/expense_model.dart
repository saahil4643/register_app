class ExpenseModel {
  final String id;
  final String category;
  final String vendor;
  final double amount;
  final String gstRate; // e.g. "0%", "5%", "12%", "18%", "28%", "Custom (15%)"
  final double gstAmount;
  final double totalAmount;
  final String paymentMode; // Cash, Bank Transfer, UPI, Credit Card, Debit Card, Cheque, Wallet, Other
  final DateTime expenseDate;
  final DateTime? dueDate;
  final String? billNumber;
  final String? notes;
  final String? invoiceFileName;
  final String? invoiceFileSize;
  final String status; // Paid, Pending, Cancelled
  final bool isDraft;

  ExpenseModel({
    required this.id,
    required this.category,
    required this.vendor,
    required this.amount,
    required this.gstRate,
    required this.gstAmount,
    required this.totalAmount,
    required this.paymentMode,
    required this.expenseDate,
    this.dueDate,
    this.billNumber,
    this.notes,
    this.invoiceFileName,
    this.invoiceFileSize,
    required this.status,
    this.isDraft = false,
  });

  ExpenseModel copyWith({
    String? id,
    String? category,
    String? vendor,
    double? amount,
    String? gstRate,
    double? gstAmount,
    double? totalAmount,
    String? paymentMode,
    DateTime? expenseDate,
    DateTime? dueDate,
    String? billNumber,
    String? notes,
    String? invoiceFileName,
    String? invoiceFileSize,
    String? status,
    bool? isDraft,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      category: category ?? this.category,
      vendor: vendor ?? this.vendor,
      amount: amount ?? this.amount,
      gstRate: gstRate ?? this.gstRate,
      gstAmount: gstAmount ?? this.gstAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      paymentMode: paymentMode ?? this.paymentMode,
      expenseDate: expenseDate ?? this.expenseDate,
      dueDate: dueDate ?? this.dueDate,
      billNumber: billNumber ?? this.billNumber,
      notes: notes ?? this.notes,
      invoiceFileName: invoiceFileName ?? this.invoiceFileName,
      invoiceFileSize: invoiceFileSize ?? this.invoiceFileSize,
      status: status ?? this.status,
      isDraft: isDraft ?? this.isDraft,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category,
      'vendor': vendor,
      'amount': amount,
      'gstRate': gstRate,
      'gstAmount': gstAmount,
      'totalAmount': totalAmount,
      'paymentMode': paymentMode,
      'expenseDate': expenseDate.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
      'billNumber': billNumber,
      'notes': notes,
      'invoiceFileName': invoiceFileName,
      'invoiceFileSize': invoiceFileSize,
      'status': status,
      'isDraft': isDraft,
    };
  }

  factory ExpenseModel.fromMap(Map<String, dynamic> map) {
    return ExpenseModel(
      id: map['id'] ?? '',
      category: map['category'] ?? '',
      vendor: map['vendor'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      gstRate: map['gstRate'] ?? '0%',
      gstAmount: (map['gstAmount'] ?? 0.0).toDouble(),
      totalAmount: (map['totalAmount'] ?? 0.0).toDouble(),
      paymentMode: map['paymentMode'] ?? 'Cash',
      expenseDate: DateTime.parse(map['expenseDate']),
      dueDate: map['dueDate'] != null ? DateTime.parse(map['dueDate']) : null,
      billNumber: map['billNumber'],
      notes: map['notes'],
      invoiceFileName: map['invoiceFileName'],
      invoiceFileSize: map['invoiceFileSize'],
      status: map['status'] ?? 'Pending',
      isDraft: map['isDraft'] ?? false,
    );
  }
}
