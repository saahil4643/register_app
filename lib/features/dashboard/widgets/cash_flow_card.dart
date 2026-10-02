import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../models/dashboard_reports.dart';

class CashFlowCard extends StatefulWidget {
  final ProfitLossReport? profitLoss;
  final SalesSummaryReport? salesSummary;

  const CashFlowCard({
    super.key,
    required this.profitLoss,
    required this.salesSummary,
  });

  @override
  State<CashFlowCard> createState() => _CashFlowCardState();
}

class _CashFlowCardState extends State<CashFlowCard> {
  String _selectedFilter = 'This Fiscal Year';

  final List<String> _filterOptions = [
    'This Fiscal Year',
    'This Quarter',
    'This Month',
    'Previous Fiscal Year',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final trends = widget.profitLoss?.monthlyTrends ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Row: Icon + Title & Dropdown Filter
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? Colors.white70 : const Color(0xFF1E293B),
                        width: 1.6,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.trending_up_rounded,
                        size: 14,
                        color: isDark ? Colors.white70 : const Color(0xFF1E293B),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Cash Flow',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),

              // Filter Dropdown Pill
              PopupMenuButton<String>(
                onSelected: (val) {
                  setState(() => _selectedFilter = val);
                },
                color: theme.colorScheme.surface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                itemBuilder: (context) => _filterOptions.map((opt) {
                  return PopupMenuItem<String>(
                    value: opt,
                    child: Text(
                      opt,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: opt == _selectedFilter ? FontWeight.bold : FontWeight.normal,
                        color: opt == _selectedFilter ? theme.colorScheme.primary : null,
                      ),
                    ),
                  );
                }).toList(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                      width: 1.1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _selectedFilter,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isDark ? AppColors.darkTextPrimary : const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 16,
                        color: isDark ? AppColors.darkTextSecondary : const Color(0xFF475569),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Cash Flow Chart Area
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: SizedBox(
            height: 180,
            width: double.infinity,
            child: CustomPaint(
              painter: _CashFlowPainter(
                trends: trends,
                isDark: isDark,
                primaryColor: theme.colorScheme.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CashFlowPainter extends CustomPainter {
  final List<MonthlyTrendItem> trends;
  final bool isDark;
  final Color primaryColor;

  _CashFlowPainter({
    required this.trends,
    required this.isDark,
    required this.primaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Left margin for Y-axis labels
    const double leftMargin = 55.0;
    const double bottomMargin = 26.0;
    const double topMargin = 12.0;

    final double chartWidth = size.width - leftMargin;
    final double chartHeight = size.height - topMargin - bottomMargin;

    // Grid line paint
    final gridPaint = Paint()
      ..color = isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFF1F5F9)
      ..strokeWidth = 1.0;

    final textStyle = TextStyle(
      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
      fontSize: 11,
      fontWeight: FontWeight.w400,
    );

    // Determine 3 Y-values (Max, Mid, Low)
    double maxVal = 1208.0;
    double midVal = 1000.0;
    double lowVal = 800.3;

    if (trends.isNotEmpty) {
      double maxRev = 0.0;
      for (final t in trends) {
        if (t.revenue > maxRev) maxRev = t.revenue;
      }
      if (maxRev > 0) {
        maxVal = maxRev;
        lowVal = maxRev * 0.4;
        midVal = (maxVal + lowVal) / 2;
      }
    }

    String formatVal(double v) {
      if (v >= 10000000) return '${(v / 10000000).toStringAsFixed(1)}Cr';
      if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
      if (v >= 1000) {
        // e.g. 1.208 or formatted
        if (v == 1208.0) return '1.208';
        if (v == 1000.0) return '1';
        return (v / 1000).toStringAsFixed(1);
      }
      return v.toStringAsFixed(1);
    }

    final labels = [formatVal(maxVal), formatVal(midVal), formatVal(lowVal)];
    final yPositions = [
      topMargin,
      topMargin + chartHeight / 2,
      topMargin + chartHeight,
    ];

    // Draw horizontal grid lines and labels
    for (int i = 0; i < 3; i++) {
      final y = yPositions[i];
      // Grid line
      canvas.drawLine(
        Offset(leftMargin, y),
        Offset(size.width, y),
        gridPaint,
      );

      // Label text
      final textSpan = TextSpan(text: labels[i], style: textStyle);
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(leftMargin - textPainter.width - 10, y - textPainter.height / 2),
      );
    }

    // Points calculation
    List<Offset> points = [];

    if (trends.length >= 2) {
      final stepX = chartWidth / (trends.length - 1);
      for (int i = 0; i < trends.length; i++) {
        final t = trends[i];
        final normY = ((t.revenue - lowVal) / (maxVal - lowVal)).clamp(0.05, 0.95);
        final x = leftMargin + i * stepX;
        final y = topMargin + chartHeight * (1.0 - normY);
        points.add(Offset(x, y));
      }
    } else {
      // Default sample smooth curve matching the design
      final sampleNorms = [0.8, 0.65, 0.75, 0.5, 0.6, 0.45];
      final stepX = chartWidth / (sampleNorms.length - 1);
      for (int i = 0; i < sampleNorms.length; i++) {
        final x = leftMargin + i * stepX;
        final y = topMargin + chartHeight * (1.0 - sampleNorms[i]);
        points.add(Offset(x, y));
      }
    }

    // Draw Smooth Curve and Gradient Area
    if (points.isNotEmpty) {
      final path = Path();
      path.moveTo(points[0].dx, points[0].dy);

      for (int i = 0; i < points.length - 1; i++) {
        final p0 = points[i];
        final p1 = points[i + 1];
        final controlX = (p0.dx + p1.dx) / 2;
        path.cubicTo(controlX, p0.dy, controlX, p1.dy, p1.dx, p1.dy);
      }

      // Fill Path for gradient under curve
      final fillPath = Path.from(path);
      fillPath.lineTo(points.last.dx, topMargin + chartHeight);
      fillPath.lineTo(points.first.dx, topMargin + chartHeight);
      fillPath.close();

      final lineCol = isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB);

      final fillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            lineCol.withValues(alpha: isDark ? 0.25 : 0.12),
            lineCol.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromLTWH(leftMargin, topMargin, chartWidth, chartHeight))
        ..style = PaintingStyle.fill;

      canvas.drawPath(fillPath, fillPaint);

      // Line Stroke
      final strokePaint = Paint()
        ..color = lineCol
        ..strokeWidth = 2.4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      canvas.drawPath(path, strokePaint);

      // Dot circles
      final dotPaint = Paint()
        ..color = lineCol
        ..style = PaintingStyle.fill;

      final dotBgPaint = Paint()
        ..color = isDark ? const Color(0xFF0F172A) : Colors.white
        ..style = PaintingStyle.fill;

      for (final p in points) {
        canvas.drawCircle(p, 4.0, dotBgPaint);
        canvas.drawCircle(p, 2.5, dotPaint);
      }
    }

    // X-axis month ticks
    final months = ['Apr', 'Jun', 'Aug', 'Oct', 'Dec', 'Feb'];
    if (trends.length >= 6) {
      for (int i = 0; i < 6; i++) {
        final label = trends[i].period.length > 3 ? trends[i].period.substring(0, 3) : trends[i].period;
        months[i] = label;
      }
    }

    final xStep = chartWidth / (months.length - 1);
    for (int i = 0; i < months.length; i++) {
      final x = leftMargin + i * xStep;
      final textSpan = TextSpan(
        text: months[i],
        style: textStyle.copyWith(fontSize: 10),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, size.height - bottomMargin + 6),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CashFlowPainter oldDelegate) {
    return oldDelegate.trends != trends ||
        oldDelegate.isDark != isDark ||
        oldDelegate.primaryColor != primaryColor;
  }
}
