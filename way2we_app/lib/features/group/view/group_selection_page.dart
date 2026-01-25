import 'package:flutter/material.dart';
import 'package:way2we_app/features/group/view/create_group_page.dart';
import 'package:way2we_app/features/group/view/join_group_page.dart';
import 'package:way2we_app/l10n/l10n.dart';
import 'package:way2we_app/theme/theme.dart';

/// Page for selecting how to get into a group.
///
/// Users must either create a new group or join an existing one
/// before they can access the main app features.
class GroupSelectionPage extends StatelessWidget {
  const GroupSelectionPage({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(
      builder: (_) => const GroupSelectionPage(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.pagePaddingH),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.space8),

              // Hero illustration
              _buildHeroIllustration(),
              const SizedBox(height: AppSpacing.space6),

              // Title
              Text(
                l10n.groupSelectionTitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: AppTypography.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.space2),

              // Subtitle
              Text(
                l10n.groupSelectionSubtitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textMutedLight,
                ),
              ),
              const SizedBox(height: AppSpacing.space8),

              // Create group card
              _SelectionCard(
                icon: Icons.add_circle_outline,
                title: l10n.groupSelectionCreateTitle,
                subtitle: l10n.groupSelectionCreateSubtitle,
                onTap: () {
                  Navigator.of(context).push(CreateGroupPage.route());
                },
              ),
              const SizedBox(height: AppSpacing.space4),

              // Join group card
              _SelectionCard(
                icon: Icons.group_add_outlined,
                title: l10n.groupSelectionJoinTitle,
                subtitle: l10n.groupSelectionJoinSubtitle,
                onTap: () {
                  Navigator.of(context).push(JoinGroupPage.route());
                },
              ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroIllustration() {
    return Center(
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary.withValues(alpha: 0.1),
              AppColors.primary.withValues(alpha: 0.3),
            ],
          ),
        ),
        child: const Icon(
          Icons.people_outline,
          size: 56,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _SelectionCard extends StatelessWidget {
  const _SelectionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radius),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.space4),
        decoration: BoxDecoration(
          color: AppColors.cardLight,
          borderRadius: BorderRadius.circular(AppSpacing.radius),
          boxShadow: AppShadows.card,
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.1),
              ),
              child: Icon(
                icon,
                color: AppColors.primary,
                size: 28,
              ),
            ),
            const SizedBox(width: AppSpacing.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: AppTypography.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textMutedLight,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.textMutedLight,
            ),
          ],
        ),
      ),
    );
  }
}
