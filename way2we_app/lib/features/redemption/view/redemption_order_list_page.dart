import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:way2we_app/features/redemption/bloc/list/redemption_list_bloc.dart';
import 'package:way2we_app/features/redemption/data/models/redemption_order.dart';
import 'package:way2we_app/features/redemption/data/providers/redemption_provider.dart';
import 'package:way2we_app/features/redemption/view/redemption_order_detail_page.dart';
import 'package:way2we_app/l10n/l10n.dart';
import 'package:way2we_app/theme/theme.dart';

class RedemptionOrderListPage extends StatelessWidget {
  const RedemptionOrderListPage({required this.groupId, super.key});

  final int groupId;

  static Route<void> route({required int groupId}) {
    return MaterialPageRoute<void>(
      builder: (_) => RedemptionOrderListPage(groupId: groupId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => RedemptionListBloc(
        redemptionProvider: context.read<RedemptionProvider>(),
      )..add(LoadOrders(groupId: groupId)),
      child: RedemptionOrderListView(groupId: groupId),
    );
  }
}

class RedemptionOrderListView extends StatefulWidget {
  const RedemptionOrderListView({required this.groupId, super.key});

  final int groupId;

  @override
  State<RedemptionOrderListView> createState() => _RedemptionOrderListViewState();
}

class _RedemptionOrderListViewState extends State<RedemptionOrderListView> {
  final _dateFormat = DateFormat('yyyy-MM-dd HH:mm');

  Future<void> _refresh() async {
    context.read<RedemptionListBloc>().add(const RefreshOrders());
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

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.redemptionOrderTabTitle),
      ),
      body: BlocConsumer<RedemptionListBloc, RedemptionListState>(
        listener: (context, state) {
          if (state is RedemptionListError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          if (state is RedemptionListLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is RedemptionListError) {
            return Center(
              child: Text(state.message, style: theme.textTheme.bodyMedium),
            );
          }
          if (state is RedemptionListReadyState) {
            if (state.orders.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.receipt_long, color: theme.colorScheme.primary),
                    const SizedBox(height: AppSpacing.space2),
                    Text(l10n.redemptionOrderEmptyTitle),
                    const SizedBox(height: AppSpacing.space1),
                    Text(
                      l10n.redemptionOrderEmptySubtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.pagePaddingH),
                itemCount: state.orders.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.space3),
                itemBuilder: (context, index) {
                  final order = state.orders[index];
                  final rewardName = order.rewardName ?? '—';
                  final statusLabel = _statusLabel(context, order.status);
                  final timeLabel = _dateFormat.format(order.createdAt);

                  return InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      Navigator.of(context).push(
                        RedemptionOrderDetailPage.route(
                          groupId: widget.groupId,
                          orderId: order.id,
                        ),
                      );
                    },
                    child: Ink(
                      padding: const EdgeInsets.all(AppSpacing.space3),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: theme.colorScheme.outline),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            rewardName,
                            style: theme.textTheme.titleSmall,
                          ),
                          const SizedBox(height: AppSpacing.space1),
                          Text(
                            '${order.quantity} × ${order.unitCostPoints} pts',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.space2),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Chip(label: Text(statusLabel)),
                              Text(
                                '${order.totalCostPoints} pts',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.space1),
                          Text(
                            timeLabel,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
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
}
