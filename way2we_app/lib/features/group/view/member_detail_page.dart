import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:way2we_app/features/group/bloc/members/group_members_bloc.dart';
import 'package:way2we_app/features/group/data/providers/group_provider.dart';
import 'package:way2we_app/features/group/models/member.dart';
import 'package:way2we_app/l10n/l10n.dart';
import 'package:way2we_app/shared/widgets/w2w.dart';
import 'package:way2we_app/theme/theme.dart';

class MemberDetailPage extends StatefulWidget {
  const MemberDetailPage({
    required this.groupId,
    required this.member,
    super.key,
    this.onUpdate,
  });

  final int groupId;
  final GroupMember member;
  final VoidCallback? onUpdate;

  static Route<void> route({
    required int groupId,
    required GroupMember member,
    VoidCallback? onUpdate,
  }) {
    return MaterialPageRoute<void>(
      builder: (_) => MemberDetailPage(
        groupId: groupId,
        member: member,
        onUpdate: onUpdate,
      ),
    );
  }

  @override
  State<MemberDetailPage> createState() => _MemberDetailPageState();
}

class _MemberDetailPageState extends State<MemberDetailPage> {
  late GroupRole _selectedRole;
  late List<String> _selectedPermissions;

  // Permissions labels map will be built dynamically using l10n

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.member.role;
    _selectedPermissions = List.from(widget.member.permissions);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => GroupMembersBloc(
        groupProvider: context.read<GroupProvider>(),
      ),
      child: BlocConsumer<GroupMembersBloc, GroupMembersState>(
        listener: (context, state) {
          if (state is MemberOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Theme.of(context).semantic.success,
              ),
            );
            widget.onUpdate?.call();
          } else if (state is MemberOperationFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Theme.of(context).semantic.error,
              ),
            );
          }
        },
        builder: (context, state) {
          final theme = Theme.of(context);
          final isLoading = state is MemberOperationInProgress;

          return Scaffold(
            appBar: AppBar(
              title: Text(widget.member.nickname),
            ),
            body: ListView(
              padding: const EdgeInsets.all(AppSpacing.pagePaddingH),
              children: [
                _buildProfileHeader(theme),
                const SizedBox(height: AppSpacing.space6),
                W2WSectionHeader(title: context.l10n.memberRoleLabel),
                const SizedBox(height: AppSpacing.space2),
                _buildRoleSelector(context, isLoading),
                const SizedBox(height: AppSpacing.space6),
                W2WSectionHeader(title: context.l10n.memberPermissionsLabel),
                const SizedBox(height: AppSpacing.space1),
                Text(
                  context.l10n.memberAdminPermissionNote,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.space2),
                _buildPermissionsList(context, isLoading),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(ThemeData theme) {
    return W2WCard(
      showBorder: true,
      child: Row(
        children: [
          _Avatar(
            avatarUrl: widget.member.avatarUrl,
            nickname: widget.member.nickname,
            size: 64,
          ),
          const SizedBox(width: AppSpacing.space4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.member.nickname,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: AppTypography.bold,
                  ),
                ),
                Text(
                  context.l10n.memberJoinedDate(
                    widget.member.joinedAt.toIso8601String().split('T').first,
                  ),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (_selectedRole == GroupRole.admin)
            W2WStatusBadge(
              label: context.l10n.roleAdmin,
              type: W2WStatusType.pending,
            ),
        ],
      ),
    );
  }

  Widget _buildRoleSelector(BuildContext context, bool isLoading) {
    return W2WCard(
      showBorder: true,
      child: Column(
        children: GroupRole.values.map((role) {
          final label = role == GroupRole.admin
              ? context.l10n.roleAdmin
              : context.l10n.roleMember;
          return RadioListTile<GroupRole>(
            title: Text(label),
            value: role,
            groupValue: _selectedRole,
            onChanged: isLoading
                ? null
                : (value) {
                    if (value != null && value != _selectedRole) {
                      setState(() => _selectedRole = value);
                      context.read<GroupMembersBloc>().add(
                        UpdateMemberRole(
                          groupId: widget.groupId,
                          userId: widget.member.userId,
                          role: value,
                        ),
                      );
                    }
                  },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPermissionsList(BuildContext context, bool isLoading) {
    // If role is admin, permissions are effectively all checked and disabled
    final isAdmin = _selectedRole == GroupRole.admin;

    return W2WCard(
      showBorder: true,
      child: Column(
        children:
            {
              'create_agreement': context.l10n.permCreateAgreement,
              'edit_agreement': context.l10n.permEditAgreement,
              'delete_agreement': context.l10n.permDeleteAgreement,
              'record_for_others': context.l10n.permRecordForOthers,
              'modify_defaults': context.l10n.permModifyDefaults,
              'create_special_events': context.l10n.permCreateSpecialEvents,
              'revoke_records': context.l10n.permRevokeRecords,
            }.entries.map((entry) {
              final key = entry.key;
              final label = entry.value;
              final isChecked = isAdmin || _selectedPermissions.contains(key);

              return CheckboxListTile(
                title: Text(label),
                value: isChecked,
                enabled: !isLoading && !isAdmin,
                onChanged: (value) {
                  if (value == null) return;

                  setState(() {
                    if (value) {
                      _selectedPermissions.add(key);
                    } else {
                      _selectedPermissions.remove(key);
                    }
                  });

                  context.read<GroupMembersBloc>().add(
                    UpdateMemberPermissions(
                      groupId: widget.groupId,
                      userId: widget.member.userId,
                      permissions: _selectedPermissions,
                    ),
                  );
                },
              );
            }).toList(),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.nickname, this.avatarUrl, this.size = 40});

  final String? avatarUrl;
  final String nickname;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initials = nickname.isNotEmpty ? nickname[0].toUpperCase() : '?';

    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: size / 2,
        backgroundImage: NetworkImage(avatarUrl!),
      );
    }

    return CircleAvatar(
      radius: size / 2,
      backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
      child: Text(
        initials,
        style: TextStyle(
          fontSize: size * 0.4,
          color: theme.colorScheme.primary,
          fontWeight: AppTypography.bold,
        ),
      ),
    );
  }
}
