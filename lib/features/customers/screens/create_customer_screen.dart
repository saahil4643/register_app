import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../models/customer.dart';
import '../providers/customer_provider.dart';

class CreateCustomerScreen extends StatefulWidget {
  final Customer? customer;

  const CreateCustomerScreen({super.key, this.customer});

  @override
  State<CreateCustomerScreen> createState() => _CreateCustomerScreenState();
}

class _CreateCustomerScreenState extends State<CreateCustomerScreen> {
  final _formKey = GlobalKey<FormState>();

  // Customer Type: 'business' or 'individual'
  String _customerType = 'business';

  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _companyController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _gstNoController;
  late TextEditingController _panController;

  // Address
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _pincodeController;

  // Financial & Terms
  String _paymentTerms = 'Due on Receipt';
  late TextEditingController _creditLimitController;
  late TextEditingController _openingBalanceController;
  late TextEditingController _notesController;

  bool _isSaving = false;

  final List<String> _paymentTermsOptions = [
    'Due on Receipt',
    'Net 15',
    'Net 30',
    'Net 45',
    'Net 60',
  ];

  @override
  void initState() {
    super.initState();
    final c = widget.customer;
    _customerType = (c != null && c.customerType.isNotEmpty) ? c.customerType : 'business';
    _nameController = TextEditingController(text: c?.displayName ?? c?.name ?? '');
    _companyController = TextEditingController(text: c?.companyName ?? c?.company ?? '');
    _phoneController = TextEditingController(text: c?.primaryPhone ?? c?.phone ?? '');
    _emailController = TextEditingController(text: c?.email ?? '');
    _gstNoController = TextEditingController(text: c?.gstNumber ?? c?.gstNo ?? '');
    _panController = TextEditingController(text: c?.panNumber ?? '');

    _addressController = TextEditingController(text: c?.billingAddressLine1 ?? '');
    _cityController = TextEditingController(text: c?.billingCity ?? '');
    _stateController = TextEditingController(text: c?.billingState ?? '');
    _pincodeController = TextEditingController(text: c?.billingPostalCode ?? '');

    _paymentTerms = (c?.paymentTerms.isNotEmpty == true) ? c!.paymentTerms : 'Due on Receipt';
    if (!_paymentTermsOptions.contains(_paymentTerms)) {
      _paymentTerms = 'Due on Receipt';
    }

    _creditLimitController = TextEditingController(text: c?.creditLimit != null ? c!.creditLimit.toStringAsFixed(0) : '50000');
    _openingBalanceController = TextEditingController(text: c?.outstanding != null ? c!.outstanding.toStringAsFixed(0) : '0');
    _notesController = TextEditingController(text: c?.notes ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _companyController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _gstNoController.dispose();
    _panController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _creditLimitController.dispose();
    _openingBalanceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveCustomer() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);
    final customerProvider = context.read<CustomerProvider>();
    final isEdit = widget.customer != null;

    final displayName = _nameController.text.trim();
    final enteredCompany = _companyController.text.trim();
    final companyName = _customerType == 'individual'
        ? ''
        : (enteredCompany.isNotEmpty ? enteredCompany : displayName);

    final customer = Customer(
      id: widget.customer?.id ?? 'CUST-${DateTime.now().millisecondsSinceEpoch}',
      customerType: _customerType,
      displayName: displayName,
      companyName: companyName,
      primaryPhone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      gstNumber: _gstNoController.text.trim().toUpperCase(),
      panNumber: _panController.text.trim().toUpperCase(),
      billingAddressLine1: _addressController.text.trim(),
      billingCity: _cityController.text.trim(),
      billingState: _stateController.text.trim(),
      billingPostalCode: _pincodeController.text.trim(),
      paymentTerms: _paymentTerms,
      creditLimit: double.tryParse(_creditLimitController.text.trim()) ?? 50000.0,
      outstanding: double.tryParse(_openingBalanceController.text.trim()) ?? 0.0,
      notes: _notesController.text.trim(),
      createdAt: widget.customer?.createdAt ?? DateTime.now(),
    );

    Customer? result;
    try {
      if (isEdit) {
        result = await customerProvider.updateCustomer(customer.id, customer);
      } else {
        result = await customerProvider.createCustomer(customer);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }

    if (!mounted) return;

    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEdit ? 'Customer updated successfully' : 'Customer added successfully'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.of(context).pop(result);
    } else {
      final err = customerProvider.errorMessage ?? 'Failed to save customer';
      ScaffoldMessenger.of(context).showSnackBar(
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
      backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: isDark ? theme.colorScheme.surface : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.customer != null ? 'Edit Customer' : 'Add New Customer',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveCustomer,
            child: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    'Save',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: isDark ? Colors.grey[200] : AppColors.lightPrimary,
                    ),
                  ),
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: const Color(0xFFE5E7EB), height: 1.0),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Customer Type Segment
              _buildCustomerTypeToggle(isDark),
              const SizedBox(height: 16),

