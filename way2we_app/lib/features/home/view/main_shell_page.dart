import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:way2we_app/features/agreement/view/agreement_list_page.dart';
import 'package:way2we_app/features/group/bloc/group_control_bloc.dart';
import 'package:way2we_app/features/group/view/group_selection_page.dart';
import 'package:way2we_app/features/home/view/home_page.dart';
import 'package:way2we_app/features/redemption/view/redemption_order_list_page.dart';
import 'package:way2we_app/features/reward/view/reward_list_page.dart';
import 'package:way2we_app/l10n/l10n.dart';
import 'package:way2we_app/shared/widgets/w2w.dart';

enum MainTab { home, agreements, rewards, orders }

class MainShellPage extends StatefulWidget {
  const MainShellPage({
    this.initialTab = MainTab.home,
    super.key,
  });

  final MainTab initialTab;

  static Route<void> route({MainTab initialTab = MainTab.home}) {
    return MaterialPageRoute<void>(
      builder: (_) => MainShellPage(initialTab: initialTab),
    );
  }

  @override
  State<MainShellPage> createState() => _MainShellPageState();
}

class _MainShellPageState extends State<MainShellPage> {
  late MainTab _currentTab;
  final Map<MainTab, GlobalKey<NavigatorState>> _navigatorKeys = {
    MainTab.home: GlobalKey<NavigatorState>(),
    MainTab.agreements: GlobalKey<NavigatorState>(),
    MainTab.rewards: GlobalKey<NavigatorState>(),
    MainTab.orders: GlobalKey<NavigatorState>(),
  };

  @override
  void initState() {
    super.initState();
    _currentTab = widget.initialTab;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GroupControlBloc, GroupControlState>(
      builder: (context, state) {
        final l10n = context.l10n;

        if (state is GroupControlLoadInProgress ||
            state is GroupControlInitial) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is GroupControlLoadFailure) {
          return Scaffold(
            body: W2WEmptyState(
              icon: Icons.error_outline,
              title: state.message,
              actionLabel: l10n.retry,
              onAction: () => context.read<GroupControlBloc>().add(
                const GroupControlGroupsLoaded(),
              ),
            ),
          );
        }

        if (state is! GroupControlLoadSuccess || state.selectedGroup == null) {
          return Scaffold(
            body: W2WEmptyState(
              icon: Icons.groups_outlined,
              title: l10n.groupSelectionTitle,
              subtitle: l10n.groupSelectionSubtitle,
              actionLabel: l10n.groupSelectionCreateTitle,
              onAction: () {
                Navigator.of(context).push(GroupSelectionPage.route());
              },
            ),
          );
        }

        final groupId = state.selectedGroup!.id;
        final tabPages = {
          MainTab.home: const HomePage(),
          MainTab.agreements: AgreementListPage(groupId: groupId),
          MainTab.rewards: RewardListPage(groupId: groupId),
          MainTab.orders: RedemptionOrderListPage(groupId: groupId),
        };

        return Scaffold(
          body: Stack(
            children: MainTab.values.map((tab) {
              return Offstage(
                offstage: _currentTab != tab,
                child: KeyedSubtree(
                  key: ValueKey('${tab.name}-$groupId'),
                  child: Navigator(
                    key: _navigatorKeys[tab],
                    onGenerateRoute: (_) => MaterialPageRoute<void>(
                      builder: (_) => tabPages[tab]!,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _currentTab.index,
            onDestinationSelected: (index) {
              setState(() {
                _currentTab = MainTab.values[index];
              });
            },
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.home_outlined),
                selectedIcon: const Icon(Icons.home),
                label: l10n.homeTabTitle,
              ),
              NavigationDestination(
                icon: const Icon(Icons.assignment_outlined),
                selectedIcon: const Icon(Icons.assignment),
                label: l10n.agreementTabTitle,
              ),
              NavigationDestination(
                icon: const Icon(Icons.card_giftcard_outlined),
                selectedIcon: const Icon(Icons.card_giftcard),
                label: l10n.rewardTabTitle,
              ),
              NavigationDestination(
                icon: const Icon(Icons.receipt_long_outlined),
                selectedIcon: const Icon(Icons.receipt_long),
                label: l10n.redemptionOrderTabTitle,
              ),
            ],
          ),
        );
      },
    );
  }
}
