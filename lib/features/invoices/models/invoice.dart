import '../../customers/models/customer.dart';
import '../../customers/models/payment.dart';
import 'invoice_item.dart';

enum InvoiceStatus {
  draft,
  sent,
  // ignore: constant_identifier_names
  partially_paid,
  paid,
  overdue,
  cancelled;

  String get displayName {
    switch (this) {
      case InvoiceStatus.draft:
        return 'Draft';
      case InvoiceStatus.sent:
        return 'Sent';
      case InvoiceStatus.partially_paid:
        return 'Partially Paid';
      case InvoiceStatus.paid:
        return 'Paid';
      case InvoiceStatus.overdue:
        return 'Overdue';
      case InvoiceStatus.cancelled:
        return 'Cancelled';
    }
  }
}

class Invoice {
  final String id;
  final String invoiceNumber;
  final Customer customer;
  final DateTime invoiceDate;
  final DateTime dueDate;
  final List<InvoiceItem> items;
  final String? notes;
  final String? terms;
  final InvoiceStatus status;
  final List<Payment> payments;
  final String currency;

  // Server calculated fields
  final double? subtotalField;
  final double? totalDiscountField;
  final double? totalTaxField;
  final double? grandTotalField;
  final double? balanceDueField;
  final double? paidAmountField;

  const Invoice({
    required this.id,
    required this.invoiceNumber,
    required this.customer,
    required this.invoiceDate,
    required this.dueDate,
    required this.items,
    this.notes,
    this.terms,
    required this.status,
    this.payments = const [],
    this.currency = 'INR',
    this.subtotalField,
    this.totalDiscountField,
    this.totalTaxField,
    this.grandTotalField,
    this.balanceDueField,
    this.paidAmountField,
  });

  double get subtotal => subtotalField ?? items.fold(0.0, (sum, item) => sum + item.subtotal);
  double get totalDiscount => totalDiscountField ?? items.fold(0.0, (sum, item) => sum + item.discountAmount);
  double get totalTax => totalTaxField ?? items.fold(0.0, (sum, item) => sum + item.taxAmount);
  double get grandTotal => grandTotalField ?? items.fold(0.0, (sum, item) => sum + item.total);
  double get paidAmount {
    if (paidAmountField != null) return paidAmountField!;
    if (payments.isNotEmpty) {
      return payments.fold(0.0, (sum, p) => sum + p.amount);
    }
    return 0.0;
  }
  double get balanceDue {
    if (balanceDueField != null) return balanceDueField!;
    final double remaining = grandTotal - paidAmount;
    return remaining > 0 ? remaining : 0.0;
  }

  factory Invoice.fromJson(Map<String, dynamic> json) {
    Customer customer;
    final customerData = json['customer'];
    if (customerData is Map<String, dynamic>) {
      customer = Customer.fromJson(customerData);
    } else if (customerData is String) {
      final custName = (json['customer_name'] ?? json['customerName'] ?? customerData).toString();
      customer = Customer(
        id: (json['customer_id'] ?? customerData).toString(),
        name: custName,
        email: (json['customer_email'] ?? '').toString(),
        phone: (json['customer_phone'] ?? '').toString(),
        address: '',
        company: custName,
        gstNo: '',
        createdAt: DateTime.now(),
      );
    } else {
      customer = Customer(
        id: (json['customer_id'] ?? '').toString(),
        name: (json['customer_name'] ?? json['customerName'] ?? 'Unknown').toString(),
        email: '',
        phone: '',
        address: '',
        company: (json['customer_name'] ?? json['customerName'] ?? 'Unknown').toString(),
        gstNo: '',
        createdAt: DateTime.now(),
      );
    }

    double? parseDouble(dynamic val) {
      if (val == null) return null;
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val);
      return null;
    }

    final rawStatus = (json['status'] ?? '').toString().toLowerCase();

