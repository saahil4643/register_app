class SalesSummaryReport {
  final int totalInvoices;
  final double totalInvoicedAmount;
  final double totalPaidAmount;
  final double totalOutstandingAmount;
  final double totalDiscountAmount;
  final double totalTaxAmount;
  final double averageInvoiceValue;
  final List<SalesPeriodItem> salesByPeriod;
  final List<TopCustomerItem> topCustomers;

  SalesSummaryReport({
    this.totalInvoices = 0,
    this.totalInvoicedAmount = 0.0,
    this.totalPaidAmount = 0.0,
    this.totalOutstandingAmount = 0.0,
    this.totalDiscountAmount = 0.0,
    this.totalTaxAmount = 0.0,
    this.averageInvoiceValue = 0.0,
    this.salesByPeriod = const [],
    this.topCustomers = const [],
  });

  static double _toDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? 0.0;
    return 0.0;
  }

  static int _toInt(dynamic val) {
    if (val == null) return 0;
    if (val is int) return val;
    if (val is num) return val.toInt();
    if (val is String) return int.tryParse(val) ?? 0;
    return 0;
  }

  factory SalesSummaryReport.fromJson(Map<String, dynamic> json) {
    return SalesSummaryReport(
      totalInvoices: _toInt(json['totalInvoices'] ?? json['total_invoices']),
      totalInvoicedAmount: _toDouble(json['totalInvoicedAmount'] ?? json['total_invoiced_amount']),
      totalPaidAmount: _toDouble(json['totalPaidAmount'] ?? json['total_paid_amount']),
      totalOutstandingAmount: _toDouble(json['totalOutstandingAmount'] ?? json['total_outstanding_amount']),
      totalDiscountAmount: _toDouble(json['totalDiscountAmount'] ?? json['total_discount_amount']),
      totalTaxAmount: _toDouble(json['totalTaxAmount'] ?? json['total_tax_amount']),
      averageInvoiceValue: _toDouble(json['averageInvoiceValue'] ?? json['average_invoice_value']),
      salesByPeriod: (json['salesByPeriod'] as List<dynamic>? ?? json['sales_by_period'] as List<dynamic>? ?? [])
          .map((e) => SalesPeriodItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      topCustomers: (json['topCustomers'] as List<dynamic>? ?? json['top_customers'] as List<dynamic>? ?? [])
          .map((e) => TopCustomerItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class SalesPeriodItem {
  final String periodLabel;
  final int invoiceCount;
  final double subtotal;
  final double tax;
  final double discount;
  final double totalSales;

  SalesPeriodItem({
    required this.periodLabel,
    this.invoiceCount = 0,
    this.subtotal = 0.0,
    this.tax = 0.0,
    this.discount = 0.0,
    this.totalSales = 0.0,
  });

  factory SalesPeriodItem.fromJson(Map<String, dynamic> json) {
    double toDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val) ?? 0.0;
      return 0.0;
    }

    int toInt(dynamic val) {
      if (val == null) return 0;
      if (val is int) return val;
      if (val is num) return val.toInt();
      if (val is String) return int.tryParse(val) ?? 0;
      return 0;
    }

    return SalesPeriodItem(
      periodLabel: (json['periodLabel'] ?? json['period_label'] ?? json['period'] ?? '').toString(),
      invoiceCount: toInt(json['invoiceCount'] ?? json['invoice_count']),
      subtotal: toDouble(json['subtotal']),
      tax: toDouble(json['tax']),
      discount: toDouble(json['discount']),
      totalSales: toDouble(json['totalSales'] ?? json['total_sales']),
    );
  }
}

class TopCustomerItem {
  final String customerId;
  final String customerName;
  final int invoiceCount;
  final double totalSales;
  final double totalPaid;
  final double balanceDue;

  TopCustomerItem({
    required this.customerId,
    required this.customerName,
    this.invoiceCount = 0,
    this.totalSales = 0.0,
    this.totalPaid = 0.0,
    this.balanceDue = 0.0,
  });

  factory TopCustomerItem.fromJson(Map<String, dynamic> json) {
    double toDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val) ?? 0.0;
      return 0.0;
    }

    int toInt(dynamic val) {
      if (val == null) return 0;
      if (val is int) return val;
      if (val is num) return val.toInt();
      if (val is String) return int.tryParse(val) ?? 0;
      return 0;
    }

    return TopCustomerItem(
      customerId: (json['customerId'] ?? json['customer_id'] ?? '').toString(),
      customerName: (json['customerName'] ?? json['customer_name'] ?? 'Unknown').toString(),
      invoiceCount: toInt(json['invoiceCount'] ?? json['invoice_count']),
      totalSales: toDouble(json['totalSales'] ?? json['total_sales']),
      totalPaid: toDouble(json['totalPaid'] ?? json['total_paid']),
      balanceDue: toDouble(json['balanceDue'] ?? json['balance_due']),
    );
  }
}

class ProfitLossReport {
  final double totalSales;
  final double salesReturns;
  final double netRevenue;
  final double operatingExpenses;
  final double billsExpenses;
  final double purchaseExpenses;
  final double totalExpenses;
  final double grossProfit;
  final double netProfit;
  final double netProfitMargin;
  final List<ExpenseCategoryItem> expenseCategories;
  final List<MonthlyTrendItem> monthlyTrends;

  ProfitLossReport({
    this.totalSales = 0.0,
    this.salesReturns = 0.0,
    this.netRevenue = 0.0,
    this.operatingExpenses = 0.0,
    this.billsExpenses = 0.0,
    this.purchaseExpenses = 0.0,
    this.totalExpenses = 0.0,
    this.grossProfit = 0.0,
    this.netProfit = 0.0,
    this.netProfitMargin = 0.0,
    this.expenseCategories = const [],
    this.monthlyTrends = const [],
  });