              // Section 1: Primary Details
              _buildSectionTitle('PRIMARY CONTACT'),
              const SizedBox(height: 8),
              _buildPrimaryDetailsCard(isDark),
              const SizedBox(height: 18),

              // Section 2: Tax & Compliance
              _buildSectionTitle('TAX & COMPLIANCE'),
              const SizedBox(height: 8),
              _buildTaxCard(isDark),
              const SizedBox(height: 18),

              // Section 3: Billing Address
              _buildSectionTitle('BILLING ADDRESS'),
              const SizedBox(height: 8),
              _buildAddressCard(isDark),
              const SizedBox(height: 18),

              // Section 4: Terms & Notes
              _buildSectionTitle('PAYMENT TERMS & NOTES'),
              const SizedBox(height: 8),
              _buildFinancialTermsCard(isDark),
              const SizedBox(height: 28),

              // Save Customer Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveCustomer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.lightPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          widget.customer != null ? 'Update Customer' : 'Save Customer',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: Colors.grey[600],
      ),
    );
  }

  // Customer Type Switcher
  Widget _buildCustomerTypeToggle(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _customerType = 'business'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: _customerType == 'business' ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: _customerType == 'business'
                      ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.business_rounded,
                      size: 16,
                      color: _customerType == 'business' ? AppColors.lightPrimary : Colors.grey[600],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Business (B2B)',
                      style: TextStyle(
                        fontWeight: _customerType == 'business' ? FontWeight.bold : FontWeight.w500,
                        color: _customerType == 'business' ? AppColors.lightPrimary : Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _customerType = 'individual'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: _customerType == 'individual' ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: _customerType == 'individual'
                      ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.person_rounded,
                      size: 16,
                      color: _customerType == 'individual' ? AppColors.lightPrimary : Colors.grey[600],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Individual (B2C)',
                      style: TextStyle(
                        fontWeight: _customerType == 'individual' ? FontWeight.bold : FontWeight.w500,
                        color: _customerType == 'individual' ? AppColors.lightPrimary : Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Primary Details Card
  Widget _buildPrimaryDetailsCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: _customerType == 'business' ? 'Contact Person Name *' : 'Customer Name *',
              hintText: 'e.g. Ramesh Kumar',
              prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter customer name' : null,
          ),
          if (_customerType == 'business') ...[
            const SizedBox(height: 14),
            TextFormField(
              controller: _companyController,
              decoration: const InputDecoration(
                labelText: 'Company / Business Name *',
                hintText: 'e.g. Acme Technologies Pvt Ltd',
                prefixIcon: Icon(Icons.apartment_rounded, size: 20),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              validator: (v) {
                if (_customerType == 'business' && (v == null || v.trim().isEmpty)) {
                  return 'Please enter business name';
                }
                return null;
              },
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number *',
                    hintText: '9876543210',
                    prefixIcon: Icon(Icons.phone_outlined, size: 18),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    hintText: 'client@domain.com',
                    prefixIcon: Icon(Icons.email_outlined, size: 18),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Tax Card
  Widget _buildTaxCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: _gstNoController,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'GSTIN (Optional)',
                hintText: '27AAAAA0000A1Z5',
                prefixIcon: Icon(Icons.badge_outlined, size: 18),
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextFormField(
              controller: _panController,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'PAN Number',
                hintText: 'ABCDE1234F',
                prefixIcon: Icon(Icons.credit_card_outlined, size: 18),
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Address Card
  Widget _buildAddressCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          TextFormField(
            controller: _addressController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Street Address',
              hintText: 'Shop No. 12, Commercial Market, MG Road',
              prefixIcon: Icon(Icons.location_on_outlined, size: 18),
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _cityController,
                  decoration: const InputDecoration(
                    labelText: 'City',
                    hintText: 'Mumbai',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: _stateController,
                  decoration: const InputDecoration(
                    labelText: 'State',
                    hintText: 'Maharashtra',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: _pincodeController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'PIN Code',
                    hintText: '400001',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Financial & Terms Card
  Widget _buildFinancialTermsCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _paymentTerms,
                  decoration: const InputDecoration(
                    labelText: 'Payment Terms',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: _paymentTermsOptions
                      .map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 13))))
                      .toList(),
                  onChanged: (v) => setState(() => _paymentTerms = v ?? 'Due on Receipt'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _creditLimitController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Credit Limit (₹)',
                    hintText: '50000',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _notesController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Internal Notes',
              hintText: 'Special terms, preferences or delivery notes...',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ],
      ),
    );
  }
}
