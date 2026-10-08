import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../customers/models/customer.dart';

const Object _customerSearchGroupId = 'customer_search_group_id';

/// Customer search field with a robust, non-intrusive Overlay dropdown.
/// Uses a custom overlay implementation linked via [CompositedTransformTarget]
/// and [CompositedTransformFollower] to ensure stable layout constraints,
/// clean overlay lifecycle management, and a crash-free experience on web and desktop.
class CustomerSearchField extends StatefulWidget {
  final ValueChanged<Customer?> onSelected;
  final Customer? initialSelected;
  final ValueChanged<String> onCreateNewTap;
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final InputDecoration? decoration;
  final ValueChanged<String>? onChanged;

  const CustomerSearchField({
    super.key,
    required this.onSelected,
    required this.initialSelected,
    required this.onCreateNewTap,
    this.controller,
    this.labelText,
    this.hintText,
    this.decoration,
    this.onChanged,
  });

  @override
  State<CustomerSearchField> createState() => _CustomerSearchFieldState();
}

class _CustomerSearchFieldState extends State<CustomerSearchField> {
  late TextEditingController _controller;
  bool _isInternalController = false;
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  Timer? _debounce;
  List<Customer> _suggestions = [];
  bool _isLoading = false;
  String? _errorMessage;
  int _highlightedIndex = -1;
  String _searchQuery = '';
  double _fieldWidth = 0.0;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _controller = TextEditingController();
      _isInternalController = true;
    }
    _focusNode.addListener(_onFocusChange);
    if (widget.initialSelected != null) {
      _controller.text = widget.initialSelected!.name;
    }
  }

  @override
  void didUpdateWidget(covariant CustomerSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      if (oldWidget.controller == null && _isInternalController) {
        _controller.dispose();
      }
      if (widget.controller != null) {
        _controller = widget.controller!;
        _isInternalController = false;
      } else {
        _controller = TextEditingController();
        _isInternalController = true;
      }
    }
    if (widget.initialSelected != oldWidget.initialSelected) {
      if (widget.initialSelected != null) {
        _controller.text = widget.initialSelected!.name;
      } else if (oldWidget.initialSelected != null) {
        _controller.clear();
      }
    }
  }

  @override
  void dispose() {
    _hideOverlay();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    if (_isInternalController) {
      _controller.dispose();
    }
    _debounce?.cancel();
    super.dispose();
  }

  // NOTE: Do NOT override setState to call _updateOverlay here.
  // Calling markNeedsBuild() inside a setState (which may run during layout)
  // is what triggers the mouse_tracker 'render box with no size' crash.
  // Instead, call _updateOverlay() explicitly only where needed after layout.

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      if (_controller.text.trim().length >= 2) {
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

        // IMPORTANT: Include `left: 0` so the Positioned is never a zero-size
        // box floating at (0,0) in the overlay Stack. Without it, the render box
        // has no height before CompositedTransformFollower resolves, causing the
        // mouse_tracker 'Cannot hit test a render box with no size' assertion.
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
              groupId: _customerSearchGroupId,
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
    // Defer to post-frame so markNeedsBuild is never called during
    // an active layout/paint phase (which causes the mouse_tracker crash).
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
    widget.onChanged?.call(text);

    if (query.length < 2) {
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
    _updateOverlay(); // refresh loading spinner in the dropdown

    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) _search(query);
    });
  }

  Future<void> _search(String query) async {
    final cleanQuery = query.trim().toLowerCase();
    if (cleanQuery.length < 2) return;
    try {
      final String path = '/api/v1/customers?search=${Uri.encodeComponent(query.trim())}';
      final response = await ApiService().get(path);
      if (!mounted) return;
      if (_searchQuery.trim().toLowerCase() != cleanQuery) return;

      if (response['success'] == true) {
        final data = response['data'];
        final List<dynamic> dataList = data is List
            ? data
            : (data is Map && data['results'] is List
                ? data['results'] as List<dynamic>
                : []);

        final fetchedCustomers = dataList
            .map((json) => Customer.fromJson(json as Map<String, dynamic>))
            .toList();

        // Strictly filter to ensure that only customers actually containing the
        // search term in their name, company, phone, email, or GSTIN are shown.
        // This avoids backend wildcard matching on customer_type or returning all records.
        final filtered = fetchedCustomers.where((c) {
          final name = c.name.toLowerCase();
          final company = c.company.toLowerCase();
          final phone = c.phone.toLowerCase();
          final email = c.email.toLowerCase();
          final gst = c.gstNo.toLowerCase();

          return name.contains(cleanQuery) ||
              company.contains(cleanQuery) ||
              phone.contains(cleanQuery) ||
              email.contains(cleanQuery) ||
              gst.contains(cleanQuery);
        }).toList();

        // Sort: customers whose name starts with the query appear first
        filtered.sort((a, b) {
          final aStartsWith = a.name.toLowerCase().startsWith(cleanQuery);
          final bStartsWith = b.name.toLowerCase().startsWith(cleanQuery);
          if (aStartsWith && !bStartsWith) return -1;
          if (!aStartsWith && bStartsWith) return 1;
          return a.name.compareTo(b.name);
        });

        setState(() {
          _suggestions = filtered;
          _highlightedIndex = _suggestions.isNotEmpty ? 0 : -1;
          _isLoading = false;
        });
        _updateOverlay(); // show results in dropdown
      } else {
        setState(() {
          _errorMessage = response['message'] ?? 'Search failed';
          _isLoading = false;
        });
        _updateOverlay(); // show error in dropdown
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Connection error';
          _isLoading = false;
        });
        _updateOverlay(); // show error in dropdown
      }
    }
  }

  void _selectCustomer(Customer customer) {
    _controller.text = customer.name;
    _hideOverlay();
    _focusNode.unfocus();
    widget.onChanged?.call(customer.name);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.onSelected(customer);
      }
    });
  }

  void _moveSelectionDown() {
    if (_suggestions.isEmpty || !mounted) return;
    setState(() {
      _highlightedIndex = (_highlightedIndex + 1) % _suggestions.length;
    });
    _updateOverlay(); // refresh highlight in dropdown
  }

  void _moveSelectionUp() {
    if (_suggestions.isEmpty || !mounted) return;
    setState(() {
      _highlightedIndex =
          (_highlightedIndex - 1 + _suggestions.length) % _suggestions.length;
    });
    _updateOverlay(); // refresh highlight in dropdown
  }

  void _onCreateNew() {
    final query = _searchQuery.trim();
    _hideOverlay();
    _focusNode.unfocus();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.onCreateNewTap(query);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return TapRegion(
      groupId: _customerSearchGroupId,
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
                    _selectCustomer(_suggestions[_highlightedIndex]);
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
                decoration: widget.decoration != null
                    ? widget.decoration!.copyWith(
                        suffixIcon: _controller.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                onPressed: () {
                                  _controller.clear();
                                  _hideOverlay();
                                  _focusNode.unfocus();
                                  widget.onChanged?.call('');
                                  WidgetsBinding.instance.addPostFrameCallback((_) {
                                    if (mounted) {
                                      widget.onSelected(null);
                                    }
                                  });
                                  setState(() {
                                    _suggestions = [];
                                    _highlightedIndex = -1;
                                    _searchQuery = '';
                                  });
                                },
                              )
                            : null,
                      )
                    : InputDecoration(
                        labelText: widget.labelText,
                        hintText: widget.hintText ?? 'Customer Name',
                        prefixIcon: const Icon(Icons.person_search_rounded),
                        suffixIcon: _controller.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                onPressed: () {
                                  _controller.clear();
                                  _hideOverlay();
                                  _focusNode.unfocus();
                                  widget.onChanged?.call('');
                                  WidgetsBinding.instance.addPostFrameCallback((_) {
                                    if (mounted) {
                                      widget.onSelected(null);
                                    }
                                  });
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
            const Icon(Icons.error_outline_rounded,
                color: AppColors.error, size: 24),
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
              'No customer found',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _onCreateNew,
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Create New Customer',
                  style: TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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

    // We have actual options!
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
              final customer = _suggestions[index];
              return CustomerSuggestionTile(
                customer: customer,
                isHighlighted: index == _highlightedIndex,
                onTap: () => _selectCustomer(customer),
              );
            },
          ),
        ),
        Divider(
          height: 1,
          color: isDark ? Colors.grey[850] : Colors.grey[200],
        ),
        InkWell(
          onTap: _onCreateNew,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.add_circle_outline_rounded,
                    color: theme.colorScheme.primary, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _searchQuery.trim().isEmpty
                        ? 'Add a new customer'
                        : 'Add "${_searchQuery.trim()}" as new customer',
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

// ─────────────────────────────────────────────────────────────────────────────
// Individual suggestion tile
// ─────────────────────────────────────────────────────────────────────────────
class CustomerSuggestionTile extends StatelessWidget {
  final Customer customer;
  final bool isHighlighted;
  final VoidCallback onTap;

  const CustomerSuggestionTile({
    super.key,
    required this.customer,
    required this.isHighlighted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      child: Container(
        color: isHighlighted
            ? theme.colorScheme.primaryContainer
                .withValues(alpha: isDark ? 0.3 : 0.6)
            : null,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: isHighlighted
                  ? theme.colorScheme.primary
                  : theme.colorScheme.primaryContainer,
              child: Text(
                customer.name.isNotEmpty
                    ? customer.name.substring(0, 1).toUpperCase()
                    : (customer.company.isNotEmpty ? customer.company.substring(0, 1).toUpperCase() : 'C'),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isHighlighted
                      ? Colors.white
                      : theme.colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.person_outline_rounded,
                          size: 15, color: Colors.grey),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          customer.name.isNotEmpty ? customer.name : customer.company,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (customer.phone.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.phone_outlined,
                            size: 13, color: Colors.grey),
                        const SizedBox(width: 6),
                        Text(
                          customer.phone,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Selected customer details card (shown after selection)
// ─────────────────────────────────────────────────────────────────────────────
class CustomerDetailsCard extends StatelessWidget {
  final Customer customer;
  final VoidCallback onClear;

  const CustomerDetailsCard({
    super.key,
    required this.customer,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: 0,
      color: isDark ? theme.colorScheme.surface : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'CUSTOMER DETAILS',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                    letterSpacing: 0.5,
                    color: theme.colorScheme.primary,
                  ),
                ),
                TextButton.icon(
                  onPressed: onClear,
                  icon: const Icon(Icons.clear_rounded, size: 14),
                  label: const Text('Change Client'),
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    textStyle: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 500;
                if (isWide) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                              child: _field(context, 'Client Name',
                                  customer.name)),
                          const SizedBox(width: 16),
                          Expanded(
                              child: _field(
                                  context,
                                  'Business Name',
                                  customer.company.isNotEmpty
                                      ? customer.company
                                      : '-')),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                              child: _field(
                                  context,
                                  'Phone Number',
                                  customer.phone.isNotEmpty
                                      ? customer.phone
                                      : '-')),
                          const SizedBox(width: 16),
                          const Expanded(child: SizedBox()),
                        ],
                      ),
                    ],
                  );
                } else {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _field(context, 'Client Name', customer.name),
                      const SizedBox(height: 12),
                      _field(
                          context,
                          'Business Name',
                          customer.company.isNotEmpty
                              ? customer.company
                              : '-'),
                      const SizedBox(height: 12),
                      _field(
                          context,
                          'Phone Number',
                          customer.phone.isNotEmpty ? customer.phone : '-'),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[900] : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : const Color(0xFFE5E7EB),
              width: 1,
            ),
          ),
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark ? Colors.white70 : AppColors.lightTextPrimary,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}
