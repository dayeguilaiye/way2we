import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:way2we_app/app/di.dart';
import 'package:way2we_app/features/redemption/bloc/detail/redemption_detail_bloc.dart';
import 'package:way2we_app/features/redemption/data/models/redemption_order.dart';
import 'package:way2we_app/features/redemption/data/providers/redemption_provider.dart';
import 'package:way2we_app/l10n/l10n.dart';
import 'package:way2we_app/shared/widgets/w2w.dart';
import 'package:way2we_app/theme/theme.dart';

class RedemptionOrderDetailPage extends StatelessWidget {
  const RedemptionOrderDetailPage({
    required this.groupId,
    required this.orderId,
    super.key,
  });

  final int groupId;
  final int orderId;

  static Route<void> route({required int groupId, required int orderId}) {
    return MaterialPageRoute<void>(
      builder: (_) => RedemptionOrderDetailPage(
        groupId: groupId,
        orderId: orderId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => RedemptionDetailBloc(
        redemptionProvider: context.read<RedemptionProvider>(),
      )..add(LoadOrderDetail(groupId: groupId, orderId: orderId)),
      child: const _RedemptionOrderDetailView(),
    );
  }
}

class _RedemptionOrderDetailView extends StatefulWidget {
  const _RedemptionOrderDetailView();

  @override
  State<_RedemptionOrderDetailView> createState() =>
      _RedemptionOrderDetailViewState();
}

class _RedemptionOrderDetailViewState
    extends State<_RedemptionOrderDetailView> {
  final _dateFormat = DateFormat('yyyy-MM-dd HH:mm');
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserId();
  }

  Future<void> _loadCurrentUserId() async {
    if (!ServiceLocator.instance.isInitialized) return;
    String? token;
    try {
      token = await ServiceLocator.instance.storage.read(key: 'auth_token');
    } on Object {
      return;
    }
    final userId = _decodeUserIdFromToken(token);
    if (!mounted) return;
    setState(() {
      _currentUserId = userId;
    });
  }

  int? _decodeUserIdFromToken(String? token) {
    if (token == null || token.isEmpty) return null;
    final parts = token.split('.');
    if (parts.length < 2) return null;
    try {
      final payload = base64Url.normalize(parts[1]);
      final decoded = utf8.decode(base64Url.decode(payload));
      final data = jsonDecode(decoded) as Map<String, dynamic>;
      return data['user_id'] as int?;
    } on Object {
      return null;
    }
  }

  String _statusLabel(BuildContext context, RedemptionOrderStatus status) {
    final l10n = context.l10n;
    switch (status) {
      case RedemptionOrderStatus.awaitingFulfill:
        return l10n.redemptionStatusAwaitingFulfill;
      case RedemptionOrderStatus.awaitingConfirm:
        return l10n.redemptionStatusAwaitingConfirm;
      case RedemptionOrderStatus.completed:
        return l10n.redemptionStatusCompleted;
      case RedemptionOrderStatus.unsatisfied:
        return l10n.redemptionStatusUnsatisfied;
    }
  }

  W2WStatusType _statusType(RedemptionOrderStatus status) {
    switch (status) {
      case RedemptionOrderStatus.awaitingFulfill:
        return W2WStatusType.awaiting;
      case RedemptionOrderStatus.awaitingConfirm:
        return W2WStatusType.pending;
      case RedemptionOrderStatus.completed:
        return W2WStatusType.completed;
      case RedemptionOrderStatus.unsatisfied:
        return W2WStatusType.rejected;
    }
  }

