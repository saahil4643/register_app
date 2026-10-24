import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProductSubcategory {
  final String id;
  final String name;

  const ProductSubcategory({
    required this.id,
    required this.name,
  });

  Map<String, dynamic> toJson() => {'id': id, 'name': name};

  factory ProductSubcategory.fromJson(Map<String, dynamic> json) => ProductSubcategory(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
      );
}

class ProductCategory {
  final String id;
  final String name;
  final List<ProductSubcategory> subcategories;

  const ProductCategory({
    required this.id,
    required this.name,
    this.subcategories = const [],
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'subcategories': subcategories.map((s) => s.toJson()).toList(),
      };

  factory ProductCategory.fromJson(Map<String, dynamic> json) => ProductCategory(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        subcategories: (json['subcategories'] as List<dynamic>? ?? [])
            .map((s) => ProductSubcategory.fromJson(Map<String, dynamic>.from(s as Map)))
            .toList(),
      );

  ProductCategory copyWith({
    String? id,
    String? name,
    List<ProductSubcategory>? subcategories,
  }) {
    return ProductCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      subcategories: subcategories ?? this.subcategories,
    );
  }
}

class ProductCompany {
  final String id;
  final String name;
  final List<ProductCategory> categories;

  const ProductCompany({
    required this.id,
    required this.name,
    this.categories = const [],
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'categories': categories.map((c) => c.toJson()).toList(),
      };

  factory ProductCompany.fromJson(Map<String, dynamic> json) => ProductCompany(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        categories: (json['categories'] as List<dynamic>? ?? [])
            .map((c) => ProductCategory.fromJson(Map<String, dynamic>.from(c as Map)))
            .toList(),
      );

  ProductCompany copyWith({
    String? id,
    String? name,
    List<ProductCategory>? categories,
  }) {
    return ProductCompany(
      id: id ?? this.id,
      name: name ?? this.name,
      categories: categories ?? this.categories,
    );
  }
}

/// Service that maintains the hierarchy of Companies, Categories, and Subcategories.
/// Seeds standard FMCG / goods brands (Wipro, Cadbury, Fena, HUL, Nestle) and
/// allows users to add custom companies, categories, and subcategories at runtime.
class ProductHierarchyService extends ChangeNotifier {
  static final ProductHierarchyService _instance = ProductHierarchyService._internal();
  factory ProductHierarchyService() => _instance;
  ProductHierarchyService._internal();

  static const String _storageKey = 'product_hierarchy_data_v1';
  bool _initialized = false;
  List<ProductCompany> _companies = [];

  List<ProductCompany> get companies => List.unmodifiable(_companies);

