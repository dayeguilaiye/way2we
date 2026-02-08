import 'package:flutter/material.dart';
import 'package:way2we_app/theme/theme.dart';

enum W2WCardVariant { standard, compact, pinned }

class W2WCard extends StatelessWidget {
  const W2WCard({
    required this.child,
    this.variant = W2WCardVariant.standard,
    this.onTap,
    this.onLongPress,
    this.padding,
    this.margin,
    this.showBorder = false,
    super.key,
  });

  final Widget child;
  final W2WCardVariant variant;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = switch (variant) {
      W2WCardVariant.standard => AppSpacing.radius,
      W2WCardVariant.compact => AppSpacing.radiusLg,
      W2WCardVariant.pinned => AppSpacing.radius,
    };
    final cardPadding =
        padding ??
        switch (variant) {
          W2WCardVariant.standard => const EdgeInsets.all(
            AppSpacing.cardPadding,
          ),
          W2WCardVariant.compact => const EdgeInsets.all(
            AppSpacing.cardPaddingCompact,
          ),
          W2WCardVariant.pinned => const EdgeInsets.all(AppSpacing.cardPadding),
        };

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: AppShadows.card,
      ),
      child: Material(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(radius),
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(radius),
          child: Container(
            padding: cardPadding,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              border: showBorder
                  ? Border.all(color: theme.colorScheme.outline)
                  : null,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
