import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../models/vendor.dart';
import '../providers/vendor_provider.dart';

const Object _vendorSearchGroupId = 'vendor_search_group_id';

/// Vendor search field with an Overlay dropdown.
/// Linked via [CompositedTransformTarget] and [CompositedTransformFollower]
/// to ensure stable layout constraints, keyboard navigation, and responsive searching.
class VendorSearchField extends StatefulWidget {
  final ValueChanged<Vendor?> onSelected;
  final Vendor? initialSelected;
  final ValueChanged<String> onCreateNewTap;
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final InputDecoration? decoration;
  final ValueChanged<String>? onChanged;

  const VendorSearchField({
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
  State<VendorSearchField> createState() => _VendorSearchFieldState();
}

class _VendorSearchFieldState extends State<VendorSearchField> {
  late TextEditingController _controller;
  bool _isInternalController = false;
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  Timer? _debounce;
  List<Vendor> _suggestions = [];
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
      _controller.text = widget.initialSelected!.displayName.isNotEmpty
          ? widget.initialSelected!.displayName
          : widget.initialSelected!.companyName;
    }
  }

  @override
  void didUpdateWidget(covariant VendorSearchField oldWidget) {
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
        _controller.text = widget.initialSelected!.displayName.isNotEmpty
            ? widget.initialSelected!.displayName
            : widget.initialSelected!.companyName;
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

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      _showOverlay();
      _search(_controller.text.trim());
    } else {
      // Delay hiding overlay to allow tap events inside dropdown to register
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
          width: _fieldWidth > 0 ? _fieldWidth : 320,
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            targetAnchor: Alignment.bottomLeft,
            followerAnchor: Alignment.topLeft,
            offset: const Offset(0, 4),
            child: TapRegion(
              groupId: _vendorSearchGroupId,
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
    widget.onChanged?.call(text);

    _showOverlay();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    _updateOverlay();

    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (mounted) _search(query);
    });
  }

  Future<void> _search(String query) async {
    final cleanQuery = query.trim().toLowerCase();
    try {
      final String path = cleanQuery.isEmpty
          ? '/api/v1/vendors'
          : '/api/v1/vendors?search=${Uri.encodeComponent(query.trim())}';

      final response = await ApiService().get(path);
      if (!mounted) return;
      if (_searchQuery.trim().toLowerCase() != cleanQuery && _focusNode.hasFocus && cleanQuery.isNotEmpty) {
        return;
      }

      List<Vendor> fetchedVendors = [];
      if (response['success'] == true) {
        final rawData = response['data'] ?? response['results'];
        final List<dynamic> dataList = rawData is List
            ? rawData
            : (rawData is Map && rawData['results'] is List
                ? rawData['results'] as List<dynamic>
                : []);

        fetchedVendors = dataList
            .map((json) => Vendor.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      // If API returned empty but local provider has vendors, fallback to provider
      if (fetchedVendors.isEmpty && mounted) {
        final providerVendors = context.read<VendorProvider>().vendors;
        if (providerVendors.isNotEmpty) {
          fetchedVendors = List.from(providerVendors);
        }
      }

      // Filter by query if query is not empty
      List<Vendor> filtered = fetchedVendors;
      if (cleanQuery.isNotEmpty) {
        filtered = fetchedVendors.where((v) {
          final dName = v.displayName.toLowerCase();
          final cName = v.companyName.toLowerCase();
          final fName = v.firstName.toLowerCase();
          final lName = v.lastName.toLowerCase();
          final phone = v.primaryPhone.toLowerCase();
          final email = v.email.toLowerCase();
          final gst = v.gstNumber.toLowerCase();

          return dName.contains(cleanQuery) ||
              cName.contains(cleanQuery) ||
              fName.contains(cleanQuery) ||
              lName.contains(cleanQuery) ||
              phone.contains(cleanQuery) ||
              email.contains(cleanQuery) ||
              gst.contains(cleanQuery);
        }).toList();

        // Sort: vendors whose name starts with query appear first
        filtered.sort((a, b) {
          final aStarts = a.displayName.toLowerCase().startsWith(cleanQuery);
          final bStarts = b.displayName.toLowerCase().startsWith(cleanQuery);
          if (aStarts && !bStarts) return -1;
          if (!aStarts && bStarts) return 1;
          return a.displayName.compareTo(b.displayName);
        });
      }

      setState(() {
        _suggestions = filtered;
        _highlightedIndex = _suggestions.isNotEmpty ? 0 : -1;
        _isLoading = false;
        _errorMessage = null;
      });
      _updateOverlay();
    } catch (e) {
      if (mounted) {
        // Fallback to in-memory provider
        final providerVendors = context.read<VendorProvider>().vendors;
        final filtered = cleanQuery.isEmpty
            ? providerVendors
            : providerVendors.where((v) {
                return v.displayName.toLowerCase().contains(cleanQuery) ||
                    v.companyName.toLowerCase().contains(cleanQuery) ||
                    v.primaryPhone.toLowerCase().contains(cleanQuery) ||
                    v.gstNumber.toLowerCase().contains(cleanQuery);
              }).toList();

        setState(() {
          _suggestions = filtered;
          _highlightedIndex = _suggestions.isNotEmpty ? 0 : -1;
          _isLoading = false;
          _errorMessage = null;
        });
        _updateOverlay();
      }
    }
  }

  void _selectVendor(Vendor vendor) {
    final name = vendor.displayName.isNotEmpty ? vendor.displayName : vendor.companyName;
    _controller.text = name;
    _hideOverlay();
    _focusNode.unfocus();
    widget.onChanged?.call(name);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.onSelected(vendor);
      }
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
      _highlightedIndex = (_highlightedIndex - 1 + _suggestions.length) % _suggestions.length;
    });
    _updateOverlay();
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
      groupId: _vendorSearchGroupId,
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
                    _selectVendor(_suggestions[_highlightedIndex]);
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
                        hintText: widget.hintText ?? 'Search or select vendor...',
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
              'No vendor found',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _onCreateNew,
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Create New Vendor', style: TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
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
              final vendor = _suggestions[index];
              return VendorSuggestionTile(
                vendor: vendor,
                isHighlighted: index == _highlightedIndex,
                onTap: () => _selectVendor(vendor),
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
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.add_circle_outline_rounded,
                    color: const Color(0xFF2563EB), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _searchQuery.trim().isEmpty
                        ? 'Add a new vendor'
                        : 'Add "${_searchQuery.trim()}" as new vendor',
                    style: const TextStyle(
                      color: Color(0xFF2563EB),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
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

class VendorSuggestionTile extends StatelessWidget {
  final Vendor vendor;
  final bool isHighlighted;
  final VoidCallback onTap;

  const VendorSuggestionTile({
    super.key,
    required this.vendor,
    required this.isHighlighted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final displayName = vendor.displayName.isNotEmpty ? vendor.displayName : vendor.companyName;

    return InkWell(
      onTap: onTap,
      child: Container(
        color: isHighlighted
            ? const Color(0xFF2563EB).withValues(alpha: isDark ? 0.25 : 0.08)
            : null,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: isHighlighted
                  ? const Color(0xFF2563EB)
                  : const Color(0xFF2563EB).withValues(alpha: 0.15),
              child: Text(
                displayName.isNotEmpty ? displayName.substring(0, 1).toUpperCase() : 'V',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isHighlighted ? Colors.white : const Color(0xFF2563EB),
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
                      const Icon(Icons.business_rounded, size: 15, color: Colors.grey),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          displayName,
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
                  if (vendor.companyName.isNotEmpty && vendor.companyName != displayName) ...[
                    const SizedBox(height: 2),
                    Text(
                      vendor.companyName,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (vendor.primaryPhone.isNotEmpty || vendor.gstNumber.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      vendor.primaryPhone.isNotEmpty
                          ? '📞 ${vendor.primaryPhone}'
                          : 'GSTIN: ${vendor.gstNumber}',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
