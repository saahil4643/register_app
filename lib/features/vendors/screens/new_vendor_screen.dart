import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../models/vendor.dart';
import '../providers/vendor_provider.dart';
import '../../../modules/expenses/providers/expense_provider.dart';

class NewVendorScreen extends StatefulWidget {
  final String? initialName;
  final ValueChanged<Vendor>? onVendorCreated;

  const NewVendorScreen({
    super.key,
    this.initialName,
    this.onVendorCreated,
  });

  @override
  State<NewVendorScreen> createState() => _NewVendorScreenState();
}

class _NewVendorScreenState extends State<NewVendorScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _companyNameController;
  late final TextEditingController _mobileController;
  late final TextEditingController _gstinController;

  // Billing Address fields
  late final TextEditingController _billingAddressController;
  String _selectedBillingState = 'Maharashtra';
  late final TextEditingController _billingPincodeController;
  late final TextEditingController _billingCityController;

  // Shipping Address fields
  bool _shippingSameAsBilling = true;
  late final TextEditingController _shippingAddressController;
  String _selectedShippingState = 'Maharashtra';
  late final TextEditingController _shippingPincodeController;
  late final TextEditingController _shippingCityController;

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

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _emailController = TextEditingController();
    _companyNameController = TextEditingController();
    _mobileController = TextEditingController(text: '+91-');
    _gstinController = TextEditingController();

    _billingAddressController = TextEditingController();
    _billingPincodeController = TextEditingController();
    _billingCityController = TextEditingController();

    _shippingAddressController = TextEditingController();
    _shippingPincodeController = TextEditingController();
    _shippingCityController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _companyNameController.dispose();
    _mobileController.dispose();
    _gstinController.dispose();

    _billingAddressController.dispose();
    _billingPincodeController.dispose();
    _billingCityController.dispose();

    _shippingAddressController.dispose();
    _shippingPincodeController.dispose();
    _shippingCityController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter vendor Name.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final newVendor = Vendor(
      id: '',
      displayName: name,
      companyName: _companyNameController.text.trim(),
      email: _emailController.text.trim(),
      mobile: _mobileController.text.trim(),
      gstin: _gstinController.text.trim().toUpperCase(),
      billingAddressLine1: _billingAddressController.text.trim(),
      billingState: _selectedBillingState,
      billingPostalCode: _billingPincodeController.text.trim(),
      billingCity: _billingCityController.text.trim(),
      billingCountry: 'India',
      shippingSameAsBilling: _shippingSameAsBilling,
      shippingAddressLine1: _shippingSameAsBilling
          ? _billingAddressController.text.trim()
          : _shippingAddressController.text.trim(),
      shippingState: _shippingSameAsBilling ? _selectedBillingState : _selectedShippingState,
      shippingPostalCode: _shippingSameAsBilling
          ? _billingPincodeController.text.trim()
          : _shippingPincodeController.text.trim(),
      shippingCity: _shippingSameAsBilling
          ? _billingCityController.text.trim()
          : _shippingCityController.text.trim(),
      shippingCountry: 'India',
      createdAt: DateTime.now(),
    );

    final provider = context.read<VendorProvider>();
    final saved = await provider.createVendor(newVendor);

    if (!mounted) return;

    if (saved != null) {
      final expProvider = context.read<ExpenseProvider>();
      if (!expProvider.vendors.contains(saved.displayName)) {
        expProvider.vendors.add(saved.displayName);
      }

      if (widget.onVendorCreated != null) {
        widget.onVendorCreated!(saved);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Vendor "${saved.displayName}" saved successfully!'),
          backgroundColor: AppColors.success,
        ),
      );

      Navigator.pop(context, saved);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Failed to save vendor'),
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
      backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: isDark ? theme.colorScheme.surface : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'New Vendor',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
            height: 1.0,
          ),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 580),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? theme.colorScheme.surface : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header: Add New Vendor + [X] Close button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Add New Vendor',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF1E293B),
                          ),
                        ),
                        InkWell(
                          onTap: () => Navigator.pop(context),
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isDark ? AppColors.darkBorder : const Color(0xFFCBD5E1),
                                width: 1,
                              ),
                            ),
                            child: Icon(
                              Icons.close_rounded,
                              size: 16,
                              color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Field 1: Name (Highlighted top box from reference image)
                    TextFormField(
                      controller: _nameController,
                      validator: (val) => (val == null || val.trim().isEmpty) ? 'Name is required' : null,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Name',
                        hintStyle: TextStyle(
                          color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFEEF2FF),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: BorderSide(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFC7D2FE),
                            width: 1,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: BorderSide(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFC7D2FE),
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: const BorderSide(color: Color(0xFF6D28D9), width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Row 2: Email Address | Company Name
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel('Email Address', isDark),
                              const SizedBox(height: 6),
                              _buildOutlineInput(
                                controller: _emailController,
                                hint: 'ex. vendor@gmail.com',
                                keyboardType: TextInputType.emailAddress,
                                isDark: isDark,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel('Company Name', isDark),
                              const SizedBox(height: 6),
                              _buildOutlineInput(
                                controller: _companyNameController,
                                hint: 'ex. Acme Technologies',
                                isDark: isDark,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Row 3: Mobile Number | GSTIN
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel('Mobile Number', isDark),
                              const SizedBox(height: 6),
                              _buildOutlineInput(
                                controller: _mobileController,
                                hint: '+91-',
                                keyboardType: TextInputType.phone,
                                isDark: isDark,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel('GSTIN', isDark),
                              const SizedBox(height: 6),
                              _buildOutlineInput(
                                controller: _gstinController,
                                hint: 'ex. 27AAAAA0000A1Z5',
                                textCapitalization: TextCapitalization.characters,
                                isDark: isDark,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Row 4: BILLING ADDRESS *
                    _buildFieldLabel('BILLING ADDRESS *', isDark, isRequired: true),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _billingAddressController,
                      maxLines: 3,
                      validator: (val) => (val == null || val.trim().isEmpty) ? 'Billing address is required' : null,
                      style: const TextStyle(fontSize: 13),
                      decoration: _inputDecoration(
                        hint: 'ex. 123 Main Street, Industrial Area',
                        isDark: isDark,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Row 5: STATE | PINCODE
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel('STATE', isDark),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                                    width: 1,
                                  ),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    isExpanded: true,
                                    value: _indianStates.contains(_selectedBillingState)
                                        ? _selectedBillingState
                                        : _indianStates.first,
                                    icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: Color(0xFF64748B)),
                                    items: _indianStates.map((st) {
                                      return DropdownMenuItem(
                                        value: st,
                                        child: Text(
                                          st,
                                          style: const TextStyle(fontSize: 13),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      if (val != null) setState(() => _selectedBillingState = val);
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel('PINCODE', isDark),
                              const SizedBox(height: 6),
                              _buildOutlineInput(
                                controller: _billingPincodeController,
                                hint: 'ex. 400001',
                                keyboardType: TextInputType.number,
                                isDark: isDark,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Row 6: CITY
                    _buildFieldLabel('CITY', isDark),
                    const SizedBox(height: 6),
                    _buildOutlineInput(
                      controller: _billingCityController,
                      hint: 'ex. Mumbai',
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),

                    // Row 7: Checkbox: Shipping address same as billing address
                    Row(
                      children: [
                        Checkbox(
                          value: _shippingSameAsBilling,
                          activeColor: const Color(0xFF1E293B),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          onChanged: (val) {
                            setState(() => _shippingSameAsBilling = val ?? true);
                          },
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () {
                            setState(() => _shippingSameAsBilling = !_shippingSameAsBilling);
                          },
                          child: Text(
                            'Shipping address same as billing address',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.grey[300] : const Color(0xFF334155),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Separate Shipping Address Form if unchecked
                    if (!_shippingSameAsBilling) ...[
                      const SizedBox(height: 12),
                      _buildFieldLabel('SHIPPING ADDRESS *', isDark, isRequired: true),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _shippingAddressController,
                        maxLines: 3,
                        style: const TextStyle(fontSize: 13),
                        decoration: _inputDecoration(
                          hint: 'ex. 456 Warehouse Blvd, Logistics Park',
                          isDark: isDark,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel('STATE', isDark),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                                      width: 1,
                                    ),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      isExpanded: true,
                                      value: _indianStates.contains(_selectedShippingState)
                                          ? _selectedShippingState
                                          : _indianStates.first,
                                      icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: Color(0xFF64748B)),
                                      items: _indianStates.map((st) {
                                        return DropdownMenuItem(
                                          value: st,
                                          child: Text(
                                            st,
                                            style: const TextStyle(fontSize: 13),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (val) {
                                        if (val != null) setState(() => _selectedShippingState = val);
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel('PINCODE', isDark),
                                const SizedBox(height: 6),
                                _buildOutlineInput(
                                  controller: _shippingPincodeController,
                                  hint: 'ex. 400001',
                                  keyboardType: TextInputType.number,
                                  isDark: isDark,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _buildFieldLabel('CITY', isDark),
                      const SizedBox(height: 6),
                      _buildOutlineInput(
                        controller: _shippingCityController,
                        hint: 'ex. Mumbai',
                        isDark: isDark,
                      ),
                    ],

                    const SizedBox(height: 22),

                    // Row 8: Action Buttons (Cancel & Save)
                    Consumer<VendorProvider>(
                      builder: (context, vProvider, _) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton(
                              onPressed: vProvider.isSaving ? null : () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: isDark ? Colors.grey[300] : const Color(0xFF334155),
                                side: BorderSide(
                                  color: isDark ? AppColors.darkBorder : const Color(0xFFCBD5E1),
                                  width: 1,
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              ),
                              child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: vProvider.isSaving ? null : _handleSave,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6D28D9),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
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
                          ],
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
  // UI Helpers
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildFieldLabel(String label, bool isDark, {bool isRequired = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label.replaceAll('*', '').trim(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.grey[300] : const Color(0xFF475569),
          ),
        ),
        if (isRequired)
          const Text(
            ' *',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFFEF4444),
            ),
          ),
      ],
    );
  }

  Widget _buildOutlineInput({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    required bool isDark,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      style: const TextStyle(fontSize: 13),
      decoration: _inputDecoration(hint: hint, isDark: isDark),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required bool isDark,
    String? fontFamily,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: isDark ? Colors.grey[500] : const Color(0xFF94A3B8),
        fontSize: 13,
        fontFamily: fontFamily,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
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
        borderSide: BorderSide(color: Color(0xFF6D28D9), width: 1.5),
      ),
    );
  }
}