    return Invoice(
      id: json['id'] as String,
      invoiceNumber: (json['invoice_number'] ?? json['invoiceNumber'] ?? '') as String,
      customer: customer,
      invoiceDate: DateTime.parse((json['invoice_date'] ?? json['invoiceDate'] ?? json['date'] ?? DateTime.now().toIso8601String()) as String),
      dueDate: DateTime.parse((json['due_date'] ?? json['dueDate'] ?? DateTime.now().toIso8601String()) as String),
      items: json['items'] != null
          ? (json['items'] as List<dynamic>)
              .map((item) => InvoiceItem.fromJson(item as Map<String, dynamic>))
              .toList()
          : [],
      notes: (json['notes'] ?? json['customer_notes']) as String?,
      terms: (json['terms'] ?? json['terms_and_conditions'] ?? json['payment_terms']) as String?,
      status: InvoiceStatus.values.firstWhere(
        (e) => e.name == rawStatus ||
               (e == InvoiceStatus.partially_paid && (rawStatus == 'partially_paid' || rawStatus == 'partial')),
        orElse: () => InvoiceStatus.draft,
      ),
      payments: json['payments'] != null
          ? (json['payments'] as List<dynamic>)
              .map((p) => Payment.fromJson(p as Map<String, dynamic>))
              .toList()
          : [],
      currency: (json['currency'] ?? 'INR') as String,
      subtotalField: parseDouble(json['subtotal']),
      totalDiscountField: parseDouble(json['discount_total'] ?? json['discountTotal']),
      totalTaxField: parseDouble(json['tax_total'] ?? json['taxTotal'] ?? json['tax_amount']),
      grandTotalField: parseDouble(json['grand_total'] ?? json['grandTotal'] ?? json['amount']),
      balanceDueField: parseDouble(json['balance_due'] ?? json['balanceDue'] ?? json['balance'] ?? json['due_amount'] ?? json['dueAmount']),
      paidAmountField: parseDouble(json['amount_paid'] ?? json['amountPaid'] ?? json['paid_amount'] ?? json['paidAmount'] ?? json['amount_received'] ?? json['amountReceived'] ?? json['received_amount'] ?? json['advance_amount'] ?? json['advance'] ?? json['paid']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'invoice_number': invoiceNumber,
      'customer': customer.id, // Write serializer expects ID (UUID string)
      'invoice_date': invoiceDate.toIso8601String().substring(0, 10),
      'due_date': dueDate.toIso8601String().substring(0, 10),
      'items': items.map((item) => item.toJson()).toList(),
      'customer_notes': notes,
      'terms_and_conditions': terms,
      'status': status.name,
      'currency': currency,
      'payments': payments.map((p) => p.toJson()).toList(),
    };
  }

  Invoice copyWith({
    String? id,
    String? invoiceNumber,
    Customer? customer,
    DateTime? invoiceDate,
    DateTime? dueDate,
    List<InvoiceItem>? items,
    String? notes,
    String? terms,
    InvoiceStatus? status,
    List<Payment>? payments,
    String? currency,
    double? subtotalField,
    double? totalDiscountField,
    double? totalTaxField,
    double? grandTotalField,
    double? balanceDueField,
    double? paidAmountField,
  }) {
    return Invoice(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      customer: customer ?? this.customer,
      invoiceDate: invoiceDate ?? this.invoiceDate,
      dueDate: dueDate ?? this.dueDate,
      items: items ?? this.items,
      notes: notes ?? this.notes,
      terms: terms ?? this.terms,
      status: status ?? this.status,
      payments: payments ?? this.payments,
      currency: currency ?? this.currency,
      subtotalField: subtotalField ?? this.subtotalField,
      totalDiscountField: totalDiscountField ?? this.totalDiscountField,
      totalTaxField: totalTaxField ?? this.totalTaxField,
      grandTotalField: grandTotalField ?? this.grandTotalField,
      balanceDueField: balanceDueField ?? this.balanceDueField,
      paidAmountField: paidAmountField ?? this.paidAmountField,
    );
  }
}
