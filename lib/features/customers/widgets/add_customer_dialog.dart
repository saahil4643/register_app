import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../models/customer.dart';
import '../providers/customer_provider.dart';
import '../../invoices/providers/invoice_provider.dart';

class AddCustomerDialog extends StatefulWidget {
  final String? initialName;

  const AddCustomerDialog({
    super.key,
    this.initialName,
  });

  @override
  State<AddCustomerDialog> createState() => _AddCustomerDialogState();
}

class _AddCustomerDialogState extends State<AddCustomerDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _showAdvanced = false;
  bool _isLoading = false;
  String _customerType = 'business';

  // Controllers - Basic Info
  late TextEditingController _nameController;
  late TextEditingController _companyController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _gstNoController;

  // Controllers - Address
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _pincodeController;

  // Controllers - Business Info
  late TextEditingController _creditLimitController;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _companyController = TextEditingController(text: widget.initialName ?? '');
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    _gstNoController = TextEditingController();
    _addressController = TextEditingController();
    _cityController = TextEditingController();
    _stateController = TextEditingController();
    _pincodeController = TextEditingController();
    _creditLimitController = TextEditingController(text: '50000.0');
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
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
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final customerProvider = context.read<CustomerProvider>();
    final invoiceProvider = context.read<InvoiceProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    // Construct address
    final street = _addressController.text.trim();
    final city = _cityController.text.trim();
    final state = _stateController.text.trim();
    final pincode = _pincodeController.text.trim();
    
    String fullAddress = '';
    if (street.isNotEmpty || city.isNotEmpty || state.isNotEmpty || pincode.isNotEmpty) {
      final parts = [
        if (street.isNotEmpty) street,
        if (city.isNotEmpty) city,
        if (state.isNotEmpty || pincode.isNotEmpty)
          '${state.isNotEmpty ? state : ''}${state.isNotEmpty && pincode.isNotEmpty ? ' - ' : ''}${pincode.isNotEmpty ? pincode : ''}'
      ];
      fullAddress = parts.join(', ');
    }

    final enteredCompany = _companyController.text.trim();
    final displayName = _nameController.text.trim();
    final companyName = _customerType == 'individual'
        ? ''
        : (enteredCompany.isNotEmpty ? enteredCompany : displayName);

    final customer = Customer(
      id: '',
      customerType: _customerType,
      displayName: displayName,
      companyName: companyName,
      primaryPhone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      billingAddressLine1: street.isNotEmpty ? street : fullAddress,
      billingCity: city,
      billingState: state,
      billingPostalCode: pincode,
      gstNumber: _gstNoController.text.trim(),
      creditLimit: double.tryParse(_creditLimitController.text) ?? 50000.0,
      outstanding: 0.0,
      notes: _notesController.text.trim(),
      createdAt: DateTime.now(),
    );

    try {
      final newCustomer = await customerProvider.createCustomer(customer);

      if (!mounted) return;

      if (newCustomer != null) {
        // Automatically select the new customer in the invoice flow
        invoiceProvider.selectCustomer(newCustomer);
        
        messenger.showSnackBar(
          SnackBar(
            content: Text('Customer "${newCustomer.name}" created and selected!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        navigator.pop(newCustomer); // Close dialog and return customer
      } else {
        final err = customerProvider.errorMessage ?? 'Failed to create customer';
        messenger.showSnackBar(
          SnackBar(
            content: Text(err),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final mediaQuery = MediaQuery.of(context);
    
    // Constrain height/width of dialog for desktop/web and make it responsive
    final dialogWidth = mediaQuery.size.width > 600 ? 550.0 : mediaQuery.size.width * 0.95;
    final dialogHeight = mediaQuery.size.height * 0.85;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 16,
      backgroundColor: theme.dialogTheme.backgroundColor ?? theme.colorScheme.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: dialogWidth,
        constraints: BoxConstraints(maxHeight: dialogHeight),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Stack(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
                  decoration: BoxDecoration(
                    color: isDark ? theme.colorScheme.surface : Colors.grey[50],
                    border: Border(
                      bottom: BorderSide(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.person_add_rounded,
                          color: theme.colorScheme.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Add New Customer',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Fill in details to create a new client profile',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: _isLoading ? null : () => Navigator.pop(context),
                        style: IconButton.styleFrom(
                          backgroundColor: isDark ? Colors.grey[850] : Colors.grey[200],
                          foregroundColor: isDark ? Colors.grey[300] : Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),

                // Form Body
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader(theme, 'CUSTOMER TYPE'),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: theme.brightness == Brightness.dark ? theme.colorScheme.surface : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: theme.brightness == Brightness.dark ? AppColors.darkBorder : AppColors.lightBorder,
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
                                        const Text('Business', style: TextStyle(fontWeight: FontWeight.w600)),
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
                                        const Text('Individual', style: TextStyle(fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          _buildSectionHeader(theme, 'CONTACT INFORMATION'),
                          const SizedBox(height: 12),

                          // Name Field
                          TextFormField(
                            controller: _nameController,
                            autofocus: widget.initialName?.isEmpty ?? true,
                            decoration: const InputDecoration(
                              labelText: 'Contact Name *',
                              hintText: 'Enter full name',
                              prefixIcon: Icon(Icons.person_outline_rounded),
                            ),
                            textCapitalization: TextCapitalization.words,
                            validator: (val) => val == null || val.trim().isEmpty
                                ? 'Please enter contact name'
                                : null,
                            onChanged: (val) {
                              if (_companyController.text == widget.initialName) {
                                _companyController.text = val;
                              }
                            },
                          ),
                          const SizedBox(height: 14),

                          // Phone Field
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'Phone Number',
                              hintText: 'e.g. 9876543210',
                              prefixIcon: Icon(Icons.phone_outlined),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) return null;
                              if (val.trim().length < 8) return 'Invalid phone number';
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),

                          // Email Field
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Email Address',
                              hintText: 'e.g. john@example.com',
                              prefixIcon: Icon(Icons.mail_outline_rounded),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) return null;
                              final emailRegex = RegExp(
                                  r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
                              if (!emailRegex.hasMatch(val.trim())) return 'Invalid email address';
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),

                          // Address Field
                          TextFormField(
                            controller: _addressController,
                            maxLines: 2,
                            decoration: const InputDecoration(
                              labelText: 'Address',
                              hintText: 'Plot No, Building, Street, City',
                              prefixIcon: Icon(Icons.location_on_outlined),
                              alignLabelWithHint: true,
                            ),
                          ),
                          const SizedBox(height: 14),

                          // GST Number Field
                          TextFormField(
                            controller: _gstNoController,
                            decoration: const InputDecoration(
                              labelText: 'GST Number (Optional)',
                              hintText: 'e.g. 27AAAAA1111A1Z1',
                              prefixIcon: Icon(Icons.receipt_long_outlined),
                            ),
                            textCapitalization: TextCapitalization.characters,
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) return null;
                              final gst = val.trim().toUpperCase();
                              final gstRegex = RegExp(r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$');
                              if (!gstRegex.hasMatch(gst)) {
                                return 'Invalid GSTIN format (15 chars, e.g. 27AAAAA1111A1Z1)';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),

                          // Company Field (only for business)
                          if (_customerType == 'business') ...[
                            TextFormField(
                              controller: _companyController,
                              decoration: const InputDecoration(
                                labelText: 'Company Name (Optional)',
                                hintText: 'e.g. Acme Corp',
                                prefixIcon: Icon(Icons.business_outlined),
                              ),
                              textCapitalization: TextCapitalization.words,
                            ),
                            const SizedBox(height: 14),
                          ],

                          const SizedBox(height: 10),

                          _buildSectionHeader(theme, 'BILLING ADDRESS'),
                          const SizedBox(height: 12),

                          // Street Address
                          TextFormField(
                            controller: _addressController,
                            decoration: const InputDecoration(
                              labelText: 'Street Address',
                              hintText: 'Plot No, Building, Street Name',
                              prefixIcon: Icon(Icons.location_on_outlined),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // City Field
                          TextFormField(
                            controller: _cityController,
                            decoration: const InputDecoration(
                              labelText: 'City',
                              hintText: 'Enter city name',
                              prefixIcon: Icon(Icons.location_city_outlined),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // State Field
                          TextFormField(
                            controller: _stateController,
                            decoration: const InputDecoration(
                              labelText: 'State',
                              hintText: 'Enter state name',
                              prefixIcon: Icon(Icons.map_outlined),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Pincode Field
                          TextFormField(
                            controller: _pincodeController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Pincode',
                              hintText: '6-digit PIN',
                              prefixIcon: Icon(Icons.pin_drop_outlined),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Expandable advanced options
                          InkWell(
                            onTap: () {
                              setState(() {
                                _showAdvanced = !_showAdvanced;
                              });
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                              child: Row(
                                children: [
                                  Icon(
                                    _showAdvanced 
                                        ? Icons.keyboard_arrow_up_rounded 
                                        : Icons.keyboard_arrow_down_rounded,
                                    color: theme.colorScheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Advanced Options',
                                    style: TextStyle(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          if (_showAdvanced) ...[
                            const SizedBox(height: 12),
                            // Credit Limit Field
                            TextFormField(
                              controller: _creditLimitController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Credit Limit (₹)',
                                prefixIcon: Icon(Icons.credit_card_outlined),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) return null;
                                if (double.tryParse(val) == null) {
                                  return 'Enter a valid number';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),

                            // Notes Field
                            TextFormField(
                              controller: _notesController,
                              maxLines: 3,
                              decoration: const InputDecoration(
                                labelText: 'Internal Notes',
                                prefixIcon: Icon(Icons.notes_rounded),
                                alignLabelWithHint: true,
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                ),

                // Footer Actions
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? theme.colorScheme.surface : Colors.grey[50],
                    border: Border(
                      top: BorderSide(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: _isLoading ? null : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 46),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _submitForm,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(0, 46),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Save Customer'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            // Loading Overlay
            if (_isLoading)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.3),
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Text(
      title,
      style: theme.textTheme.labelMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.primary.withOpacity(0.8),
        letterSpacing: 0.8,
        fontSize: 11,
      ),
    );
  }
}
