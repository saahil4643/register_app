import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../products/models/product.dart';
import '../../products/providers/product_provider.dart';
import '../providers/invoice_provider.dart';

const Object _productSearchGroupId = 'product_search_group_id';

/// Product search field with a robust, non-intrusive Overlay dropdown.
/// Uses a custom overlay implementation linked via [CompositedTransformTarget]
/// and [CompositedTransformFollower] to ensure stable layout constraints,
/// clean overlay lifecycle management, and a crash-free experience on web and desktop.
class ProductSearchField extends StatefulWidget {
  final ValueChanged<Product> onSelected;

  const ProductSearchField({
    super.key,
    required this.onSelected,
  });

  @override
  State<ProductSearchField> createState() => _ProductSearchFieldState();
}

class _ProductSearchFieldState extends State<ProductSearchField> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  Timer? _debounce;
  List<Product> _suggestions = [];
  bool _isLoading = false;
  String? _errorMessage;
  int _highlightedIndex = -1;
  String _searchQuery = '';
  double _fieldWidth = 0.0;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _hideOverlay();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      if (_controller.text.trim().isNotEmpty) {
        _showOverlay();
      }
    } else {
      // Delay hiding the overlay to allow tap events inside the overlay to register.
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted && !_focusNode.hasFocus) {
          _hideOverlay();
        }
      });
    }
  }

  void _showOverlay() {
    if (!mounted || _overlayEntry != null) return;

    _overlayEntry = OverlayEntry(
      builder: (context) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;

        return Positioned(
          left: 0,
          top: 0,
          width: _fieldWidth > 0 ? _fieldWidth : 300,
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            targetAnchor: Alignment.bottomLeft,
            followerAnchor: Alignment.topLeft,
            offset: const Offset(0, 4),
            child: TapRegion(
              groupId: _productSearchGroupId,
              child: Material(
                elevation: 6,
                borderRadius: BorderRadius.circular(12),
                color: isDark ? theme.colorScheme.surface : Colors.white,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        width: 1.5,
                      ),
                    ),
                    child: _buildDropdownBody(context),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideOverlay() {
    if (_overlayEntry != null) {
      try {
        _overlayEntry!.remove();
      } catch (_) {}
      _overlayEntry = null;
    }
  }

  void _updateOverlay() {
    if (_overlayEntry != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _overlayEntry != null) {
          _overlayEntry!.markNeedsBuild();
        }
      });
    }
  }

  void _onTextChanged(String text) {
    final query = text.trim();
    _searchQuery = query;

    if (query.isEmpty) {
      _hideOverlay();
      setState(() {
        _suggestions = [];
        _highlightedIndex = -1;
        _isLoading = false;
        _errorMessage = null;
      });
      return;
    }

    _showOverlay();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    _updateOverlay();

    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) _search(query);
    });
  }

  Future<void> _search(String query) async {
    if (query.isEmpty) return;
    try {
      final String path = '/api/v1/products?search=${Uri.encodeComponent(query)}';
      final response = await ApiService().get(path);
      if (!mounted) return;

      if (response['success'] == true) {
        final data = response['data'];
        final List<dynamic> dataList = data is List
            ? data
            : (data is Map && data['results'] is List
                ? data['results'] as List<dynamic>
                : []);
        setState(() {
          _suggestions = dataList
              .map((json) => Product.fromJson(json as Map<String, dynamic>))
              .toList();
          _highlightedIndex = _suggestions.isNotEmpty ? 0 : -1;
          _isLoading = false;
        });
        _updateOverlay();
      } else {
        setState(() {
          _errorMessage = response['message'] ?? 'Search failed';
          _isLoading = false;
        });
        _updateOverlay();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Connection error';
          _isLoading = false;
        });
        _updateOverlay();
      }
    }
  }

  void _selectProduct(Product product) {
    _controller.clear();
    _hideOverlay();
    _focusNode.unfocus();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.onSelected(product);
      }
    });

    setState(() {
      _suggestions = [];
      _highlightedIndex = -1;
      _searchQuery = '';
    });
  }

  void _moveSelectionDown() {
    if (_suggestions.isEmpty || !mounted) return;
    setState(() {
      _highlightedIndex = (_highlightedIndex + 1) % _suggestions.length;
    });
    _updateOverlay();
  }

  void _moveSelectionUp() {
    if (_suggestions.isEmpty || !mounted) return;
    setState(() {
      _highlightedIndex =
          (_highlightedIndex - 1 + _suggestions.length) % _suggestions.length;
    });
    _updateOverlay();
  }

  void _showQuickAddProductDialog(String initialName) {
    final productProvider = context.read<ProductProvider>();
    InvoiceProvider? invoiceProvider;
    try {
      invoiceProvider = context.read<InvoiceProvider>();
    } catch (_) {}
    final messenger = ScaffoldMessenger.of(context);

    _hideOverlay();
    _focusNode.unfocus();

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) {
        final formKey = GlobalKey<FormState>();
        final nameController = TextEditingController(text: initialName);
        final priceController = TextEditingController();
        bool isSubmitting = false;

        return StatefulBuilder(
          builder: (context, setState) {
            final theme = Theme.of(context);

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Icon(Icons.add_shopping_cart_rounded, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  const Text('Quick Add Product'),
                ],
              ),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Product Name *',
                        prefixIcon: Icon(Icons.label_rounded),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Enter product name' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: priceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'Price (₹) *',
                        prefixIcon: Icon(Icons.sell_outlined),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Enter price';
                        final parsed = double.tryParse(val);
                        if (parsed == null) return 'Invalid price';
                        if (parsed < 0) return 'Price cannot be negative';
                        final parts = val.trim().split('.');
                        if (parts[0].length > 9) {
                          return 'Price cannot exceed 9 digits';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(dialogCtx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          setState(() {
                            isSubmitting = true;
                          });

                          final price = double.parse(
                            (double.tryParse(priceController.text) ?? 0.0).toStringAsFixed(2)
                          );

                          final product = Product(
                            id: '',
                            name: nameController.text.trim(),
                            sku: '',
                            barcode: '',
                            category: 'Services',
                            brand: 'Generic',
                            purchasePrice: double.parse((price * 0.7).toStringAsFixed(2)),
                            sellingPrice: price,
                            stock: 10,
                            minStock: 5,
                            gst: 18.0,
                            createdAt: DateTime.now(),
                          );

                          final newProduct = await productProvider.createProduct(product);

                          if (dialogCtx.mounted) {
                            if (newProduct != null) {
                              widget.onSelected(newProduct);
                              invoiceProvider?.addProduct(newProduct);
                              Navigator.pop(dialogCtx); // Close Dialog
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text('Product "${newProduct.name}" created and added!'),
                                  backgroundColor: AppColors.success,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            } else {
                              setState(() {
                                isSubmitting = false;
                              });
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(productProvider.errorMessage ?? 'Failed to create product'),
                                  backgroundColor: AppColors.error,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Add & Select'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return TapRegion(
      groupId: _productSearchGroupId,
      onTapOutside: (_) {
        _focusNode.unfocus();
      },
      child: CompositedTransformTarget(
        link: _layerLink,
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            if (_fieldWidth != constraints.maxWidth) {
              _fieldWidth = constraints.maxWidth;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _updateOverlay();
              });
            }

            return Focus(
              onKeyEvent: (_, event) {
                if (event is! KeyDownEvent) return KeyEventResult.ignored;
                if (_overlayEntry == null) return KeyEventResult.ignored;

                if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                  _moveSelectionDown();
                  return KeyEventResult.handled;
                }
                if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                  _moveSelectionUp();
                  return KeyEventResult.handled;
                }
                if (event.logicalKey == LogicalKeyboardKey.enter) {
                  if (_suggestions.isNotEmpty &&
                      _highlightedIndex >= 0 &&
                      _highlightedIndex < _suggestions.length) {
                    _selectProduct(_suggestions[_highlightedIndex]);
                    return KeyEventResult.handled;
                  }
                }
                if (event.logicalKey == LogicalKeyboardKey.escape) {
                  _focusNode.unfocus();
                  return KeyEventResult.handled;
                }
                return KeyEventResult.ignored;
              },
              child: TextFormField(
                controller: _controller,
                focusNode: _focusNode,
                onChanged: _onTextChanged,
                decoration: InputDecoration(
                  labelText: 'Search Product / SKU',
                  hintText: 'Type product name or SKU...',
                  prefixIcon: const Icon(Icons.shopping_bag_outlined),
                  suffixIcon: _controller.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            _controller.clear();
                            _hideOverlay();
                            _focusNode.unfocus();
                            setState(() {
                              _suggestions = [];
                              _highlightedIndex = -1;
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDropdownBody(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 24),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: const TextStyle(color: AppColors.error, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_suggestions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'No product found',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => _showQuickAddProductDialog(_searchQuery),
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Quick Add Product', style: TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                minimumSize: Size.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Suggestions List
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 280),
          child: ListView.separated(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            itemCount: _suggestions.length,
            separatorBuilder: (_, _) => Divider(
              height: 1,
              color: isDark ? Colors.grey[850] : Colors.grey[200],
            ),
            itemBuilder: (_, index) {
              final product = _suggestions[index];
              final isHighlighted = index == _highlightedIndex;
              return ProductSuggestionTile(
                product: product,
                isHighlighted: isHighlighted,
                onTap: () => _selectProduct(product),
              );
            },
          ),
        ),
        Divider(
          height: 1,
          color: isDark ? Colors.grey[850] : Colors.grey[200],
        ),
        InkWell(
          onTap: () => _showQuickAddProductDialog(_searchQuery),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.add_circle_outline_rounded, color: theme.colorScheme.primary, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _searchQuery.trim().isEmpty
                        ? 'Quick Add New Product'
                        : 'Quick Add "${_searchQuery.trim()}"',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class ProductSuggestionTile extends StatelessWidget {
  final Product product;
  final bool isHighlighted;
  final VoidCallback onTap;

  const ProductSuggestionTile({
    super.key,
    required this.product,
    required this.isHighlighted,
    required this.onTap,
  });

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Services':
        return const Color(0xFF6D28D9); // Purple
      case 'Hardware':
        return const Color(0xFF3B82F6); // Blue
      case 'Software':
        return const Color(0xFF10B981); // Green
      case 'Consulting':
        return const Color(0xFFF59E0B); // Orange
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    return InkWell(
      onTap: onTap,
      child: Container(
        color: isHighlighted
            ? theme.colorScheme.primaryContainer.withValues(alpha: isDark ? 0.3 : 0.6)
            : null,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      Text(
                        product.sku,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                      Text(
                        '•',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.grey[700] : Colors.grey[300],
                        ),
                      ),
                      Text(
                        'Stock: ${product.stock}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                          color: product.stock < 10
                              ? AppColors.error
                              : (isDark ? Colors.grey[400] : Colors.grey[600]),
                          fontWeight: product.stock < 10 ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      Text(
                        '•',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.grey[700] : Colors.grey[300],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getCategoryColor(product.category).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          product.category,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: _getCategoryColor(product.category),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              currencyFormat.format(product.sellingPrice),
              style: theme.textTheme.titleMedium?.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
