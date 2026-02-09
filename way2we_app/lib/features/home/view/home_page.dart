import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:way2we_app/app/view/app.dart';
import 'package:way2we_app/features/agreement/bloc/list/agreement_list_bloc.dart';
import 'package:way2we_app/features/agreement/data/providers/agreement_provider.dart';
import 'package:way2we_app/features/agreement/view/agreement_detail_page.dart';
import 'package:way2we_app/features/agreement/view/widgets/agreement_card.dart';
import 'package:way2we_app/features/group/bloc/group_control_bloc.dart';
import 'package:way2we_app/features/group/data/providers/group_provider.dart';
import 'package:way2we_app/features/group/view/group_default_settings_page.dart';
import 'package:way2we_app/features/group/view/invitation_page.dart';
import 'package:way2we_app/features/group/view/member_management_page.dart';
import 'package:way2we_app/features/group/view/widgets/group_switcher_sheet.dart';
import 'package:way2we_app/features/profile/view/profile_page.dart';
import 'package:way2we_app/features/reward/bloc/list/reward_list_bloc.dart';
import 'package:way2we_app/features/reward/data/models/reward.dart';
import 'package:way2we_app/features/reward/data/providers/reward_provider.dart';
import 'package:way2we_app/features/reward/view/reward_detail_page.dart';
import 'package:way2we_app/l10n/l10n.dart';
import 'package:way2we_app/shared/widgets/w2w.dart';
import 'package:way2we_app/theme/theme.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const HomePage());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocConsumer<GroupControlBloc, GroupControlState>(
      listener: (context, state) {},
      builder: (context, state) {
        final selectedGroup = state is GroupControlLoadSuccess
            ? state.selectedGroup
            : null;
        final isLoading =
            state is GroupControlLoadInProgress || state is GroupControlInitial;
        final chrome = Theme.of(context).homeChrome;

        return Scaffold(
          backgroundColor: chrome.backgroundBase,
          body: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [chrome.backgroundBase, chrome.backgroundElevated],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.pagePaddingH,
                      AppSpacing.space3,
                      AppSpacing.pagePaddingH,
                      AppSpacing.space2,
                    ),
                    child: _HomeTopBar(
                      groupName: selectedGroup?.name ?? l10n.commonAppName,
                      onProfileTap: () {
                        Navigator.of(context).push(ProfilePage.route());
                      },
                      onSettingsTap: selectedGroup == null
                          ? null
                          : () {
                              Navigator.of(context).push(
                                GroupDefaultSettingsPage.route(
                                  groupId: selectedGroup.id,
                                ),
                              );
                            },
                      onGroupTap: isLoading || selectedGroup == null
                          ? null
                          : () => GroupSwitcherSheet.show(context),
                    ),
                  ),
                  Expanded(
                    child: isLoading
                        ? const _HomeLoadingView()
                        : selectedGroup == null
                        ? Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.pagePaddingH,
                            ),
                            child: W2WEmptyState(
                              icon: Icons.groups_outlined,
                              title: l10n.groupSelectionTitle,
                              subtitle: l10n.groupSelectionSubtitle,
                              actionLabel: l10n.retry,
                              onAction: () =>
                                  context.read<GroupControlBloc>().add(
                                    const GroupControlGroupsLoaded(),
                                  ),
                            ),
                          )
                        : SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.pagePaddingH,
                              AppSpacing.space2,
                              AppSpacing.pagePaddingH,
                              AppSpacing.space12,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _GroupHeroCard(group: selectedGroup),
                                const SizedBox(height: AppSpacing.space6),
                                PinnedAgreementsSection(
                                  groupId: selectedGroup.id,
                                ),
                                const SizedBox(height: AppSpacing.space6),
                                PinnedRewardsSection(groupId: selectedGroup.id),
                                const SizedBox(height: AppSpacing.space6),
                                W2WSectionHeader(
                                  title: l10n.defaultSettingsTitle,
                                ),
                                const SizedBox(height: AppSpacing.space3),
                                GridView.count(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  crossAxisCount: 2,
                                  mainAxisSpacing: AppSpacing.space3,
                                  crossAxisSpacing: AppSpacing.space3,
                                  childAspectRatio: 2.6,
                                  children: [
                                    if (selectedGroup.isAdmin)
                                      _DashboardActionCard(
                                        icon: Icons.person_add_outlined,
                                        title: l10n.homeInviteMembers,
                                        onTap: () {
                                          Navigator.of(context).push(
                                            InvitationPage.route(
                                              groupId: selectedGroup.id,
                                              groupName: selectedGroup.name,
                                            ),
                                          );
                                        },
                                      ),
                                    _DashboardActionCard(
                                      icon: Icons.tune_outlined,
                                      title: l10n.defaultSettingsTitle,
                                      onTap: () {
                                        Navigator.of(context).push(
                                          GroupDefaultSettingsPage.route(
                                            groupId: selectedGroup.id,
                                          ),
                                        );
                                      },
                                    ),
                                    _DashboardActionCard(
                                      icon: Icons.people_outline,
                                      title: l10n.memberManagementTitle,
                                      onTap: () {
                                        Navigator.of(context).push(
                                          MemberManagementPage.route(
                                            groupId: selectedGroup.id,
                                            groupName: selectedGroup.name,
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HomeTopBar extends StatelessWidget {
  const _HomeTopBar({
    required this.groupName,
    this.onProfileTap,
    this.onSettingsTap,
    this.onGroupTap,
  });

  final String groupName;
  final VoidCallback? onProfileTap;
  final VoidCallback? onSettingsTap;
  final VoidCallback? onGroupTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final chrome = theme.homeChrome;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space2,
        vertical: AppSpacing.space2,
      ),
      decoration: BoxDecoration(
        color: chrome.topBarBackground,
        borderRadius: BorderRadius.circular(AppSpacing.radius),
        border: Border.all(color: chrome.topBarBorder),
      ),
      child: Row(
        children: [
          Semantics(
            button: true,
            enabled: onProfileTap != null,
            label: l10n.profilePageTitle,
            child: Tooltip(
              message: l10n.profilePageTitle,
              child: InkWell(
                onTap: onProfileTap,
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                child: Opacity(
                  opacity: onProfileTap == null ? 0.6 : 1,
                  child: _GroupBadge(label: groupName),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.space2),
          Expanded(
            child: Semantics(
              button: true,
              enabled: onGroupTap != null,
              label: l10n.groupSelectTitle,
              child: Tooltip(
                message: l10n.groupSelectTitle,
                child: InkWell(
                  onTap: onGroupTap,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  child: Opacity(
                    opacity: onGroupTap == null ? 0.6 : 1,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        minHeight: AppSpacing.minTouchTarget,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.homeManagingLabel,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    fontWeight: AppTypography.medium,
                                    height: 1.2,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: AppSpacing.space1),
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        groupName,
                                        style: theme.textTheme.headlineSmall
                                            ?.copyWith(
                                              fontWeight: AppTypography.bold,
                                              height: 1.1,
                                            ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.space1),
                                    Icon(
                                      Icons.expand_more_rounded,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.space2),
          Semantics(
            button: true,
            label: l10n.homeMessageEntryLabel,
            child: IconButton(
              tooltip: l10n.homeMessageEntryLabel,
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.homeMessageEntryHint)),
                );
              },
              style: IconButton.styleFrom(
                minimumSize: const Size.square(AppSpacing.minTouchTarget),
                backgroundColor: chrome.iconBackground,
                foregroundColor: chrome.iconForeground,
                shape: const CircleBorder(),
              ),
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.notifications_none_rounded),
                  Positioned(
                    top: -1,
                    right: -1,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: chrome.notificationDot,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: chrome.notificationDotBorder,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.space1),
          Semantics(
            button: true,
            enabled: onSettingsTap != null,
            label: l10n.defaultSettingsTitle,
            child: IconButton(
              tooltip: l10n.defaultSettingsTitle,
              onPressed: onSettingsTap,
              style: IconButton.styleFrom(
                minimumSize: const Size.square(AppSpacing.minTouchTarget),
                backgroundColor: chrome.iconBackground,
                foregroundColor: chrome.iconForeground,
                shape: const CircleBorder(),
              ),
              icon: const Icon(Icons.settings_outlined),
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupBadge extends StatelessWidget {
  const _GroupBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chrome = theme.homeChrome;
    final initials = _extractInitials(label);

    return Container(
      width: AppSpacing.minTouchTarget,
      height: AppSpacing.minTouchTarget,
      decoration: BoxDecoration(
        color: chrome.avatarBackground,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: theme.textTheme.labelMedium?.copyWith(
          color: chrome.avatarForeground,
          fontWeight: AppTypography.bold,
        ),
      ),
    );
  }

  String _extractInitials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) {
      return 'WG';
    }
    if (parts.length == 1) {
      final chunk = parts.first;
      return chunk.substring(0, chunk.length.clamp(1, 2)).toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

class _HomeLoadingView extends StatelessWidget {
  const _HomeLoadingView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pagePaddingH,
        AppSpacing.space2,
        AppSpacing.pagePaddingH,
        AppSpacing.space12,
      ),
      children: const [
        W2WCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              W2WSkeleton(height: 22, width: 180),
              SizedBox(height: AppSpacing.space2),
              W2WSkeleton(width: 120),
              SizedBox(height: AppSpacing.space2),
              W2WSkeleton(width: 260),
            ],
          ),
        ),
        SizedBox(height: AppSpacing.space6),
        W2WSkeleton(height: 160),
        SizedBox(height: AppSpacing.space6),
        W2WSkeleton(height: 140),
      ],
    );
  }
}

class _GroupHeroCard extends StatelessWidget {
  const _GroupHeroCard({required this.group});

  final UserGroup group;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return W2WCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary.withValues(alpha: 0.14),
                  AppColors.primary.withValues(alpha: 0.32),
                ],
              ),
            ),
            child: const Icon(
              Icons.groups_outlined,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  group.name,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: AppTypography.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.space1),
                W2WStatusBadge(
                  label: group.isAdmin ? l10n.roleAdmin : l10n.roleMember,
                  type: group.isAdmin
                      ? W2WStatusType.completed
                      : W2WStatusType.pending,
                ),
                if (group.description != null &&
                    group.description!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.space2),
                  Text(
                    group.description!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardActionCard extends StatelessWidget {
  const _DashboardActionCard({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      button: true,
      label: title,
      child: W2WCard(
        variant: W2WCardVariant.compact,
        onTap: onTap,
        child: Row(
          children: [
            Container(
              width: AppSpacing.minTouchTarget,
              height: AppSpacing.minTouchTarget,
              decoration: BoxDecoration(
                color: AppColors.primaryTint,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              ),
              child: Icon(icon, color: AppColors.primary),
            ),
            const SizedBox(width: AppSpacing.space2),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: AppTypography.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
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

    return BlocProvider.value(
      value: _bloc,
      child: BlocBuilder<AgreementListBloc, AgreementListState>(
        builder: (context, state) {
          if (state is AgreementListLoading) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                W2WSectionHeader(title: l10n.agreementPinnedSectionTitle),
                const SizedBox(height: AppSpacing.space3),
                const SizedBox(
                  height: 160,
                  child: _HorizontalSkeletonList(itemWidth: 220),
                ),
              ],
            );
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
                W2WSectionHeader(
                  title: l10n.agreementPinnedSectionTitle,
                ),
                const SizedBox(height: AppSpacing.space3),
                SizedBox(
                  height: 160,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: pinnedAgreements.length,
                    separatorBuilder: (_, _) =>
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

class PinnedRewardsSection extends StatefulWidget {
  const PinnedRewardsSection({required this.groupId, super.key});

  final int groupId;

  @override
  State<PinnedRewardsSection> createState() => _PinnedRewardsSectionState();
}

class _PinnedRewardsSectionState extends State<PinnedRewardsSection>
    with RouteAware {
  late final RewardListBloc _bloc;
  bool _subscribed = false;

  @override
  void initState() {
    super.initState();
    _bloc = RewardListBloc(
      rewardProvider: context.read<RewardProvider>(),
    );
    _loadRewards();
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
  void didUpdateWidget(PinnedRewardsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.groupId != widget.groupId) {
      _loadRewards();
    }
  }

  @override
  void didPopNext() {
    _loadRewards();
  }

  @override
  void dispose() {
    if (_subscribed) {
      routeObserver.unsubscribe(this);
    }
    _bloc.close();
    super.dispose();
  }

  void _loadRewards() {
    _bloc.add(
      LoadRewards(
        groupId: widget.groupId,
        statusFilter: 'active',
        pinnedOnly: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocProvider.value(
      value: _bloc,
      child: BlocBuilder<RewardListBloc, RewardListState>(
        builder: (context, state) {
          if (state is RewardListLoading) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                W2WSectionHeader(title: l10n.rewardPinnedSectionTitle),
                const SizedBox(height: AppSpacing.space3),
                const SizedBox(
                  height: 140,
                  child: _HorizontalSkeletonList(itemWidth: 180),
                ),
              ],
            );
          }

          if (state is RewardListError) {
            return const SizedBox.shrink();
          }

          if (state is RewardListReadyState) {
            final pinnedRewards = state.rewards
                .where((reward) => reward.isPinned)
                .toList();

            if (pinnedRewards.isEmpty) {
              return const SizedBox.shrink();
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                W2WSectionHeader(
                  title: l10n.rewardPinnedSectionTitle,
                ),
                const SizedBox(height: AppSpacing.space3),
                SizedBox(
                  height: 140,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: pinnedRewards.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(width: AppSpacing.space3),
                    itemBuilder: (context, index) {
                      final reward = pinnedRewards[index];
                      return RewardCompactCard(
                        reward: reward,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => RewardDetailPage(
                                groupId: widget.groupId,
                                reward: reward,
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

class _HorizontalSkeletonList extends StatelessWidget {
  const _HorizontalSkeletonList({required this.itemWidth});

  final double itemWidth;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: 2,
      separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.space3),
      itemBuilder: (_, _) {
        return SizedBox(
          width: itemWidth,
          child: const W2WCard(
            variant: W2WCardVariant.compact,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                W2WSkeleton(width: 120),
                SizedBox(height: AppSpacing.space2),
                W2WSkeleton(height: 14, width: 90),
                SizedBox(height: AppSpacing.space2),
                W2WSkeleton(height: 14, width: 140),
              ],
            ),
          ),
        );
      },
    );
  }
}

class RewardCompactCard extends StatelessWidget {
  const RewardCompactCard({required this.reward, this.onTap, super.key});

  final Reward reward;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return SizedBox(
      width: 180,
      child: W2WCard(
        variant: W2WCardVariant.compact,
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  ),
                  child:
                      reward.coverImageUrl != null &&
                          reward.coverImageUrl!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusLg,
                          ),
                          child: Image.network(
                            reward.coverImageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Icon(
                              Icons.card_giftcard_outlined,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                        )
                      : Icon(
                          Icons.card_giftcard_outlined,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                ),
                const SizedBox(width: AppSpacing.space2),
                Expanded(
                  child: Text(
                    reward.name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: AppTypography.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.space2),
            Text(
              l10n.commonPoints(reward.costPoints),
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: AppTypography.bold,
              ),
            ),
            const Spacer(),
            Text(
              reward.providerNickname?.isNotEmpty ?? false
                  ? reward.providerNickname!
                  : '—',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