  static double _toDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? 0.0;
    return 0.0;
  }

  factory ProfitLossReport.fromJson(Map<String, dynamic> json) {
    return ProfitLossReport(
      totalSales: _toDouble(json['totalSales'] ?? json['total_sales']),
      salesReturns: _toDouble(json['salesReturns'] ?? json['sales_returns']),
      netRevenue: _toDouble(json['netRevenue'] ?? json['net_revenue']),
      operatingExpenses: _toDouble(json['operatingExpenses'] ?? json['operating_expenses']),
      billsExpenses: _toDouble(json['billsExpenses'] ?? json['bills_expenses']),
      purchaseExpenses: _toDouble(json['purchaseExpenses'] ?? json['purchase_expenses']),
      totalExpenses: _toDouble(json['totalExpenses'] ?? json['total_expenses']),
      grossProfit: _toDouble(json['grossProfit'] ?? json['gross_profit']),
      netProfit: _toDouble(json['netProfit'] ?? json['net_profit']),
      netProfitMargin: _toDouble(json['netProfitMargin'] ?? json['net_profit_margin']),
      expenseCategories: (json['expenseCategories'] as List<dynamic>? ?? json['expense_categories'] as List<dynamic>? ?? [])
          .map((e) => ExpenseCategoryItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      monthlyTrends: (json['monthlyTrends'] as List<dynamic>? ?? json['monthly_trends'] as List<dynamic>? ?? [])
          .map((e) => MonthlyTrendItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ExpenseCategoryItem {
  final String category;
  final double amount;
  final double percentage;

  ExpenseCategoryItem({
    required this.category,
    this.amount = 0.0,
    this.percentage = 0.0,
  });

  factory ExpenseCategoryItem.fromJson(Map<String, dynamic> json) {
    double toDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val) ?? 0.0;
      return 0.0;
    }

    return ExpenseCategoryItem(
      category: (json['category'] ?? json['category_name'] ?? 'Other').toString(),
      amount: toDouble(json['amount']),
      percentage: toDouble(json['percentage']),
    );
  }
}

class MonthlyTrendItem {
  final String period;
  final double revenue;
  final double expenses;
  final double netProfit;

  MonthlyTrendItem({
    required this.period,
    this.revenue = 0.0,
    this.expenses = 0.0,
    this.netProfit = 0.0,
  });

  factory MonthlyTrendItem.fromJson(Map<String, dynamic> json) {
    double toDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val) ?? 0.0;
      return 0.0;
    }

    return MonthlyTrendItem(
      period: (json['period'] ?? json['month'] ?? '').toString(),
      revenue: toDouble(json['revenue']),
      expenses: toDouble(json['expenses']),
      netProfit: toDouble(json['netProfit'] ?? json['net_profit']),
    );
  }
}

class ReceivablesReport {
  final double totalReceivables;
  final double totalOverdue;
  final double currentAmount;
  final double days1To30;
  final double days31To60;
  final double days61To90;
  final double days90Plus;
  final List<CustomerAgingItem> customerAgingList;

  ReceivablesReport({
    this.totalReceivables = 0.0,
    this.totalOverdue = 0.0,
    this.currentAmount = 0.0,
    this.days1To30 = 0.0,
    this.days31To60 = 0.0,
    this.days61To90 = 0.0,
    this.days90Plus = 0.0,
    this.customerAgingList = const [],
  });

  static double _toDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? 0.0;
    return 0.0;
  }

  factory ReceivablesReport.fromJson(Map<String, dynamic> json) {
    return ReceivablesReport(
      totalReceivables: _toDouble(json['totalReceivables'] ?? json['total_receivables']),
      totalOverdue: _toDouble(json['totalOverdue'] ?? json['total_overdue']),
      currentAmount: _toDouble(json['currentAmount'] ?? json['current_amount']),
      days1To30: _toDouble(json['days1To30'] ?? json['days_1_to_30']),
      days31To60: _toDouble(json['days31To60'] ?? json['days_31_to_60']),
      days61To90: _toDouble(json['days61To90'] ?? json['days_61_to_90']),
      days90Plus: _toDouble(json['days90Plus'] ?? json['days_90_plus']),
      customerAgingList: (json['customerAgingList'] as List<dynamic>? ?? json['customer_aging_list'] as List<dynamic>? ?? [])
          .map((e) => CustomerAgingItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class CustomerAgingItem {
  final String customerId;
  final String customerName;
  final double totalBalance;
  final double currentAmount;
  final double days1To30;
  final int openInvoicesCount;

  CustomerAgingItem({
    required this.customerId,
    required this.customerName,
    this.totalBalance = 0.0,
    this.currentAmount = 0.0,
    this.days1To30 = 0.0,
    this.openInvoicesCount = 0,
  });

  factory CustomerAgingItem.fromJson(Map<String, dynamic> json) {
    double toDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val) ?? 0.0;
      return 0.0;
    }

    int toInt(dynamic val) {
      if (val == null) return 0;
      if (val is int) return val;
      if (val is num) return val.toInt();
      if (val is String) return int.tryParse(val) ?? 0;
      return 0;
    }

    return CustomerAgingItem(
      customerId: (json['customerId'] ?? json['customer_id'] ?? '').toString(),
      customerName: (json['customerName'] ?? json['customer_name'] ?? 'Unknown').toString(),
      totalBalance: toDouble(json['totalBalance'] ?? json['total_balance']),
      currentAmount: toDouble(json['currentAmount'] ?? json['current_amount']),
      days1To30: toDouble(json['days1To30'] ?? json['days_1_to_30']),
      openInvoicesCount: toInt(json['openInvoicesCount'] ?? json['open_invoices_count']),
    );
  }
}
