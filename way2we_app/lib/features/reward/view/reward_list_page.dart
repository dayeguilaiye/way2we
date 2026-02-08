import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:way2we_app/app/di.dart';
import 'package:way2we_app/features/group/bloc/group_control_bloc.dart';
import 'package:way2we_app/features/reward/bloc/list/reward_list_bloc.dart';
import 'package:way2we_app/features/reward/data/models/reward.dart';
import 'package:way2we_app/features/reward/data/providers/reward_provider.dart';
import 'package:way2we_app/features/reward/view/create_reward_page.dart';
import 'package:way2we_app/features/reward/view/reward_detail_page.dart';
import 'package:way2we_app/features/reward/view/widgets/reward_card.dart';
import 'package:way2we_app/l10n/l10n.dart';
import 'package:way2we_app/shared/widgets/w2w.dart';
import 'package:way2we_app/theme/theme.dart';

class RewardListPage extends StatelessWidget {
  const RewardListPage({
    required this.groupId,
    super.key,
  });

  final int groupId;

  static Route<void> route({required int groupId}) {
    return MaterialPageRoute<void>(
      builder: (_) => RewardListPage(groupId: groupId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => RewardListBloc(
        rewardProvider: context.read<RewardProvider>(),
      )..add(LoadRewards(groupId: groupId, statusFilter: 'active')),
      child: RewardListView(groupId: groupId),
    );
  }
}

class RewardListView extends StatefulWidget {
  const RewardListView({
    required this.groupId,
    super.key,
  });

  final int groupId;

  @override
  State<RewardListView> createState() => _RewardListViewState();
}

class _RewardListViewState extends State<RewardListView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this)
      ..addListener(_onTabChanged);
    _loadCurrentUserId();
  }

  @override
  void dispose() {
    _tabController
      ..removeListener(_onTabChanged)
      ..dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUserId() async {
    if (!ServiceLocator.instance.isInitialized) return;
    final token = await ServiceLocator.instance.storage.read(key: 'auth_token');

    if (!mounted) return;
    setState(() {
      _currentUserId = _decodeUserIdFromToken(token);
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
    } on Object catch (_) {
      return null;
    }
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    _loadRewardsForTab();
  }

  void _loadRewardsForTab() {
    final status = _tabController.index == 0 ? 'active' : 'inactive';
    context.read<RewardListBloc>().add(
      LoadRewards(groupId: widget.groupId, statusFilter: status),
    );
  }

  Future<void> _navigateToCreate(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CreateRewardPage(groupId: widget.groupId),
      ),
    );
    if (!mounted) return;
    _loadRewardsForTab();
  }

  Future<void> _navigateToDetail(BuildContext context, Reward reward) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            RewardDetailPage(groupId: widget.groupId, reward: reward),
      ),
    );
    if (!mounted) return;
    _loadRewardsForTab();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.rewardTabTitle),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l10n.rewardStatusActive),
            Tab(text: l10n.rewardStatusInactive),
          ],
        ),
      ),
      body: BlocConsumer<RewardListBloc, RewardListState>(
        listener: (context, state) {
          if (state is RewardListActionSuccess) {
            final message = state.updatedStatus == 'inactive'
                ? l10n.rewardDisableSuccess
                : l10n.rewardEnableSuccess;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message),
                backgroundColor: theme.colorScheme.primary,
              ),
            );
          } else if (state is RewardListActionFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: theme.colorScheme.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is RewardListLoading) {
            return _buildLoadingState();
          }

          if (state is RewardListError) {
            return W2WEmptyState(
              icon: Icons.error_outline,
              title: state.message,
              actionLabel: l10n.retry,
              onAction: _loadRewardsForTab,
            );
          }

          if (state is RewardListReadyState) {
            return _buildRewardList(
              context,
              state.rewards,
              state.isActiveFilter,
            );
          }

          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToCreate(context),
        icon: const Icon(Icons.add),
        label: Text(l10n.rewardCreateButton),
      ),
    );
  }

  Widget _buildRewardList(
    BuildContext context,
    List<Reward> rewards,
    bool isActive,
  ) {
    final l10n = context.l10n;

    if (rewards.isEmpty) {
      return W2WEmptyState(
        icon: isActive ? Icons.card_giftcard_outlined : Icons.archive_outlined,
        title: isActive ? l10n.rewardEmptyTitle : l10n.rewardNoInactive,
        subtitle: isActive ? l10n.rewardEmptySubtitle : null,
      );
    }

    return BlocBuilder<GroupControlBloc, GroupControlState>(
      builder: (context, groupState) {
        final selectedGroup = groupState is GroupControlLoadSuccess
            ? groupState.selectedGroup
            : null;
        final isAdmin =
            selectedGroup != null &&
            selectedGroup.id == widget.groupId &&
            selectedGroup.isAdmin;

        return RefreshIndicator(
          onRefresh: () async {
            context.read<RewardListBloc>().add(const RefreshRewards());
          },
          child: ListView.builder(
            padding: const EdgeInsets.only(
              top: AppSpacing.space2,
              bottom: 80,
            ),
            itemCount: rewards.length,
            itemBuilder: (context, index) {
              final reward = rewards[index];
              final canManage =
                  isAdmin ||
                  (_currentUserId != null &&
                      _currentUserId == reward.providerId);
              final statusLabel = reward.isActive
                  ? l10n.rewardDisableAction
                  : l10n.rewardEnableAction;

              return RewardCard(
                reward: reward,
                onTap: () => _navigateToDetail(context, reward),
                onTogglePin: () {
                  context.read<RewardListBloc>().add(
                    reward.isPinned
                        ? UnpinRewardRequested(rewardId: reward.id)
                        : PinRewardRequested(rewardId: reward.id),
                  );
                },
                showActions: canManage,
                statusActionLabel: statusLabel,
                onToggleStatus: canManage
                    ? () {
                        context.read<RewardListBloc>().add(
                          UpdateRewardStatus(
                            rewardId: reward.id,
                            newStatus: reward.isActive ? 'inactive' : 'active',
                          ),
                        );
                      }
                    : null,
              );
            },
          ),
        );
      },
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
              W2WSkeleton(height: 14, width: 160),
              SizedBox(height: AppSpacing.space2),
              W2WSkeleton(height: 14, width: 220),
            ],
          ),
        );
      },
    );
  }
}
