import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:way2we_app/features/auth/bloc/authentication_bloc.dart';
import 'package:way2we_app/features/group/bloc/group_control_bloc.dart';
import 'package:way2we_app/features/group/view/invitation_page.dart';
import 'package:way2we_app/features/group/view/member_management_page.dart';
import 'package:way2we_app/features/group/view/widgets/group_switcher_sheet.dart';
import 'package:way2we_app/features/profile/view/profile_page.dart';
import 'package:way2we_app/l10n/l10n.dart';
import 'package:way2we_app/theme/theme.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const HomePage());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return BlocConsumer<GroupControlBloc, GroupControlState>(
      listener: (context, state) {
        if (state is GroupControlLoadSuccess) {
          // TODO: Notify other feature blocs about the group change
          // context.read<AgreementBloc>().add(LoadAgreements(groupId: state.selectedGroup.id));
          // context.read<RewardBloc>().add(LoadRewards(groupId: state.selectedGroup.id));

          // For now, we just log it or show a snackbar if needed for debug
          // ScaffoldMessenger.of(context).showSnackBar(
          //   SnackBar(content: Text('Switched to ${state.selectedGroup!.name}')),
          // );
        }
      },
      builder: (context, state) {
        final selectedGroup = state is GroupControlLoadSuccess
            ? state.selectedGroup
            : null;
        final isLoading =
            state is GroupControlLoadInProgress || state is GroupControlInitial;

        return Scaffold(
          appBar: AppBar(
            title: GestureDetector(
              // Option A: Disable interaction when loading
              onTap: isLoading ? null : () => GroupSwitcherSheet.show(context),
              child: Opacity(
                opacity: isLoading ? 0.6 : 1.0,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        selectedGroup?.name ?? 'Way2We',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.expand_more),
                  ],
                ),
              ),
            ),
            actions: [
              // Invite members button (only for admins)
              if (selectedGroup != null && selectedGroup.isAdmin)
                IconButton(
                  icon: const Icon(Icons.person_add),
                  tooltip: l10n.homeInviteMembers,
                  onPressed: () {
                    Navigator.of(context).push(
                      InvitationPage.route(
                        groupId: selectedGroup.id,
                        groupName: selectedGroup.name,
                      ),
                    );
                  },
                ),
              // Profile button
              IconButton(
                icon: const Icon(Icons.person),
                onPressed: () {
                  Navigator.of(context).push(ProfilePage.route());
                },
              ),
              // Logout button
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () {
                  context.read<AuthenticationBloc>().add(
                    const AppLogoutRequested(),
                  );
                },
              ),
            ],
          ),
          body: isLoading
              ? const Center(child: CircularProgressIndicator())
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.primary.withValues(alpha: 0.1),
                              AppColors.primary.withValues(alpha: 0.3),
                            ],
                          ),
                        ),
                        child: const Icon(
                          Icons.home,
                          size: 56,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.space6),
                      if (selectedGroup != null) ...[
                        Text(
                          selectedGroup.name,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: AppTypography.bold,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.space2),
                        Text(
                          selectedGroup.isAdmin ? 'Admin' : 'Member',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.textMutedLight,
                          ),
                        ),
                        if (selectedGroup.description != null &&
                            selectedGroup.description!.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.space2),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Text(
                              selectedGroup.description!,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],

                        // Placeholder for future content
                        const SizedBox(height: AppSpacing.space6),
                        _buildFeaturePlaceholder(
                          context,
                          icon: Icons.assignment_outlined,
                          label: 'Agreements (Coming Soon)',
                        ),
                        const SizedBox(height: AppSpacing.space4),
                        _buildFeaturePlaceholder(
                          context,
                          icon: Icons.stars_outlined,
                          label: 'Rewards (Coming Soon)',
                        ),
                        const SizedBox(height: AppSpacing.space4),
                        // Member Management Entry
                        InkWell(
                          onTap: () {
                            Navigator.of(context).push(
                              MemberManagementPage.route(
                                groupId: selectedGroup.id,
                                groupName: selectedGroup.name,
                              ),
                            );
                          },
                          child: Column(
                            children: [
                              Icon(
                                Icons.people_outline,
                                size: 32,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                l10n.memberManagementTitle,
                                style: theme.textTheme.labelMedium,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _buildFeaturePlaceholder(
    BuildContext context, {
    required IconData icon,
    required String label,
  }) {
    final theme = Theme.of(context);
    return Opacity(
      opacity: 0.5,
      child: Column(
        children: [
          Icon(icon, size: 32, color: theme.colorScheme.primary),
          const SizedBox(height: 8),
          Text(
            label,
            style: theme.textTheme.labelMedium,
          ),
        ],
      ),
    );
  }
}
