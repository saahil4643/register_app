import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/config/env.dart';
import '../../../core/constants/app_colors.dart';
import '../../authentication/providers/auth_provider.dart';
import '../models/settings_models.dart';
import '../providers/settings_provider.dart';

class ProfileBusinessSettingsScreen extends StatefulWidget {
  const ProfileBusinessSettingsScreen({super.key});

  @override
  State<ProfileBusinessSettingsScreen> createState() => _ProfileBusinessSettingsScreenState();
}

class _ProfileBusinessSettingsScreenState extends State<ProfileBusinessSettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _fullNameController;
  late TextEditingController _companyNameController;
  late TextEditingController _legalNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _websiteController;
  late TextEditingController _gstNumberController;
  late TextEditingController _panNumberController;
  late TextEditingController _countryController;
  late TextEditingController _stateController;
  late TextEditingController _cityController;
  late TextEditingController _addressController;
  late TextEditingController _postalCodeController;
  late TextEditingController _timezoneController;

  @override
  void initState() {
    super.initState();
    final settingsProvider = context.read<SettingsProvider>();
    final comp = settingsProvider.companySettings;

    final authProvider = context.read<AuthProvider>();
    final firstName = authProvider.currentUserFirstName ?? '';
    final lastName = authProvider.currentUserLastName ?? '';
    
    _fullNameController = TextEditingController(text: '$firstName $lastName'.trim());
    _companyNameController = TextEditingController(text: comp?.companyName ?? '');
    _legalNameController = TextEditingController(text: comp?.legalName ?? '');
    _emailController = TextEditingController(text: authProvider.currentUserEmail ?? comp?.email ?? '');
    _phoneController = TextEditingController(text: comp?.phone ?? '');
    _websiteController = TextEditingController(text: comp?.website ?? '');
    _gstNumberController = TextEditingController(text: comp?.gstNumber ?? '');
    _panNumberController = TextEditingController(text: comp?.panNumber ?? '');
    _countryController = TextEditingController(text: comp?.country ?? '');
    _stateController = TextEditingController(text: comp?.state ?? '');
    _cityController = TextEditingController(text: comp?.city ?? '');
    _addressController = TextEditingController(text: comp?.address ?? '');
    _postalCodeController = TextEditingController(text: comp?.postalCode ?? '');
    _timezoneController = TextEditingController(text: comp?.timezone ?? 'UTC');
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _companyNameController.dispose();
    _legalNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _websiteController.dispose();
    _gstNumberController.dispose();
    _panNumberController.dispose();
    _countryController.dispose();
    _stateController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    _postalCodeController.dispose();
    _timezoneController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _pickImage({required bool isProfile}) async {
    try {
      // 1. Show Modal Bottom Sheet to choose between Camera and Gallery
      final ImageSource? source = await showModalBottomSheet<ImageSource>(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (BuildContext context) {
          final theme = Theme.of(context);
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Text(
                    isProfile ? 'Choose Profile Photo' : 'Choose Company Logo',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.photo_library_rounded, color: Colors.blue),
                  title: const Text('Choose from Gallery'),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt_rounded, color: Colors.green),
                  title: const Text('Take Photo (Camera)'),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
                const SizedBox(height: 8),
              ],
            ),
          );
        },
      );

      if (source == null) return;

      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: source, imageQuality: 85);
      if (image == null) return;

      if (!mounted) return;

      final bytes = await image.readAsBytes();

      // Get initial logo settings
      final settingsProvider = context.read<SettingsProvider>();
      String selectedShape = isProfile ? 'circle' : settingsProvider.logoShape;
      String selectedFit = isProfile ? 'cover' : settingsProvider.logoFit;

      final TransformationController transformationController = TransformationController(
        isProfile ? Matrix4.identity() : settingsProvider.logoMatrix,
      );

      // 2. Show confirmation/edit dialog with live shape, fit & dynamic InteractiveViewer preview
      final bool? confirm = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
            builder: (context, setStateDialog) {
              final theme = Theme.of(context);
              final isDark = theme.brightness == Brightness.dark;

              final double previewWidth = selectedShape == 'rectangle' ? 150 : 100;
              final double previewHeight = 100;
              final fit = selectedFit == 'contain' ? BoxFit.contain : BoxFit.cover;
              final double borderRadiusValue = selectedShape == 'circle' ? (previewWidth / 2) : 8.0;

              return AlertDialog(
                title: Text(
                  isProfile ? 'Confirm Profile Photo' : 'Adjust Logo Layout',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Pinch to zoom and drag to position the logo inside the frame:',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      // Circular / Square / Rectangular Interactive Preview
                      Center(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOut,
                          width: previewWidth,
                          height: previewHeight,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(borderRadiusValue),
                            shape: BoxShape.rectangle, // Always rectangle to avoid animation assertion errors
                            border: Border.all(
                              color: theme.colorScheme.primary.withOpacity(0.4),
                              width: 2,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(borderRadiusValue - 1),
                            child: InteractiveViewer(
                              transformationController: transformationController,
                              minScale: 0.5,
                              maxScale: 5.0,
                              boundaryMargin: const EdgeInsets.all(80),
                              child: Image.memory(
                                bytes,
                                fit: fit,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (!isProfile) ...[
                        // Shape Choice Chips
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Logo Shape:',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: [
                            ChoiceChip(
                              label: const Text('Circle'),
                              selected: selectedShape == 'circle',
                              onSelected: (selected) {
                                if (selected) setStateDialog(() => selectedShape = 'circle');
                              },
                            ),
                            ChoiceChip(
                              label: const Text('Square'),
                              selected: selectedShape == 'square',
                              onSelected: (selected) {
                                if (selected) setStateDialog(() => selectedShape = 'square');
                              },
                            ),
                            ChoiceChip(
                              label: const Text('Rectangle'),
                              selected: selectedShape == 'rectangle',
                              onSelected: (selected) {
                                if (selected) setStateDialog(() => selectedShape = 'rectangle');
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Fit Choice Chips
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Image Fit:',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: [
                            ChoiceChip(
                              label: const Text('Fill (Cover)'),
                              selected: selectedFit == 'cover',
                              onSelected: (selected) {
                                if (selected) setStateDialog(() => selectedFit = 'cover');
                              },
                            ),
                            ChoiceChip(
                              label: const Text('Fit Inside (Contain)'),
                              selected: selectedFit == 'contain',
                              onSelected: (selected) {
                                if (selected) setStateDialog(() => selectedFit = 'contain');
                              },
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Confirm & Save'),
                  ),
                ],
              );
            },
          );
        },
      );

      if (confirm != true) return;
      if (!mounted) return;

      // 3. Save shape, fit and matrix choices to SettingsProvider
      if (!isProfile) {
        await settingsProvider.updateLogoSettings(
          shape: selectedShape,
          fit: selectedFit,
          matrix: transformationController.value,
        );
      }

      if (isProfile) {
        final provider = context.read<AuthProvider>();
        final success = await provider.uploadProfileImage(image);
        if (success) {
          _showSnackBar('Profile image uploaded successfully', isError: false);
        } else {
          final err = provider.errorMessage ?? 'Failed to upload profile image';
          _showSnackBar(err, isError: true);
        }
      } else {
        final provider = context.read<SettingsProvider>();
        final success = await provider.uploadCompanyLogo(image);
        if (success) {
          _showSnackBar('Company logo uploaded successfully', isError: false);
        } else {
          final err = provider.errorMessage ?? 'Failed to upload company logo';
          _showSnackBar(err, isError: true);
        }
      }
    } catch (e) {
      _showSnackBar('Error picking image: $e', isError: true);
    }
  }

  Future<void> _deleteImage({required bool isProfile}) async {
    try {
      if (isProfile) {
        final provider = context.read<AuthProvider>();
        final success = await provider.deleteProfileImage();
        if (success) {
          _showSnackBar('Profile image deleted successfully', isError: false);
        } else {
          final err = provider.errorMessage ?? 'Failed to delete profile image';
          _showSnackBar(err, isError: true);
        }
      } else {
        final provider = context.read<SettingsProvider>();
        final success = await provider.deleteCompanyLogo();
        if (success) {
          _showSnackBar('Company logo deleted successfully', isError: false);
        } else {
          final err = provider.errorMessage ?? 'Failed to delete company logo';
          _showSnackBar(err, isError: true);
        }
      }
    } catch (e) {
      _showSnackBar('Error deleting image: $e', isError: true);
    }
  }

  Widget _buildImagePickerCard({
    required String title,
    required String? imageUrl,
    required VoidCallback onPick,
    required VoidCallback? onDelete,
    required bool isLoading,
    required IconData placeholderIcon,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final settingsProvider = context.read<SettingsProvider>();
    final isLogo = title == 'Company Logo';
    final shape = isLogo ? settingsProvider.logoShape : 'circle';
    final fitStr = isLogo ? settingsProvider.logoFit : 'cover';
    final fit = fitStr == 'contain' ? BoxFit.contain : BoxFit.cover;

    final double width = shape == 'rectangle' ? 140 : 100;
    final double height = 100;

    String? fullImageUrl;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      if (imageUrl.startsWith('http')) {
        fullImageUrl = imageUrl;
      } else {
        fullImageUrl = '${Env.apiBaseUrl}$imageUrl';
      }
    }

    return Column(
      children: [
        Text(
          title,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.grey[300] : Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              width: width,
              height: height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(shape == 'circle' ? (width / 2) : 8.0),
                shape: BoxShape.rectangle, // Always rectangle to avoid animation assertion errors
                gradient: LinearGradient(
                  colors: isDark
                      ? [Colors.grey[800]!, Colors.grey[900]!]
                      : [Colors.grey[200]!, Colors.grey[300]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: theme.colorScheme.primary.withOpacity(0.2),
                  width: 2,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(shape == 'circle' ? (width / 2 - 1) : 6.0),
                child: isLoading
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24.0),
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        ),
                      )
                    : (fullImageUrl != null
                        ? Transform(
                            transform: isLogo ? settingsProvider.getScaledLogoMatrix(height) : Matrix4.identity(),
                            alignment: Alignment.topLeft,
                            child: Image.network(
                              fullImageUrl,
                              fit: fit,
                              errorBuilder: (context, error, stackTrace) {
                                return Center(
                                  child: Icon(
                                    placeholderIcon,
                                    size: 36,
                                    color: isDark ? Colors.grey[600] : Colors.grey[400],
                                  ),
                                );
                              },
                            ),
                          )
                        : Center(
                            child: Icon(
                              placeholderIcon,
                              size: 36,
                              color: isDark ? Colors.grey[600] : Colors.grey[400],
                            ),
                          )),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Material(
                color: theme.colorScheme.primary,
                shape: const CircleBorder(),
                elevation: 4,
                child: InkWell(
                  onTap: isLoading ? null : onPick,
                  customBorder: const CircleBorder(),
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Icon(
                      Icons.camera_alt_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            if (fullImageUrl != null && onDelete != null)
              Positioned(
                top: 0,
                right: 0,
                child: Material(
                  color: AppColors.error,
                  shape: const CircleBorder(),
                  elevation: 4,
                  child: InkWell(
                    onTap: isLoading ? null : onDelete,
                    customBorder: const CircleBorder(),
                    child: const Padding(
                      padding: EdgeInsets.all(6.0),
                      child: Icon(
                        Icons.delete_rounded,
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final settingsProvider = context.read<SettingsProvider>();
    final authProvider = context.read<AuthProvider>();

    final nameParts = _fullNameController.text.trim().split(' ');
    final firstName = nameParts.isNotEmpty ? nameParts.first : '';
    final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

    // Update User Profile
    final profileSuccess = await authProvider.updateUserProfile(
      firstName: firstName,
      lastName: lastName,
      phone: _phoneController.text.trim(),
    );

    if (!profileSuccess) {
      if (mounted) {
        final err = authProvider.errorMessage ?? 'Failed to update user profile';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(err),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    // Update Company Settings
    final updated = CompanySettings(
      companyName: _companyNameController.text.trim(),
      legalName: _legalNameController.text.trim(),
      website: _websiteController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      gstNumber: _gstNumberController.text.trim(),
      panNumber: _panNumberController.text.trim(),
      currency: settingsProvider.companySettings?.currency ?? 'INR',
      timezone: _timezoneController.text.trim(),
      country: _countryController.text.trim(),
      state: _stateController.text.trim(),
      city: _cityController.text.trim(),
      address: _addressController.text.trim(),
      postalCode: _postalCodeController.text.trim(),
      financialYear: settingsProvider.companySettings?.financialYear ?? 'April - March',
      language: settingsProvider.companySettings?.language ?? 'en',
      dateFormat: settingsProvider.companySettings?.dateFormat ?? 'YYYY-MM-DD',
      timeFormat: settingsProvider.companySettings?.timeFormat ?? 'HH:mm:ss',
    );

    final success = await settingsProvider.updateProfile(updated);
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      } else {
        final err = settingsProvider.errorMessage ?? 'Failed to update company settings';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(err),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildCustomTextField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    required IconData prefixIcon,
    bool isReadOnly = false,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction textInputAction = TextInputAction.next,
    String? Function(String?)? validator,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.grey[300] : Colors.grey[700],
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          readOnly: isReadOnly,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          style: const TextStyle(fontSize: 15),
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: Icon(
              prefixIcon,
              size: 20,
              color: theme.colorScheme.primary.withOpacity(0.7),
            ),
            fillColor: isReadOnly
                ? (isDark ? Colors.grey[900] : Colors.grey[100])
                : theme.inputDecorationTheme.fillColor,
          ),
          validator: validator,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    final authProvider = context.watch<AuthProvider>();

    final isSaving = settingsProvider.isSaving || authProvider.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile & Business'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check_rounded),
            onPressed: isSaving ? null : _save,
          ),
        ],
      ),
      body: settingsProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: _buildImagePickerCard(
                        title: 'Company Logo',
                        imageUrl: settingsProvider.companySettings?.companyLogo,
                        onPick: () => _pickImage(isProfile: false),
                        onDelete: settingsProvider.companySettings?.companyLogo != null && settingsProvider.companySettings!.companyLogo!.isNotEmpty
                            ? () => _deleteImage(isProfile: false)
                            : null,
                        isLoading: settingsProvider.isSaving,
                        placeholderIcon: Icons.business_rounded,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Section 1: Account Information (similar to signup page)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Account Details',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 16),
                            _buildCustomTextField(
                              controller: _fullNameController,
                              label: 'Full Name',
                              hintText: 'Enter your full name',
                              prefixIcon: Icons.person_outline_rounded,
                              validator: (val) =>
                                  val == null || val.trim().isEmpty ? 'Please enter your name' : null,
                            ),
                            const SizedBox(height: 16),
                            _buildCustomTextField(
                              controller: _companyNameController,
                              label: 'Business Name',
                              hintText: 'e.g. Prabhim One',
                              prefixIcon: Icons.business_outlined,
                              validator: (val) =>
                                  val == null || val.trim().isEmpty ? 'Please enter your business name' : null,
                            ),
                            const SizedBox(height: 16),
                            _buildCustomTextField(
                              controller: _phoneController,
                              label: 'Phone Number',
                              hintText: 'e.g. +1234567890',
                              prefixIcon: Icons.phone_outlined,
                              keyboardType: TextInputType.phone,
                              validator: (val) =>
                                  val == null || val.trim().isEmpty ? 'Please enter your phone number' : null,
                            ),
                            const SizedBox(height: 16),
                            _buildCustomTextField(
                              controller: _emailController,
                              label: 'Email Address',
                              hintText: 'email@example.com',
                              prefixIcon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              isReadOnly: true,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Section 2: Business Registration & Address
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Business Details & Address',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 16),
                            _buildCustomTextField(
                              controller: _legalNameController,
                              label: 'Legal Entity Name',
                              hintText: 'Legal Name',
                              prefixIcon: Icons.business_center_outlined,
                            ),
                            const SizedBox(height: 16),
                            _buildCustomTextField(
                              controller: _websiteController,
                              label: 'Website URL',
                              hintText: 'https://example.com',
                              prefixIcon: Icons.language_outlined,
                              keyboardType: TextInputType.url,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildCustomTextField(
                                    controller: _gstNumberController,
                                    label: 'GSTIN (Tax ID)',
                                    hintText: 'GSTIN',
                                    prefixIcon: Icons.percent_outlined,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildCustomTextField(
                                    controller: _panNumberController,
                                    label: 'PAN Number',
                                    hintText: 'PAN',
                                    prefixIcon: Icons.card_membership_outlined,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildCustomTextField(
                              controller: _addressController,
                              label: 'Street Address',
                              hintText: 'Address',
                              prefixIcon: Icons.location_on_outlined,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildCustomTextField(
                                    controller: _cityController,
                                    label: 'City',
                                    hintText: 'City',
                                    prefixIcon: Icons.location_city_outlined,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildCustomTextField(
                                    controller: _stateController,
                                    label: 'State',
                                    hintText: 'State',
                                    prefixIcon: Icons.map_outlined,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildCustomTextField(
                                    controller: _postalCodeController,
                                    label: 'Postal Code',
                                    hintText: 'Postal Code',
                                    prefixIcon: Icons.pin_drop_outlined,
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildCustomTextField(
                                    controller: _countryController,
                                    label: 'Country',
                                    hintText: 'Country',
                                    prefixIcon: Icons.public_outlined,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildCustomTextField(
                              controller: _timezoneController,
                              label: 'Timezone *',
                              hintText: 'UTC',
                              prefixIcon: Icons.schedule_outlined,
                              textInputAction: TextInputAction.done,
                              validator: (val) =>
                                  val == null || val.trim().isEmpty ? 'Timezone is required' : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: isSaving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: isSaving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Save Changes'),
                    ),
                  ],
                ).animate().fade(duration: 200.ms),
              ),
            ),
    );
  }
}
