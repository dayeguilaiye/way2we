import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:way2we_app/features/group/bloc/members/group_members_bloc.dart';
import 'package:way2we_app/features/group/data/providers/group_provider.dart';
import 'package:way2we_app/features/group/models/member.dart';
import 'package:way2we_app/features/group/view/member_detail_page.dart';
import 'package:way2we_app/l10n/l10n.dart';
import 'package:way2we_app/shared/widgets/w2w.dart';
import 'package:way2we_app/theme/theme.dart';

class MemberManagementPage extends StatelessWidget {
  const MemberManagementPage({
    required this.groupId,
    required this.groupName,
    super.key,
  });

  final int groupId;
  final String groupName;

  static Route<void> route({
    required int groupId,
    required String groupName,
  }) {
    return MaterialPageRoute<void>(
      builder: (_) => MemberManagementPage(
        groupId: groupId,
        groupName: groupName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => GroupMembersBloc(
        groupProvider: context.read<GroupProvider>(),
      )..add(LoadGroupMembers(groupId)),
      child: _MemberManagementView(groupName: groupName, groupId: groupId),
    );
  }
}

class _MemberManagementView extends StatelessWidget {
  const _MemberManagementView({
    required this.groupName,
    required this.groupId,
  });

  final String groupName;
  final int groupId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text('${l10n.memberManagementTitle} · $groupName'),
      ),
      body: BlocBuilder<GroupMembersBloc, GroupMembersState>(
        builder: (context, state) {
          if (state is GroupMembersLoading || state is GroupMembersInitial) {
            return const _MemberListLoading();
          }

          if (state is GroupMembersError) {
            return W2WEmptyState(
              icon: Icons.group_off_outlined,
              title: state.message,
              actionLabel: l10n.commonRetry,
              onAction: () {
                context.read<GroupMembersBloc>().add(
                  LoadGroupMembers(groupId),
                );
              },
            );
          }

          if (state is GroupMembersLoaded) {
            final members = state.members;
            if (members.isEmpty) {
              return W2WEmptyState(
                icon: Icons.groups_outlined,
                title: l10n.noMembersWarning,
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                context.read<GroupMembersBloc>().add(
                  LoadGroupMembers(groupId),
                );
              },
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.pagePaddingH,
                  AppSpacing.pagePaddingV,
                  AppSpacing.pagePaddingH,
                  AppSpacing.pagePaddingV,
                ),
                itemCount: members.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final member = members[index];
                  return _MemberListItem(
                    member: member,
                    onTap: () {
                      Navigator.of(context).push(
                        MemberDetailPage.route(
                          groupId: groupId,
                          member: member,
                          onUpdate: () {
                            context.read<GroupMembersBloc>().add(
                              LoadGroupMembers(groupId),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            );
          }

          if (state is MemberOperationFailure) {
            return W2WEmptyState(
              icon: Icons.error_outline,
              title: state.message,
              actionLabel: l10n.commonRetry,
              onAction: () {
                context.read<GroupMembersBloc>().add(
                  LoadGroupMembers(groupId),
                );
              },
            );
          }

          if (state is MemberOperationInProgress) {
            return const _MemberListLoading();
          }

          if (state is MemberOperationSuccess) {
            return W2WEmptyState(
              icon: Icons.check_circle_outline,
              title: state.message,
              actionLabel: l10n.commonRetry,
              onAction: () {
                context.read<GroupMembersBloc>().add(
                  LoadGroupMembers(groupId),
                );
              },
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _MemberListLoading extends StatelessWidget {
  const _MemberListLoading();

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
        child: Row(
          children: [
            W2WSkeleton(width: 44, height: 44, radius: AppSpacing.radiusFull),
            SizedBox(width: AppSpacing.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  W2WSkeleton(width: 140),
                  SizedBox(height: AppSpacing.space2),
                  W2WSkeleton(width: 120, height: 12),
                ],
              ),
            ),
            SizedBox(width: AppSpacing.space2),
            W2WSkeleton(width: 18, height: 18, radius: AppSpacing.radiusFull),
          ],
        ),
      ),
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemCount: 4,
    );
  }
}

class _MemberListItem extends StatelessWidget {
  const _MemberListItem({
    required this.member,
    required this.onTap,
  });

  final GroupMember member;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final joinedDate = member.joinedAt.toIso8601String().split('T').first;

    return Semantics(
      button: true,
      label: member.nickname,
      child: W2WCard(
        showBorder: true,
        onTap: onTap,
        child: Row(
          children: [
            _Avatar(
              avatarUrl: member.avatarUrl,
              nickname: member.nickname,
            ),
            const SizedBox(width: AppSpacing.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member.nickname,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: AppTypography.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space1),
                  Text(
                    context.l10n.memberJoinedDate(joinedDate),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.space2),
            if (member.role == GroupRole.admin)
              W2WStatusBadge(
                label: context.l10n.roleAdmin,
                type: W2WStatusType.pending,
              ),
            const SizedBox(width: AppSpacing.space2),
            const Icon(
              Icons.chevron_right,
              size: 18,
              color: AppColors.textMutedLight,
            ),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.nickname, this.avatarUrl});

  final String? avatarUrl;
  final String nickname;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initials = nickname.isNotEmpty ? nickname[0].toUpperCase() : '?';

    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 22,
        backgroundImage: NetworkImage(avatarUrl!),
      );
    }

    return CircleAvatar(
      radius: 22,
      backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
      child: Text(
        initials,
        style: TextStyle(
          color: theme.colorScheme.primary,
          fontWeight: AppTypography.bold,
        ),
      ),
    );
  }
}
