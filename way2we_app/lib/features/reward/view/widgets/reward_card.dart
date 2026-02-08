import 'package:flutter/material.dart';
import 'package:way2we_app/features/reward/data/models/reward.dart';
import 'package:way2we_app/l10n/l10n.dart';
import 'package:way2we_app/shared/widgets/w2w.dart';
import 'package:way2we_app/theme/theme.dart';

/// Card widget for displaying a reward item.
class RewardCard extends StatelessWidget {
  const RewardCard({
    required this.reward,
    this.onTap,
    this.onTogglePin,
    this.onToggleStatus,
    this.statusActionLabel,
    this.showActions = false,
    super.key,
  });

  final Reward reward;
  final VoidCallback? onTap;
  final VoidCallback? onTogglePin;
  final VoidCallback? onToggleStatus;
  final String? statusActionLabel;
  final bool showActions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final pinLabel = reward.isPinned
        ? l10n.rewardUnpinAction
        : l10n.rewardPinAction;

    return W2WCard(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space4,
        vertical: AppSpacing.space2,
      ),
      onTap: onTap,
      onLongPress: onTogglePin,
      showBorder: !reward.isActive,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _RewardCover(reward: reward),
              const SizedBox(width: AppSpacing.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reward.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: reward.isActive
                            ? theme.colorScheme.onSurface
                            : theme.colorScheme.onSurfaceVariant,
                        decoration: reward.isActive
                            ? null
                            : TextDecoration.lineThrough,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.space1),
                    Text(
                      reward.providerNickname?.isNotEmpty ?? false
                          ? reward.providerNickname!
                          : '—',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              _CostPill(
                label: l10n.commonPoints(reward.costPoints),
                isActive: reward.isActive,
              ),
              if (onTogglePin != null) ...[
                const SizedBox(width: AppSpacing.space1),
                Semantics(
                  button: true,
                  label: pinLabel,
                  child: IconButton(
                    onPressed: onTogglePin,
                    icon: Icon(
                      reward.isPinned
                          ? Icons.push_pin
                          : Icons.push_pin_outlined,
                    ),
                    color: reward.isPinned
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                    tooltip: pinLabel,
                    constraints: const BoxConstraints(
                      minWidth: AppSpacing.minTouchTarget,
                      minHeight: AppSpacing.minTouchTarget,
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (reward.description != null && reward.description!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.space2),
            Text(
              reward.description!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (showActions && statusActionLabel != null) ...[
            const SizedBox(height: AppSpacing.space3),
            W2WButton(
              label: statusActionLabel!,
              variant: W2WButtonVariant.secondary,
              expanded: false,
              icon: reward.isActive
                  ? Icons.pause_circle_outline
                  : Icons.play_circle_outline,
              onPressed: onToggleStatus,
            ),
          ],
        ],
      ),
    );
  }
}

class _RewardCover extends StatelessWidget {
  const _RewardCover({required this.reward});

  final Reward reward;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: AppSpacing.minTouchTarget,
      height: AppSpacing.minTouchTarget,
      decoration: BoxDecoration(
        color: reward.isActive
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: reward.coverImageUrl != null && reward.coverImageUrl!.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              child: Image.network(
                reward.coverImageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Icon(
                  Icons.card_giftcard_outlined,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            )
          : Icon(
              Icons.card_giftcard_outlined,
              color: reward.isActive
                  ? theme.colorScheme.onPrimaryContainer
                  : theme.colorScheme.onSurfaceVariant,
            ),
    );
  }
}

class _CostPill extends StatelessWidget {
  const _CostPill({
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
