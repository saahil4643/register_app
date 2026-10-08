import '../../products/models/product.dart';

class InvoiceItem {
  final String id;
  final Product product;
  final int quantity;
  final double unitPrice;
  final String description;
  final double discountPercentage; // e.g. 5.0 for 5%
  final double taxPercentage; // GST percentage e.g. 18.0 for 18%
  final String discountType; // "₹" or "%"
  final double discountValue; // Raw value entered (either flat ₹ or %)
  final String? hsnSac;
  final String? unit;
  final String? itemName;

  const InvoiceItem({
    required this.id,
    required this.product,
    required this.quantity,
    required this.unitPrice,
    this.description = '',
    this.discountPercentage = 0.0,
    this.taxPercentage = 18.0, // Default to 18% GST typical for ERPs
    this.discountType = '%',
    this.discountValue = 0.0,
    this.hsnSac,
    this.unit,
    this.itemName,
  });

  double get subtotal => unitPrice * quantity;
  double get discountAmount {
    if (discountType == '₹') {
      return discountValue > 0 ? discountValue : discountPercentage;
    }
    final rate = discountValue > 0 ? discountValue : discountPercentage;
    return subtotal * (rate / 100);
  }
  double get taxableAmount => (subtotal - discountAmount).clamp(0.0, double.infinity);
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
    final iName = (json['item_name'] ?? json['itemName'] ?? json['name'] ?? (prodData is String ? prodData : null))?.toString();
    final hsn = (json['hsn_sac'] ?? json['hsnSac'] ?? json['hsn'] ?? '').toString();
    final unitVal = (json['unit'] ?? json['unit_of_measurement'] ?? json['unitAbbreviation'] ?? '').toString();

    if (prodData is Map<String, dynamic>) {
      prod = Product.fromJson(prodData);
    } else {
      final name = iName ?? (prodData ?? 'Item').toString();
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
        unitAbbreviation: unitVal.isNotEmpty ? unitVal : 'Nos',
        hsnSacCode: hsn,
        createdAt: DateTime.now(),
      );
    }

    final String rawDiscType = (json['discount_type'] ?? json['discountType'] ?? '%').toString();
    final String discType = (rawDiscType == '₹' || rawDiscType == 'flat' || rawDiscType == 'amount' || rawDiscType == 'INR') ? '₹' : '%';
    final double rawDiscount = toDouble(json['discount'] ?? json['discount_value'] ?? json['discountPercentage']);
    final double unitP = toDouble(json['unit_price'] ?? json['unitPrice'] ?? json['rate'] ?? json['price']);
    int qty = toInt(json['quantity'] ?? json['qty'] ?? json['item_quantity'], defaultValue: 1);
    if (qty <= 0) qty = 1;
    final double sub = unitP * qty;

    double discPct = 0.0;
    double discVal = rawDiscount;
    if (discType == '₹') {
      discVal = rawDiscount;
      discPct = sub > 0 ? (rawDiscount / sub) * 100 : 0.0;
    } else {
      discPct = rawDiscount;
      if (rawDiscount > 0 && sub > 0 && rawDiscount > 100) {
        discPct = (rawDiscount / sub) * 100;
      }
      discVal = discPct;
    }

    return InvoiceItem(
      id: (json['id'] ?? '').toString(),
      product: prod,
      quantity: qty,
      unitPrice: unitP,
      description: (json['description'] ?? prod.name).toString(),
      discountPercentage: discPct,
      taxPercentage: toDouble(json['tax'] ?? json['tax_percentage'] ?? json['taxPercentage']),
      discountType: discType,
      discountValue: discVal,
      hsnSac: hsn.isNotEmpty ? hsn : prod.hsnSacCode,
      unit: unitVal.isNotEmpty ? unitVal : prod.unitAbbreviation,
      itemName: iName ?? prod.name,
    );
  }

  Map<String, dynamic> toJson() {
    final effectiveName = (itemName != null && itemName!.isNotEmpty)
        ? itemName!
        : (product.name.isNotEmpty ? product.name : (description.isNotEmpty ? description : 'Item'));
    final effectiveHsn = (hsnSac != null && hsnSac!.isNotEmpty)
        ? hsnSac!
        : product.hsnSacCode;
    final effectiveUnit = (unit != null && unit!.isNotEmpty)
        ? unit!
        : (product.unitAbbreviation.isNotEmpty ? product.unitAbbreviation : 'Nos');
    final effectiveDisc = discountType == '₹'
        ? (discountValue > 0 ? discountValue : discountAmount)
        : (discountValue > 0 ? discountValue : discountPercentage);

    return {
      'product': product.id.isNotEmpty ? product.id : effectiveName,
      'item_name': effectiveName,
      'description': description.isNotEmpty ? description : effectiveName,
      'hsn_sac': effectiveHsn,
      'quantity': quantity,
      'unit_price': unitPrice,
      'discount': effectiveDisc,
      'discount_type': discountType,
      'tax': taxPercentage,
      'unit': effectiveUnit,
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
    String? discountType,
    double? discountValue,
    String? hsnSac,
    String? unit,
    String? itemName,
  }) {
    return InvoiceItem(
      id: id ?? this.id,
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      description: description ?? this.description,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      taxPercentage: taxPercentage ?? this.taxPercentage,
      discountType: discountType ?? this.discountType,
      discountValue: discountValue ?? this.discountValue,
      hsnSac: hsnSac ?? this.hsnSac,
      unit: unit ?? this.unit,
      itemName: itemName ?? this.itemName,
    );
  }
}
