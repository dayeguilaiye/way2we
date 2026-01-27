import 'package:flutter/material.dart';
import 'package:way2we_app/features/agreement/models/agreement.dart';
import 'package:way2we_app/l10n/l10n.dart';

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

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        onLongPress: onTogglePin == null ? null : showPinMenu,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row: name and points
              Row(
                children: [
                  // Cover image or icon
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: agreement.isActive
                          ? theme.colorScheme.primaryContainer
                          : theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: agreement.coverImageUrl != null &&
                            agreement.coverImageUrl!.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              agreement.coverImageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Icon(
                                Icons.assignment_outlined,
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                          )
                        : Icon(
                            Icons.assignment_outlined,
                            color: agreement.isActive
                                ? theme.colorScheme.onPrimaryContainer
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                  ),
                  const SizedBox(width: 12),
                  // Name
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
                    IconButton(
                      onPressed: onTogglePin,
                      icon: Icon(
                        agreement.isPinned
                            ? Icons.push_pin
                            : Icons.push_pin_outlined,
                      ),
                      color: agreement.isPinned
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                      tooltip: agreement.isPinned
                          ? l10n.agreementUnpinAction
                          : l10n.agreementPinAction,
                      visualDensity: VisualDensity.compact,
                    )
                  else if (agreement.isPinned)
                    Icon(
                      Icons.push_pin,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                  // Points badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: agreement.isActive
                          ? theme.colorScheme.primary
                          : theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '+${agreement.points} pts',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: agreement.isActive
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              // Description (if any)
              if (agreement.description != null &&
                  agreement.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  agreement.description!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              // Footer row: applicable members and status
              Row(
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    agreement.appliesToAllMembers
                        ? l10n.agreementAllMembers
                        : '${agreement.applicableMemberIds.length} ${l10n.agreementMembersCount}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  if (agreement.requireConfirmation) ...[
                    Icon(
                      Icons.verified_outlined,
                      size: 16,
                      color: theme.colorScheme.tertiary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      l10n.agreementRequiresConfirmation,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.tertiary,
                      ),
                    ),
                  ],
                ],
              ),
              // Record completion button
              if (agreement.isActive && onRecordComplete != null) ...[
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: onTap,
                      child: Text(l10n.agreementDetails),
                    ),
                    FilledButton.icon(
                      onPressed: onRecordComplete,
                      icon: const Icon(Icons.check, size: 18),
                      label: Text(l10n.agreementRecordComplete),
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
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: agreement.isActive
                            ? theme.colorScheme.primaryContainer
                            : theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.assignment_outlined,
                        color: agreement.isActive
                            ? theme.colorScheme.onPrimaryContainer
                            : theme.colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: agreement.isActive
                            ? theme.colorScheme.primary
                            : theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '+${agreement.points}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: agreement.isActive
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
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
                  const SizedBox(height: 6),
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
        ),
      ),
    );
  }
}
