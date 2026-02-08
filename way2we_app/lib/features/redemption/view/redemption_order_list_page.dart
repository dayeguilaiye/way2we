import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:way2we_app/features/redemption/bloc/list/redemption_list_bloc.dart';
import 'package:way2we_app/features/redemption/data/models/redemption_order.dart';
import 'package:way2we_app/features/redemption/data/providers/redemption_provider.dart';
import 'package:way2we_app/features/redemption/view/redemption_order_detail_page.dart';
import 'package:way2we_app/l10n/l10n.dart';
import 'package:way2we_app/shared/widgets/w2w.dart';
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
  State<RedemptionOrderListView> createState() =>
      _RedemptionOrderListViewState();
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
            return _buildLoadingState();
          }
          if (state is RedemptionListError) {
            return W2WEmptyState(
              icon: Icons.error_outline,
              title: state.message,
              actionLabel: l10n.retry,
              onAction: () => context.read<RedemptionListBloc>().add(
                LoadOrders(groupId: widget.groupId),
              ),
            );
          }
          if (state is RedemptionListReadyState) {
            if (state.orders.isEmpty) {
              return W2WEmptyState(
                icon: Icons.receipt_long_outlined,
                title: l10n.redemptionOrderEmptyTitle,
                subtitle: l10n.redemptionOrderEmptySubtitle,
              );
            }

            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.pagePaddingH),
                itemCount: state.orders.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.space3),
                itemBuilder: (context, index) {
                  final order = state.orders[index];
                  final rewardName = order.rewardName ?? '—';
                  final statusLabel = _statusLabel(context, order.status);
                  final statusType = _statusType(order.status);
                  final timeLabel = _dateFormat.format(order.createdAt);

                  return W2WCard(
                    showBorder: true,
                    onTap: () {
                      Navigator.of(context).push(
                        RedemptionOrderDetailPage.route(
                          groupId: widget.groupId,
                          orderId: order.id,
                        ),
                      );
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rewardName,
                          style: theme.textTheme.titleSmall,
                        ),
                        const SizedBox(height: AppSpacing.space1),
                        Text(
                          l10n.commonQuantityTimesPoints(
                            order.quantity,
                            order.unitCostPoints,
                          ),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.space2),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            W2WStatusBadge(
                              label: statusLabel,
                              type: statusType,
                            ),
                            Text(
                              l10n.commonPoints(order.totalCostPoints),
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
              W2WSkeleton(height: 18, width: 200),
              SizedBox(height: AppSpacing.space2),
              W2WSkeleton(height: 14, width: 160),
              SizedBox(height: AppSpacing.space2),
              W2WSkeleton(height: 14, width: 240),
            ],
          ),
        );
      },
    );
  }
}
