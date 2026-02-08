import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:way2we_app/app/di.dart';
import 'package:way2we_app/features/group/bloc/group_control_bloc.dart';
import 'package:way2we_app/features/redemption/bloc/create/redemption_create_bloc.dart';
import 'package:way2we_app/features/redemption/data/models/redemption_order.dart';
import 'package:way2we_app/features/redemption/data/providers/redemption_provider.dart';
import 'package:way2we_app/features/redemption/view/redemption_order_detail_page.dart';
import 'package:way2we_app/features/reward/data/models/reward.dart';
import 'package:way2we_app/features/reward/view/edit_reward_page.dart';
import 'package:way2we_app/l10n/l10n.dart';
import 'package:way2we_app/shared/widgets/w2w.dart';
import 'package:way2we_app/theme/theme.dart';

class RewardDetailPage extends StatefulWidget {
  const RewardDetailPage({
    required this.groupId,
    required this.reward,
    super.key,
  });

  final int groupId;
  final Reward reward;

  static Route<void> route({
    required int groupId,
    required Reward reward,
  }) {
    return MaterialPageRoute<void>(
      builder: (_) => RewardDetailPage(groupId: groupId, reward: reward),
    );
  }

  @override
  State<RewardDetailPage> createState() => _RewardDetailPageState();
}

class _RewardDetailPageState extends State<RewardDetailPage> {
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