  Future<void> _showUnsatisfiedDialog() async {
    final l10n = context.l10n;
    final controller = TextEditingController();
    final result = await showDialog<String?>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.redemptionUnsatisfiedButton),
          content: TextField(
            controller: controller,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: l10n.redemptionUnsatisfiedReasonHint,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: Text(MaterialLocalizations.of(context).okButtonLabel),
            ),
          ],
        );
      },
    );

    if (result == null || !mounted) return;
    context.read<RedemptionDetailBloc>().add(
      MarkUnsatisfiedRequested(reason: result),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.redemptionOrderDetailTitle),
      ),
      body: BlocConsumer<RedemptionDetailBloc, RedemptionDetailState>(
        listener: (context, state) {
          if (state is RedemptionDetailActionSuccess) {
            final actionMessage = switch (state.action) {
              RedemptionDetailAction.fulfill => l10n.redemptionFulfillButton,
              RedemptionDetailAction.confirm =>
                l10n.redemptionConfirmSatisfiedButton,
              RedemptionDetailAction.unsatisfied =>
                l10n.redemptionUnsatisfiedButton,
            };
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(actionMessage)),
            );
          } else if (state is RedemptionDetailActionFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          } else if (state is RedemptionDetailError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          if (state is RedemptionDetailLoading ||
              state is RedemptionDetailInitial) {
            return ListView(
              padding: const EdgeInsets.all(AppSpacing.pagePaddingH),
              children: const [
                W2WSkeleton(height: 120),
                SizedBox(height: AppSpacing.space4),
                W2WSkeleton(height: 160),
                SizedBox(height: AppSpacing.space4),
                W2WSkeleton(height: 180),
              ],
            );
          }
          if (state is RedemptionDetailError) {
            return Center(
              child: W2WEmptyState(
                icon: Icons.error_outline,
                title: state.message,
              ),
            );
          }
          if (state is RedemptionDetailReadyState) {
            final order = state.order;
            final isProvider = _currentUserId == order.providerId;
            final isConsumer = _currentUserId == order.consumerId;
            final statusLabel = _statusLabel(context, order.status);
            final statusType = _statusType(order.status);

            return ListView(
              padding: const EdgeInsets.all(AppSpacing.pagePaddingH),
              children: [
                W2WCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.rewardName ?? l10n.redemptionOrderDetailTitle,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: AppTypography.bold,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.space2),
                      W2WStatusBadge(label: statusLabel, type: statusType),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.space4),
                W2WCard(
                  showBorder: true,
                  child: Column(
                    children: [
                      _InfoRow(
                        label: l10n.redemptionOrderQuantityLabel,
                        value: order.quantity.toString(),
                      ),
                      _InfoRow(
                        label: l10n.redemptionOrderUnitPointsLabel,
                        value: l10n.commonPoints(order.unitCostPoints),
                      ),
                      _InfoRow(
                        label: l10n.redemptionOrderTotalPointsLabel,
                        value: l10n.commonPoints(order.totalCostPoints),
                      ),
                      _InfoRow(
                        label: l10n.redemptionOrderConsumerLabel,
                        value:
                            order.consumerNickname ??
                            order.consumerId.toString(),
                      ),
                      _InfoRow(
                        label: l10n.redemptionOrderProviderLabel,
                        value:
                            order.providerNickname ??
                            order.providerId.toString(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.space4),
                W2WCard(
                  showBorder: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      W2WSectionHeader(
                        title: l10n.redemptionOrderTimelineTitle,
                      ),
                      const SizedBox(height: AppSpacing.space2),
                      _TimelineItem(
                        label: l10n.redemptionOrderCreatedAtLabel,
                        value: _dateFormat.format(order.createdAt),
                      ),
                      if (order.fulfilledAt != null)
                        _TimelineItem(
                          label: l10n.redemptionOrderFulfilledAtLabel,
                          value: _dateFormat.format(order.fulfilledAt!),
                        ),
                      if (order.confirmedAt != null)
                        _TimelineItem(
                          label: l10n.redemptionOrderConfirmedAtLabel,
                          value: _dateFormat.format(order.confirmedAt!),
                        ),
                      if (order.endedAt != null)
                        _TimelineItem(
                          label: l10n.redemptionOrderEndedAtLabel,
                          value: _dateFormat.format(order.endedAt!),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.space4),
                if (order.isAwaitingFulfill && isProvider)
                  W2WButton(
                    label: l10n.redemptionFulfillButton,
                    icon: Icons.task_alt_outlined,
                    onPressed: () {
                      context.read<RedemptionDetailBloc>().add(
                        const FulfillOrderRequested(),
                      );
                    },
                  ),
                if (order.isAwaitingConfirm && isConsumer) ...[
                  W2WButton(
                    label: l10n.redemptionConfirmSatisfiedButton,
                    icon: Icons.check_circle_outline,
                    onPressed: () {
                      context.read<RedemptionDetailBloc>().add(
                        const ConfirmOrderRequested(),
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.space2),
                  W2WButton(
                    label: l10n.redemptionUnsatisfiedButton,
                    variant: W2WButtonVariant.ghost,
                    icon: Icons.report_problem_outlined,
                    onPressed: _showUnsatisfiedDialog,
                  ),
                ],
                if (order.unsatisfiedReason != null &&
                    order.unsatisfiedReason!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.space4),
                  W2WCard(
                    showBorder: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.redemptionUnsatisfiedReasonHint,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                fontWeight: AppTypography.bold,
                              ),
                        ),
                        const SizedBox(height: AppSpacing.space2),
                        Text(order.unsatisfiedReason!),
                      ],
                    ),
                  ),
                ],
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.space1),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: AppTypography.medium,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.space1),
      child: Row(
        children: [
          const Icon(
            Icons.circle,
            size: 8,
            color: AppColors.primary,
          ),
          const SizedBox(width: AppSpacing.space2),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: AppTypography.medium,
            ),
          ),
        ],
      ),
    );
  }
}
