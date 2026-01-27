import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:way2we_app/features/agreement/bloc/detail/agreement_detail_bloc.dart';
import 'package:way2we_app/features/agreement/data/providers/agreement_provider.dart';
import 'package:way2we_app/features/agreement/models/agreement.dart';
import 'package:way2we_app/features/agreement/view/agreement_error_mapper.dart';
import 'package:way2we_app/features/agreement/view/edit_agreement_page.dart';
import 'package:way2we_app/features/group/bloc/group_control_bloc.dart';
import 'package:way2we_app/l10n/l10n.dart';

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
    final theme = Theme.of(context);

    return BlocListener<AgreementDetailBloc, AgreementDetailState>(
      listener: (context, state) {
        if (state is AgreementStatusUpdateSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.agreementUpdateSuccess),
              backgroundColor: theme.colorScheme.primary,
            ),
          );
        } else if (state is AgreementPinUpdateSuccess) {
          final message = state.isPinned
              ? l10n.agreementPinSuccess
              : l10n.agreementUnpinSuccess;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: theme.colorScheme.primary,
            ),
          );
        } else if (state is AgreementPinUpdateFailure) {
          final message = agreementErrorMessage(context, state.code);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: theme.colorScheme.error,
            ),
          );
        } else if (state is AgreementDetailError) {
          final message = agreementErrorMessage(context, state.code);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: theme.colorScheme.error,
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
              return const Center(child: CircularProgressIndicator());
            }

            if (state is AgreementDetailError) {
              final message = agreementErrorMessage(context, state.code);
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(message),
                  ],
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

    // Only admins or members with permission can edit agreements
    final hasPermission =
        groupState.selectedGroup?.hasPermission('edit_agreement') ?? false;

    if (!hasPermission) return const SizedBox.shrink();

    return IconButton(
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

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Cover image
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: agreement.coverImageUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                agreement.coverImageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Icon(
                                      Icons.assignment_outlined,
                                      color:
                                          theme.colorScheme.onPrimaryContainer,
                                      size: 32,
                                    ),
                              ),
                            )
                          : Icon(
                              Icons.assignment,
                              size: 32,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            agreement.name,
                            style: theme.textTheme.titleLarge,
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: agreement.isActive
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              agreement.isActive
                                  ? l10n.agreementStatusActive
                                  : l10n.agreementStatusInactive,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: agreement.isActive
                                    ? theme.colorScheme.onPrimary
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Points
                    Column(
                      children: [
                        Text(
                          '+${agreement.points}',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'pts',
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
                  const Divider(height: 24),
                  Text(
                    agreement.description!,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Details card
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.people_outline),
                title: Text(l10n.agreementApplicableMembersLabel),
                subtitle: Text(
                  agreement.appliesToAllMembers
                      ? l10n.agreementAllMembers
                      : '${agreement.applicableMemberIds.length} members',
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.verified_outlined),
                title: Text(l10n.agreementRequireConfirmationLabel),
                trailing: Icon(
                  agreement.requireConfirmation
                      ? Icons.check_circle
                      : Icons.cancel,
                  color: agreement.requireConfirmation
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Status toggle button
        _buildStatusButton(context, agreement),
      ],
    );
  }

  Widget _buildStatusButton(BuildContext context, Agreement agreement) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    final groupState = context.read<GroupControlBloc>().state;
    if (groupState is! GroupControlLoadSuccess) return const SizedBox.shrink();

    // Only admins or members with permission can toggle agreement status
    final hasPermission =
        groupState.selectedGroup?.hasPermission('edit_agreement') ?? false;

    if (!hasPermission) return const SizedBox.shrink();

    return BlocBuilder<AgreementDetailBloc, AgreementDetailState>(
      builder: (context, state) {
        final isUpdating = state is AgreementStatusUpdating;

        return agreement.isActive
            ? OutlinedButton.icon(
                onPressed: isUpdating
                    ? null
                    : () {
                        context.read<AgreementDetailBloc>().add(
                          const UpdateAgreementStatus(newStatus: 'inactive'),
                        );
                      },
                icon: isUpdating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.pause_circle_outline),
                label: Text(l10n.agreementDeactivate),
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                ),
              )
            : FilledButton.icon(
                onPressed: isUpdating
                    ? null
                    : () {
                        context.read<AgreementDetailBloc>().add(
                          const UpdateAgreementStatus(newStatus: 'active'),
                        );
                      },
                icon: isUpdating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.play_circle_outline),
                label: Text(l10n.agreementActivate),
              );
      },
    );
  }
}
