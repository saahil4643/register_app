import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/gst_service.dart';
import '../models/vendor.dart';
import '../providers/vendor_provider.dart';
import '../../../modules/expenses/providers/expense_provider.dart';

class NewVendorScreen extends StatefulWidget {
  final String? initialName;
  final Vendor? vendorToEdit;
  final ValueChanged<Vendor>? onVendorCreated;

  const NewVendorScreen({
    super.key,
    this.initialName,
    this.vendorToEdit,
    this.onVendorCreated,
  });

  @override
  State<NewVendorScreen> createState() => _NewVendorScreenState();
}

class _NewVendorScreenState extends State<NewVendorScreen> {
  final _formKey = GlobalKey<FormState>();

  bool get isEditing => widget.vendorToEdit != null;

  // Active Tab Index: 0: Address, 1: Contact Persons, 2: Custom Fields, 3: Reporting Tags, 4: Remarks
  int _selectedTabIndex = 0;
  bool _isFetchingGst = false;

  // Primary Contact
  String _salutation = 'Mr.';
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;

  // Basic Details
  late final TextEditingController _companyNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _gstinController;

  // Billing Address
  late final TextEditingController _billingStreetController;
  late final TextEditingController _billingCityController;
  String _selectedBillingState = 'Maharashtra';
  late final TextEditingController _billingPincodeController;

  // Shipping Address
  late final TextEditingController _shippingStreetController;
  late final TextEditingController _shippingCityController;
  String _selectedShippingState = 'Maharashtra';
  late final TextEditingController _shippingPincodeController;

  // Custom Fields / Tax & Financials
  late final TextEditingController _panController;
  String _taxPreference = 'Taxable';
  String _currency = 'INR';
  String _paymentTerms = 'Net 30';
  late final TextEditingController _websiteController;

  // Reporting Tags & Remarks
  late final TextEditingController _reportingTagsController;
  late final TextEditingController _remarksController;

  // Contact Persons List
  List<VendorContactPerson> _contactPersons = [];

  static const List<String> _salutations = ['Mr.', 'Mrs.', 'Ms.', 'Miss', 'Dr.'];

  static const List<String> _indianStates = [
    'Andaman & Nicobar Islands',
    'Andhra Pradesh',
    'Arunachal Pradesh',
    'Assam',
    'Bihar',
    'Chandigarh',
    'Chhattisgarh',
    'Dadra & Nagar Haveli and Daman & Diu',
    'Delhi',
    'Goa',
    'Gujarat',
    'Haryana',
    'Himachal Pradesh',
    'Jammu & Kashmir',
    'Jharkhand',
    'Karnataka',
    'Kerala',
    'Ladakh',
    'Lakshadweep',
    'Madhya Pradesh',
    'Maharashtra',
    'Manipur',
    'Meghalaya',
    'Mizoram',
    'Nagaland',
    'Odisha',
    'Puducherry',
    'Punjab',
    'Rajasthan',
    'Sikkim',
    'Tamil Nadu',
    'Telangana',
    'Tripura',
    'Uttar Pradesh',
    'Uttarakhand',
    'West Bengal',
  ];

  static const List<String> _taxPreferenceOptions = ['Taxable', 'Tax Exempt'];
  static const List<String> _currencyOptions = ['INR', 'USD', 'EUR', 'GBP', 'AED', 'SGD'];
  static const List<String> _paymentTermsOptions = [
    'Due on Receipt',
    'Net 15',
    'Net 30',
    'Net 45',
    'Net 60',
  ];

