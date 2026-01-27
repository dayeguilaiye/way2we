import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:way2we_app/app/di.dart';
import 'package:way2we_app/features/group/bloc/group_control_bloc.dart';
import 'package:way2we_app/features/reward/data/models/reward.dart';
import 'package:way2we_app/features/reward/view/edit_reward_page.dart';
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
            ],
          ),
        );
      },
    );
  }
}