  static final List<ProductCompany> defaultCompanies = [
    ProductCompany(
      id: 'comp_wipro',
      name: 'Wipro',
      categories: [
        ProductCategory(
          id: 'cat_santoor',
          name: 'Santoor',
          subcategories: [
            ProductSubcategory(id: 'sub_soap', name: 'Soap'),
            ProductSubcategory(id: 'sub_handwash', name: 'Handwash'),
            ProductSubcategory(id: 'sub_powder', name: 'Powder'),
            ProductSubcategory(id: 'sub_bodywash', name: 'Body Wash'),
          ],
        ),
        ProductCategory(
          id: 'cat_yardley',
          name: 'Yardley',
          subcategories: [
            ProductSubcategory(id: 'sub_talc', name: 'Talcum Powder'),
            ProductSubcategory(id: 'sub_perfume', name: 'Perfume / Deodorant'),
            ProductSubcategory(id: 'sub_mist', name: 'Body Mist'),
          ],
        ),
        ProductCategory(
          id: 'cat_chandrika',
          name: 'Chandrika',
          subcategories: [
            ProductSubcategory(id: 'sub_ayur_soap', name: 'Ayurvedic Soap'),
            ProductSubcategory(id: 'sub_facewash', name: 'Face Wash'),
          ],
        ),
        ProductCategory(
          id: 'cat_glucovita',
          name: 'Glucovita',
          subcategories: [
            ProductSubcategory(id: 'sub_energy_pdr', name: 'Energy Powder'),
            ProductSubcategory(id: 'sub_energy_drk', name: 'Energy Drink'),
          ],
        ),
      ],
    ),
    ProductCompany(
      id: 'comp_cadbury',
      name: 'Cadbury',
      categories: [
        ProductCategory(
          id: 'cat_dairy_milk',
          name: 'Dairy Milk',
          subcategories: [
            ProductSubcategory(id: 'sub_chocolate_bar', name: 'Regular Bar'),
            ProductSubcategory(id: 'sub_silk', name: 'Silk'),
            ProductSubcategory(id: 'sub_fruit_nut', name: 'Roast Almond & Fruit Nut'),
            ProductSubcategory(id: 'sub_crackle', name: 'Crackle'),
          ],
        ),
        ProductCategory(
          id: 'cat_oreo',
          name: 'Oreo',
          subcategories: [
            ProductSubcategory(id: 'sub_vanilla_bisc', name: 'Vanilla Cream Biscuits'),
            ProductSubcategory(id: 'sub_choco_bisc', name: 'Chocolate Cream Biscuits'),
          ],
        ),
        ProductCategory(
          id: 'cat_bournvita',
          name: 'Bournvita',
          subcategories: [
            ProductSubcategory(id: 'sub_health_drink', name: 'Health Drink Jar / Refill'),
            ProductSubcategory(id: 'sub_bourn_bisc', name: 'Bournvita Biscuits'),
          ],
        ),
        ProductCategory(
          id: 'cat_5star',
          name: '5 Star',
          subcategories: [
            ProductSubcategory(id: 'sub_5star_bar', name: 'Chocolate Bar'),
            ProductSubcategory(id: 'sub_5star_3d', name: '5 Star 3D'),
          ],
        ),
      ],
    ),
    ProductCompany(
      id: 'comp_fena',
      name: 'Fena',
      categories: [
        ProductCategory(
          id: 'cat_fena_detergent',
          name: 'Fena Detergent',
          subcategories: [
            ProductSubcategory(id: 'sub_det_powder', name: 'Detergent Powder'),
            ProductSubcategory(id: 'sub_det_cake', name: 'Detergent Cake'),
            ProductSubcategory(id: 'sub_det_liquid', name: 'Liquid Detergent'),
          ],
        ),
        ProductCategory(
          id: 'cat_nip',
          name: 'Nip',
          subcategories: [
            ProductSubcategory(id: 'sub_dish_bar', name: 'Dishwash Bar'),
            ProductSubcategory(id: 'sub_dish_liquid', name: 'Liquid Dishwash'),
          ],
        ),
      ],
    ),
    ProductCompany(
      id: 'comp_hul',
      name: 'Hindustan Unilever',
      categories: [
        ProductCategory(
          id: 'cat_dove',
          name: 'Dove',
          subcategories: [
            ProductSubcategory(id: 'sub_dove_soap', name: 'Bathing Bar'),
            ProductSubcategory(id: 'sub_dove_shampoo', name: 'Shampoo'),
            ProductSubcategory(id: 'sub_dove_conditioner', name: 'Conditioner'),
          ],
        ),
        ProductCategory(
          id: 'cat_lifebuoy',
          name: 'Lifebuoy',
          subcategories: [
            ProductSubcategory(id: 'sub_lifebuoy_soap', name: 'Soap'),
            ProductSubcategory(id: 'sub_lifebuoy_handwash', name: 'Handwash'),
            ProductSubcategory(id: 'sub_lifebuoy_sanitizer', name: 'Hand Sanitizer'),
          ],
        ),
        ProductCategory(
          id: 'cat_surf_excel',
          name: 'Surf Excel',
          subcategories: [
            ProductSubcategory(id: 'sub_surf_powder', name: 'Washing Powder'),
            ProductSubcategory(id: 'sub_surf_matic', name: 'Matic Liquid'),
          ],
        ),
      ],
    ),
    ProductCompany(
      id: 'comp_nestle',
      name: 'Nestle',
      categories: [
        ProductCategory(
          id: 'cat_maggi',
          name: 'Maggi',
          subcategories: [
            ProductSubcategory(id: 'sub_maggi_noodles', name: 'Instant Noodles'),
            ProductSubcategory(id: 'sub_maggi_sauce', name: 'Tomato Ketchup'),
            ProductSubcategory(id: 'sub_maggi_masala', name: 'Magic Masala'),
          ],
        ),
        ProductCategory(
          id: 'cat_nescafe',
          name: 'Nescafe',
          subcategories: [
            ProductSubcategory(id: 'sub_nescafe_classic', name: 'Classic Coffee'),
            ProductSubcategory(id: 'sub_nescafe_gold', name: 'Gold Blend'),
          ],
        ),
        ProductCategory(
          id: 'cat_kitkat',
          name: 'KitKat',
          subcategories: [
            ProductSubcategory(id: 'sub_kitkat_wafer', name: 'Chocolate Wafer Bar'),
          ],
        ),
      ],
    ),
    ProductCompany(
      id: 'comp_general',
      name: 'General',
      categories: [
        ProductCategory(
          id: 'cat_general_goods',
          name: 'General Goods',
          subcategories: [
            ProductSubcategory(id: 'sub_general_item', name: 'General'),
          ],
        ),
        ProductCategory(
          id: 'cat_services',
          name: 'Services',
          subcategories: [
            ProductSubcategory(id: 'sub_consulting', name: 'Consulting'),
            ProductSubcategory(id: 'sub_support', name: 'Support / Maintenance'),
          ],
        ),
      ],
    ),
  ];

