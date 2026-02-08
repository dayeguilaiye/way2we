import 'package:flutter/material.dart';
import 'package:way2we_app/features/agreement/models/agreement.dart';
import 'package:way2we_app/l10n/l10n.dart';
import 'package:way2we_app/shared/widgets/w2w.dart';
import 'package:way2we_app/theme/theme.dart';

/// Card widget for displaying an agreement in the list
class AgreementCard extends StatelessWidget {
  const AgreementCard({
    required this.agreement,
    this.onTap,
    this.onRecordComplete,
    this.onTogglePin,
    super.key,
  });

  final Agreement agreement;
  final VoidCallback? onTap;
  final VoidCallback? onRecordComplete;
  final VoidCallback? onTogglePin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final pinLabel = agreement.isPinned
        ? l10n.agreementUnpinAction
        : l10n.agreementPinAction;

    void showPinMenu() {
      if (onTogglePin == null) return;

      final isPinned = agreement.isPinned;

      showModalBottomSheet<void>(
        context: context,
        builder: (context) {
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(
                    isPinned ? Icons.push_pin_outlined : Icons.push_pin,
                  ),
                  title: Text(
                    isPinned
                        ? l10n.agreementUnpinAction
                        : l10n.agreementPinAction,
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    onTogglePin?.call();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.close),
                  title: Text(l10n.cancel),
                  onTap: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          );
        },
      );
    }

    return W2WCard(
      variant: agreement.isPinned
          ? W2WCardVariant.pinned
          : W2WCardVariant.standard,
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space4,
        vertical: AppSpacing.space2,
      ),
      onTap: onTap,
      onLongPress: onTogglePin == null ? null : showPinMenu,
      showBorder: !agreement.isActive,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _AgreementCover(agreement: agreement),
              const SizedBox(width: AppSpacing.space3),
              Expanded(
                child: Text(
                  agreement.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: agreement.isActive
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.onSurfaceVariant,
                    decoration: agreement.isActive
                        ? null
                        : TextDecoration.lineThrough,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (onTogglePin != null)
                Semantics(
                  button: true,
                  label: pinLabel,
                  child: IconButton(
                    onPressed: onTogglePin,
                    icon: Icon(
                      agreement.isPinned
                          ? Icons.push_pin
                          : Icons.push_pin_outlined,
                    ),
                    color: agreement.isPinned
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                    tooltip: pinLabel,
                    constraints: const BoxConstraints(
                      minWidth: AppSpacing.minTouchTarget,
                      minHeight: AppSpacing.minTouchTarget,
                    ),
                  ),
                )
              else if (agreement.isPinned)
                Icon(
                  Icons.push_pin,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
              const SizedBox(width: AppSpacing.space2),
              _PointsPill(
                label: l10n.commonPointsDelta(agreement.points),
                isActive: agreement.isActive,
              ),
            ],
          ),
          if (agreement.description != null &&
              agreement.description!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.space2),
            Text(
              agreement.description!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: AppSpacing.space3),
          Row(
            children: [
              Icon(
                Icons.people_outline,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.space1),
              Expanded(
                child: Text(
                  agreement.appliesToAllMembers
                      ? l10n.agreementAllMembers
                      : '${agreement.applicableMemberIds.length} '
                            '${l10n.agreementMembersCount}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (agreement.requireConfirmation)
                W2WStatusBadge(
                  label: l10n.agreementRequiresConfirmation,
                  type: W2WStatusType.awaiting,
                ),
            ],
          ),
          if (agreement.isActive && onRecordComplete != null) ...[
            const Divider(height: AppSpacing.space6),
            Wrap(
              spacing: AppSpacing.space2,
              runSpacing: AppSpacing.space2,
              alignment: WrapAlignment.end,
              children: [
                W2WButton(
                  label: l10n.agreementDetails,
                  variant: W2WButtonVariant.ghost,
                  expanded: false,
                  onPressed: onTap,
                ),
                W2WButton(
                  label: l10n.agreementRecordComplete,
                  icon: Icons.check,
                  expanded: false,
                  onPressed: onRecordComplete,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class AgreementCompactCard extends StatelessWidget {
  const AgreementCompactCard({
    required this.agreement,
    this.onTap,
    super.key,
  });

  final Agreement agreement;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: 220,
      child: W2WCard(
        variant: W2WCardVariant.compact,
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _AgreementCover(agreement: agreement, size: 36, iconSize: 20),
                const Spacer(),
                _PointsPill(
                  label: '+${agreement.points}',
                  isActive: agreement.isActive,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.space3),
            Text(
              agreement.name,
              style: theme.textTheme.titleSmall?.copyWith(
                color: agreement.isActive
                    ? theme.colorScheme.onSurface
                    : theme.colorScheme.onSurfaceVariant,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (agreement.description != null &&
                agreement.description!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.space2),
              Text(
                agreement.description!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AgreementCover extends StatelessWidget {
  const _AgreementCover({
    required this.agreement,
    this.size = AppSpacing.minTouchTarget,
    this.iconSize = 22,
  });

  final Agreement agreement;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: agreement.isActive
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child:
          agreement.coverImageUrl != null && agreement.coverImageUrl!.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              child: Image.network(
                agreement.coverImageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Icon(
                  Icons.assignment_outlined,
                  size: iconSize,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            )
          : Icon(
              Icons.assignment_outlined,
              size: iconSize,
              color: agreement.isActive
                  ? theme.colorScheme.onPrimaryContainer
                  : theme.colorScheme.onSurfaceVariant,
            ),
    );
  }
}

class _PointsPill extends StatelessWidget {
  const _PointsPill({
    required this.label,
    required this.isActive,
  });

  final String label;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space2,
        vertical: AppSpacing.space1,
      ),
      decoration: BoxDecoration(
        color: isActive
            ? theme.colorScheme.primary
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: isActive
              ? theme.colorScheme.onPrimary
              : theme.colorScheme.onSurfaceVariant,
          fontWeight: AppTypography.bold,
        ),
      ),
    );
  }
}
