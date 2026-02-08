import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import 'package:way2we_app/app/di.dart';
import 'package:way2we_app/features/group/bloc/invitation_bloc.dart';
import 'package:way2we_app/features/group/data/providers/group_provider.dart';
import 'package:way2we_app/features/home/view/main_shell_page.dart';
import 'package:way2we_app/l10n/l10n.dart';
import 'package:way2we_app/shared/widgets/w2w.dart';
import 'package:way2we_app/theme/theme.dart';

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
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return BlocListener<InvitationBloc, InvitationState>(
      listener: (context, state) {
        if (state.status == InvitationStatus.copied) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.invitationCopied),
              backgroundColor: theme.semantic.success,
            ),
          );
        } else if (state.status == InvitationStatus.refreshed) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.invitationRefreshed),
              backgroundColor: theme.semantic.success,
            ),
          );
        } else if (state.status == InvitationStatus.failure && state.hasCode) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage ?? l10n.invitationError),
              backgroundColor: theme.semantic.error,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.invitationTitle),
          leading: Tooltip(
            message: MaterialLocalizations.of(context).backButtonTooltip,
            child: IconButton(
              constraints: const BoxConstraints(
                minWidth: AppSpacing.minTouchTarget,
                minHeight: AppSpacing.minTouchTarget,
              ),
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MainShellPage.route(),
                  (route) => false,
                );
              },
              icon: const Icon(Icons.arrow_back),
            ),
          ),
        ),
        body: SafeArea(
          child: BlocBuilder<InvitationBloc, InvitationState>(
            builder: (context, state) {
              if (state.status == InvitationStatus.failure && !state.hasCode) {
                return Padding(
                  padding: const EdgeInsets.all(AppSpacing.pagePaddingH),
                  child: W2WEmptyState(
                    icon: Icons.link_off_outlined,
                    title: state.errorMessage ?? l10n.invitationError,
                    actionLabel: l10n.commonRetry,
                    onAction: () {
                      context.read<InvitationBloc>().add(
                        const InvitationLoadRequested(),
                      );
                    },
                  ),
                );
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.pagePaddingH,
                  AppSpacing.pagePaddingV,
                  AppSpacing.pagePaddingH,
                  AppSpacing.pagePaddingV,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppSpacing.space4),
                    const _InvitationHero(),
                    const SizedBox(height: AppSpacing.space6),
                    Text(
                      l10n.invitationHeadline,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: AppTypography.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space2),
                    Text(
                      l10n.invitationSubtitle(groupName),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space8),
                    _InvitationCodeCard(state: state, l10n: l10n),
                    const SizedBox(height: AppSpacing.space6),
                    Row(
                      children: [
                        Expanded(
                          child: W2WButton(
                            label: l10n.invitationCopyButton,
                            variant: W2WButtonVariant.secondary,
                            expanded: false,
                            onPressed: state.hasCode
                                ? () async {
                                    await Clipboard.setData(
                                      ClipboardData(text: state.shareUrl),
                                    );
                                    if (!context.mounted) return;
                                    context.read<InvitationBloc>().add(
                                      const InvitationCopyRequested(),
                                    );
                                  }
                                : null,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.space3),
                        Expanded(
                          child: W2WButton(
                            label: l10n.invitationShareButton,
                            expanded: false,
                            onPressed: state.hasCode
                                ? () async {
                                    await Share.share(
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
                    ),
                    const SizedBox(height: AppSpacing.space6),
                    W2WButton(
                      label: l10n.invitationRefreshButton,
                      icon: Icons.refresh,
                      variant: W2WButtonVariant.ghost,
                      isLoading: state.status == InvitationStatus.refreshing,
                      onPressed:
                          state.hasCode &&
                              state.status != InvitationStatus.refreshing
                          ? () => _showRefreshConfirmation(context, l10n)
                          : null,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _showRefreshConfirmation(BuildContext context, AppLocalizations l10n) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.invitationRefreshTitle),
        content: Text(l10n.invitationRefreshMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<InvitationBloc>().add(
                const InvitationRefreshRequested(),
              );
            },
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
  }
}

class _InvitationHero extends StatelessWidget {
  const _InvitationHero();

  @override
  Widget build(BuildContext context) {
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
          Icons.share_outlined,
          size: 56,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _InvitationCodeCard extends StatelessWidget {
  const _InvitationCodeCard({
    required this.state,
    required this.l10n,
  });

  final InvitationState state;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isInitialLoading =
        !state.hasCode &&
        (state.isLoading || state.status == InvitationStatus.initial);

    return W2WCard(
      showBorder: true,
      child: SizedBox(
        height: 96,
        child: Center(
          child: isInitialLoading
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.space4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      W2WSkeleton(width: 120, height: 12),
                      SizedBox(height: AppSpacing.space2),
                      W2WSkeleton(width: 180, height: 36),
                    ],
                  ),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      l10n.invitationCodeLabel,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: AppTypography.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space1),
                    Text(
                      state.formattedCode,
                      style: theme.textTheme.displaySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: AppTypography.bold,
                        letterSpacing: 6,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
