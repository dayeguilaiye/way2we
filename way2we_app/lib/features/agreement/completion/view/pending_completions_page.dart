import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:way2we_app/app/di.dart';
import 'package:way2we_app/features/agreement/completion/bloc/pending/pending_completions_bloc.dart';
import 'package:way2we_app/features/agreement/completion/data/providers/agreement_completion_provider.dart';
import 'package:way2we_app/features/agreement/completion/models/agreement_completion.dart';
import 'package:way2we_app/l10n/l10n.dart';

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
                backgroundColor: theme.colorScheme.primary,
              ),
            );
          } else if (state is PendingCompletionsActionFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: theme.colorScheme.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is PendingCompletionsLoading ||
              state is PendingCompletionsInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is PendingCompletionsError) {
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
                  Text(state.message),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => context
                        .read<PendingCompletionsBloc>()
                        .add(const RefreshPendingCompletions()),
                    child: Text(l10n.retry),
                  ),
                ],
              ),
            );
          }

          if (state is PendingCompletionsReadyState) {
            if (state.completions.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.pending_actions,
                      size: 64,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.agreementCompletionPendingEmpty,
                      style: theme.textTheme.titleMedium,
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                context
                    .read<PendingCompletionsBloc>()
                    .add(const RefreshPendingCompletions());
              },
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 12),
                itemCount: state.completions.length,
                separatorBuilder: (_, __) => const SizedBox(height: 4),
                itemBuilder: (context, index) {
                  final completion = state.completions[index];
                  return _PendingCompletionCard(
                    completion: completion,
                    currentUserId: _currentUserId,
                    onConfirm: () => context
                        .read<PendingCompletionsBloc>()
                        .add(ConfirmPendingCompletion(
                          completionId: completion.id,
                        )),
                    onReject: () async {
                      final reason = await _showRejectDialog(context);
                      if (reason == null) return;
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
              onPressed: () => Navigator.of(context).pop(null),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(controller.text.trim()),
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
    final dateText = DateFormat('yyyy-MM-dd HH:mm')
        .format(completion.createdAt.toLocal());
    final isCompleter =
        currentUserId != null && currentUserId == completion.completerId;
    final canConfirm = !isCompleter;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    completion.agreementName ??
                        l10n.agreementCompletionUnknownAgreement,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '+${completion.points}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${l10n.agreementCompletionCompleterLabel} ${completion.completerNickname ?? completion.completerId}',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Text(
              '${l10n.agreementCompletionRecorderLabel} ${completion.recorderNickname ?? completion.recorderId}',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Text(
              '${l10n.agreementCompletionCreatedAtLabel} $dateText',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: onReject,
                  child: Text(l10n.agreementCompletionRejectAction),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: canConfirm ? onConfirm : null,
                  child: Text(l10n.agreementCompletionConfirmAction),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
