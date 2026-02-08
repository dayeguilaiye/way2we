import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:way2we_app/features/agreement/bloc/detail/agreement_detail_bloc.dart';
import 'package:way2we_app/features/agreement/data/providers/agreement_provider.dart';
import 'package:way2we_app/features/agreement/models/agreement.dart';
import 'package:way2we_app/features/agreement/view/agreement_error_mapper.dart';
import 'package:way2we_app/features/agreement/view/edit_agreement_page.dart';
import 'package:way2we_app/features/group/bloc/group_control_bloc.dart';
import 'package:way2we_app/l10n/l10n.dart';
import 'package:way2we_app/shared/widgets/w2w.dart';
import 'package:way2we_app/theme/theme.dart';

class AgreementDetailPage extends StatelessWidget {
  const AgreementDetailPage({
    required this.groupId,
    required this.agreementId,
    super.key,
  });

  final int groupId;
  final int agreementId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          AgreementDetailBloc(
            agreementProvider: context.read<AgreementProvider>(),
          )..add(
            LoadAgreementDetail(
              groupId: groupId,
              agreementId: agreementId,
            ),
          ),
      child: AgreementDetailView(groupId: groupId),
    );
  }
}

class AgreementDetailView extends StatelessWidget {
  const AgreementDetailView({
    required this.groupId,
    super.key,
  });

  final int groupId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;

