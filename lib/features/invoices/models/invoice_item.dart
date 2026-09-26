import '../../products/models/product.dart';

class InvoiceItem {
  final String id;
  final Product product;
  final int quantity;
  final double unitPrice;
  final double discountPercentage; // e.g. 5.0 for 5%
  final double taxPercentage; // GST percentage e.g. 18.0 for 18%

  const InvoiceItem({
    required this.id,
    required this.product,
    required this.quantity,
    required this.unitPrice,
    this.discountPercentage = 0.0,
    this.taxPercentage = 18.0, // Default to 18% GST typical for ERPs
  });

  double get subtotal => unitPrice * quantity;
  double get discountAmount => subtotal * (discountPercentage / 100);
  double get taxableAmount => subtotal - discountAmount;
  double get taxAmount => taxableAmount * (taxPercentage / 100);
  double get total => taxableAmount + taxAmount;

  factory InvoiceItem.fromJson(Map<String, dynamic> json) {
    double toDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val) ?? 0.0;
      return 0.0;
    }

    int toInt(dynamic val) {
      if (val == null) return 0;
      if (val is num) return val.toInt();
      if (val is String) return double.tryParse(val)?.toInt() ?? int.tryParse(val) ?? 0;
      return 0;
    }

    return InvoiceItem(
      id: json['id'] as String,
      product: Product.fromJson(json['product'] as Map<String, dynamic>),
      quantity: toInt(json['quantity']),
      unitPrice: toDouble(json['unit_price'] ?? json['unitPrice'] ?? json['rate']),
      discountPercentage: toDouble(json['discount'] ?? json['discountPercentage']),
      taxPercentage: toDouble(json['tax_percentage'] ?? json['taxPercentage'] ?? json['tax']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product': product.id, // Write serializer expects ID (UUID string)
      'quantity': quantity,
      'unit_price': unitPrice,
      'discount': discountPercentage,
      'discount_type': 'percentage',
      'tax_percentage': taxPercentage,
    };
  }

  InvoiceItem copyWith({
    String? id,
    Product? product,
    int? quantity,
    double? unitPrice,
    double? discountPercentage,
    double? taxPercentage,
  }) {
    return InvoiceItem(
      id: id ?? this.id,
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      taxPercentage: taxPercentage ?? this.taxPercentage,
    );
  }
}
