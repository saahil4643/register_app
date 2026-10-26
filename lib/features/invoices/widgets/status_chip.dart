import 'package:flutter/material.dart';
import '../models/invoice.dart';

class StatusChip extends StatelessWidget {
  final InvoiceStatus status;
  final double fontSize;
  final EdgeInsets padding;

  const StatusChip({
    super.key,
    required this.status,
    this.fontSize = 11,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    IconData icon;

    switch (status) {
      case InvoiceStatus.draft:
        backgroundColor = const Color(0xFFF3F4F6); // Neutral Grey 100
        textColor = const Color(0xFF4B5563); // Grey 600
        icon = Icons.drafts_outlined;
        break;
      case InvoiceStatus.sent: // equivalent to Pending
        backgroundColor = const Color(0xFFEFF6FF); // Blue 50
        textColor = const Color(0xFF1D4ED8); // Blue 700
        icon = Icons.hourglass_empty_rounded;
        break;
      case InvoiceStatus.partially_paid:
        backgroundColor = const Color(0xFFFFFBEB); // Amber 50
        textColor = const Color(0xFFB45309); // Amber 700
        icon = Icons.pie_chart_outline_rounded;
        break;
      case InvoiceStatus.paid:
        backgroundColor = const Color(0xFFECFDF5); // Emerald/Green 50
        textColor = const Color(0xFF059669); // Emerald/Green 600
        icon = Icons.check_circle_rounded;
        break;
      case InvoiceStatus.overdue:
        backgroundColor = const Color(0xFFFEF2F2); // Red 50
        textColor = const Color(0xFFDC2626); // Red 600
        icon = Icons.warning_amber_rounded;
        break;
      case InvoiceStatus.cancelled:
        backgroundColor = const Color(0xFFF9FAFB); // Cool Grey 50
        textColor = const Color(0xFF9CA3AF); // Muted Grey
        icon = Icons.cancel_outlined;
        break;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20), // Zoho style pill-shape
        border: Border.all(
          color: textColor.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: fontSize + 2,
            color: textColor,
          ),
          const SizedBox(width: 4),
          Text(
            status.displayName,
            style: TextStyle(
              color: textColor,
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
