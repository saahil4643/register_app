import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../customers/models/customer.dart';
import '../../../customers/providers/customer_provider.dart';
import '../../providers/invoice_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Full-screen transparent overlay pushed via GoRouter (opaque: false).
// The invoice screen is still painted behind the black54 Scaffold.
// ─────────────────────────────────────────────────────────────────────────────
class AddCustomerOverlayScreen extends StatelessWidget {
  final String prefillName;
  const AddCustomerOverlayScreen({super.key, required this.prefillName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black54,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: AddCustomerForm(
              prefillName: prefillName,
              onSaved: (Customer newCustomer) {
                final inv = context.read<InvoiceProvider>();
                inv.addCustomer(newCustomer);
                inv.selectCustomer(newCustomer);
                context.pop();
              },
              onCancel: () => context.pop(),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable customer creation form card
// ─────────────────────────────────────────────────────────────────────────────
class AddCustomerForm extends StatefulWidget {
  final String prefillName;
  final ValueChanged<Customer> onSaved;
  final VoidCallback onCancel;

  const AddCustomerForm({
    super.key,
    required this.prefillName,
    required this.onSaved,
    required this.onCancel,
  });

  @override
  State<AddCustomerForm> createState() => _AddCustomerFormState();
}

class _AddCustomerFormState extends State<AddCustomerForm> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  late final TextEditingController _nameCtrl;
  late final TextEditingController _companyCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _gstCtrl;
  late final TextEditingController _addressCtrl;
  late final FocusNode _nameFocus;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.prefillName);
    _companyCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
    _emailCtrl = TextEditingController();
    _gstCtrl = TextEditingController();
    _addressCtrl = TextEditingController();
    _nameFocus = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _nameFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _companyCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _gstCtrl.dispose();
    _addressCtrl.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final cp = context.read<CustomerProvider>();
      final draft = Customer(
        id: '',
        displayName: _nameCtrl.text.trim(),
        companyName: _companyCtrl.text.trim(),
        primaryPhone: _phoneCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        billingAddressLine1: _addressCtrl.text.trim(),
        gstNumber: _gstCtrl.text.trim(),
        creditLimit: 50000.0,
        outstanding: 0.0,
        notes: '',
        createdAt: DateTime.now(),
      );
      final created = await cp.createCustomer(draft);
      if (!mounted) return;
      if (created != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Customer "${created.name}" created!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ));
        widget.onSaved(created);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(cp.errorMessage ?? 'Failed to create customer'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: 8,
      color: isDark ? theme.colorScheme.surface : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.primary, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Row(children: [
                Icon(Icons.person_add_rounded, color: theme.colorScheme.primary, size: 18),
                const SizedBox(width: 8),
                Text('NEW CUSTOMER',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold, fontSize: 10,
                      letterSpacing: 0.5, color: theme.colorScheme.primary,
                    )),
                const Spacer(),
                IconButton(
                  onPressed: _isLoading ? null : widget.onCancel,
                  icon: const Icon(Icons.close_rounded, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Cancel',
                ),
              ]),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 14),
              TextFormField(
                controller: _nameCtrl,
                focusNode: _nameFocus,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Contact Name *',
                  hintText: 'Enter full name (letters only)',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (v) {
                  final trimmed = v?.trim() ?? '';
                  if (trimmed.isEmpty) return 'Contact name is required';
                  if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(trimmed)) {
                    return 'Only letters and spaces are allowed';
                  }
                  if (trimmed.length < 2) {
                    return 'Contact name must be at least 2 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  hintText: 'Enter mobile number',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  hintText: 'Enter email address',
                  prefixIcon: Icon(Icons.mail_outline_rounded),
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _addressCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  hintText: 'Enter billing / shipping address',
                  prefixIcon: Icon(Icons.location_on_outlined),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _gstCtrl,
                decoration: const InputDecoration(
                  labelText: 'GST Number',
                  hintText: 'e.g. 27AABCU9603R1ZX',
                  prefixIcon: Icon(Icons.receipt_long_outlined),
                ),
                textCapitalization: TextCapitalization.characters,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return null;
                  final gst = val.trim().toUpperCase();
                  final gstRegex = RegExp(r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$');
                  if (!gstRegex.hasMatch(gst)) {
                    return 'Invalid GSTIN (e.g. 27AABCU9603R1ZX)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _companyCtrl,
                decoration: const InputDecoration(
                  labelText: 'Company Name',
                  hintText: 'Enter company / business name',
                  prefixIcon: Icon(Icons.business_outlined),
                ),
                textCapitalization: TextCapitalization.words,
              ),

              const SizedBox(height: 20),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                OutlinedButton(
                  onPressed: _isLoading ? null : widget.onCancel,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 46),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _submit,
                  icon: _isLoading
                      ? const SizedBox(width: 14, height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.save_rounded, size: 16),
                  label: Text(_isLoading ? 'Saving...' : 'Save Customer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 46),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ]),
            ],
          ),
        ),
        ),
      ),
    );
  }
}
