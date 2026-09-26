class Product {
  final String id;
  final String name;
  final String sku;
  final String barcode;
  final String category;
  final String brand;
  final double purchasePrice;
  final double sellingPrice;
  final int stock;
  final int minStock;
  final double gst;
  final String? image;
  final DateTime createdAt;

  const Product({
    required this.id,
    required this.name,
    required this.sku,
    required this.barcode,
    required this.category,
    required this.brand,
    required this.purchasePrice,
    required this.sellingPrice,
    required this.stock,
    required this.minStock,
    this.gst = 18.0,
    this.image,
    required this.createdAt,
  });

  // Getter to prevent breaking any legacy code referencing price and imageUrl
  double get price => sellingPrice;
  String? get imageUrl => image;

  // Safely parses a value that may be a num or a String (Django DecimalField
  // serialises as string by default, e.g. "999.00").
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      final double? parsedDouble = double.tryParse(value);
      if (parsedDouble != null) {
        return parsedDouble.toInt();
      }
      return int.tryParse(value);
    }
    return null;
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      name: (json['name'] ?? '').toString(),
      sku: (json['sku'] ?? '').toString(),
      barcode: (json['barcode'] ?? '').toString(),
      category: (json['category'] ?? json['category_name'] ?? 'Services').toString(),
      brand: (json['brand'] ?? '').toString(),
      purchasePrice: _parseDouble(json['purchasePrice'] ?? json['purchase_price']) ?? 0.0,
      sellingPrice: _parseDouble(json['sellingPrice'] ?? json['selling_price'] ?? json['price']) ?? 0.0,
      stock: _parseInt(json['stock'] ?? json['current_stock']) ?? 0,
      minStock: _parseInt(json['minStock'] ?? json['min_stock'] ?? json['reorder_level']) ?? 5,
      gst: _parseDouble(json['gst'] ?? json['gst_tax_rate']) ?? 18.0,
      image: (json['image'] ?? json['imageUrl'] ?? json['image_url']) as String?,
      createdAt: json['createdAt'] != null || json['created_at'] != null
          ? DateTime.parse((json['createdAt'] ?? json['created_at']) as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'sku': sku,
      'barcode': barcode,
      'category_name': category,
      'category': category,
      'brand': brand,
      'purchase_price': purchasePrice,
      'purchasePrice': purchasePrice,
      'selling_price': sellingPrice,
      'sellingPrice': sellingPrice,
      'price': sellingPrice, // Compatibility
      'current_stock': stock,
      'stock': stock,
      'min_stock': minStock,
      'minStock': minStock,
      'gst_tax_rate': gst,
      'gst': gst,
      'image_url': image,
      'image': image,
      'imageUrl': image, // Compatibility
      'createdAt': createdAt.toIso8601String(),
    };
  }

  Product copyWith({
    String? id,
    String? name,
    String? sku,
    String? barcode,
    String? category,
    String? brand,
    double? purchasePrice,
    double? sellingPrice,
    int? stock,
    int? minStock,
    double? gst,
    String? image,
    DateTime? createdAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      barcode: barcode ?? this.barcode,
      category: category ?? this.category,
      brand: brand ?? this.brand,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      stock: stock ?? this.stock,
      minStock: minStock ?? this.minStock,
      gst: gst ?? this.gst,
      image: image ?? this.image,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
