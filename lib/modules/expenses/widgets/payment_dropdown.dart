import 'package:flutter/material.dart';

class PaymentDropdown extends StatelessWidget {
  final String? initialValue;
  final ValueChanged<String?> onChanged;
  final FormFieldValidator<String>? validator;

  const PaymentDropdown({
    super.key,
    this.initialValue,
    required this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final List<String> paymentModes = [
      'Cash',
      'Bank Transfer',
      'UPI',
      'Credit Card',
      'Debit Card',
      'Cheque',
      'Wallet',
      'Other'
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            'Payment Mode *',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.grey[300] : Colors.grey[700],
            ),
          ),
        ),
        DropdownButtonFormField<String>(
          value: initialValue,
          items: paymentModes
              .map((mode) => DropdownMenuItem<String>(
                    value: mode,
                    child: Text(mode),
                  ))
              .toList(),
          onChanged: onChanged,
          validator: validator,
          style: TextStyle(
            fontSize: 15,
            color: isDark ? Colors.white : Colors.black,
          ),
          decoration: InputDecoration(
            hintText: 'Select Payment Mode',
            prefixIcon: Icon(
              Icons.account_balance_wallet_outlined,
              size: 20,
              color: theme.colorScheme.primary.withOpacity(0.7),
            ),
          ),
        ),
      ],
    );
  }
}
