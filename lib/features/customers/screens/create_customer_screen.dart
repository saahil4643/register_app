import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../models/customer.dart';
import '../providers/customer_provider.dart';

class CreateCustomerScreen extends StatefulWidget {
  final Customer? customer; // If null, we are in Create mode; if not, Edit mode.

  const CreateCustomerScreen({super.key, this.customer});

  @override
  State<CreateCustomerScreen> createState() => _CreateCustomerScreenState();
}

class _CreateCustomerScreenState extends State<CreateCustomerScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TabController _tabController;

  // Customer Type
  String _customerType = 'business';

  // Form Fields - Basic
  late TextEditingController _nameController;
  late TextEditingController _companyController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _gstNoController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _pincodeController;

  // Form Fields - Business
  late TextEditingController _creditLimitController;
  late TextEditingController _openingBalanceController;
  late TextEditingController _paymentTermsController;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    final c = widget.customer;
    _customerType = (c != null && c.customerType.isNotEmpty) ? c.customerType : 'business';
    _nameController = TextEditingController(text: c?.name ?? '');
    _companyController = TextEditingController(text: c?.company ?? '');
    _phoneController = TextEditingController(text: c?.phone ?? '');
    _emailController = TextEditingController(text: c?.email ?? '');
    _gstNoController = TextEditingController(text: c?.gstNo ?? '');
    
    // Attempt to split address back into components if editing
    String street = '';
    String city = '';
    String state = '';
    String pincode = '';
    if (c != null && c.address.isNotEmpty) {
      final parts = c.address.split(', ');
      if (parts.length >= 3) {
        street = parts[0];
        city = parts[1];
        final statePin = parts[2].split(' - ');
        if (statePin.length >= 2) {
          state = statePin[0];
          pincode = statePin[1];
        } else {
          state = parts[2];
        }
      } else {
        street = c.address;
      }
    }

    _addressController = TextEditingController(text: street);
    _cityController = TextEditingController(text: city);
    _stateController = TextEditingController(text: state);
    _pincodeController = TextEditingController(text: pincode);

    _creditLimitController = TextEditingController(text: c?.creditLimit.toString() ?? '50000.0');
    _openingBalanceController = TextEditingController(text: c?.outstanding.toString() ?? '0.0');
    _paymentTermsController = TextEditingController(text: 'Net 30');
    _notesController = TextEditingController(text: c?.notes ?? '');
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _companyController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _gstNoController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _creditLimitController.dispose();
    _openingBalanceController.dispose();
    _paymentTermsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveCustomer() async {
    if (!_formKey.currentState!.validate()) {
      // If validation fails, jump to first tab where most fields reside
      _tabController.animateTo(0);
      return;
    }

    final customerProvider = context.read<CustomerProvider>();
    final isEdit = widget.customer != null;

    // Capture these BEFORE the await — must match useRootNavigator: false used in showDialog
    final navigator = Navigator.of(context, rootNavigator: false);
    final messenger = ScaffoldMessenger.of(context);

    final enteredCompany = _companyController.text.trim();
    final displayName = _nameController.text.trim();
    // For business, if company name is empty, fallback to displayName so API never complains
    final companyName = _customerType == 'individual'
        ? ''
        : (enteredCompany.isNotEmpty ? enteredCompany : displayName);

    final customer = Customer(
      id: widget.customer?.id ?? '',
      customerType: _customerType,
      displayName: displayName,
      companyName: companyName,
      primaryPhone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      billingAddressLine1: _addressController.text.trim(),
      billingCity: _cityController.text.trim(),
      billingState: _stateController.text.trim(),
      billingPostalCode: _pincodeController.text.trim(),
      gstNumber: _gstNoController.text.trim(),
      paymentTerms: _paymentTermsController.text.trim().isNotEmpty ? _paymentTermsController.text.trim() : 'Due on Receipt',
      creditLimit: double.tryParse(_creditLimitController.text) ?? 50000.0,
      outstanding: double.tryParse(_openingBalanceController.text) ?? 0.0,
      notes: _notesController.text.trim(),
      createdAt: widget.customer?.createdAt ?? DateTime.now(),
    );

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: false,
      builder: (ctx) => const PopScope(
        canPop: false,
        child: Center(child: CircularProgressIndicator()),
      ),
    );

    Customer? result;
    try {
      if (isEdit) {
        result = await customerProvider.updateCustomer(customer.id, customer);
      } else {
        result = await customerProvider.createCustomer(customer);
      }
    } finally {
      // Always dismiss the loading dialog — use captured navigator
      if (mounted) navigator.pop();
    }

    if (!mounted) return;

    if (result != null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(isEdit ? 'Customer updated successfully' : 'Customer added successfully'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.success,
        ),
      );
      navigator.pop(result); // Return result to caller
    } else {
      final err = customerProvider.errorMessage ?? 'Failed to save customer';
      messenger.showSnackBar(
        SnackBar(
          content: Text(err),
          behavior: SnackBarBehavior.floating,
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
      appBar: AppBar(
        title: Text(widget.customer != null ? 'Edit Customer' : 'Add Customer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check_rounded),
            onPressed: _saveCustomer,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: theme.colorScheme.primary,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          tabs: const [
            Tab(icon: Icon(Icons.person_outline), text: 'Basic Info'),
            Tab(icon: Icon(Icons.business_center_outlined), text: 'Business Info'),
          ],
        ),
      ),
      body: Form(
        key: _formKey,
        child: TabBarView(
          controller: _tabController,
          children: [
            // Tab 1: Basic Info
            SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(theme, 'Customer Type'),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? theme.colorScheme.surface : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => setState(() => _customerType = 'business'),
                            borderRadius: BorderRadius.circular(8),
                            child: Row(
                              children: [
                                Radio<String>(
                                  value: 'business',
                                  groupValue: _customerType,
                                  activeColor: theme.colorScheme.primary,
                                  onChanged: (val) {
                                    if (val != null) setState(() => _customerType = val);
                                  },
                                ),
                                const Text(
                                  'Business',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () => setState(() => _customerType = 'individual'),
                            borderRadius: BorderRadius.circular(8),
                            child: Row(
                              children: [
                                Radio<String>(
                                  value: 'individual',
                                  groupValue: _customerType,
                                  activeColor: theme.colorScheme.primary,
                                  onChanged: (val) {
                                    if (val != null) setState(() => _customerType = val);
                                  },
                                ),
                                const Text(
                                  'Individual',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSectionHeader(theme, 'Contact Details'),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Contact Name *',
                      hintText: 'Enter full name (letters only)',
                      prefixIcon: Icon(Icons.person_rounded),
                    ),
                    validator: (val) {
                      final trimmed = val?.trim() ?? '';
                      if (trimmed.isEmpty) {
                        return 'Please enter contact name';
                      }
                      if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(trimmed)) {
                        return 'Only letters and spaces are allowed';
                      }
                      if (trimmed.length < 2) {
                        return 'Contact name must be at least 2 characters';
                      }
                      return null;
                    },
                  ),
                  if (_customerType == 'business') ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _companyController,
                      decoration: const InputDecoration(
                        labelText: 'Company Name (Optional)',
                        prefixIcon: Icon(Icons.business_rounded),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Phone Number *',
                      hintText: 'Enter 10-digit mobile number',
                      prefixIcon: Icon(Icons.phone_rounded),
                    ),
                    validator: (val) {
                      final trimmed = val?.trim() ?? '';
                      if (trimmed.isEmpty) return 'Enter phone number';
                      if (trimmed.length != 10) return 'Enter a valid 10-digit phone number';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email Address',
                      prefixIcon: Icon(Icons.email_rounded),
                    ),
                    validator: (val) {
                      if (val != null && val.trim().isNotEmpty) {
                        final emailRegex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w{2,}$');
                        if (!emailRegex.hasMatch(val.trim())) {
                          return 'Enter a valid email address';
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _gstNoController,
                    textCapitalization: TextCapitalization.characters,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(15),
                      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'GST Number',
                      prefixIcon: Icon(Icons.receipt_rounded),
                      hintText: 'e.g. 27AAAAA1111A1Z1',
                    ),
                    validator: (val) {
                      if (val != null && val.trim().isNotEmpty) {
                        if (val.trim().length != 15) {
                          return 'GST number must be 15 characters';
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildSectionHeader(theme, 'Address Details'),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                      labelText: 'Street Address',
                      prefixIcon: Icon(Icons.location_on_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _cityController,
                    textCapitalization: TextCapitalization.words,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'City',
                      prefixIcon: Icon(Icons.location_city_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _stateController,
                    textCapitalization: TextCapitalization.words,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'State',
                      prefixIcon: Icon(Icons.map_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _pincodeController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Pincode',
                      prefixIcon: Icon(Icons.pin_drop_rounded),
                    ),
                    validator: (val) {
                      if (val != null && val.trim().isNotEmpty && val.trim().length != 6) {
                        return 'Enter a valid 6-digit pincode';
                      }
                      return null;
                    },
                  ),
                ],
              ).animate().fade(duration: 200.ms),
            ),

            // Tab 2: Business Info
            SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(theme, 'Financial Configuration'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _creditLimitController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Credit Limit (₹)',
                            prefixIcon: Icon(Icons.credit_card_rounded),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return null;
                            if (double.tryParse(val) == null) return 'Enter valid amount';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _openingBalanceController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Opening Balance (₹)',
                            prefixIcon: Icon(Icons.account_balance_wallet_rounded),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return null;
                            if (double.tryParse(val) == null) return 'Enter valid amount';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _paymentTermsController,
                    decoration: const InputDecoration(
                      labelText: 'Payment Terms',
                      prefixIcon: Icon(Icons.av_timer_rounded),
                      hintText: 'e.g. Net 30, Due on Receipt',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _notesController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Business Notes',
                      prefixIcon: Icon(Icons.notes_rounded),
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(120, 50),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _saveCustomer,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(120, 50),
                          ),
                          child: const Text('Save Customer'),
                        ),
                      ),
                    ],
                  ),
                ],
              ).animate().fade(duration: 200.ms),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.primary,
        fontSize: 14,
        letterSpacing: 0.5,
      ),
    );
  }
}
