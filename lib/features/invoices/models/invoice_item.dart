import '../../products/models/product.dart';

class InvoiceItem {
  final String id;
  final Product product;
  final int quantity;
  final double unitPrice;
  final String description;
  final double discountPercentage; // e.g. 5.0 for 5%
  final double taxPercentage; // GST percentage e.g. 18.0 for 18%

  const InvoiceItem({
    required this.id,
    required this.product,
    required this.quantity,
    required this.unitPrice,
    this.description = '',
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

    int toInt(dynamic val, {int defaultValue = 0}) {
      if (val == null) return defaultValue;
      if (val is num) return val.toInt();
      if (val is String) return double.tryParse(val)?.toInt() ?? int.tryParse(val) ?? defaultValue;
      return defaultValue;
    }

    Product prod;
    final prodData = json['product'];
    if (prodData is Map<String, dynamic>) {
      prod = Product.fromJson(prodData);
    } else {
      final name = (json['product_name'] ?? json['name'] ?? prodData ?? 'Item').toString();
      final id = (json['product_id'] ?? json['productId'] ?? (prodData is String && prodData != name ? prodData : '')).toString();
      prod = Product(
        id: id,
        name: name,
        sku: (json['sku'] ?? '').toString(),
        barcode: '',
        category: '',
        brand: '',
        purchasePrice: 0.0,
        sellingPrice: toDouble(json['unit_price'] ?? json['unitPrice'] ?? json['rate'] ?? json['price']),
        stock: 0,
        minStock: 0,
        gst: toDouble(json['tax'] ?? json['tax_percentage'] ?? json['taxPercentage']),
        createdAt: DateTime.now(),
      );
    }

    final double rawDiscount = toDouble(json['discount'] ?? json['discountPercentage']);
    final double unitP = toDouble(json['unit_price'] ?? json['unitPrice'] ?? json['rate'] ?? json['price']);
    int qty = toInt(json['quantity'] ?? json['qty'] ?? json['item_quantity'], defaultValue: 1);
    if (qty <= 0) qty = 1;
    final double sub = unitP * qty;
    double discPct = rawDiscount;
    if (rawDiscount > 0 && sub > 0 && rawDiscount > 100) {
      discPct = (rawDiscount / sub) * 100;
    }

    return InvoiceItem(
      id: (json['id'] ?? '').toString(),
      product: prod,
      quantity: qty,
      unitPrice: unitP,
      description: (json['description'] ?? prod.name).toString(),
      discountPercentage: discPct,
      taxPercentage: toDouble(json['tax'] ?? json['tax_percentage'] ?? json['taxPercentage']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product': product.id.isNotEmpty ? product.id : product.name,
      'description': description.isNotEmpty ? description : product.name,
      'quantity': quantity,
      'unit_price': unitPrice,
      'tax': taxPercentage,
      'discount': discountAmount > 0 ? discountAmount : discountPercentage,
    };
  }

  InvoiceItem copyWith({
    String? id,
    Product? product,
    int? quantity,
    double? unitPrice,
    String? description,
    double? discountPercentage,
    double? taxPercentage,
  }) {
    return InvoiceItem(
      id: id ?? this.id,
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      description: description ?? this.description,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      taxPercentage: taxPercentage ?? this.taxPercentage,
    );
  }
}
