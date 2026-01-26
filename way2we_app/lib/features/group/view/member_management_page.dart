import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:way2we_app/features/group/bloc/members/group_members_bloc.dart';
import 'package:way2we_app/features/group/data/providers/group_provider.dart';
import 'package:way2we_app/features/group/models/member.dart';
import 'package:way2we_app/features/group/view/member_detail_page.dart';
import 'package:way2we_app/l10n/l10n.dart';
import 'package:way2we_app/theme/theme.dart';

class MemberManagementPage extends StatelessWidget {
  const MemberManagementPage({
    super.key,
    required this.groupId,
    required this.groupName,
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
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text('${l10n.memberManagementTitle} - $groupName'),
      ),
      body: BlocBuilder<GroupMembersBloc, GroupMembersState>(
        builder: (context, state) {
          if (state is GroupMembersLoading || state is GroupMembersInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is GroupMembersError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(state.message, style: theme.textTheme.bodyLarge),
                  const SizedBox(height: AppSpacing.space4),
                  ElevatedButton(
                    onPressed: () {
                      context.read<GroupMembersBloc>().add(
                        LoadGroupMembers(groupId),
                      );
                    },
                    child: Text(l10n.commonRetry),
                  ),
                ],
              ),
            );
          }

          if (state is GroupMembersLoaded) {
            final members = state.members;
            if (members.isEmpty) {
              return Center(child: Text(l10n.noMembersWarning));
            }

            return ListView.separated(
              itemCount: members.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
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
            );
          }

          return const SizedBox.shrink();
        },
      ),
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

    return ListTile(
      onTap: onTap,
      leading: _Avatar(avatarUrl: member.avatarUrl, nickname: member.nickname),
      title: Text(
        member.nickname,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: AppTypography.bold,
        ),
      ),
      subtitle: Text(
        context.l10n.memberJoinedDate(member.joinedAt.toString().split(' ')[0]),
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (member.role == GroupRole.admin)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                context.l10n.roleAdmin,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: AppTypography.bold,
                ),
              ),
            ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, size: 20),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({this.avatarUrl, required this.nickname});

  final String? avatarUrl;
  final String nickname;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initials = nickname.isNotEmpty ? nickname[0].toUpperCase() : '?';

    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return CircleAvatar(
        backgroundImage: NetworkImage(avatarUrl!),
      );
    }

    return CircleAvatar(
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
