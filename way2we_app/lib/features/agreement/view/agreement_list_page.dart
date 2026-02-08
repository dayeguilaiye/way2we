import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:way2we_app/features/agreement/bloc/list/agreement_list_bloc.dart';
import 'package:way2we_app/features/agreement/completion/bloc/record/agreement_completion_record_bloc.dart';
import 'package:way2we_app/features/agreement/completion/data/providers/agreement_completion_provider.dart';
import 'package:way2we_app/features/agreement/completion/models/agreement_completion.dart';
import 'package:way2we_app/features/agreement/completion/view/pending_completions_page.dart';
import 'package:way2we_app/features/agreement/data/providers/agreement_provider.dart';
import 'package:way2we_app/features/agreement/models/agreement.dart';
import 'package:way2we_app/features/agreement/view/agreement_detail_page.dart';
import 'package:way2we_app/features/agreement/view/agreement_error_mapper.dart';
import 'package:way2we_app/features/agreement/view/create_agreement_page.dart';
import 'package:way2we_app/features/agreement/view/widgets/agreement_card.dart';
import 'package:way2we_app/features/group/bloc/group_control_bloc.dart';
import 'package:way2we_app/features/group/data/providers/group_provider.dart';
import 'package:way2we_app/features/group/models/member.dart';
import 'package:way2we_app/l10n/l10n.dart';
import 'package:way2we_app/shared/widgets/w2w.dart';
import 'package:way2we_app/theme/theme.dart';

class AgreementListPage extends StatelessWidget {
  const AgreementListPage({
    required this.groupId,
    super.key,
  });

  final int groupId;

  static Route<void> route({required int groupId}) {
    return MaterialPageRoute<void>(
      builder: (_) => AgreementListPage(groupId: groupId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => AgreementListBloc(
            agreementProvider: context.read<AgreementProvider>(),
          )..add(LoadAgreements(groupId: groupId)),
        ),
        BlocProvider(
          create: (context) => AgreementCompletionRecordBloc(
            completionProvider: context.read<AgreementCompletionProvider>(),
          ),
        ),
      ],
      child: AgreementListView(groupId: groupId),
    );
  }
}

class AgreementListView extends StatefulWidget {
  const AgreementListView({
    required this.groupId,
    super.key,
  });

  final int groupId;

  @override
  State<AgreementListView> createState() => _AgreementListViewState();
}

