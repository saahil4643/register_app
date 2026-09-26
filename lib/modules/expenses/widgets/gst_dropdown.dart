import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_spacing.dart';

class GstDropdown extends StatefulWidget {
  final String? initialValue;
  final Function(String rate, double percentageValue) onGstChanged;
  final FormFieldValidator<String>? validator;

  const GstDropdown({
    super.key,
    this.initialValue,
    required this.onGstChanged,
    this.validator,
  });

  @override
  State<GstDropdown> createState() => _GstDropdownState();
}

class _GstDropdownState extends State<GstDropdown> {
  final List<String> _gstOptions = ['0%', '5%', '12%', '18%', '28%', 'Custom'];
  String? _selectedValue;
  bool _isCustom = false;
  final TextEditingController _customController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeValues();
  }

  void _initializeValues() {
    final val = widget.initialValue;
    if (val == null) {
      _selectedValue = '18%'; // Default rate in Indian accounting typically
      _isCustom = false;
      _customController.text = '';
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onGstChanged('18%', 0.18);
      });
    } else if (_gstOptions.contains(val)) {
      _selectedValue = val;
      _isCustom = val == 'Custom';
      _customController.text = '';
    } else {
      _selectedValue = 'Custom';
      _isCustom = true;
      // Extract numeric value from "Custom (15%)"
      final regExp = RegExp(r'\d+');
      final match = regExp.firstMatch(val);
      if (match != null) {
        _customController.text = match.group(0) ?? '';
      }
    }
  }

  @override
  void didUpdateWidget(GstDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != oldWidget.initialValue) {
      _initializeValues();
    }
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  double _getPercentage(String text) {
    if (text == '0%') return 0.0;
    if (text == '5%') return 0.05;
    if (text == '12%') return 0.12;
    if (text == '18%') return 0.18;
    if (text == '28%') return 0.28;
    
    // Custom logic
    final parsed = double.tryParse(_customController.text) ?? 0.0;
    return parsed / 100;
  }

  void _handleChanged(String? val) {
    if (val == null) return;
    setState(() {
      _selectedValue = val;
      _isCustom = val == 'Custom';
    });

    if (!_isCustom) {
      widget.onGstChanged(val, _getPercentage(val));
    } else {
      final customVal = _customController.text;
      final pct = _getPercentage('Custom');
      widget.onGstChanged('Custom ($customVal%)', pct);
    }
  }

  void _handleCustomValChanged(String val) {
    final pct = _getPercentage('Custom');
    widget.onGstChanged('Custom ($val%)', pct);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            'GST Rate *',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.grey[300] : Colors.grey[700],
            ),
          ),
        ),
        DropdownButtonFormField<String>(
          value: _selectedValue,
          items: _gstOptions
              .map((val) => DropdownMenuItem<String>(
                    value: val,
                    child: Text(val),
                  ))
              .toList(),
          onChanged: _handleChanged,
          validator: widget.validator,
          style: TextStyle(
            fontSize: 15,
            color: isDark ? Colors.white : Colors.black,
          ),
          decoration: InputDecoration(
            hintText: 'Select GST Rate',
            prefixIcon: Icon(
              Icons.percent_rounded,
              size: 20,
              color: theme.colorScheme.primary.withOpacity(0.7),
            ),
          ),
        ),
        if (_isCustom) ...[
          AppSpacing.heightM,
          AnimatedOpacity(
            opacity: _isCustom ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 6),
                  child: Text(
                    'Custom GST Rate (%) *',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.grey[300] : Colors.grey[700],
                    ),
                  ),
                ),
                TextFormField(
                  controller: _customController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(fontSize: 15),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  decoration: InputDecoration(
                    hintText: 'Enter custom percentage (e.g. 15)',
                    prefixIcon: Icon(
                      Icons.tune_rounded,
                      size: 20,
                      color: theme.colorScheme.primary.withOpacity(0.7),
                    ),
                  ),
                  onChanged: _handleCustomValChanged,
                  validator: (value) {
                    if (_isCustom) {
                      if (value == null || value.isEmpty) {
                        return 'GST Percentage is required';
                      }
                      final parsed = double.tryParse(value);
                      if (parsed == null || parsed < 0) {
                        return 'Enter a valid rate';
                      }
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
