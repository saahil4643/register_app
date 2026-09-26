import 'package:flutter/material.dart';
import '../models/invoice.dart';

class InvoiceStatusBadge extends StatelessWidget {
  final InvoiceStatus status;

  const InvoiceStatusBadge({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;

    switch (status) {
      case InvoiceStatus.draft:
        backgroundColor = const Color(0xFFF3F4F6); // Gray 100
        textColor = const Color(0xFF374151); // Gray 700
        break;
      case InvoiceStatus.sent:
        backgroundColor = const Color(0xFFEFF6FF); // Blue 50
        textColor = const Color(0xFF1D4ED8); // Blue 700
        break;
      case InvoiceStatus.paid:
        backgroundColor = const Color(0xFFD1FAE5); // Emerald 100
        textColor = const Color(0xFF047857); // Emerald 700
        break;
      case InvoiceStatus.overdue:
        backgroundColor = const Color(0xFFFEE2E2); // Red 100
        textColor = const Color(0xFFB91C1C); // Red 700
        break;
      case InvoiceStatus.cancelled:
        backgroundColor = const Color(0xFFECEFF1); // BlueGray 50
        textColor = const Color(0xFF546E7A); // BlueGray 600
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
