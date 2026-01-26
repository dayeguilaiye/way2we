import 'package:flutter/material.dart';
import 'package:way2we_app/features/agreement/models/agreement.dart';
import 'package:way2we_app/l10n/l10n.dart';

/// Card widget for displaying an agreement in the list
class AgreementCard extends StatelessWidget {
  const AgreementCard({
    required this.agreement,
    this.onTap,
    this.onRecordComplete,
    super.key,
  });

  final Agreement agreement;
  final VoidCallback? onTap;
  final VoidCallback? onRecordComplete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

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
