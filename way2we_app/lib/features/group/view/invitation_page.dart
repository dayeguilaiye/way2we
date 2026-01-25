import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import 'package:way2we_app/app/di.dart';
import 'package:way2we_app/features/group/bloc/invitation_bloc.dart';
import 'package:way2we_app/features/group/data/providers/group_provider.dart';
import 'package:way2we_app/features/home/view/home_page.dart';
import 'package:way2we_app/l10n/l10n.dart';
import 'package:way2we_app/theme/theme.dart';

/// Page for managing group invitation code.
///
/// Features:
/// - Display current invitation code (formatted for readability)
/// - Copy invitation link to clipboard
/// - Share invitation link via system share
/// - Refresh invitation code (invalidates old code)
class InvitationPage extends StatelessWidget {
  const InvitationPage({
    required this.groupId,
    required this.groupName,
    super.key,
  });

  final int groupId;
  final String groupName;

  static Route<void> route({
    required int groupId,
    required String groupName,
  }) {
    return MaterialPageRoute<void>(
      builder: (_) => InvitationPage(
        groupId: groupId,
        groupName: groupName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dio = ServiceLocator.instance.dio;

    return RepositoryProvider(
      create: (_) => GroupProvider(dio: dio),
      child: BlocProvider(
        create: (context) => InvitationBloc(
          groupProvider: context.read<GroupProvider>(),
          groupId: groupId,
        )..add(const InvitationLoadRequested()),
        child: InvitationView(groupName: groupName),
      ),
    );
  }
}

class InvitationView extends StatelessWidget {
  const InvitationView({required this.groupName, super.key});

  final String groupName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return BlocListener<InvitationBloc, InvitationState>(
      listener: (context, state) {
        if (state.status == InvitationStatus.copied) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.invitationCopied),
              backgroundColor: AppColors.success,
            ),
          );
        } else if (state.status == InvitationStatus.refreshed) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.invitationRefreshed),
              backgroundColor: AppColors.success,
            ),
          );
        } else if (state.status == InvitationStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage ?? l10n.invitationError),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.invitationTitle),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              // Navigate to home, clearing the stack
              Navigator.of(context).pushAndRemoveUntil(
                HomePage.route(),
                (route) => false,
              );
            },
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.pagePaddingH),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.space6),

                // Hero illustration
                _buildHeroIllustration(),
                const SizedBox(height: AppSpacing.space6),

                // Title
                Text(
                  l10n.invitationHeadline,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: AppTypography.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.space2),

                // Subtitle
                Text(
                  l10n.invitationSubtitle(groupName),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textMutedLight,
                  ),
                ),
                const SizedBox(height: AppSpacing.space8),

                // Invitation code display
                _buildInvitationCodeDisplay(context, theme, l10n),
                const SizedBox(height: AppSpacing.space6),

                // Action buttons
                _buildActionButtons(context, theme, l10n),

                const Spacer(),

                // Refresh button
                _buildRefreshButton(context, theme, l10n),
                const SizedBox(height: AppSpacing.space6),
              ],
            ),
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
          Icons.share,
          size: 56,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildInvitationCodeDisplay(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    return BlocBuilder<InvitationBloc, InvitationState>(
      builder: (context, state) {
        if (state.isLoading && !state.hasCode) {
          return Container(
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.cardLight,
              borderRadius: BorderRadius.circular(AppSpacing.radius),
              boxShadow: AppShadows.card,
            ),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.space4,
            horizontal: AppSpacing.space6,
          ),
          decoration: BoxDecoration(
            color: AppColors.cardLight,
            borderRadius: BorderRadius.circular(AppSpacing.radius),
            boxShadow: AppShadows.card,
          ),
          child: Column(
            children: [
              Text(
                l10n.invitationCodeLabel,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.textMutedLight,
                  fontWeight: AppTypography.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: AppSpacing.space2),
              Text(
                state.formattedCode,
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: AppTypography.bold,
                  letterSpacing: 8,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    return BlocBuilder<InvitationBloc, InvitationState>(
      builder: (context, state) {
        return Row(
          children: [
            // Copy button
            Expanded(
              child: _ActionButton(
                icon: Icons.copy,
                label: l10n.invitationCopyButton,
                onPressed: state.hasCode
                    ? () {
                        Clipboard.setData(
                          ClipboardData(text: state.shareUrl),
                        );
                        context
                            .read<InvitationBloc>()
                            .add(const InvitationCopyRequested());
                      }
                    : null,
              ),
            ),
            const SizedBox(width: AppSpacing.space4),
            // Share button
            Expanded(
              child: _ActionButton(
                icon: Icons.share,
                label: l10n.invitationShareButton,
                onPressed: state.hasCode
                    ? () {
                        Share.share(
                          l10n.invitationShareMessage(
                            groupName,
                            state.shareUrl,
                          ),
                        );
                      }
                    : null,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRefreshButton(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    return BlocBuilder<InvitationBloc, InvitationState>(
      builder: (context, state) {
        final isRefreshing = state.status == InvitationStatus.refreshing;

        return TextButton.icon(
          onPressed: state.hasCode && !isRefreshing
              ? () => _showRefreshConfirmation(context, l10n)
              : null,
          icon: isRefreshing
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.refresh),
          label: Text(l10n.invitationRefreshButton),
        );
      },
    );
  }

  void _showRefreshConfirmation(BuildContext context, AppLocalizations l10n) {
    showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.invitationRefreshTitle),
        content: Text(l10n.invitationRefreshMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop(true);
              context
                  .read<InvitationBloc>()
                  .add(const InvitationRefreshRequested());
            },
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: AppSpacing.inputHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        boxShadow: onPressed != null
            ? const [
                BoxShadow(
                  color: AppColors.primaryShadow,
                  blurRadius: 16,
                  offset: Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(label),
        style: FilledButton.styleFrom(
          minimumSize: const Size(double.infinity, AppSpacing.inputHeight),
          textStyle: theme.textTheme.labelLarge,
        ),
      ),
    );
  }
}
