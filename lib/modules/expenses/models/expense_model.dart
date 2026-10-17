class ExpenseModel {
  final String id;
  final String? expenseNumber;
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
  final bool billable;
  final String? customer;
  final String? invoiceFileName;
  final String? invoiceFileSize;
  final String status; // Paid, Pending, Cancelled
  final bool isDraft;

  ExpenseModel({
    required this.id,
    this.expenseNumber,
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
    this.billable = false,
    this.customer,
    this.invoiceFileName,
    this.invoiceFileSize,
    required this.status,
    this.isDraft = false,
  });

  String get displayIdentifier => expenseNumber ?? (id.startsWith('EXP-') ? id : id.substring(0, id.length > 8 ? 8 : id.length));

  ExpenseModel copyWith({
    String? id,
    String? expenseNumber,
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
    bool? billable,
    String? customer,
    String? invoiceFileName,
    String? invoiceFileSize,
    String? status,
    bool? isDraft,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      expenseNumber: expenseNumber ?? this.expenseNumber,
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
      billable: billable ?? this.billable,
      customer: customer ?? this.customer,
      invoiceFileName: invoiceFileName ?? this.invoiceFileName,
      invoiceFileSize: invoiceFileSize ?? this.invoiceFileSize,
      status: status ?? this.status,
      isDraft: isDraft ?? this.isDraft,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'expenseNumber': expenseNumber,
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
      'billable': billable,
      'customer': customer,
      'invoiceFileName': invoiceFileName,
      'invoiceFileSize': invoiceFileSize,
      'status': status,
      'isDraft': isDraft,
    };
  }

  /// Converts to JSON payload conforming directly to backend /api/v1/expenses
  Map<String, dynamic> toApiJson() {
    final dateStr = expenseDate.toIso8601String().split('T').first;
    final Map<String, dynamic> payload = {
      'date': dateStr,
      'category': category,
      'amount': amount > 0 ? amount : totalAmount,
      'payment_mode': paymentMode,
      'billable': billable,
    };

    if (billNumber != null && billNumber!.trim().isNotEmpty) {
      payload['reference'] = billNumber!.trim();
    }
    if (notes != null && notes!.trim().isNotEmpty) {
      payload['description'] = notes!.trim();
      payload['notes'] = notes!.trim();
    }
    if (customer != null && customer!.trim().isNotEmpty) {
      payload['customer'] = customer!.trim();
    } else if (vendor.isNotEmpty && vendor != 'General Vendor') {
      payload['customer'] = vendor;
    }

    return payload;
  }

  static double _toDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? 0.0;
    return 0.0;
  }

  static DateTime _parseDate(dynamic val) {
    if (val == null) return DateTime.now();
    if (val is DateTime) return val;
    if (val is String) {
      try {
        return DateTime.parse(val);
      } catch (_) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  factory ExpenseModel.fromMap(Map<String, dynamic> map) {
    final amount = _toDouble(map['amount'] ?? map['total'] ?? map['grand_total'] ?? map['grandTotal'] ?? map['price']);
    final gstAmount = _toDouble(map['gstAmount'] ?? map['gst_amount']);
    final totalAmount = _toDouble(map['totalAmount'] ?? map['total_amount'] ?? (amount + gstAmount));

    final String expenseNum = map['expense_number']?.toString() ?? 
        map['expenseNumber']?.toString() ?? 
        '';
    final String rawId = map['id']?.toString() ?? '';
    final String finalId = rawId.isNotEmpty ? rawId : (expenseNum.isNotEmpty ? expenseNum : 'EXP-temp');

    final customerOrVendor = map['customer']?.toString() ??
        map['customer_name']?.toString() ??
        map['customerName']?.toString() ??
        map['vendor']?.toString() ??
        map['client']?.toString() ??
        '';

    final referenceOrBill = map['reference']?.toString() ??
        map['reference_number']?.toString() ??
        map['referenceNumber']?.toString() ??
        map['billNumber']?.toString() ??
        map['bill_number']?.toString() ??
        map['ref_no']?.toString();

    final notesOrDesc = map['description']?.toString() ??
        map['notes']?.toString() ??
        map['note']?.toString() ??
        map['remarks']?.toString();

    final isBillable = map['billable'] == true ||
        map['is_billable'] == true ||
        map['isBillable'] == true;

    final dateVal = map['date'] ?? map['expenseDate'] ?? map['expense_date'] ?? map['issue_date'] ?? map['created_at'];

    return ExpenseModel(
      id: finalId,
      expenseNumber: expenseNum.isNotEmpty ? expenseNum : (finalId.startsWith('EXP-') ? finalId : null),
      category: map['category']?.toString() ?? map['expense_category']?.toString() ?? 'General Expense',
      vendor: customerOrVendor.isNotEmpty ? customerOrVendor : 'General Vendor',
      amount: amount,
      gstRate: map['gstRate']?.toString() ?? map['gst_rate']?.toString() ?? '0%',
      gstAmount: gstAmount,
      totalAmount: totalAmount > 0 ? totalAmount : amount,
      paymentMode: map['payment_mode']?.toString() ?? map['paymentMode']?.toString() ?? map['payment_method']?.toString() ?? 'Cash',
      expenseDate: _parseDate(dateVal),
      dueDate: map['dueDate'] != null ? _parseDate(map['dueDate']) : (map['due_date'] != null ? _parseDate(map['due_date']) : null),
      billNumber: referenceOrBill,
      notes: notesOrDesc,
      billable: isBillable,
      customer: customerOrVendor,
      invoiceFileName: map['invoiceFileName']?.toString() ?? map['invoice_file_name']?.toString(),
      invoiceFileSize: map['invoiceFileSize']?.toString() ?? map['invoice_file_size']?.toString(),
      status: map['status']?.toString() ?? 'Paid',
      isDraft: map['isDraft'] == true || map['is_draft'] == true,
    );
  }
}
