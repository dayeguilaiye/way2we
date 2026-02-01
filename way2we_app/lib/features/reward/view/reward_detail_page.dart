import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:way2we_app/app/di.dart';
import 'package:way2we_app/features/group/bloc/group_control_bloc.dart';
import 'package:way2we_app/features/reward/data/models/reward.dart';
import 'package:way2we_app/features/reward/view/edit_reward_page.dart';
import 'package:way2we_app/features/redemption/bloc/create/redemption_create_bloc.dart';
import 'package:way2we_app/features/redemption/data/models/redemption_order.dart';
import 'package:way2we_app/features/redemption/data/providers/redemption_provider.dart';
import 'package:way2we_app/features/redemption/view/redemption_order_detail_page.dart';
import 'package:way2we_app/l10n/l10n.dart';

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

  Future<void> _navigateToEdit(BuildContext context) async {
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

  Future<void> _showRedeemDialog(BuildContext context) async {
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
    Navigator.of(context).push(
      RedemptionOrderDetailPage.route(
        groupId: widget.groupId,
        orderId: result.id,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final reward = widget.reward;
    final statusLabel =
        reward.isActive ? l10n.rewardStatusActive : l10n.rewardStatusInactive;

    return BlocBuilder<GroupControlBloc, GroupControlState>(
      builder: (context, groupState) {
        final selectedGroup = groupState is GroupControlLoadSuccess
            ? groupState.selectedGroup
            : null;
        final isAdmin = selectedGroup != null &&
                selectedGroup.id == widget.groupId
            ? selectedGroup.isAdmin
            : false;
        final canManage =
            isAdmin || (_currentUserId != null && _currentUserId == reward.providerId);

        return Scaffold(
          appBar: AppBar(
            title: Text(reward.name),
            actions: [
              if (canManage)
                IconButton(
                  icon: const Icon(Icons.edit),
                  tooltip: l10n.rewardEditTitle,
                  onPressed: () => _navigateToEdit(context),
                ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (reward.coverImageUrl != null &&
                  reward.coverImageUrl!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    reward.coverImageUrl!,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 200,
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: const Icon(Icons.image_not_supported_outlined),
                    ),
                  ),
                )
              else
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.card_giftcard_outlined, size: 48),
                ),
              const SizedBox(height: 16),
              Text(
                reward.name,
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 4),
              Text(
                reward.providerNickname?.isNotEmpty == true
                    ? reward.providerNickname!
                    : '—',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  Chip(label: Text('${reward.costPoints} pts')),
                  Chip(label: Text(statusLabel)),
                ],
              ),
              if (reward.description != null &&
                  reward.description!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  l10n.rewardDescriptionLabel,
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  reward.description!,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.rewardAutoFulfillLabel),
                trailing: Icon(
                  reward.autoFulfill ? Icons.check_circle : Icons.cancel_outlined,
                  color: reward.autoFulfill
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.rewardAutoCompleteLabel),
                trailing: Icon(
                  reward.autoComplete ? Icons.check_circle : Icons.cancel_outlined,
                  color: reward.autoComplete
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: reward.isActive
                    ? () => _showRedeemDialog(context)
                    : null,
                child: Text(l10n.redemptionActionRedeem),
              ),
            ],
          ),
        );
      },
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
    } catch (e) {
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
    final isInsufficient =
        _balance != null && _totalCost > (_balance ?? 0);
    final balanceUnavailable = _loadingBalance || _balanceError != null;

    return AlertDialog(
      title: Text(l10n.redemptionActionRedeem),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.reward.name, style: theme.textTheme.titleSmall),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.redemptionOrderQuantityLabel),
              Row(
                children: [
                  IconButton(
                    onPressed: () => _updateQuantity(-1),
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  Text('$_quantity'),
                  IconButton(
                    onPressed: () => _updateQuantity(1),
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.redemptionOrderTotalPointsLabel),
              Text('${_totalCost} pts'),
            ],
          ),
          const SizedBox(height: 8),
          if (_loadingBalance)
            Row(
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 8),
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
              '${l10n.redemptionBalanceLabel}: ${_balance ?? 0} pts',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          if (isInsufficient)
            Padding(
              padding: const EdgeInsets.only(top: 8),
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
                SnackBar(content: Text(state.message ?? l10n.redemptionCreateFailed)),
              );
            }
          },
          builder: (context, state) {
            final isSubmitting =
                state.status == RedemptionCreateStatus.submitting;
            return FilledButton(
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
              child: isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.redemptionConfirmButton),
            );
          },
        ),
      ],
    );
  }
}
