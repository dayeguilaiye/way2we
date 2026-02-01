import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:way2we_app/app/di.dart';
import 'package:way2we_app/features/redemption/bloc/detail/redemption_detail_bloc.dart';
import 'package:way2we_app/features/redemption/data/models/redemption_order.dart';
import 'package:way2we_app/features/redemption/data/providers/redemption_provider.dart';
import 'package:way2we_app/l10n/l10n.dart';
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
    final token = await ServiceLocator.instance.storage.read(key: 'auth_token');
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
    } catch (_) {
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

  Future<void> _showUnsatisfiedDialog(BuildContext context) async {
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

    if (result == null) return;
    if (!mounted) return;
    context.read<RedemptionDetailBloc>().add(
      MarkUnsatisfiedRequested(reason: result),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

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
              SnackBar(content: Text('$actionMessage ✅')),
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
            return const Center(child: CircularProgressIndicator());
          }
          if (state is RedemptionDetailError) {
            return Center(child: Text(state.message));
          }
          if (state is RedemptionDetailReadyState) {
            final order = state.order;
            final isProvider = _currentUserId == order.providerId;
            final isConsumer = _currentUserId == order.consumerId;
            final statusLabel = _statusLabel(context, order.status);

            return ListView(
              padding: const EdgeInsets.all(AppSpacing.pagePaddingH),
              children: [
                Text(
                  order.rewardName ?? l10n.redemptionOrderDetailTitle,
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.space2),
                Chip(label: Text(statusLabel)),
                const SizedBox(height: AppSpacing.space4),
                _InfoRow(
                  label: l10n.redemptionOrderQuantityLabel,
                  value: order.quantity.toString(),
                ),
                _InfoRow(
                  label: l10n.redemptionOrderUnitPointsLabel,
                  value: '${order.unitCostPoints} pts',
                ),
                _InfoRow(
                  label: l10n.redemptionOrderTotalPointsLabel,
                  value: '${order.totalCostPoints} pts',
                ),
                _InfoRow(
                  label: l10n.redemptionOrderConsumerLabel,
                  value: order.consumerNickname ?? order.consumerId.toString(),
                ),
                _InfoRow(
                  label: l10n.redemptionOrderProviderLabel,
                  value: order.providerNickname ?? order.providerId.toString(),
                ),
                const SizedBox(height: AppSpacing.space4),
                Text(
                  l10n.redemptionOrderTimelineTitle,
                  style: theme.textTheme.titleSmall,
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
                const SizedBox(height: AppSpacing.space4),
                if (order.isAwaitingFulfill && isProvider)
                  FilledButton(
                    onPressed: () {
                      context.read<RedemptionDetailBloc>().add(
                        const FulfillOrderRequested(),
                      );
                    },
                    child: Text(l10n.redemptionFulfillButton),
                  ),
                if (order.isAwaitingConfirm && isConsumer) ...[
                  FilledButton(
                    onPressed: () {
                      context.read<RedemptionDetailBloc>().add(
                        const ConfirmOrderRequested(),
                      );
                    },
                    child: Text(l10n.redemptionConfirmSatisfiedButton),
                  ),
                  const SizedBox(height: AppSpacing.space2),
                  OutlinedButton(
                    onPressed: () => _showUnsatisfiedDialog(context),
                    child: Text(l10n.redemptionUnsatisfiedButton),
                  ),
                ],
                if (order.unsatisfiedReason != null &&
                    order.unsatisfiedReason!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.space3),
                  Text(
                    l10n.redemptionUnsatisfiedReasonHint,
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: AppSpacing.space1),
                  Text(order.unsatisfiedReason!),
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
          Text(value, style: theme.textTheme.bodyMedium),
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
          const Icon(Icons.circle, size: 8),
          const SizedBox(width: AppSpacing.space2),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(value, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