class _AgreementListViewState extends State<AgreementListView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadAgreements() {
    context.read<AgreementListBloc>().add(
      LoadAgreements(groupId: widget.groupId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return BlocListener<
      AgreementCompletionRecordBloc,
      AgreementCompletionRecordState
    >(
      listener: (context, state) {
        if (state is AgreementCompletionRecordSuccess) {
          final message =
              state.completion.status == AgreementCompletionStatus.pending
              ? l10n.agreementCompletionSubmittedMessage
              : l10n.agreementCompletionConfirmedMessage;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: theme.colorScheme.primary,
            ),
          );
          context.read<AgreementCompletionRecordBloc>().add(
            const ResetAgreementCompletionStatus(),
          );
        } else if (state is AgreementCompletionRecordFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: theme.colorScheme.error,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.agreementTabTitle),
          bottom: TabBar(
            controller: _tabController,
            tabs: [
              Tab(text: l10n.agreementStatusActive),
              Tab(text: l10n.agreementStatusInactive),
            ],
          ),
          actions: [
            IconButton(
              tooltip: l10n.agreementCompletionPendingTitle,
              constraints: const BoxConstraints(
                minWidth: AppSpacing.minTouchTarget,
                minHeight: AppSpacing.minTouchTarget,
              ),
              icon: const Icon(Icons.pending_actions),
              onPressed: () => _navigateToPending(context),
            ),
          ],
        ),
        body: BlocConsumer<AgreementListBloc, AgreementListState>(
          listener: (context, state) {
            if (state is AgreementListActionSuccess) {
              final message = state.isPinned
                  ? l10n.agreementPinSuccess
                  : l10n.agreementUnpinSuccess;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(message),
                  backgroundColor: theme.colorScheme.primary,
                ),
              );
            } else if (state is AgreementListActionFailure) {
              final message = agreementErrorMessage(context, state.code);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(message),
                  backgroundColor: theme.colorScheme.error,
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is AgreementListLoading) {
              return _buildLoadingState();
            }

            if (state is AgreementListError) {
              final message = agreementErrorMessage(context, state.code);
              return W2WEmptyState(
                icon: Icons.error_outline,
                title: message,
                actionLabel: l10n.retry,
                onAction: _loadAgreements,
              );
            }

            if (state is AgreementListReadyState) {
              return TabBarView(
                controller: _tabController,
                children: [
                  // Active agreements
                  _buildAgreementList(
                    context,
                    state.activeAgreements,
                    isActive: true,
                  ),
                  // Inactive agreements
                  _buildAgreementList(
                    context,
                    state.inactiveAgreements,
                    isActive: false,
                  ),
                ],
              );
            }

            return const SizedBox.shrink();
          },
        ),
        floatingActionButton: BlocBuilder<GroupControlBloc, GroupControlState>(
          builder: (context, groupState) {
            if (groupState is! GroupControlLoadSuccess) {
              return const SizedBox.shrink();
            }

            // Only admins or members with permission can create agreements
            final hasPermission =
                groupState.selectedGroup?.hasPermission('create_agreement') ??
                false;

            if (!hasPermission) return const SizedBox.shrink();

            return FloatingActionButton.extended(
              onPressed: () => _navigateToCreate(context),
              icon: const Icon(Icons.add),
              label: Text(l10n.agreementCreateButton),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAgreementList(
    BuildContext context,
    List<Agreement> agreements, {
    required bool isActive,
  }) {
    final l10n = context.l10n;

    if (agreements.isEmpty) {
      return W2WEmptyState(
        icon: isActive ? Icons.assignment_outlined : Icons.archive_outlined,
        title: isActive ? l10n.agreementEmptyTitle : l10n.agreementNoInactive,
        subtitle: isActive ? l10n.agreementEmptySubtitle : null,
      );
    }

    final pinnedAgreements = agreements
        .where((agreement) => agreement.isPinned)
        .toList();
    final unpinnedAgreements = agreements
        .where((agreement) => !agreement.isPinned)
        .toList();
    final orderedAgreements = [...pinnedAgreements, ...unpinnedAgreements];

    return RefreshIndicator(
      onRefresh: () async {
        context.read<AgreementListBloc>().add(const RefreshAgreements());
      },
      child: ListView.builder(
        padding: const EdgeInsets.only(
          top: AppSpacing.space2,
          bottom: 80,
        ),
        itemCount: orderedAgreements.length,
        itemBuilder: (context, index) {
          final agreement = orderedAgreements[index];
          return AgreementCard(
            agreement: agreement,
            onTap: () => _navigateToDetail(context, agreement),
            onRecordComplete: isActive
                ? () => _recordComplete(agreement)
                : null,
            onTogglePin: () {
              context.read<AgreementListBloc>().add(
                TogglePinAgreement(
                  agreementId: agreement.id,
                  currentPinStatus: agreement.isPinned,
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.pagePaddingH),
      itemCount: 4,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.space3),
      itemBuilder: (_, _) {
        return const W2WCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              W2WSkeleton(height: 20, width: 180),
              SizedBox(height: AppSpacing.space2),
              W2WSkeleton(height: 14, width: 220),
              SizedBox(height: AppSpacing.space2),
              W2WSkeleton(height: 14, width: 140),
            ],
          ),
        );
      },
    );
  }

  void _navigateToCreate(BuildContext context) {
    final bloc = context.read<AgreementListBloc>();
    Navigator.of(context)
        .push<void>(
          MaterialPageRoute<void>(
            builder: (_) => CreateAgreementPage(groupId: widget.groupId),
          ),
        )
        .then((_) {
          if (mounted) {
            bloc.add(const RefreshAgreements());
          }
        });
  }

  void _navigateToDetail(BuildContext context, Agreement agreement) {
    final bloc = context.read<AgreementListBloc>();
    Navigator.of(context)
        .push<void>(
          MaterialPageRoute<void>(
            builder: (_) => AgreementDetailPage(
              groupId: widget.groupId,
              agreementId: agreement.id,
            ),
          ),
        )
        .then((_) {
          if (mounted) {
            bloc.add(const RefreshAgreements());
          }
        });
  }

  Future<void> _recordComplete(Agreement agreement) async {
    final completerId = await _showRecordDialog(agreement);
    if (completerId == null) return;
    if (!mounted) return;

    final normalizedCompleterId = completerId == -1 ? null : completerId;

    context.read<AgreementCompletionRecordBloc>().add(
      SubmitAgreementCompletion(
        groupId: widget.groupId,
        agreementId: agreement.id,
        completerId: normalizedCompleterId,
      ),
    );
  }

  Future<int?> _showRecordDialog(Agreement agreement) async {
    final l10n = context.l10n;

    final groupState = context.read<GroupControlBloc>().state;
    final canRecordForOthers =
        groupState is GroupControlLoadSuccess &&
        (groupState.selectedGroup?.hasPermission('record_for_others') ?? false);

    final membersFuture = canRecordForOthers
        ? context.read<GroupProvider>().listMembers(groupId: widget.groupId)
        : null;

    var recordForOthers = false;
    int? selectedCompleterId;

    return showDialog<int?>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(l10n.agreementCompletionRecordDialogTitle),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.agreementCompletionRecordDialogMessage),
                  const SizedBox(height: 12),
                  if (agreement.requireConfirmation)
                    Text(
                      l10n.agreementCompletionRequiresConfirmationHint,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  if (canRecordForOthers) ...[
                    const SizedBox(height: 12),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        l10n.agreementCompletionRecordForOthersToggle,
                      ),
                      value: recordForOthers,
                      onChanged: (value) {
                        setState(() {
                          recordForOthers = value;
                          if (!recordForOthers) {
                            selectedCompleterId = null;
                          }
                        });
                      },
                    ),
                    if (recordForOthers && membersFuture != null)
                      FutureBuilder<List<Map<String, dynamic>>>(
                        future: membersFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: LinearProgressIndicator(),
                            );
                          }

                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return Text(l10n.noMembersWarning);
                          }

                          final members = snapshot.data!
                              .map(GroupMember.fromJson)
                              .toList();
                          selectedCompleterId ??= members.first.userId;

                          return DropdownButtonFormField<int>(
                            value: selectedCompleterId,
                            decoration: InputDecoration(
                              labelText: l10n.agreementCompletionRecordForLabel,
                            ),
                            items: members
                                .map(
                                  (member) => DropdownMenuItem<int>(
                                    value: member.userId,
                                    child: Text(member.nickname),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedCompleterId = value;
                              });
                            },
                          );
                        },
                      ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.cancel),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(
                    recordForOthers ? selectedCompleterId : -1,
                  ),
                  child: Text(l10n.confirm),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _navigateToPending(BuildContext context) {
    Navigator.of(context).push<void>(
      PendingCompletionsPage.route(groupId: widget.groupId),
    );
  }
}