  Future<void> _navigateToEdit() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => EditRewardPage(
          groupId: widget.groupId,
          reward: widget.reward,
        ),
      ),
    );
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  Future<void> _showRedeemDialog() async {
    final result = await showDialog<RedemptionOrder>(
      context: context,
      builder: (context) {
        return BlocProvider(
          create: (context) => RedemptionCreateBloc(
            redemptionProvider: context.read<RedemptionProvider>(),
          ),
          child: RedeemDialog(groupId: widget.groupId, reward: widget.reward),
        );
      },
    );

    if (!mounted || result == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.redemptionCreateSuccess)),
    );
    await Navigator.of(context).push(
      RedemptionOrderDetailPage.route(
        groupId: widget.groupId,
        orderId: result.id,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final reward = widget.reward;
    final statusLabel = reward.isActive
        ? l10n.rewardStatusActive
        : l10n.rewardStatusInactive;
    final statusType = reward.isActive
        ? W2WStatusType.completed
        : W2WStatusType.pending;

    return BlocBuilder<GroupControlBloc, GroupControlState>(
      builder: (context, groupState) {
        final selectedGroup = groupState is GroupControlLoadSuccess
            ? groupState.selectedGroup
            : null;
        final isAdmin =
            selectedGroup != null &&
            selectedGroup.id == widget.groupId &&
            selectedGroup.isAdmin;
        final canManage =
            isAdmin ||
            (_currentUserId != null && _currentUserId == reward.providerId);

        return Scaffold(
          appBar: AppBar(
            title: Text(reward.name),
            actions: [
              if (canManage)
                IconButton(
                  icon: const Icon(Icons.edit),
                  tooltip: l10n.rewardEditTitle,
                  constraints: const BoxConstraints(
                    minWidth: AppSpacing.minTouchTarget,
                    minHeight: AppSpacing.minTouchTarget,
                  ),
                  onPressed: _navigateToEdit,
                ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(AppSpacing.pagePaddingH),
            children: [
              W2WCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _RewardCover(coverImageUrl: reward.coverImageUrl),
                    const SizedBox(height: AppSpacing.space4),
                    Text(
                      reward.name,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: AppTypography.bold,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.space1),
                    Text(
                      reward.providerNickname?.isNotEmpty ?? false
                          ? reward.providerNickname!
                          : '—',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space3),
                    Wrap(
                      spacing: AppSpacing.space2,
                      runSpacing: AppSpacing.space2,
                      children: [
                        W2WStatusBadge(
                          label: l10n.commonPoints(reward.costPoints),
                          type: W2WStatusType.awaiting,
                        ),
                        W2WStatusBadge(label: statusLabel, type: statusType),
                      ],
                    ),
                  ],
                ),
              ),
              if (reward.description != null && reward.description!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.space4),
                  child: W2WCard(
                    showBorder: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        W2WSectionHeader(title: l10n.rewardDescriptionLabel),
                        const SizedBox(height: AppSpacing.space2),
                        Text(reward.description!),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: AppSpacing.space4),
              W2WCard(
                showBorder: true,
                child: Column(
                  children: [
                    _BoolSettingRow(
                      title: l10n.rewardAutoFulfillLabel,
                      enabled: reward.autoFulfill,
                    ),
                    const SizedBox(height: AppSpacing.space2),
                    _BoolSettingRow(
                      title: l10n.rewardAutoCompleteLabel,
                      enabled: reward.autoComplete,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.space8),
              W2WButton(
                label: l10n.redemptionActionRedeem,
                icon: Icons.redeem_outlined,
                onPressed: reward.isActive ? _showRedeemDialog : null,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RewardCover extends StatelessWidget {
  const _RewardCover({required this.coverImageUrl});

  final String? coverImageUrl;

  @override
  Widget build(BuildContext context) {
    if (coverImageUrl != null && coverImageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Image.network(
          coverImageUrl!,
          height: 200,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => Container(
            height: 200,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: const Icon(Icons.image_not_supported_outlined),
          ),
        ),
      );
    }
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: const Icon(Icons.card_giftcard_outlined, size: 48),
    );
  }
}

class _BoolSettingRow extends StatelessWidget {
  const _BoolSettingRow({required this.title, required this.enabled});

  final String title;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: AppTypography.medium,
            ),
          ),
        ),
        Icon(
          enabled ? Icons.check_circle : Icons.cancel_outlined,
          color: enabled
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ],
    );
  }
}

class RedeemDialog extends StatefulWidget {
  const RedeemDialog({required this.groupId, required this.reward, super.key});

  final int groupId;
  final Reward reward;

  @override
  State<RedeemDialog> createState() => _RedeemDialogState();
}

class _RedeemDialogState extends State<RedeemDialog> {
  int _quantity = 1;
  int? _balance;
  bool _loadingBalance = true;
  String? _balanceError;

  @override
  void initState() {
    super.initState();
    _fetchBalance();
  }

  int get _totalCost => widget.reward.costPoints * _quantity;

  Future<void> _fetchBalance() async {
    try {
      final dio = ServiceLocator.instance.dio;
      final response = await dio.get<Map<String, dynamic>>(
        '/v1/groups/${widget.groupId}/points/me',
      );
      if (!mounted) return;
      setState(() {
        _balance = (response.data?['balance'] as num?)?.toInt();
        _loadingBalance = false;
      });
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _balanceError = e.toString();
        _loadingBalance = false;
      });
    }
  }

  void _updateQuantity(int delta) {
    final next = _quantity + delta;
    if (next < 1) return;
    setState(() {
      _quantity = next;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isInsufficient = _balance != null && _totalCost > (_balance ?? 0);
    final balanceUnavailable = _loadingBalance || _balanceError != null;

    return AlertDialog(
      title: Text(l10n.redemptionActionRedeem),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.reward.name, style: theme.textTheme.titleSmall),
          const SizedBox(height: AppSpacing.space3),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.redemptionOrderQuantityLabel),
              Row(
                children: [
                  IconButton(
                    tooltip: '${l10n.redemptionOrderQuantityLabel} -',
                    onPressed: () => _updateQuantity(-1),
                    constraints: const BoxConstraints(
                      minWidth: AppSpacing.minTouchTarget,
                      minHeight: AppSpacing.minTouchTarget,
                    ),
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  Text(
                    '$_quantity',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: AppTypography.bold,
                    ),
                  ),
                  IconButton(
                    tooltip: '${l10n.redemptionOrderQuantityLabel} +',
                    onPressed: () => _updateQuantity(1),
                    constraints: const BoxConstraints(
                      minWidth: AppSpacing.minTouchTarget,
                      minHeight: AppSpacing.minTouchTarget,
                    ),
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.redemptionOrderTotalPointsLabel),
              Text(
                l10n.commonPoints(_totalCost),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: AppTypography.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space2),
          if (_loadingBalance)
            Row(
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: AppSpacing.space2),
                Text(l10n.redemptionBalanceLoading),
              ],
            )
          else if (_balanceError != null)
            Text(
              l10n.redemptionBalanceLoadFailed,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            )
          else
            Text(
              '${l10n.redemptionBalanceLabel}: '
              '${l10n.commonPoints(_balance ?? 0)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          if (isInsufficient)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.space2),
              child: Text(
                l10n.redemptionInsufficientPoints,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        BlocConsumer<RedemptionCreateBloc, RedemptionCreateState>(
          listener: (context, state) {
            if (state.status == RedemptionCreateStatus.success &&
                state.order != null) {
              Navigator.of(context).pop(state.order);
            }
            if (state.status == RedemptionCreateStatus.failure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message ?? l10n.redemptionCreateFailed),
                ),
              );
            }
          },
          builder: (context, state) {
            final isSubmitting =
                state.status == RedemptionCreateStatus.submitting;
            return W2WButton(
              label: l10n.redemptionConfirmButton,
              expanded: false,
              isLoading: isSubmitting,
              onPressed: isSubmitting || isInsufficient || balanceUnavailable
                  ? null
                  : () {
                      context.read<RedemptionCreateBloc>().add(
                        SubmitRedemption(
                          groupId: widget.groupId,
                          rewardId: widget.reward.id,
                          quantity: _quantity,
                        ),
                      );
                    },
            );
          },
        ),
      ],
    );
  }
}
