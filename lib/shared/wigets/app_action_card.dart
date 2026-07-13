import 'package:flutter/material.dart';

import '../../core/app_constants.dart';

class AppActionCard extends StatelessWidget {
  const AppActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.trailing,
    this.iconBackgroundColor,
    this.iconColor,
    this.contentPadding = AppInsets.actionCard,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Color? iconBackgroundColor;
  final Color? iconColor;
  final EdgeInsetsGeometry contentPadding;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.md),
        onTap: onTap,
        child: Padding(
          padding: contentPadding,
          child: Row(
            children: [
              Container(
                width: AppSizes.actionIconBox,
                height: AppSizes.actionIconBox,
                decoration: BoxDecoration(
                  color: iconBackgroundColor ?? colors.secondaryContainer,
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                child: Icon(
                  icon,
                  color: iconColor ?? colors.onSecondaryContainer,
                ),
              ),
              const SizedBox(width: AppSpacing.item + 2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: AppSpacing.xs - 1),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              trailing ??
                  Icon(AppIcons.chevronRight, color: colors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
