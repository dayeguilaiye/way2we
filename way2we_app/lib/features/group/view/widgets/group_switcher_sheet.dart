import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:way2we_app/features/group/bloc/group_control_bloc.dart';
import 'package:way2we_app/features/group/view/create_group_page.dart';
import 'package:way2we_app/features/group/view/join_group_page.dart';
import 'package:way2we_app/l10n/l10n.dart';
import 'package:way2we_app/theme/theme.dart';

class GroupSwitcherSheet extends StatelessWidget {
  const GroupSwitcherSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const GroupSwitcherSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle for aesthetics
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              l10n.groupSelectTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Flexible(
            child: BlocBuilder<GroupControlBloc, GroupControlState>(
              builder: (context, state) {
                if (state is GroupControlLoadSuccess) {
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: state.groups.length,
                    itemBuilder: (context, index) {
                      final group = state.groups[index];
                      final isSelected = group.id == state.selectedGroup?.id;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isSelected
                              ? AppColors.primary
                              : theme.disabledColor,
                          child: Text(
                            group.name.isNotEmpty
                                ? group.name[0].toUpperCase()
                                : '?',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(group.name),
                        subtitle: Text(
                          l10n.joinGroupMemberCount(group.memberCount),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check, color: AppColors.primary)
                            : null,
                        onTap: () {
                          context.read<GroupControlBloc>().add(
                            GroupControlGroupSelected(group.id),
                          );
                          Navigator.pop(context);
                        },
                      );
                    },
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.add),
            title: Text(l10n.groupCreateAction),
            onTap: () {
              Navigator.pop(context); // Close sheet
              Navigator.push(context, CreateGroupPage.route());
            },
          ),
          ListTile(
            leading: const Icon(Icons.group_add),
            title: Text(l10n.groupJoinAction),
            onTap: () {
              Navigator.pop(context); // Close sheet
              Navigator.push(context, JoinGroupPage.route());
            },
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }
}