  Future<void> init() async {
    if (_initialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_storageKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final decoded = jsonDecode(jsonStr) as List<dynamic>;
        _companies = decoded
            .map((e) => ProductCompany.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      } else {
        _companies = List.from(defaultCompanies);
        await _save();
      }
    } catch (e) {
      debugPrint('Error loading product hierarchy: $e');
      _companies = List.from(defaultCompanies);
    }
    _initialized = true;
    notifyListeners();
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(_companies.map((c) => c.toJson()).toList());
      await prefs.setString(_storageKey, encoded);
    } catch (e) {
      debugPrint('Error saving product hierarchy: $e');
    }
  }

  List<String> getCompanyNames() {
    if (!_initialized) _companies = List.from(defaultCompanies);
    return _companies.map((c) => c.name).toList();
  }

  List<String> getCategoryNames(String companyName) {
    if (!_initialized) _companies = List.from(defaultCompanies);
    final comp = _companies.firstWhere(
      (c) => c.name.toLowerCase() == companyName.toLowerCase(),
      orElse: () => const ProductCompany(id: '', name: ''),
    );
    return comp.categories.map((c) => c.name).toList();
  }

  List<String> getSubcategoryNames(String companyName, String categoryName) {
    if (!_initialized) _companies = List.from(defaultCompanies);
    final comp = _companies.firstWhere(
      (c) => c.name.toLowerCase() == companyName.toLowerCase(),
      orElse: () => const ProductCompany(id: '', name: ''),
    );
    final cat = comp.categories.firstWhere(
      (c) => c.name.toLowerCase() == categoryName.toLowerCase(),
      orElse: () => const ProductCategory(id: '', name: ''),
    );
    return cat.subcategories.map((s) => s.name).toList();
  }

  Future<void> addCompany(String name) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty) return;
    if (_companies.any((c) => c.name.toLowerCase() == cleanName.toLowerCase())) return;

    final newComp = ProductCompany(
      id: 'comp_${DateTime.now().millisecondsSinceEpoch}',
      name: cleanName,
      categories: [
        ProductCategory(
          id: 'cat_${DateTime.now().millisecondsSinceEpoch}',
          name: 'General',
          subcategories: [
            ProductSubcategory(
              id: 'sub_${DateTime.now().millisecondsSinceEpoch}',
              name: 'General',
            ),
          ],
        ),
      ],
    );
    _companies.add(newComp);
    await _save();
    notifyListeners();
  }

  Future<void> addCategory(String companyName, String categoryName) async {
    final cleanCat = categoryName.trim();
    if (cleanCat.isEmpty) return;

    final compIdx = _companies.indexWhere(
      (c) => c.name.toLowerCase() == companyName.trim().toLowerCase(),
    );
    if (compIdx < 0) return;

    final comp = _companies[compIdx];
    if (comp.categories.any((c) => c.name.toLowerCase() == cleanCat.toLowerCase())) return;

    final newCat = ProductCategory(
      id: 'cat_${DateTime.now().millisecondsSinceEpoch}',
      name: cleanCat,
      subcategories: [
        ProductSubcategory(
          id: 'sub_${DateTime.now().millisecondsSinceEpoch}',
          name: 'General',
        ),
      ],
    );

    final updatedCategories = List<ProductCategory>.from(comp.categories)..add(newCat);
    _companies[compIdx] = comp.copyWith(categories: updatedCategories);
    await _save();
    notifyListeners();
  }

  Future<void> addSubcategory(String companyName, String categoryName, String subcategoryName) async {
    final cleanSub = subcategoryName.trim();
    if (cleanSub.isEmpty) return;

    final compIdx = _companies.indexWhere(
      (c) => c.name.toLowerCase() == companyName.trim().toLowerCase(),
    );
    if (compIdx < 0) return;

    final comp = _companies[compIdx];
    final catIdx = comp.categories.indexWhere(
      (c) => c.name.toLowerCase() == categoryName.trim().toLowerCase(),
    );
    if (catIdx < 0) return;

    final cat = comp.categories[catIdx];
    if (cat.subcategories.any((s) => s.name.toLowerCase() == cleanSub.toLowerCase())) return;

    final newSub = ProductSubcategory(
      id: 'sub_${DateTime.now().millisecondsSinceEpoch}',
      name: cleanSub,
    );

    final updatedSubs = List<ProductSubcategory>.from(cat.subcategories)..add(newSub);
    final updatedCat = cat.copyWith(subcategories: updatedSubs);

    final updatedCategories = List<ProductCategory>.from(comp.categories);
    updatedCategories[catIdx] = updatedCat;

    _companies[compIdx] = comp.copyWith(categories: updatedCategories);
    await _save();
    notifyListeners();
  }
}
