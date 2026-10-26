import 'dart:convert';
import 'package:flutter/material.dart';
import '../config/env.dart';
import '../constants/app_colors.dart';

class StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final Color backgroundColor;

  const StatusChip({
    super.key,
    required this.label,
    required this.color,
    required this.backgroundColor,
  });

  // Factory methods for typical ERP statuses
  factory StatusChip.paid({String label = 'Paid'}) {
    return StatusChip(
      label: label,
      color: AppColors.success,
      backgroundColor: const Color(0xFFD1FAE5),
    );
  }

  factory StatusChip.pending({String label = 'Pending'}) {
    return StatusChip(
      label: label,
      color: AppColors.warning,
      backgroundColor: const Color(0xFFFEF3C7),
    );
  }

  factory StatusChip.overdue({String label = 'Overdue'}) {
    return StatusChip(
      label: label,
      color: AppColors.error,
      backgroundColor: const Color(0xFFFEE2E2),
    );
  }

  factory StatusChip.draft({String label = 'Draft'}) {
    return StatusChip(
      label: label,
      color: const Color(0xFF4B5563),
      backgroundColor: const Color(0xFFE5E7EB),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class LoadingSkeleton extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const LoadingSkeleton({
    super.key,
    this.width = double.infinity,
    this.height = 20,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBorder.withValues(alpha: 0.5) : AppColors.lightBorder,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onActionPressed;

  const EmptyState({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    this.actionLabel,
    this.onActionPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight.isFinite ? constraints.maxHeight : 0,
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkPrimaryContainer : AppColors.lightPrimaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        size: 40,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (actionLabel != null && onActionPressed != null) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        width: 180,
                        child: ElevatedButton(
                          onPressed: onActionPressed,
                          child: Text(actionLabel!),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorState({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight.isFinite ? constraints.maxHeight : 0,
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: AppColors.error,
                      size: 44,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Something went wrong',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      message,
                      style: theme.textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    if (onRetry != null) ...[
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: onRetry,
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('Try Again'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(150, 40),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onActionPressed;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onActionPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (actionLabel != null && onActionPressed != null)
            TextButton(
              onPressed: onActionPressed,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(actionLabel!),
            ),
        ],
      ),
    );
  }
}

class CustomAvatar extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double radius;
  final VoidCallback? onTap;

  const CustomAvatar({
    super.key,
    this.imageUrl,
    required this.name,
    this.radius = 20,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final initials = name.isNotEmpty
        ? name.trim().split(' ').map((l) => l.isNotEmpty ? l[0] : '').take(2).join().toUpperCase()
        : 'U';
    final theme = Theme.of(context);

    Widget? content;
    ImageProvider? backgroundImage;

    if (imageUrl != null && imageUrl!.trim().isNotEmpty) {
      final img = imageUrl!.trim();
      if (img.startsWith('http')) {
        backgroundImage = NetworkImage(img);
      } else if (img.startsWith('/api')) {
        backgroundImage = NetworkImage('${Env.apiBaseUrl}$img');
      } else if (img.startsWith('data:image')) {
        try {
          final commaIdx = img.indexOf(',');
          final base64Data = commaIdx != -1 ? img.substring(commaIdx + 1) : img;
          backgroundImage = MemoryImage(base64Decode(base64Data));
        } catch (_) {}
      } else if (img.length <= 4) {
        // Emoji avatar!
        content = Text(img, style: TextStyle(fontSize: radius * 1.05));
      }
    }

    if (backgroundImage == null && content == null) {
      content = Text(
        initials.isNotEmpty ? initials : 'U',
        style: TextStyle(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
          fontSize: radius * 0.8,
        ),
      );
    }

    Widget avatar = CircleAvatar(
      radius: radius,
      backgroundColor: theme.colorScheme.primaryContainer,
      backgroundImage: backgroundImage,
      child: content,
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: avatar,
      );
    }

    return avatar;
  }
}
