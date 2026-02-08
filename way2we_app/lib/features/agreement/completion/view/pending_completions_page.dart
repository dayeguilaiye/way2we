import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:way2we_app/app/di.dart';
import 'package:way2we_app/features/agreement/completion/bloc/pending/pending_completions_bloc.dart';
import 'package:way2we_app/features/agreement/completion/data/providers/agreement_completion_provider.dart';
import 'package:way2we_app/features/agreement/completion/models/agreement_completion.dart';
import 'package:way2we_app/l10n/l10n.dart';
import 'package:way2we_app/shared/widgets/w2w.dart';
import 'package:way2we_app/theme/theme.dart';

class PendingCompletionsPage extends StatelessWidget {
  const PendingCompletionsPage({required this.groupId, super.key});

  final int groupId;

  static Route<void> route({required int groupId}) {
    return MaterialPageRoute<void>(
      builder: (_) => PendingCompletionsPage(groupId: groupId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PendingCompletionsBloc(
        completionProvider: context.read<AgreementCompletionProvider>(),
      )..add(LoadPendingCompletions(groupId: groupId)),
      child: _PendingCompletionsView(groupId: groupId),
    );
  }
}

class _PendingCompletionsView extends StatefulWidget {
  const _PendingCompletionsView({required this.groupId});

  final int groupId;

  @override
  State<_PendingCompletionsView> createState() =>
      _PendingCompletionsViewState();
}

class _PendingCompletionsViewState extends State<_PendingCompletionsView> {
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserId();
  }

  Future<void> _loadCurrentUserId() async {
    final userId = await ServiceLocator.instance.currentUserRepository
        .getUserId();
    if (!mounted) return;
    setState(() {
      _currentUserId = userId;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.agreementCompletionPendingTitle),
      ),
      body: BlocConsumer<PendingCompletionsBloc, PendingCompletionsState>(
        listener: (context, state) {
          if (state is PendingCompletionsActionSuccess) {
            final message = state.action == PendingCompletionAction.confirm
                ? l10n.agreementCompletionConfirmSuccess
                : l10n.agreementCompletionRejectSuccess;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message),
                backgroundColor: theme.semantic.success,
              ),
            );
          } else if (state is PendingCompletionsActionFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: theme.semantic.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is PendingCompletionsLoading ||
              state is PendingCompletionsInitial) {
            return const _PendingLoadingState();
          }

          if (state is PendingCompletionsError) {
            return W2WEmptyState(
              icon: Icons.error_outline,
              title: state.message,
              actionLabel: l10n.retry,
              onAction: () => context.read<PendingCompletionsBloc>().add(
                const RefreshPendingCompletions(),
              ),
            );
          }

          if (state is PendingCompletionsReadyState) {
            if (state.completions.isEmpty) {
              return W2WEmptyState(
                icon: Icons.pending_actions,
                title: l10n.agreementCompletionPendingEmpty,
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                context.read<PendingCompletionsBloc>().add(
                  const RefreshPendingCompletions(),
                );
              },
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.pagePaddingH,
                  AppSpacing.pagePaddingV,
                  AppSpacing.pagePaddingH,
                  AppSpacing.pagePaddingV,
                ),
                itemCount: state.completions.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final completion = state.completions[index];
                  return _PendingCompletionCard(
                    completion: completion,
                    currentUserId: _currentUserId,
                    onConfirm: () => context.read<PendingCompletionsBloc>().add(
                      ConfirmPendingCompletion(
                        completionId: completion.id,
                      ),
                    ),
                    onReject: () async {
                      final reason = await _showRejectDialog(context);
                      if (reason == null) return;
                      if (!context.mounted) return;
                      context.read<PendingCompletionsBloc>().add(
                        RejectPendingCompletion(
                          completionId: completion.id,
                          reason: reason,
                        ),
                      );
                    },
                  );
                },
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Future<String?> _showRejectDialog(BuildContext context) async {
    final l10n = context.l10n;
    final controller = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.agreementCompletionRejectAction),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: l10n.agreementCompletionRejectReasonHint,
            ),
            maxLength: 200,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(context).pop(controller.text.trim()),
              child: Text(l10n.confirm),
            ),
          ],
        );
      },
    );

    controller.dispose();
    return result;
  }
}

class _PendingCompletionCard extends StatelessWidget {
  const _PendingCompletionCard({
    required this.completion,
    required this.onConfirm,
    required this.onReject,
    required this.currentUserId,
  });

  final AgreementCompletion completion;
  final VoidCallback onConfirm;
  final VoidCallback onReject;
  final int? currentUserId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final dateText = DateFormat(
      'yyyy-MM-dd HH:mm',
    ).format(completion.createdAt.toLocal());
    final isCompleter =
        currentUserId != null && currentUserId == completion.completerId;
    final canConfirm = !isCompleter;

    return W2WCard(
      showBorder: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  completion.agreementName ??
                      l10n.agreementCompletionUnknownAgreement,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: AppTypography.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space2,
                  vertical: AppSpacing.space1,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
                child: Text(
                  '+${completion.points}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: AppTypography.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space2),
          Text(
            '${l10n.agreementCompletionCompleterLabel} '
            '${completion.completerNickname ?? completion.completerId}',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.space1),
          Text(
            '${l10n.agreementCompletionRecorderLabel} '
            '${completion.recorderNickname ?? completion.recorderId}',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.space1),
          Text(
            '${l10n.agreementCompletionCreatedAtLabel} $dateText',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.space3),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              W2WButton(
                label: l10n.agreementCompletionRejectAction,
                variant: W2WButtonVariant.secondary,
                expanded: false,
                onPressed: onReject,
              ),
              const SizedBox(width: AppSpacing.space2),
              W2WButton(
                label: l10n.agreementCompletionConfirmAction,
                expanded: false,
                onPressed: canConfirm ? onConfirm : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PendingLoadingState extends StatelessWidget {
  const _PendingLoadingState();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pagePaddingH,
        AppSpacing.pagePaddingV,
        AppSpacing.pagePaddingH,
        AppSpacing.pagePaddingV,
      ),
      itemBuilder: (_, _) => const W2WCard(
        showBorder: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            W2WSkeleton(width: 180),
            SizedBox(height: AppSpacing.space2),
            W2WSkeleton(width: 220, height: 12),
            SizedBox(height: AppSpacing.space1),
            W2WSkeleton(width: 220, height: 12),
            SizedBox(height: AppSpacing.space3),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                W2WSkeleton(width: 90, height: AppSpacing.inputHeight),
                SizedBox(width: AppSpacing.space2),
                W2WSkeleton(width: 110, height: AppSpacing.inputHeight),
              ],
            ),
          ],
        ),
      ),
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemCount: 4,
    );
  }
}
