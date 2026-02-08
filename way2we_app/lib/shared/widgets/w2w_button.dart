import 'package:flutter/material.dart';
import 'package:way2we_app/theme/theme.dart';

enum W2WButtonVariant { primary, secondary, ghost, destructive }

class W2WButton extends StatelessWidget {
  const W2WButton({
    required this.label,
    this.onPressed,
    this.variant = W2WButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.expanded = true,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final W2WButtonVariant variant;
  final bool isLoading;
  final IconData? icon;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null && !isLoading;
    final content = _ButtonContent(
      label: label,
      icon: icon,
      isLoading: isLoading,
    );

    final child = switch (variant) {
      W2WButtonVariant.primary => FilledButton(
        onPressed: isEnabled ? onPressed : null,
        child: content,
      ),
      W2WButtonVariant.secondary => TextButton(
        onPressed: isEnabled ? onPressed : null,
        child: content,
      ),
      W2WButtonVariant.ghost => OutlinedButton(
        onPressed: isEnabled ? onPressed : null,
        child: content,
      ),
      W2WButtonVariant.destructive => FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: Theme.of(context).semantic.error,
          foregroundColor: Colors.white,
        ),
        onPressed: isEnabled ? onPressed : null,
        child: content,
      ),
    };

    if (expanded) {
      return SizedBox(width: double.infinity, child: child);
    }
    return child;
  }
}

class _ButtonContent extends StatelessWidget {
  const _ButtonContent({
    required this.label,
    required this.icon,
    required this.isLoading,
  });

  final String label;
  final IconData? icon;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: AppMotion.resolve(context, AppMotion.normal),
      child: isLoading
          ? const SizedBox(
              key: ValueKey('loading'),
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Row(
              key: const ValueKey('content'),
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18),
                  const SizedBox(width: AppSpacing.space2),
                ],
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
    );
  }
}
