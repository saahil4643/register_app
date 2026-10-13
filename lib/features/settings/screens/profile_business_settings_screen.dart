import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/config/env.dart';
import '../../../core/constants/app_colors.dart';
import '../../authentication/providers/auth_provider.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../models/settings_models.dart';
import '../providers/settings_provider.dart';

class ProfileBusinessSettingsScreen extends StatefulWidget {
  const ProfileBusinessSettingsScreen({super.key});

  @override
  State<ProfileBusinessSettingsScreen> createState() => _ProfileBusinessSettingsScreenState();
}

class _ProfileBusinessSettingsScreenState extends State<ProfileBusinessSettingsScreen>
    with SingleTickerProviderStateMixin {
  final _profileFormKey = GlobalKey<FormState>();
  final _businessFormKey = GlobalKey<FormState>();

  late TabController _tabController;

  // Profile controllers
  late TextEditingController _fullNameController;
  late TextEditingController _personalPhoneController;
  late TextEditingController _designationController;
  late TextEditingController _personalEmailController;
  String _selectedAvatar = '👤';
  String _selectedTheme = 'light';

  // Business / Organization controllers
  late TextEditingController _companyNameController;
  late TextEditingController _legalNameController;
  late TextEditingController _businessEmailController;
  late TextEditingController _businessPhoneController;
  late TextEditingController _websiteController;
  late TextEditingController _gstNumberController;
  late TextEditingController _panNumberController;
  late TextEditingController _countryController;
  late TextEditingController _stateController;
  late TextEditingController _cityController;
  late TextEditingController _addressController;
  late TextEditingController _postalCodeController;
  late TextEditingController _timezoneController;

  final List<String> _avatarOptions = [
    '👤', '👨‍💻', '👩‍💻', '🧑‍💼', '🚀', '💼', '⭐', '🎨', '🤖'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    final settingsProvider = context.read<SettingsProvider>();
    final comp = settingsProvider.companySettings;

    final authProvider = context.read<AuthProvider>();
    final initialName = authProvider.currentUserName ??
        '${authProvider.currentUserFirstName ?? ''} ${authProvider.currentUserLastName ?? ''}'.trim();

    _fullNameController = TextEditingController(text: initialName);
    _personalPhoneController = TextEditingController(text: authProvider.currentUserPhone ?? '');
    _designationController = TextEditingController(text: authProvider.currentUserDesignation ?? '');
    _personalEmailController = TextEditingController(text: authProvider.currentUserEmail ?? '');
    _selectedAvatar = authProvider.currentUserAvatar ?? '👤';
    _selectedTheme = authProvider.currentUserTheme ?? 'light';

    _companyNameController = TextEditingController(text: comp?.companyName ?? '');
    _legalNameController = TextEditingController(text: comp?.legalName ?? '');
    _businessEmailController = TextEditingController(text: comp?.email ?? '');
    _businessPhoneController = TextEditingController(text: comp?.phone ?? '');
    _websiteController = TextEditingController(text: comp?.website ?? '');
    _gstNumberController = TextEditingController(text: comp?.gstNumber ?? '');
    _panNumberController = TextEditingController(text: comp?.panNumber ?? '');
    _countryController = TextEditingController(text: comp?.country ?? '');
    _stateController = TextEditingController(text: comp?.state ?? '');
    _cityController = TextEditingController(text: comp?.city ?? '');
    _addressController = TextEditingController(text: comp?.address ?? '');
    _postalCodeController = TextEditingController(text: comp?.postalCode ?? '');
    _timezoneController = TextEditingController(text: comp?.timezone ?? 'UTC');

    // Asynchronously fetch fresh profile and organization data
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = context.read<AuthProvider>();
      final settings = context.read<SettingsProvider>();

      final profileData = await auth.getProfile();
      final orgData = await settings.fetchOrganization();

      if (mounted) {
        if (profileData != null) {
          final name = profileData['name'] ?? profileData['fullName'];
          if (name != null && name.toString().isNotEmpty) {
            _fullNameController.text = name.toString();
          }
          if (profileData['phone'] != null) {
            _personalPhoneController.text = profileData['phone'].toString();
          }
          if (profileData['designation'] != null) {
            _designationController.text = profileData['designation'].toString();
          }
          if (profileData['avatar'] != null) {
            setState(() {
              _selectedAvatar = profileData['avatar'].toString();
            });
          }
          if (profileData['theme'] != null) {
            setState(() {
              _selectedTheme = profileData['theme'].toString();
            });
          }
        }

        if (orgData != null) {
          _companyNameController.text = orgData.companyName;
          _legalNameController.text = orgData.legalName;
          _businessEmailController.text = orgData.email;
          _businessPhoneController.text = orgData.phone;
          _websiteController.text = orgData.website;
          _gstNumberController.text = orgData.gstNumber;
          _panNumberController.text = orgData.panNumber;
          _addressController.text = orgData.address;
          _cityController.text = orgData.city;
          _stateController.text = orgData.state;
          _postalCodeController.text = orgData.postalCode;
          if (orgData.timezone.isNotEmpty) {
            _timezoneController.text = orgData.timezone;
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fullNameController.dispose();
    _personalPhoneController.dispose();
    _designationController.dispose();
    _personalEmailController.dispose();

    _companyNameController.dispose();
    _legalNameController.dispose();
    _businessEmailController.dispose();
    _businessPhoneController.dispose();
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
      final ImageSource? source = await showModalBottomSheet<ImageSource>(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (BuildContext ctx) {
          final theme = Theme.of(ctx);
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
                  onTap: () => Navigator.pop(ctx, ImageSource.gallery),
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt_rounded, color: Colors.green),
                  title: const Text('Take Photo (Camera)'),
                  onTap: () => Navigator.pop(ctx, ImageSource.camera),
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

      if (isProfile) {
        final auth = context.read<AuthProvider>();
        final success = await auth.uploadProfilePicture(image);
        if (mounted) {
          if (success) {
            _showSnackBar('Profile picture updated successfully', isError: false);
          } else {
            _showSnackBar(auth.errorMessage ?? 'Failed to upload profile picture', isError: true);
          }
        }
      } else {
        final settings = context.read<SettingsProvider>();
        final success = await settings.uploadCompanyLogo(image);
        if (mounted) {
          if (success) {
            _showSnackBar('Company logo updated successfully', isError: false);
          } else {
            _showSnackBar(settings.errorMessage ?? 'Failed to upload company logo', isError: true);
          }
        }
      }
    } catch (e) {
      _showSnackBar('Error selecting image: $e', isError: true);
    }
  }

  Future<void> _deleteImage({required bool isProfile}) async {
    try {
      if (isProfile) {
        final auth = context.read<AuthProvider>();
        final success = await auth.deleteProfilePicture();
        if (mounted) {
          if (success) {
            _showSnackBar('Profile picture removed', isError: false);
          } else {
            _showSnackBar(auth.errorMessage ?? 'Failed to remove picture', isError: true);
          }
        }
      } else {
        final settings = context.read<SettingsProvider>();
        final success = await settings.deleteCompanyLogo();
        if (mounted) {
          if (success) {
            _showSnackBar('Company logo removed', isError: false);
          } else {
            _showSnackBar(settings.errorMessage ?? 'Failed to remove logo', isError: true);
          }
        }
      }
    } catch (e) {
      _showSnackBar('Error removing image: $e', isError: true);
    }
  }

  void _showChangePasswordDialog() {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final dialogFormKey = GlobalKey<FormState>();

    bool obscureOld = true;
    bool obscureNew = true;
    bool obscureConfirm = true;
    bool isSubmitting = false;
    String? dialogError;

    showDialog(
      context: context,
      barrierDismissible: !isSubmitting,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final theme = Theme.of(context);

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.lock_reset_rounded, color: theme.colorScheme.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Text('Change Password', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: dialogFormKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (dialogError != null)
                        Container(
                          padding: const EdgeInsets.all(10),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  dialogError!,
                                  style: const TextStyle(color: AppColors.error, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                      TextFormField(
                        controller: oldPasswordController,
                        obscureText: obscureOld,
                        decoration: InputDecoration(
                          labelText: 'Current Password',
                          prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(obscureOld ? Icons.visibility_off : Icons.visibility, size: 20),
                            onPressed: () => setDialogState(() => obscureOld = !obscureOld),
                          ),
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'Enter current password' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: newPasswordController,
                        obscureText: obscureNew,
                        decoration: InputDecoration(
                          labelText: 'New Password',
                          helperText: 'Must be at least 8 characters',
                          prefixIcon: const Icon(Icons.lock_rounded, size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(obscureNew ? Icons.visibility_off : Icons.visibility, size: 20),
                            onPressed: () => setDialogState(() => obscureNew = !obscureNew),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Enter new password';
                          if (v.length < 8) return 'Password must be at least 8 characters long';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: confirmPasswordController,
                        obscureText: obscureConfirm,
                        decoration: InputDecoration(
                          labelText: 'Confirm New Password',
                          prefixIcon: const Icon(Icons.check_circle_outline_rounded, size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(obscureConfirm ? Icons.visibility_off : Icons.visibility, size: 20),
                            onPressed: () => setDialogState(() => obscureConfirm = !obscureConfirm),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Confirm your password';
                          if (v != newPasswordController.text) return 'Passwords do not match';
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (!dialogFormKey.currentState!.validate()) return;
                          setDialogState(() {
                            isSubmitting = true;
                            dialogError = null;
                          });

                          final auth = context.read<AuthProvider>();
                          final success = await auth.changePassword(
                            oldPassword: oldPasswordController.text,
                            newPassword: newPasswordController.text,
                            confirmPassword: confirmPasswordController.text,
                          );

                          if (dialogContext.mounted) {
                            if (success) {
                              Navigator.pop(dialogContext);
                              _showSnackBar('Password changed successfully.', isError: false);
                            } else {
                              setDialogState(() {
                                isSubmitting = false;
                                dialogError = auth.errorMessage ?? 'Failed to change password.';
                              });
                            }
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Update Password'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _saveAll() async {
    final isProfileTab = _tabController.index == 0;
    if (isProfileTab) {
      if (!_profileFormKey.currentState!.validate()) return;
    } else {
      if (!_businessFormKey.currentState!.validate()) return;
    }

    final authProvider = context.read<AuthProvider>();
    final settingsProvider = context.read<SettingsProvider>();

    bool allSuccess = true;

    // Save Profile
    if (_profileFormKey.currentState?.validate() ?? true) {
      final profileSuccess = await authProvider.updateProfile(
        name: _fullNameController.text.trim(),
        phone: _personalPhoneController.text.trim(),
        designation: _designationController.text.trim(),
        avatar: _selectedAvatar,
        theme: _selectedTheme,
        timeZone: _timezoneController.text.trim(),
      );
      if (!profileSuccess) {
        allSuccess = false;
        if (mounted) {
          _showSnackBar(authProvider.errorMessage ?? 'Failed to update personal profile', isError: true);
        }
      }
    }

    // Save Business / Organization
    final updatedOrg = CompanySettings(
      companyName: _companyNameController.text.trim(),
      legalName: _legalNameController.text.trim(),
      website: _websiteController.text.trim(),
      email: _businessEmailController.text.trim(),
      phone: _businessPhoneController.text.trim(),
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
      companyLogo: settingsProvider.companySettings?.companyLogo,
    );

    final orgSuccess = await settingsProvider.updateCompany(updatedOrg);
    if (!orgSuccess) {
      allSuccess = false;
      if (mounted) {
        _showSnackBar(settingsProvider.errorMessage ?? 'Failed to update organization details', isError: true);
      }
    } else {
      if (mounted) {
        context.read<AuthProvider>().updateCompanyName(updatedOrg.companyName);
        context.read<DashboardProvider>().setOrganization(updatedOrg);
      }
    }

    if (mounted && allSuccess) {
      _showSnackBar('Profile & Business details saved successfully', isError: false);
      Navigator.pop(context);
    }
  }

  Widget _buildImageWidget(String? url, IconData placeholderIcon, bool isDark) {
    if (url == null || url.isEmpty) {
      return Center(
        child: Icon(placeholderIcon, size: 40, color: isDark ? Colors.grey[600] : Colors.grey[400]),
      );
    }

    if (url.startsWith('data:image')) {
      try {
        final commaIdx = url.indexOf(',');
        final base64Data = commaIdx != -1 ? url.substring(commaIdx + 1) : url;
        final bytes = base64Decode(base64Data);
        return Image.memory(bytes, fit: BoxFit.cover);
      } catch (_) {
        return Center(
          child: Icon(placeholderIcon, size: 40, color: isDark ? Colors.grey[600] : Colors.grey[400]),
        );
      }
    }

    final fullUrl = url.startsWith('http') ? url : '${Env.apiBaseUrl}$url';
    return Image.network(
      fullUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Center(
          child: Icon(placeholderIcon, size: 40, color: isDark ? Colors.grey[600] : Colors.grey[400]),
        );
      },
    );
  }

  Widget _buildPhotoCard({
    required String title,
    required String? imageUrl,
    required VoidCallback onPick,
    required VoidCallback? onDelete,
    required bool isLoading,
    required IconData placeholderIcon,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        Text(
          title,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.grey[300] : Colors.grey[700],
          ),
        ),
        const SizedBox(height: 10),
        Stack(
          children: [
            Container(
              width: 104,
              height: 104,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(52),
                gradient: LinearGradient(
                  colors: isDark
                      ? [Colors.grey[800]!, Colors.grey[900]!]
                      : [Colors.grey[200]!, Colors.grey[300]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.3),
                  width: 2.5,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(50),
                child: isLoading
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24.0),
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        ),
                      )
                    : _buildImageWidget(imageUrl, placeholderIcon, isDark),
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
                    child: Icon(Icons.camera_alt_rounded, size: 16, color: Colors.white),
                  ),
                ),
              ),
            ),
            if (imageUrl != null && imageUrl.isNotEmpty && onDelete != null)
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
                      child: Icon(Icons.delete_rounded, size: 14, color: Colors.white),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
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
              fontWeight: FontWeight.w600,
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
              color: theme.colorScheme.primary.withValues(alpha: 0.7),
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

  Widget _buildProfileTab(AuthProvider auth) {
    final role = auth.currentUserRole ?? 'Administrator';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _profileFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: _buildPhotoCard(
                title: 'Profile Picture',
                imageUrl: auth.currentUserProfileImage,
                onPick: () => _pickImage(isProfile: true),
                onDelete: auth.currentUserProfileImage != null && auth.currentUserProfileImage!.isNotEmpty
                    ? () => _deleteImage(isProfile: true)
                    : null,
                isLoading: auth.isLoading,
                placeholderIcon: Icons.person_rounded,
              ),
            ),
            const SizedBox(height: 20),

            // Avatar Emoji Selector
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Choose Avatar Emoji',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Text(
                          _selectedAvatar,
                          style: const TextStyle(fontSize: 22),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _avatarOptions.map((emoji) {
                        final isSelected = _selectedAvatar == emoji;
                        return InkWell(
                          onTap: () => setState(() => _selectedAvatar = emoji),
                          borderRadius: BorderRadius.circular(24),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.15)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.grey.withValues(alpha: 0.3),
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Text(emoji, style: const TextStyle(fontSize: 20)),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Profile Details Card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Personal Information',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            role,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildCustomTextField(
                      controller: _fullNameController,
                      label: 'Full Name',
                      hintText: 'John Doe',
                      prefixIcon: Icons.person_outline_rounded,
                      validator: (val) =>
                          val == null || val.trim().isEmpty ? 'Please enter your name' : null,
                    ),
                    const SizedBox(height: 14),
                    _buildCustomTextField(
                      controller: _designationController,
                      label: 'Designation / Title',
                      hintText: 'e.g. Director, Managing Partner',
                      prefixIcon: Icons.badge_outlined,
                    ),
                    const SizedBox(height: 14),
                    _buildCustomTextField(
                      controller: _personalPhoneController,
                      label: 'Phone Number',
                      hintText: '9876543210',
                      prefixIcon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 14),
                    _buildCustomTextField(
                      controller: _personalEmailController,
                      label: 'Account Email',
                      hintText: 'user@example.com',
                      prefixIcon: Icons.email_outlined,
                      isReadOnly: true,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Security & Password Card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
              ),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.lock_reset_rounded, color: Colors.amber, size: 22),
                ),
                title: const Text('Change Password', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                subtitle: const Text('Update your account login password', style: TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: _showChangePasswordDialog,
              ),
            ),
          ],
        ).animate().fade(duration: 200.ms),
      ),
    );
  }

  Widget _buildBusinessTab(SettingsProvider settings) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _businessFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: _buildPhotoCard(
                title: 'Company Logo',
                imageUrl: settings.companySettings?.companyLogo,
                onPick: () => _pickImage(isProfile: false),
                onDelete: settings.companySettings?.companyLogo != null &&
                        settings.companySettings!.companyLogo!.isNotEmpty
                    ? () => _deleteImage(isProfile: false)
                    : null,
                isLoading: settings.isSaving,
                placeholderIcon: Icons.business_rounded,
              ),
            ),
            const SizedBox(height: 20),

            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Company Information',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    _buildCustomTextField(
                      controller: _companyNameController,
                      label: 'Company / Business Name *',
                      hintText: 'Acme Solutions Pvt Ltd',
                      prefixIcon: Icons.business_outlined,
                      validator: (val) =>
                          val == null || val.trim().isEmpty ? 'Company name is required' : null,
                    ),
                    const SizedBox(height: 14),
                    _buildCustomTextField(
                      controller: _legalNameController,
                      label: 'Legal Entity Name',
                      hintText: 'Acme Solutions Private Limited',
                      prefixIcon: Icons.business_center_outlined,
                    ),
                    const SizedBox(height: 14),
                    _buildCustomTextField(
                      controller: _businessEmailController,
                      label: 'Business Email',
                      hintText: 'contact@acme.com',
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 14),
                    _buildCustomTextField(
                      controller: _businessPhoneController,
                      label: 'Business Phone',
                      hintText: '9876543210',
                      prefixIcon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 14),
                    _buildCustomTextField(
                      controller: _websiteController,
                      label: 'Website URL',
                      hintText: 'https://acme.com',
                      prefixIcon: Icons.language_outlined,
                      keyboardType: TextInputType.url,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tax & Registration',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildCustomTextField(
                            controller: _gstNumberController,
                            label: 'GSTIN (Tax ID)',
                            hintText: '27AAPCP6019G1Z5',
                            prefixIcon: Icons.percent_outlined,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildCustomTextField(
                            controller: _panNumberController,
                            label: 'PAN Number',
                            hintText: 'AAPCP6019G',
                            prefixIcon: Icons.card_membership_outlined,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Address & Location',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    _buildCustomTextField(
                      controller: _addressController,
                      label: 'Street Address',
                      hintText: '402 Tech Park, Sector 5',
                      prefixIcon: Icons.location_on_outlined,
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _buildCustomTextField(
                            controller: _cityController,
                            label: 'City',
                            hintText: 'Mumbai',
                            prefixIcon: Icons.location_city_outlined,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildCustomTextField(
                            controller: _stateController,
                            label: 'State',
                            hintText: 'Maharashtra',
                            prefixIcon: Icons.map_outlined,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _buildCustomTextField(
                            controller: _postalCodeController,
                            label: 'Postal Code',
                            hintText: '400001',
                            prefixIcon: Icons.pin_drop_outlined,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildCustomTextField(
                            controller: _countryController,
                            label: 'Country',
                            hintText: 'India',
                            prefixIcon: Icons.public_outlined,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _buildCustomTextField(
                      controller: _timezoneController,
                      label: 'Timezone',
                      hintText: '(GMT+05:30) India Standard Time',
                      prefixIcon: Icons.schedule_outlined,
                      textInputAction: TextInputAction.done,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ).animate().fade(duration: 200.ms),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    final authProvider = context.watch<AuthProvider>();

    final isSaving = settingsProvider.isSaving || authProvider.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile & Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check_rounded),
            tooltip: 'Save',
            onPressed: isSaving ? null : _saveAll,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.person_rounded, size: 20), text: 'My Profile'),
            Tab(icon: Icon(Icons.business_rounded, size: 20), text: 'Organization'),
          ],
        ),
      ),
      body: settingsProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildProfileTab(authProvider),
                _buildBusinessTab(settingsProvider),
              ],
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: ElevatedButton(
            onPressed: isSaving ? null : _saveAll,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: isSaving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                  )
                : const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }
}