  @override
  void initState() {
    super.initState();
    final v = widget.vendorToEdit;

    _salutation = (v != null && v.salutation.isNotEmpty && _salutations.contains(v.salutation))
        ? v.salutation
        : 'Mr.';
    _firstNameController = TextEditingController(text: v?.firstName ?? '');
    _lastNameController = TextEditingController(text: v?.lastName ?? '');

    _companyNameController = TextEditingController(
      text: v?.companyName.isNotEmpty == true
          ? v!.companyName
          : (v?.displayName ?? widget.initialName ?? ''),
    );
    _emailController = TextEditingController(text: v?.email ?? '');
    _phoneController = TextEditingController(
      text: v != null
          ? (v.primaryPhone.isNotEmpty ? v.primaryPhone : v.phone)
          : '+91 ',
    );
    _gstinController = TextEditingController(text: v?.gstNumber ?? '');

    // Billing
    _billingStreetController = TextEditingController(text: v?.billingAddressLine1 ?? '');
    _billingCityController = TextEditingController(text: v?.billingCity ?? '');
    if (v != null && v.billingState.isNotEmpty && _indianStates.contains(v.billingState)) {
      _selectedBillingState = v.billingState;
    }
    _billingPincodeController = TextEditingController(text: v?.billingPostalCode ?? '');

    // Shipping
    _shippingStreetController = TextEditingController(text: v?.shippingAddressLine1 ?? '');
    _shippingCityController = TextEditingController(text: v?.shippingCity ?? '');
    if (v != null && v.shippingState.isNotEmpty && _indianStates.contains(v.shippingState)) {
      _selectedShippingState = v.shippingState;
    }
    _shippingPincodeController = TextEditingController(text: v?.shippingPostalCode ?? '');

    // Custom Fields
    _panController = TextEditingController(text: v?.panNumber ?? '');
    if (v != null && v.taxPreference.isNotEmpty) {
      _taxPreference = _taxPreferenceOptions.contains(v.taxPreference) ? v.taxPreference : 'Taxable';
    }
    if (v != null && v.currency.isNotEmpty) {
      _currency = _currencyOptions.contains(v.currency) ? v.currency : 'INR';
    }
    if (v != null && v.paymentTerms.isNotEmpty) {
      _paymentTerms = _paymentTermsOptions.contains(v.paymentTerms) ? v.paymentTerms : 'Net 30';
    }
    _websiteController = TextEditingController(text: v?.website ?? '');

    // Reporting Tags & Remarks
    _reportingTagsController = TextEditingController(text: v?.socialLinks ?? '');
    _remarksController = TextEditingController(text: v?.notes ?? '');

    _contactPersons = v?.contactPersons.isNotEmpty == true ? List.from(v!.contactPersons) : [];
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _companyNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _gstinController.dispose();

    _billingStreetController.dispose();
    _billingCityController.dispose();
    _billingPincodeController.dispose();

    _shippingStreetController.dispose();
    _shippingCityController.dispose();
    _shippingPincodeController.dispose();

    _panController.dispose();
    _websiteController.dispose();
    _reportingTagsController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  void _copyBillingToShipping() {
    setState(() {
      _shippingStreetController.text = _billingStreetController.text;
      _shippingCityController.text = _billingCityController.text;
      _selectedShippingState = _selectedBillingState;
      _shippingPincodeController.text = _billingPincodeController.text;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Shipping address copied from Billing address'),
        duration: Duration(milliseconds: 1500),
      ),
    );
  }

  Future<void> _handlePrefillGst({String? explicitGstin}) async {
    final gstin = (explicitGstin ?? _gstinController.text).trim().toUpperCase();
    if (gstin.isEmpty) {
      _showEnterGstDialog();
      return;
    }

    if (gstin.length != 15) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('GSTIN must be 15 characters long (e.g., 27AAPFU0939F1ZV).'),
          backgroundColor: Color(0xFF2563EB),
        ),
      );
      return;
    }

    setState(() => _isFetchingGst = true);

    try {
      final info = await GstService().fetchTaxpayer(gstin);

      if (!mounted) return;

      if (info != null) {
        setState(() {
          _gstinController.text = info.gstin.isNotEmpty ? info.gstin : gstin;

          // Company Name & Trade Name
          final legal = info.legalName.trim();
          final trade = info.tradeName.trim();
          if (legal.isNotEmpty) {
            _companyNameController.text = legal;
          } else if (trade.isNotEmpty) {
            _companyNameController.text = trade;
          }

          // PAN Number
          if (info.pan.isNotEmpty) {
            _panController.text = info.pan;
          } else if (gstin.length >= 12) {
            _panController.text = gstin.substring(2, 12);
          }

          // Address
          if (info.address.isNotEmpty) {
            _billingStreetController.text = info.address;
            _shippingStreetController.text = info.address;

            // Extract 6-digit Pincode from address string
            final pinMatch = RegExp(r'\b\d{6}\b').firstMatch(info.address);
            if (pinMatch != null) {
              _billingPincodeController.text = pinMatch.group(0)!;
              _shippingPincodeController.text = pinMatch.group(0)!;
            }

            // Extract City from address tokens
            final parts = info.address.split(',');
            if (parts.length >= 2) {
              for (final part in parts.reversed) {
                final trimmed = part.trim();
                if (trimmed.isNotEmpty &&
                    !RegExp(r'^\d+$').hasMatch(trimmed) &&
                    !_indianStates.any((s) => s.toLowerCase() == trimmed.toLowerCase())) {
                  _billingCityController.text = trimmed;
                  _shippingCityController.text = trimmed;
                  break;
                }
              }
            }
          }

          // State from stateCode or GSTIN prefix
          if (info.stateCode.isNotEmpty) {
            final stateName = GstService.getStateFromCode(info.stateCode);
            if (stateName.isNotEmpty && _indianStates.contains(stateName)) {
              _selectedBillingState = stateName;
              _selectedShippingState = stateName;
            }
          } else if (gstin.length >= 2) {
            final stateCode = gstin.substring(0, 2);
            final stateName = GstService.getStateFromCode(stateCode);
            if (stateName.isNotEmpty && _indianStates.contains(stateName)) {
              _selectedBillingState = stateName;
              _selectedShippingState = stateName;
            }
          }

          // Tax Preference
          if (info.taxpayerType.isNotEmpty) {
            _taxPreference = 'Taxable';
          }

          // Add metadata to remarks if available
          if (info.constitutionOfBusiness.isNotEmpty && _remarksController.text.isEmpty) {
            _remarksController.text =
                'Constitution: ${info.constitutionOfBusiness}${info.status.isNotEmpty ? ' | Status: ${info.status}' : ''}';
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Prefilled details for "${info.tradeName.isNotEmpty ? info.tradeName : info.legalName}" from GST portal!',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        // Fallback: parse state & PAN from GSTIN format
        _applyLocalGstinFallback(gstin);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('GST lookup: Extracted State & PAN locally from GSTIN format.'),
            backgroundColor: Color(0xFF2563EB),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _applyLocalGstinFallback(gstin);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('GST lookup: Extracted State & PAN locally ($e)'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isFetchingGst = false);
      }
    }
  }

  void _showEnterGstDialog() {
    final dialogController = TextEditingController(text: _gstinController.text);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Row(
          children: [
            Icon(Icons.auto_fix_high_rounded, color: Color(0xFF2563EB), size: 20),
            SizedBox(width: 8),
            Text('Prefill from GSTIN', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter the 15-digit GSTIN to auto-fetch taxpayer legal name, trade name, PAN, state, and registered address.',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: dialogController,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                hintText: 'e.g. 27AAPFU0939F1ZV',
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            onPressed: () {
              final entered = dialogController.text.trim();
              Navigator.pop(ctx);
              if (entered.isNotEmpty) {
                _gstinController.text = entered.toUpperCase();
                _handlePrefillGst(explicitGstin: entered);
              }
            },
            child: const Text('Fetch Details'),
          ),
        ],
      ),
    );
  }

  void _applyLocalGstinFallback(String gstin) {
    setState(() {
      _gstinController.text = gstin;
      if (gstin.length >= 2) {
        final code = gstin.substring(0, 2);
        final state = GstService.getStateFromCode(code);
        if (state.isNotEmpty && _indianStates.contains(state)) {
          _selectedBillingState = state;
          _selectedShippingState = state;
        }
      }
      if (gstin.length >= 12) {
        _panController.text = gstin.substring(2, 12);
      }
    });
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final company = _companyNameController.text.trim();
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final fullName = '$firstName $lastName'.trim();

    // Determine Display Name (strictly required by API)
    String displayName = company;
    if (displayName.isEmpty) {
      displayName = fullName;
    }
    if (displayName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter Company Name or Contact Name.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final rawPhone = _phoneController.text.trim();
    final cleanPhone = rawPhone.replaceAll('+91', '').trim();

    final newVendor = Vendor(
      id: isEditing ? widget.vendorToEdit!.id : '',
      organization: widget.vendorToEdit?.organization,
      displayName: displayName,
      companyName: company.isNotEmpty ? company : displayName,
      salutation: _salutation,
      firstName: firstName,
      lastName: lastName,
      email: _emailController.text.trim(),
      primaryPhone: cleanPhone.isNotEmpty ? cleanPhone : rawPhone,
      secondaryPhone: '',
      website: _websiteController.text.trim(),
      gstNumber: _gstinController.text.trim().toUpperCase(),
      panNumber: _panController.text.trim().toUpperCase(),
      taxPreference: _taxPreference,
      currency: _currency,
      paymentTerms: _paymentTerms,
      notes: _remarksController.text.trim(),
      billingAttention: fullName,
      billingAddressLine1: _billingStreetController.text.trim(),
      billingCity: _billingCityController.text.trim(),
      billingState: _selectedBillingState,
      billingPostalCode: _billingPincodeController.text.trim(),
      billingCountry: 'India',
      shippingSameAsBilling: _shippingStreetController.text.trim().isEmpty ||
          _shippingStreetController.text.trim() == _billingStreetController.text.trim(),
      shippingAttention: fullName,
      shippingAddressLine1: _shippingStreetController.text.trim().isNotEmpty
          ? _shippingStreetController.text.trim()
          : _billingStreetController.text.trim(),
      shippingCity: _shippingCityController.text.trim().isNotEmpty
          ? _shippingCityController.text.trim()
          : _billingCityController.text.trim(),
      shippingState: _shippingStreetController.text.trim().isNotEmpty
          ? _selectedShippingState
          : _selectedBillingState,
      shippingPostalCode: _shippingPincodeController.text.trim().isNotEmpty
          ? _shippingPincodeController.text.trim()
          : _billingPincodeController.text.trim(),
      shippingCountry: 'India',
      socialLinks: _reportingTagsController.text.trim(),
      contactPersons: _contactPersons,
      createdAt: isEditing ? widget.vendorToEdit!.createdAt : DateTime.now(),
      updatedAt: isEditing ? DateTime.now() : null,
    );

    final provider = context.read<VendorProvider>();
    Vendor? saved;
    if (isEditing) {
      saved = await provider.updateVendor(widget.vendorToEdit!.id, newVendor);
    } else {
      saved = await provider.createVendor(newVendor);
    }

    if (!mounted) return;

    if (saved != null) {
      final expProvider = context.read<ExpenseProvider>();
      if (!expProvider.vendors.contains(saved.displayName)) {
        expProvider.vendors.add(saved.displayName);
      }

      widget.onVendorCreated?.call(saved);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEditing
                ? 'Vendor "${saved.displayName}" updated successfully!'
                : 'Vendor "${saved.displayName}" created successfully!',
          ),
          backgroundColor: AppColors.success,
        ),
      );

      Navigator.pop(context, saved);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? (isEditing ? 'Failed to update vendor' : 'Failed to save vendor')),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded, color: Color(0xFF334155)),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          isEditing ? 'Edit Vendor' : 'New Vendor',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            height: 1.0,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top GST Prefill Banner matching reference image
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1E293B).withValues(alpha: 0.8)
                            : const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isDark ? const Color(0xFF3B82F6).withValues(alpha: 0.3) : const Color(0xFFBFDBFE),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded, color: Color(0xFF2563EB), size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Prefill Vendor details from the GST portal using the Vendor's GSTIN.",
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? Colors.blue[200] : const Color(0xFF1E40AF),
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: _handlePrefillGst,
                            borderRadius: BorderRadius.circular(4),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              child: Text(
                                'Prefill ›',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2563EB),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),

                    // 1. Primary Contact Row [Mr. v] [First Name] [Last Name]
                    _buildAlignedRow(
                      label: 'Primary Contact',
                      isDark: isDark,
                      child: Row(
                        children: [
                          Container(
                            width: 95,
                            height: 40,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                                width: 1,
                              ),
                              color: isDark ? const Color(0xFF0F172A) : Colors.white,
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: _salutations.contains(_salutation) ? _salutation : _salutations.first,
                                icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xFF64748B)),
                                items: _salutations.map((s) {
                                  return DropdownMenuItem(
                                    value: s,
                                    child: Text(s, style: const TextStyle(fontSize: 13)),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _salutation = val);
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildInput(
                              controller: _firstNameController,
                              hint: 'First Name',
                              isDark: isDark,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildInput(
                              controller: _lastNameController,
                              hint: 'Last Name',
                              isDark: isDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 2. Company Name Row
                    _buildAlignedRow(
                      label: 'Company Name',
                      isDark: isDark,
                      child: _buildInput(
                        controller: _companyNameController,
                        hint: '',
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 3. Email Address Row
                    _buildAlignedRow(
                      label: 'Email Address',
                      isDark: isDark,
                      child: _buildInput(
                        controller: _emailController,
                        hint: '',
                        prefixIcon: const Icon(Icons.mail_outline_rounded, size: 17, color: Color(0xFF94A3B8)),
                        keyboardType: TextInputType.emailAddress,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 4. Phone Row
                    _buildAlignedRow(
                      label: 'Phone',
                      isDark: isDark,
                      child: _buildInput(
                        controller: _phoneController,
                        hint: '+91',
                        keyboardType: TextInputType.phone,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 5. GSTIN Row
                    _buildAlignedRow(
                      label: 'GSTIN',
                      isDark: isDark,
                      child: _buildInput(
                        controller: _gstinController,
                        hint: 'e.g. 27AAAAA1111A1Z1',
                        textCapitalization: TextCapitalization.characters,
                        isDark: isDark,
                        onFieldSubmitted: (val) => _handlePrefillGst(explicitGstin: val),
                        suffixIcon: _isFetchingGst
                            ? const Padding(
                                padding: EdgeInsets.all(10),
                                child: SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2563EB)),
                                ),
                              )
                            : Tooltip(
                                message: 'Fetch details from GST portal',
                                child: InkWell(
                                  onTap: () => _handlePrefillGst(),
                                  borderRadius: BorderRadius.circular(4),
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.auto_fix_high_rounded, size: 14, color: Color(0xFF2563EB)),
                                        SizedBox(width: 4),
                                        Text(
                                          'Prefill',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF2563EB),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // TABS Bar matching reference image
                    Container(
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                            width: 1.5,
                          ),
                        ),
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildTabItem('Address', 0, isDark),
                            _buildTabItem('Contact Persons', 1, isDark),
                            _buildTabItem('Custom Fields', 2, isDark),
                            _buildTabItem('Reporting Tags', 3, isDark),
                            _buildTabItem('Remarks', 4, isDark),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // TAB CONTENT
                    if (_selectedTabIndex == 0) ...[
                      // Address Tab
                      Text(
                        'Billing Address',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 14),

                      _buildAlignedRow(
                        label: 'Street Address',
                        isDark: isDark,
                        child: _buildInput(
                          controller: _billingStreetController,
                          hint: 'e.g. 404 Main St, Bandra East',
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(height: 14),

                      _buildAlignedRow(
                        label: 'City',
                        isDark: isDark,
                        child: _buildInput(
                          controller: _billingCityController,
                          hint: 'e.g. Mumbai',
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(height: 14),

                      _buildAlignedRow(
                        label: 'State',
                        isDark: isDark,
                        child: _buildDropdown(
                          value: _selectedBillingState,
                          items: _indianStates,
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedBillingState = val);
                          },
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(height: 14),

                      _buildAlignedRow(
                        label: 'Pincode',
                        isDark: isDark,
                        child: _buildInput(
                          controller: _billingPincodeController,
                          hint: 'e.g. 400001',
                          keyboardType: TextInputType.number,
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Shipping Address Header with "Same as Billing Address" link
                      Row(
                        children: [
                          Text(
                            'Shipping Address',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(width: 14),
                          InkWell(
                            onTap: _copyBillingToShipping,
                            borderRadius: BorderRadius.circular(4),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.link_rounded, size: 16, color: Color(0xFF2563EB)),
                                  SizedBox(width: 4),
                                  Text(
                                    'Same as Billing Address',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF2563EB),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      _buildAlignedRow(
                        label: 'Street Address',
                        isDark: isDark,
                        child: _buildInput(
                          controller: _shippingStreetController,
                          hint: 'e.g. 404 Main St, Bandra East',
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(height: 14),

                      _buildAlignedRow(
                        label: 'City',
                        isDark: isDark,
                        child: _buildInput(
                          controller: _shippingCityController,
                          hint: 'e.g. Mumbai',
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(height: 14),

                      _buildAlignedRow(
                        label: 'State',
                        isDark: isDark,
                        child: _buildDropdown(
                          value: _selectedShippingState,
                          items: _indianStates,
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedShippingState = val);
                          },
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(height: 14),

                      _buildAlignedRow(
                        label: 'Pincode',
                        isDark: isDark,
                        child: _buildInput(
                          controller: _shippingPincodeController,
                          hint: 'e.g. 400001',
                          keyboardType: TextInputType.number,
                          isDark: isDark,
                        ),
                      ),
                    ] else if (_selectedTabIndex == 1) ...[
                      // Contact Persons Tab
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Additional Contact Persons',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF1E293B),
                            ),
                          ),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF2563EB),
                              side: const BorderSide(color: Color(0xFF2563EB)),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            ),
                            icon: const Icon(Icons.add_rounded, size: 16),
                            label: const Text('Add Contact Person', style: TextStyle(fontSize: 12)),
                            onPressed: () => _showAddContactPersonDialog(context, isDark),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_contactPersons.isEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          alignment: Alignment.center,
                          child: Text(
                            'No additional contact persons added.',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                            ),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _contactPersons.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (ctx, idx) {
                            final cp = _contactPersons[idx];
                            return ListTile(
                              tileColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              title: Text(cp.fullName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                              subtitle: Text('${cp.email} • ${cp.phone}', style: const TextStyle(fontSize: 12)),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                                onPressed: () {
                                  setState(() => _contactPersons.removeAt(idx));
                                },
                              ),
                            );
                          },
                        ),
                    ] else if (_selectedTabIndex == 2) ...[
                      // Custom Fields / Tax & Payment Terms
                      _buildAlignedRow(
                        label: 'PAN Number',
                        isDark: isDark,
                        child: _buildInput(
                          controller: _panController,
                          hint: 'e.g. AAPFU0939F',
                          textCapitalization: TextCapitalization.characters,
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(height: 14),

                      _buildAlignedRow(
                        label: 'Tax Preference',
                        isDark: isDark,
                        child: _buildDropdown(
                          value: _taxPreference,
                          items: _taxPreferenceOptions,
                          onChanged: (val) {
                            if (val != null) setState(() => _taxPreference = val);
                          },
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(height: 14),

                      _buildAlignedRow(
                        label: 'Currency',
                        isDark: isDark,
                        child: _buildDropdown(
                          value: _currency,
                          items: _currencyOptions,
                          onChanged: (val) {
                            if (val != null) setState(() => _currency = val);
                          },
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(height: 14),

                      _buildAlignedRow(
                        label: 'Payment Terms',
                        isDark: isDark,
                        child: _buildDropdown(
                          value: _paymentTerms,
                          items: _paymentTermsOptions,
                          onChanged: (val) {
                            if (val != null) setState(() => _paymentTerms = val);
                          },
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(height: 14),

                      _buildAlignedRow(
                        label: 'Website',
                        isDark: isDark,
                        child: _buildInput(
                          controller: _websiteController,
                          hint: 'https://www.acmesupplies.com',
                          keyboardType: TextInputType.url,
                          isDark: isDark,
                        ),
                      ),
                    ] else if (_selectedTabIndex == 3) ...[
                      // Reporting Tags
                      _buildAlignedRow(
                        label: 'Reporting Tags',
                        isDark: isDark,
                        child: _buildInput(
                          controller: _reportingTagsController,
                          hint: 'e.g. Hardware, Tier-1 Supplier, IT',
                          isDark: isDark,
                        ),
                      ),
                    ] else if (_selectedTabIndex == 4) ...[
                      // Remarks
                      _buildAlignedRow(
                        label: 'Remarks / Notes',
                        isDark: isDark,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        child: TextFormField(
                          controller: _remarksController,
                          maxLines: 4,
                          style: const TextStyle(fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'Preferred vendor for office hardware supplies...',
                            hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: BorderSide(
                                color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                                width: 1,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: BorderSide(
                                color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                                width: 1,
                              ),
                            ),
                            focusedBorder: const OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(6)),
                              borderSide: BorderSide(color: Color(0xFF2563EB), width: 1.5),
                            ),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 28),

                    // Action Buttons: Save & Cancel
                    Consumer<VendorProvider>(
                      builder: (context, vProvider, _) {
                        return LayoutBuilder(
                          builder: (context, constraints) {
                            final isNarrow = constraints.maxWidth < 540;
                            return Row(
                              children: [
                                if (!isNarrow) const SizedBox(width: 176), // Aligned with input column
                                ElevatedButton(
                                  onPressed: vProvider.isSaving ? null : _handleSave,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2563EB),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                  ),
                                  child: vProvider.isSaving
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                        )
                                      : const Text(
                                          'Save',
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                        ),
                                ),
                                const SizedBox(width: 12),
                                OutlinedButton(
                                  onPressed: vProvider.isSaving ? null : () => Navigator.pop(context),
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                                    foregroundColor: isDark ? Colors.grey[300] : const Color(0xFF334155),
                                    side: BorderSide(
                                      color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                                      width: 1,
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                  ),
                                  child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // UI Helpers: Clean, Consistent Two-Column Form Alignment
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildAlignedRow({
    required String label,
    required Widget child,
    bool isRequired = false,
    double labelWidth = 160,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center,
    required bool isDark,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 540;

        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.grey[300] : const Color(0xFF334155),
                    ),
                  ),
                  if (isRequired)
                    const Text(' *', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 6),
              child,
            ],
          );
        }

        return Row(
          crossAxisAlignment: crossAxisAlignment,
          children: [
            SizedBox(
              width: labelWidth,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.grey[300] : const Color(0xFF334155),
                      ),
                    ),
                  ),
                  if (isRequired)
                    const Text(' *', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(child: child),
          ],
        );
      },
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String hint,
    Widget? prefixIcon,
    Widget? suffixIcon,
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onFieldSubmitted,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    required bool isDark,
  }) {
    return SizedBox(
      height: 40,
      child: TextFormField(
        controller: controller,
        onChanged: onChanged,
        onFieldSubmitted: onFieldSubmitted,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
          prefixIcon: prefixIcon,
          suffixIcon: suffixIcon,
          filled: true,
          fillColor: isDark ? const Color(0xFF0F172A) : Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
              width: 1,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
              width: 1,
            ),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(6)),
            borderSide: BorderSide(color: Color(0xFF2563EB), width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required bool isDark,
  }) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
          width: 1,
        ),
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: items.contains(value) ? value : items.first,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xFF64748B)),
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(
                item,
                style: const TextStyle(fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildTabItem(String title, int index, bool isDark) {
    final isSelected = _selectedTabIndex == index;
    return InkWell(
      onTap: () => setState(() => _selectedTabIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? const Color(0xFF2563EB) : Colors.transparent,
              width: 2.5,
            ),
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected
                ? const Color(0xFF2563EB)
                : (isDark ? Colors.grey[400] : const Color(0xFF64748B)),
          ),
        ),
      ),
    );
  }

  void _showAddContactPersonDialog(BuildContext context, bool isDark) {
    final fnCtrl = TextEditingController();
    final lnCtrl = TextEditingController();
    final emCtrl = TextEditingController();
    final phCtrl = TextEditingController();
    String sal = 'Mr.';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Contact Person', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButton<String>(
              isExpanded: true,
              value: sal,
              items: _salutations.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (v) {
                if (v != null) sal = v;
              },
            ),
            const SizedBox(height: 8),
            TextField(controller: fnCtrl, decoration: const InputDecoration(labelText: 'First Name')),
            const SizedBox(height: 8),
            TextField(controller: lnCtrl, decoration: const InputDecoration(labelText: 'Last Name')),
            const SizedBox(height: 8),
            TextField(controller: emCtrl, decoration: const InputDecoration(labelText: 'Email')),
            const SizedBox(height: 8),
            TextField(controller: phCtrl, decoration: const InputDecoration(labelText: 'Phone')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (fnCtrl.text.trim().isNotEmpty) {
                setState(() {
                  _contactPersons.add(
                    VendorContactPerson(
                      salutation: sal,
                      firstName: fnCtrl.text.trim(),
                      lastName: lnCtrl.text.trim(),
                      email: emCtrl.text.trim(),
                      phone: phCtrl.text.trim(),
                    ),
                  );
                });
              }
              Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