    return BlocListener<AgreementDetailBloc, AgreementDetailState>(
      listener: (context, state) {
        if (state is AgreementStatusUpdateSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.agreementUpdateSuccess),
              backgroundColor: colorScheme.primary,
            ),
          );
        } else if (state is AgreementPinUpdateSuccess) {
          final message = state.isPinned
              ? l10n.agreementPinSuccess
              : l10n.agreementUnpinSuccess;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: colorScheme.primary,
            ),
          );
        } else if (state is AgreementPinUpdateFailure) {
          final message = agreementErrorMessage(context, state.code);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: colorScheme.error,
            ),
          );
        } else if (state is AgreementDetailError) {
          final message = agreementErrorMessage(context, state.code);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: colorScheme.error,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.agreementDetails),
          actions: () {
            final state = context.watch<AgreementDetailBloc>().state;
            final agreement = state.agreementOrNull;
            if (agreement == null) {
              return <Widget>[];
            }

            final isPinUpdating = state is AgreementPinUpdating;

            return [
              _buildPinButton(context, agreement, isPinUpdating),
              _buildEditButton(context, agreement),
            ];
          }(),
        ),
        body: BlocBuilder<AgreementDetailBloc, AgreementDetailState>(
          builder: (context, state) {
            if (state is AgreementDetailLoading) {
              return ListView(
                padding: const EdgeInsets.all(AppSpacing.pagePaddingH),
                children: const [
                  W2WSkeleton(height: 150),
                  SizedBox(height: AppSpacing.space4),
                  W2WSkeleton(height: 120),
                  SizedBox(height: AppSpacing.space4),
                  W2WSkeleton(height: 48),
                ],
              );
            }

            if (state is AgreementDetailError) {
              final message = agreementErrorMessage(context, state.code);
              return Center(
                child: W2WEmptyState(
                  icon: Icons.error_outline,
                  title: message,
                ),
              );
            }

            final agreement = state.agreementOrNull;
            if (agreement != null) {
              return _buildContent(context, agreement);
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildPinButton(
    BuildContext context,
    Agreement agreement,
    bool isUpdating,
  ) {
    final theme = Theme.of(context);

    return IconButton(
      tooltip: agreement.isPinned
          ? context.l10n.agreementUnpinAction
          : context.l10n.agreementPinAction,
      constraints: const BoxConstraints(
        minWidth: AppSpacing.minTouchTarget,
        minHeight: AppSpacing.minTouchTarget,
      ),
      onPressed: isUpdating
          ? null
          : () {
              context.read<AgreementDetailBloc>().add(
                TogglePin(currentPinStatus: agreement.isPinned),
              );
            },
      icon: Icon(
        agreement.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
        color: agreement.isPinned ? theme.colorScheme.primary : null,
      ),
    );
  }

  Widget _buildEditButton(BuildContext context, Agreement agreement) {
    final groupState = context.read<GroupControlBloc>().state;
    if (groupState is! GroupControlLoadSuccess) return const SizedBox.shrink();

    final hasPermission =
        groupState.selectedGroup?.hasPermission('edit_agreement') ?? false;

    if (!hasPermission) return const SizedBox.shrink();

    return IconButton(
      tooltip: context.l10n.agreementEditTitle,
      constraints: const BoxConstraints(
        minWidth: AppSpacing.minTouchTarget,
        minHeight: AppSpacing.minTouchTarget,
      ),
      icon: const Icon(Icons.edit),
      onPressed: () {
        Navigator.of(context)
            .push(
              MaterialPageRoute<void>(
                builder: (_) => EditAgreementPage(
                  groupId: groupId,
                  agreement: agreement,
                ),
              ),
            )
            .then((_) {
              if (context.mounted) {
                context.read<AgreementDetailBloc>().add(
                  LoadAgreementDetail(
                    groupId: groupId,
                    agreementId: agreement.id,
                  ),
                );
              }
            });
      },
    );
  }

  Widget _buildContent(BuildContext context, Agreement agreement) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final statusLabel = agreement.isActive
        ? l10n.agreementStatusActive
        : l10n.agreementStatusInactive;
    final statusType = agreement.isActive
        ? W2WStatusType.completed
        : W2WStatusType.pending;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.pagePaddingH),
      children: [
        W2WCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _AgreementCover(coverImageUrl: agreement.coverImageUrl),
                  const SizedBox(width: AppSpacing.space3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          agreement.name,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: AppTypography.bold,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.space1),
                        W2WStatusBadge(label: statusLabel, type: statusType),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.space2),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '+${agreement.points}',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: AppTypography.bold,
                        ),
                      ),
                      Text(
                        l10n.commonPointsUnit,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (agreement.description != null &&
                  agreement.description!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.space4),
                W2WSectionHeader(title: l10n.rewardDescriptionLabel),
                const SizedBox(height: AppSpacing.space2),
                Text(agreement.description!),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.space4),
        W2WCard(
          showBorder: true,
          child: Column(
            children: [
              _DetailRow(
                title: l10n.agreementApplicableMembersLabel,
                value: agreement.appliesToAllMembers
                    ? l10n.agreementAllMembers
                    : '${agreement.applicableMemberIds.length}',
                icon: Icons.people_outline,
              ),
              const SizedBox(height: AppSpacing.space2),
              _DetailRow(
                title: l10n.agreementRequireConfirmationLabel,
                value: agreement.requireConfirmation
                    ? l10n.confirm
                    : l10n.cancel,
                icon: Icons.verified_outlined,
                isPositive: agreement.requireConfirmation,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.space8),
        _buildStatusButton(context, agreement),
      ],
    );
  }

  Widget _buildStatusButton(BuildContext context, Agreement agreement) {
    final l10n = context.l10n;

    final groupState = context.read<GroupControlBloc>().state;
    if (groupState is! GroupControlLoadSuccess) return const SizedBox.shrink();

    final hasPermission =
        groupState.selectedGroup?.hasPermission('edit_agreement') ?? false;

    if (!hasPermission) return const SizedBox.shrink();

    return BlocBuilder<AgreementDetailBloc, AgreementDetailState>(
      builder: (context, state) {
        final isUpdating = state is AgreementStatusUpdating;

        return agreement.isActive
            ? W2WButton(
                label: l10n.agreementDeactivate,
                variant: W2WButtonVariant.destructive,
                icon: Icons.pause_circle_outline,
                isLoading: isUpdating,
                onPressed: () {
                  context.read<AgreementDetailBloc>().add(
                    const UpdateAgreementStatus(newStatus: 'inactive'),
                  );
                },
              )
            : W2WButton(
                label: l10n.agreementActivate,
                icon: Icons.play_circle_outline,
                isLoading: isUpdating,
                onPressed: () {
                  context.read<AgreementDetailBloc>().add(
                    const UpdateAgreementStatus(newStatus: 'active'),
                  );
                },
              );
      },
    );
  }
}

class _AgreementCover extends StatelessWidget {
  const _AgreementCover({required this.coverImageUrl});

  final String? coverImageUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: coverImageUrl != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              child: Image.network(
                coverImageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.assignment_outlined,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  size: 32,
                ),
              ),
            )
          : Icon(
              Icons.assignment,
              size: 32,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.title,
    required this.value,
    required this.icon,
    this.isPositive = false,
  });

  final String title;
  final String value;
  final IconData icon;
  final bool isPositive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: AppSpacing.space2),
        Expanded(child: Text(title)),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isPositive
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
            fontWeight: AppTypography.medium,
          ),
        ),
      ],
    );
  }
}
