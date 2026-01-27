import 'package:flutter/material.dart';
import 'package:way2we_app/features/reward/data/models/reward.dart';

/// Card widget for displaying a reward item.
class RewardCard extends StatelessWidget {
  const RewardCard({
    required this.reward,
    this.onTap,
    this.onToggleStatus,
    this.statusActionLabel,
    this.showActions = false,
    super.key,
  });

  final Reward reward;
  final VoidCallback? onTap;
  final VoidCallback? onToggleStatus;
  final String? statusActionLabel;
  final bool showActions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: reward.isActive
                          ? theme.colorScheme.primaryContainer
                          : theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: reward.coverImageUrl != null &&
                            reward.coverImageUrl!.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              reward.coverImageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Icon(
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
                  ),
                  const SizedBox(width: 12),
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
                        const SizedBox(height: 4),
                        Text(
                          reward.providerNickname?.isNotEmpty == true
                              ? reward.providerNickname!
                              : '—',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: reward.isActive
                          ? theme.colorScheme.primary
                          : theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${reward.costPoints} pts',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: reward.isActive
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              if (reward.description != null &&
                  reward.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
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
                const SizedBox(height: 12),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: onToggleStatus,
                      icon: Icon(
                        reward.isActive
                            ? Icons.pause_circle_outline
                            : Icons.play_circle_outline,
                      ),
                      label: Text(statusActionLabel!),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
