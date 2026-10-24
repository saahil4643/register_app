class Product {
  final String id;
  final String name;
  final String sku;
  final String productCode;
  final String barcode;
  final String productType; // 'goods' or 'service'
  final String company; // Company name (e.g. Wipro, Cadbury, Fena)
  final String? companyId;
  final String category; // Category name (e.g. Santoor, Yardley)
  final String? categoryId;
  final String subcategory; // Subcategory name (e.g. Handwash, Soap, Powder)
  final String? subcategoryId;
  final String brand; // Brand name for display
  final String? brandId;
  final String unitOfMeasurement;
  final String unitAbbreviation;
  final String warehouse;
  final String? warehouseId;
  final String hsnSacCode;
  final double purchasePrice;
  final double sellingPrice;
  final int stock;
  final double openingStock;
  final int minStock; // reorder_level
  final bool trackInventory;
  final String status; // 'active' or 'inactive'
  final String description;
  final double gst;
  final String? image;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Product({
    required this.id,
    required this.name,
    required this.sku,
    this.productCode = '',
    this.barcode = '',
    this.productType = 'goods',
    String? company,
    this.companyId,
    required this.category,
    this.categoryId,
    String? subcategory,
    this.subcategoryId,
    String? brand,
    this.brandId,
    this.unitOfMeasurement = 'Pieces',
    this.unitAbbreviation = 'pcs',
    this.warehouse = 'Main Warehouse',
    this.warehouseId,
    this.hsnSacCode = '',
    this.purchasePrice = 0.0,
    double? sellingPrice,
    double? price,
    required this.stock,
    this.openingStock = 0.0,
    required this.minStock,
    this.trackInventory = true,
    this.status = 'active',
    this.description = '',
    this.gst = 18.0,
    String? image,
    String? imageUrl,
    required this.createdAt,
    this.updatedAt,
  })  : company = (company != null && company.isNotEmpty)
            ? company
            : ((brand != null && brand.isNotEmpty && brand != 'Generic') ? brand : 'General'),
        subcategory = (subcategory != null && subcategory.isNotEmpty) ? subcategory : 'General',
        brand = (brand != null && brand.isNotEmpty)
            ? brand
            : ((company != null && company.isNotEmpty) ? company : 'Generic'),
        sellingPrice = sellingPrice ?? price ?? 0.0,
        image = image ?? imageUrl;

  // Getter to prevent breaking any legacy code referencing price and imageUrl
  double get price => sellingPrice;
  String? get imageUrl => image;
  bool get isActive => status.toLowerCase() == 'active';

  // Safely parses a value that may be a num or a String
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

  static bool _parseBool(dynamic value, {bool fallback = true}) {
    if (value == null) return fallback;
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final lower = value.toLowerCase().trim();
      return lower == 'true' || lower == '1' || lower == 'yes';
    }
    return fallback;
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    // Resolve company name and id
    String compName = 'General';
    String? compId;
    if (json['company'] is Map) {
      final compMap = json['company'] as Map<String, dynamic>;
      compName = (compMap['name'] ?? 'General').toString();
      compId = compMap['id']?.toString();
    } else if (json['company_name'] != null) {
      compName = json['company_name'].toString();
      compId = json['company']?.toString();
    } else if (json['company'] != null) {
      compName = json['company'].toString();
    }

    // Resolve category name and id
    String catName = 'General';
    String? catId;
    if (json['category'] is Map) {
      final catMap = json['category'] as Map<String, dynamic>;
      catName = (catMap['name'] ?? 'General').toString();
      catId = catMap['id']?.toString();
    } else if (json['category_name'] != null) {
      catName = json['category_name'].toString();
      catId = json['category']?.toString();
    } else if (json['category'] != null) {
      catName = json['category'].toString();
    }

    // Resolve subcategory name and id
    String subcatName = 'General';
    String? subcatId;
    if (json['subcategory'] is Map) {
      final subMap = json['subcategory'] as Map<String, dynamic>;
      subcatName = (subMap['name'] ?? 'General').toString();
      subcatId = subMap['id']?.toString();
    } else if (json['subcategory_name'] != null) {
      subcatName = json['subcategory_name'].toString();
      subcatId = json['subcategory']?.toString();
    } else if (json['subcategory'] != null) {
      subcatName = json['subcategory'].toString();
    }

    // Resolve brand name and id
    String brandName = compName != 'General' ? compName : 'Generic';
    String? bId;
    if (json['brand'] is Map) {
      final brandMap = json['brand'] as Map<String, dynamic>;
      brandName = (brandMap['name'] ?? brandName).toString();
      bId = brandMap['id']?.toString();
    } else if (json['brand_name'] != null) {
      brandName = json['brand_name'].toString();
      bId = json['brand']?.toString();
    } else if (json['brand'] != null) {
      brandName = json['brand'].toString();
    }

    if (compName == 'General' && brandName != 'Generic') {
      compName = brandName;
    }

    // Resolve unit of measurement
    String uomName = 'Pieces';
    String uomAbbr = 'pcs';
    if (json['unit_of_measurement'] is Map) {
      final uomMap = json['unit_of_measurement'] as Map<String, dynamic>;
      uomName = (uomMap['name'] ?? 'Pieces').toString();
      uomAbbr = (uomMap['abbreviation'] ?? 'pcs').toString();
    } else {
      if (json['unit_name'] != null) uomName = json['unit_name'].toString();
      if (json['unit_abbreviation'] != null) uomAbbr = json['unit_abbreviation'].toString();
    }

    // Resolve warehouse
    String whName = 'Main Warehouse';
    String? whId;
    if (json['warehouse'] is Map) {
      final whMap = json['warehouse'] as Map<String, dynamic>;
      whName = (whMap['name'] ?? 'Main Warehouse').toString();
      whId = whMap['id']?.toString();
    } else if (json['warehouse_name'] != null) {
      whName = json['warehouse_name'].toString();
      whId = json['warehouse']?.toString();
    } else if (json['warehouse'] != null) {
      whName = json['warehouse'].toString();
    }

    return Product(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      sku: (json['sku'] ?? '').toString(),
      productCode: (json['product_code'] ?? '').toString(),
      barcode: (json['barcode'] ?? '').toString(),
      productType: (json['product_type'] ?? 'goods').toString(),
      company: compName,
      companyId: compId,
      category: catName,
      categoryId: catId,
      subcategory: subcatName,
      subcategoryId: subcatId,
      brand: brandName,
      brandId: bId,
      unitOfMeasurement: uomName,
      unitAbbreviation: uomAbbr,
      warehouse: whName,
      warehouseId: whId,
      hsnSacCode: (json['hsn_sac_code'] ?? json['hsn_code'] ?? '').toString(),
      purchasePrice: _parseDouble(json['purchase_price'] ?? json['purchasePrice']) ?? 0.0,
      sellingPrice: _parseDouble(json['selling_price'] ?? json['sellingPrice'] ?? json['price']) ?? 0.0,
      stock: _parseInt(json['current_stock'] ?? json['stock'] ?? json['opening_stock']) ?? 0,
      openingStock: _parseDouble(json['opening_stock'] ?? json['current_stock'] ?? json['stock']) ?? 0.0,
      minStock: _parseInt(json['reorder_level'] ?? json['min_stock'] ?? json['minStock']) ?? 5,
      trackInventory: _parseBool(json['track_inventory'], fallback: true),
      status: (json['status'] ?? 'active').toString(),
      description: (json['description'] ?? '').toString(),
      gst: _parseDouble(json['gst_tax_rate'] ?? json['gst']) ?? 18.0,
      image: (json['image'] ?? json['image_url'] ?? json['imageUrl']) as String?,
      createdAt: json['created_at'] != null || json['createdAt'] != null
          ? DateTime.tryParse((json['created_at'] ?? json['createdAt']).toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'name': name,
      'sku': sku,
      if (productCode.isNotEmpty) 'product_code': productCode,
      if (barcode.isNotEmpty) 'barcode': barcode,
      'product_type': productType,
      'company': companyId ?? company,
      'company_name': company,
      'category': categoryId ?? category,
      'category_name': category,
      'subcategory': subcategoryId ?? subcategory,
      'subcategory_name': subcategory,
      'brand': brandId ?? (company.isNotEmpty ? company : brand),
      'brand_name': company.isNotEmpty ? company : brand,
      'unit_of_measurement': unitOfMeasurement,
      'unit_abbreviation': unitAbbreviation,
      'warehouse': warehouseId ?? warehouse,
      if (hsnSacCode.isNotEmpty) 'hsn_sac_code': hsnSacCode,
      'gst_tax_rate': gst,
      'selling_price': sellingPrice,
      'purchase_price': purchasePrice,
      'current_stock': stock,
      'opening_stock': openingStock > 0 ? openingStock : stock.toDouble(),
      'reorder_level': minStock,
      'track_inventory': trackInventory,
      'status': status,
      if (description.isNotEmpty) 'description': description,
      if (image != null) 'image_url': image,
      'created_at': createdAt.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      // Compatibility aliases
      'price': sellingPrice,
      'stock': stock,
      'minStock': minStock,
      'gst': gst,
      'image': image,
    };
  }

  Product copyWith({
    String? id,
    String? name,
    String? sku,
    String? productCode,
    String? barcode,
    String? productType,
    String? company,
    String? companyId,
    String? category,
    String? categoryId,
    String? subcategory,
    String? subcategoryId,
    String? brand,
    String? brandId,
    String? unitOfMeasurement,
    String? unitAbbreviation,
    String? warehouse,
    String? warehouseId,
    String? hsnSacCode,
    double? purchasePrice,
    double? sellingPrice,
    int? stock,
    double? openingStock,
    int? minStock,
    bool? trackInventory,
    String? status,
    String? description,
    double? gst,
    String? image,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      productCode: productCode ?? this.productCode,
      barcode: barcode ?? this.barcode,
      productType: productType ?? this.productType,
      company: company ?? this.company,
      companyId: companyId ?? this.companyId,
      category: category ?? this.category,
      categoryId: categoryId ?? this.categoryId,
      subcategory: subcategory ?? this.subcategory,
      subcategoryId: subcategoryId ?? this.subcategoryId,
      brand: brand ?? this.brand,
      brandId: brandId ?? this.brandId,
      unitOfMeasurement: unitOfMeasurement ?? this.unitOfMeasurement,
      unitAbbreviation: unitAbbreviation ?? this.unitAbbreviation,
      warehouse: warehouse ?? this.warehouse,
      warehouseId: warehouseId ?? this.warehouseId,
      hsnSacCode: hsnSacCode ?? this.hsnSacCode,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      stock: stock ?? this.stock,
      openingStock: openingStock ?? this.openingStock,
      minStock: minStock ?? this.minStock,
      trackInventory: trackInventory ?? this.trackInventory,
      status: status ?? this.status,
      description: description ?? this.description,
      gst: gst ?? this.gst,
      image: image ?? this.image,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
