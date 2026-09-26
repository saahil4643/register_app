import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/settings_provider.dart';
import '../models/settings_models.dart';

class UsersStaffSettingsScreen extends StatefulWidget {
  const UsersStaffSettingsScreen({super.key});

  @override
  State<UsersStaffSettingsScreen> createState() => _UsersStaffSettingsScreenState();
}

class _UsersStaffSettingsScreenState extends State<UsersStaffSettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SettingsProvider>().fetchStaff();
    });
  }

  Future<void> _showInviteDialog() async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    String role = 'User';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Invite Staff Member'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name *',
                      prefixIcon: Icon(Icons.person_rounded),
                    ),
                    validator: (val) => val == null || val.trim().isEmpty ? 'Enter name' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email Address *',
                      prefixIcon: Icon(Icons.email_rounded),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (val) => val == null || val.trim().isEmpty ? 'Enter email' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      prefixIcon: Icon(Icons.phone_rounded),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: role,
                    decoration: const InputDecoration(
                      labelText: 'Organization Role *',
                      prefixIcon: Icon(Icons.security_rounded),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Admin', child: Text('Admin (Full Access)')),
                      DropdownMenuItem(value: 'Staff', child: Text('Staff (Standard Access)')),
                      DropdownMenuItem(value: 'User', child: Text('User (Read-only Access)')),
                    ],
                    onChanged: (val) {
                      if (val != null) role = val;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(context, true);
                }
              },
              child: const Text('Invite'),
            ),
          ],
        );
      },
    );

    if (confirm == true && mounted) {
      final provider = context.read<SettingsProvider>();
      final success = await provider.inviteStaff(
        nameController.text.trim(),
        emailController.text.trim(),
        role,
        phone: phoneController.text.trim(),
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Staff member invited successfully'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          final err = provider.errorMessage ?? 'Failed to invite staff member';
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
  }

  Future<void> _showEditDialog(StaffUser staff) async {
    String role = staff.role;
    String status = staff.status;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit ${staff.name}'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: role,
                decoration: const InputDecoration(
                  labelText: 'Role',
                  prefixIcon: Icon(Icons.security_rounded),
                ),
                items: const [
                  DropdownMenuItem(value: 'Admin', child: Text('Admin')),
                  DropdownMenuItem(value: 'Staff', child: Text('Staff')),
                  DropdownMenuItem(value: 'User', child: Text('User')),
                ],
                onChanged: (val) {
                  if (val != null) role = val;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: status,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  prefixIcon: Icon(Icons.check_circle_outline_rounded),
                ),
                items: const [
                  DropdownMenuItem(value: 'Active', child: Text('Active')),
                  DropdownMenuItem(value: 'Disabled', child: Text('Disabled')),
                ],
                onChanged: (val) {
                  if (val != null) status = val;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (confirm == true && mounted) {
      final provider = context.read<SettingsProvider>();
      final success = await provider.updateStaff(staff.id, role: role, status: status);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Staff updated successfully'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          final err = provider.errorMessage ?? 'Failed to update staff';
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
  }

  Future<void> _deleteStaffConfirm(StaffUser staff) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Staff Member'),
          content: Text('Are you sure you want to remove "${staff.name}" from the organization?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm == true && mounted) {
      final provider = context.read<SettingsProvider>();
      final success = await provider.deleteStaff(staff.id);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Staff member deleted successfully'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          final err = provider.errorMessage ?? 'Failed to delete staff';
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
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<SettingsProvider>();
    final staffList = provider.staffList;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Users / Staff'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_rounded),
            onPressed: provider.isSaving ? null : _showInviteDialog,
          ),
        ],
      ),
      body: provider.isLoading && staffList.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => provider.fetchStaff(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.supervised_user_circle_rounded, size: 40, color: theme.colorScheme.primary),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Organization Staff Directory', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                SizedBox(height: 4),
                                Text('View and edit access privileges for registered workers.', style: TextStyle(fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Active Members (${staffList.length})',
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        if (provider.isSaving)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    staffList.isEmpty
                        ? Container(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            child: const Center(
                              child: Text('No staff members found. Add some by tapping the icon above.'),
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: staffList.length,
                            separatorBuilder: (_, _) => const Divider(),
                            itemBuilder: (context, index) {
                              final member = staffList[index];
                              final isInactive = member.status.toLowerCase() != 'active';
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: CircleAvatar(
                                  backgroundColor: theme.colorScheme.secondary.withValues(alpha: 0.2),
                                  child: Text(
                                    member.name.isNotEmpty ? member.name[0].toUpperCase() : 'U',
                                    style: TextStyle(color: theme.colorScheme.secondary, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                title: Text(member.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(member.email, style: const TextStyle(fontSize: 12)),
                                    if (member.phone.isNotEmpty)
                                      Text(member.phone, style: const TextStyle(fontSize: 11)),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: theme.dividerColor.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        member.role,
                                        style: TextStyle(fontSize: 10, color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isInactive ? AppColors.error.withValues(alpha: 0.15) : AppColors.success.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        member.status,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isInactive ? AppColors.error : AppColors.success,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    PopupMenuButton<String>(
                                      onSelected: (val) {
                                        if (val == 'edit') {
                                          _showEditDialog(member);
                                        } else if (val == 'delete') {
                                          _deleteStaffConfirm(member);
                                        }
                                      },
                                      itemBuilder: (context) => [
                                        const PopupMenuItem(
                                          value: 'edit',
                                          child: Text('Edit Role/Status'),
                                        ),
                                        const PopupMenuItem(
                                          value: 'delete',
                                          child: Text('Delete Member', style: TextStyle(color: AppColors.error)),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ],
                ).animate().fade(duration: 200.ms),
              ),
            ),
    );
  }
}
