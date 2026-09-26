import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_constants.dart';

class UploadWidget extends StatefulWidget {
  final String? initialFileName;
  final String? initialFileSize;
  final Function(String? name, String? size, File? file) onFileSelected;

  const UploadWidget({
    super.key,
    this.initialFileName,
    this.initialFileSize,
    required this.onFileSelected,
  });

  @override
  State<UploadWidget> createState() => _UploadWidgetState();
}

class _UploadWidgetState extends State<UploadWidget> {
  String? _fileName;
  String? _fileSize;
  bool _isDragging = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fileName = widget.initialFileName;
    _fileSize = widget.initialFileSize;
  }

  @override
  void didUpdateWidget(UploadWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialFileName != oldWidget.initialFileName) {
      setState(() {
        _fileName = widget.initialFileName;
        _fileSize = widget.initialFileSize;
      });
    }
  }

  Future<void> _pickFile() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image != null) {
        final length = await image.length();
        final sizeInMb = length / (1024 * 1024);
        
        if (sizeInMb > AppConstants.maxInvoiceFileSizeMB) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('File is too large. Max limit is ${AppConstants.maxInvoiceFileSizeMB}MB.'),
                backgroundColor: AppColors.error,
              ),
            );
          }
          return;
        }

        final name = image.name;
        final sizeStr = '${sizeInMb.toStringAsFixed(2)} MB';
        final file = File(image.path);

        setState(() {
          _fileName = name;
          _fileSize = sizeStr;
        });
        widget.onFileSelected(name, sizeStr, file);
      }
    } catch (e) {
      // Fallback/Simulate for PDF or non-supported devices/web mockup
      _simulateMockFile();
    }
  }

  Future<void> _simulateMockFile() async {
    final mockFiles = [
      {'name': 'invoice_rent_phoenix.pdf', 'size': '1.24 MB'},
      {'name': 'aws_receipt_july.png', 'size': '0.85 MB'},
      {'name': 'fuel_bill_hp.jpg', 'size': '2.10 MB'},
      {'name': 'reliance_internet_wifi.pdf', 'size': '3.40 MB'},
    ];
    // Select a random mock file
    final selected = (mockFiles..shuffle()).first;
    
    // Write a temporary mock file to disk
    File? tempFile;
    try {
      final tempDir = await getTemporaryDirectory();
      tempFile = File('${tempDir.path}/${selected['name']}');
      await tempFile.writeAsString('Mock file contents.');
    } catch (e) {
      debugPrint('Failed to create mock file: $e');
    }

    setState(() {
      _fileName = selected['name'];
      _fileSize = selected['size'];
    });
    widget.onFileSelected(selected['name'], selected['size'], tempFile);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Simulated picking document successfully.'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  void _removeFile() {
    setState(() {
      _fileName = null;
      _fileSize = null;
    });
    widget.onFileSelected(null, null, null);
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
            'Upload Invoice / Bill',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.grey[300] : Colors.grey[700],
            ),
          ),
        ),
        if (_fileName != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? theme.colorScheme.surface : const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _fileName!.endsWith('.pdf')
                        ? Icons.picture_as_pdf_rounded
                        : Icons.image_rounded,
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                ),
                AppSpacing.widthM,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _fileName!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _fileSize ?? 'Unknown size',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                  onPressed: _removeFile,
                ),
              ],
            ),
          )
        else
          DragTarget<String>(
            onWillAccept: (_) {
              setState(() => _isDragging = true);
              return true;
            },
            onLeave: (_) {
              setState(() => _isDragging = false);
            },
            onAccept: (_) {
              setState(() => _isDragging = false);
              _simulateMockFile();
            },
            builder: (context, candidateData, rejectedData) {
              return InkWell(
                onTap: _pickFile,
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
                  decoration: BoxDecoration(
                    color: _isDragging
                        ? theme.colorScheme.primary.withOpacity(0.04)
                        : (isDark ? theme.colorScheme.surface : const Color(0xFFF9FAFB)),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                    border: Border.all(
                      color: _isDragging
                          ? theme.colorScheme.primary
                          : (isDark ? AppColors.darkBorder : const Color(0xFFD1D5DB)),
                      width: 1.5,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.cloud_upload_outlined,
                          color: theme.colorScheme.primary,
                          size: 28,
                        ),
                      ),
                      AppSpacing.heightM,
                      Text(
                        'Drag & drop invoice here, or browse',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      AppSpacing.heightXs,
                      Text(
                        'Supported formats: JPG, PNG, PDF (Max ${AppConstants.maxInvoiceFileSizeMB}MB)',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      AppSpacing.heightM,
                      OutlinedButton(
                        onPressed: _pickFile,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        ),
                        child: const Text('Browse File'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
