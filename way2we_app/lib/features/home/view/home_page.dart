import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:way2we_app/app/view/app.dart';
import 'package:way2we_app/features/agreement/bloc/list/agreement_list_bloc.dart';
import 'package:way2we_app/features/agreement/data/providers/agreement_provider.dart';
import 'package:way2we_app/features/agreement/view/agreement_detail_page.dart';
import 'package:way2we_app/features/agreement/view/agreement_list_page.dart';
import 'package:way2we_app/features/agreement/view/widgets/agreement_card.dart';
import 'package:way2we_app/features/auth/bloc/authentication_bloc.dart';
import 'package:way2we_app/features/group/bloc/group_control_bloc.dart';
import 'package:way2we_app/features/group/view/group_default_settings_page.dart';
import 'package:way2we_app/features/group/view/invitation_page.dart';
import 'package:way2we_app/features/group/view/member_management_page.dart';
import 'package:way2we_app/features/group/view/widgets/group_switcher_sheet.dart';
import 'package:way2we_app/features/profile/view/profile_page.dart';
import 'package:way2we_app/features/reward/view/reward_list_page.dart';
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
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.pagePaddingH,
                    vertical: AppSpacing.space6,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
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
                        const SizedBox(height: AppSpacing.space6),
                        PinnedAgreementsSection(groupId: selectedGroup.id),
                        const SizedBox(height: AppSpacing.space6),
                        // Agreements Entry
                        InkWell(
                          onTap: () {
                            Navigator.of(context).push(
                              AgreementListPage.route(groupId: selectedGroup.id),
                            );
                          },
                          child: Column(
                            children: [
                              Icon(
                                Icons.assignment_outlined,
                                size: 32,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                l10n.agreementTabTitle,
                                style: theme.textTheme.labelMedium,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.space4),
                        InkWell(
                          onTap: () {
                            Navigator.of(context).push(
                              RewardListPage.route(groupId: selectedGroup.id),
                            );
                          },
                          child: Column(
                            children: [
                              Icon(
                                Icons.card_giftcard_outlined,
                                size: 32,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                l10n.rewardTabTitle,
                                style: theme.textTheme.labelMedium,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.space4),
                        // Group Settings Entry
                        InkWell(
                          onTap: () {
                            Navigator.of(context).push(
                              GroupDefaultSettingsPage.route(
                                groupId: selectedGroup.id,
                              ),
                            );
                          },
                          child: Column(
                            children: [
                              Icon(
                                Icons.tune,
                                size: 32,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                l10n.defaultSettingsTitle,
                                style: theme.textTheme.labelMedium,
                              ),
                            ],
                          ),
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

class PinnedAgreementsSection extends StatefulWidget {
  const PinnedAgreementsSection({required this.groupId, super.key});

  final int groupId;

  @override
  State<PinnedAgreementsSection> createState() =>
      _PinnedAgreementsSectionState();
}

class _PinnedAgreementsSectionState extends State<PinnedAgreementsSection>
    with RouteAware {
  late final AgreementListBloc _bloc;
  bool _subscribed = false;

  @override
  void initState() {
    super.initState();
    _bloc = AgreementListBloc(
      agreementProvider: context.read<AgreementProvider>(),
    );
    _loadAgreements();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute && !_subscribed) {
      routeObserver.subscribe(this, route);
      _subscribed = true;
    }
  }

  @override
  void didUpdateWidget(PinnedAgreementsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.groupId != widget.groupId) {
      _loadAgreements();
    }
  }

  @override
  void didPopNext() {
    _loadAgreements();
  }

  @override
  void dispose() {
    if (_subscribed) {
      routeObserver.unsubscribe(this);
    }
    _bloc.close();
    super.dispose();
  }

  void _loadAgreements() {
    _bloc.add(LoadAgreements(groupId: widget.groupId, statusFilter: 'active'));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return BlocProvider.value(
      value: _bloc,
      child: BlocBuilder<AgreementListBloc, AgreementListState>(
        builder: (context, state) {
          if (state is AgreementListLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is AgreementListError) {
            return const SizedBox.shrink();
          }

          if (state is AgreementListReadyState) {
            final pinnedAgreements = state.activeAgreements
                .where((agreement) => agreement.isPinned)
                .toList();

            if (pinnedAgreements.isEmpty) {
              return const SizedBox.shrink();
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.agreementPinnedSectionTitle,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: AppTypography.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.space3),
                SizedBox(
                  height: 160,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: pinnedAgreements.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(width: AppSpacing.space3),
                    itemBuilder: (context, index) {
                      final agreement = pinnedAgreements[index];
                      return AgreementCompactCard(
                        agreement: agreement,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => AgreementDetailPage(
                                groupId: widget.groupId,
                                agreementId: agreement.id,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
