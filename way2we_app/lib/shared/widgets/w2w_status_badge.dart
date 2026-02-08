import 'package:flutter/material.dart';
import 'package:way2we_app/theme/theme.dart';

enum W2WStatusType { pending, completed, awaiting, rejected }

class W2WStatusBadge extends StatelessWidget {
  const W2WStatusBadge({
    required this.label,
    required this.type,
    super.key,
  });

  final String label;
  final W2WStatusType type;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).semantic;
    final (bgColor, textColor) = switch (type) {
      W2WStatusType.pending => (AppColors.primaryTint, AppColors.primaryDark),
      W2WStatusType.completed => (palette.successTint, palette.success),
      W2WStatusType.awaiting => (palette.warningTint, palette.warning),
      W2WStatusType.rejected => (palette.errorTint, palette.error),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space2,
        vertical: AppSpacing.space1,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: textColor,
          fontWeight: AppTypography.bold,
        ),
      ),
    );
  }
}
