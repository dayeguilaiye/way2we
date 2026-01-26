import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:way2we_app/app/di.dart';
import 'package:way2we_app/features/agreement/bloc/list/agreement_list_bloc.dart';
import 'package:way2we_app/features/agreement/data/providers/agreement_provider.dart';
import 'package:way2we_app/features/agreement/models/agreement.dart';
import 'package:way2we_app/features/agreement/view/agreement_detail_page.dart';
import 'package:way2we_app/features/agreement/view/create_agreement_page.dart';
import 'package:way2we_app/features/agreement/view/widgets/agreement_card.dart';
import 'package:way2we_app/features/group/bloc/group_control_bloc.dart';
import 'package:way2we_app/l10n/l10n.dart';

class AgreementListPage extends StatelessWidget {
  const AgreementListPage({
    required this.groupId,
    super.key,
  });

  final int groupId;

  static Route<void> route({required int groupId}) {
    return MaterialPageRoute<void>(
      builder: (_) => AgreementListPage(groupId: groupId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider(
      create: (_) => AgreementProvider(dio: ServiceLocator.instance.dio),
      child: BlocProvider(
        create: (context) => AgreementListBloc(
          agreementProvider: context.read<AgreementProvider>(),
        )..add(LoadAgreements(groupId: groupId)),
        child: AgreementListView(groupId: groupId),
      ),
    );
  }
}

class AgreementListView extends StatefulWidget {
  const AgreementListView({
    required this.groupId,
    super.key,
  });

  final int groupId;

  @override
  State<AgreementListView> createState() => _AgreementListViewState();
}

class _AgreementListViewState extends State<AgreementListView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadAgreements() {
    context.read<AgreementListBloc>().add(
      LoadAgreements(groupId: widget.groupId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.agreementTabTitle),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l10n.agreementStatusActive),
            Tab(text: l10n.agreementStatusInactive),
          ],
        ),
      ),
      body: BlocBuilder<AgreementListBloc, AgreementListState>(
        builder: (context, state) {
          if (state is AgreementListLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is AgreementListError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(state.message),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _loadAgreements,
                    child: Text(l10n.retry),
                  ),
                ],
              ),
            );
          }

          if (state is AgreementListLoaded) {
            return TabBarView(
              controller: _tabController,
              children: [
                // Active agreements
                _buildAgreementList(
                  context,
                  state.activeAgreements,
                  isActive: true,
                ),
                // Inactive agreements
                _buildAgreementList(
                  context,
                  state.inactiveAgreements,
                  isActive: false,
                ),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: BlocBuilder<GroupControlBloc, GroupControlState>(
        builder: (context, groupState) {
          if (groupState is! GroupControlLoadSuccess) {
            return const SizedBox.shrink();
          }

          // Only admins or members with permission can create agreements
          final hasPermission =
              groupState.selectedGroup?.hasPermission('create_agreement') ??
              false;

          if (!hasPermission) return const SizedBox.shrink();

          return FloatingActionButton.extended(
            onPressed: () => _navigateToCreate(context),
            icon: const Icon(Icons.add),
            label: Text(l10n.agreementCreateButton),
          );
        },
      ),
    );
  }

  Widget _buildAgreementList(
    BuildContext context,
    List<Agreement> agreements, {
    required bool isActive,
  }) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    if (agreements.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? Icons.assignment_outlined : Icons.archive_outlined,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              isActive ? l10n.agreementEmptyTitle : l10n.agreementNoInactive,
              style: theme.textTheme.titleMedium,
            ),
            if (isActive) ...[
              const SizedBox(height: 8),
              Text(
                l10n.agreementEmptySubtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<AgreementListBloc>().add(const RefreshAgreements());
      },
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 80),
        itemCount: agreements.length,
        itemBuilder: (context, index) {
          final agreement = agreements[index];
          return AgreementCard(
            agreement: agreement,
            onTap: () => _navigateToDetail(context, agreement),
            onRecordComplete: isActive
                ? () => _recordComplete(agreement)
                : null,
          );
        },
      ),
    );
  }

  void _navigateToCreate(BuildContext context) {
    final bloc = context.read<AgreementListBloc>();
    Navigator.of(context)
        .push<void>(
          MaterialPageRoute<void>(
            builder: (_) => CreateAgreementPage(groupId: widget.groupId),
          ),
        )
        .then((_) {
          if (mounted) {
            bloc.add(const RefreshAgreements());
          }
        });
  }

  void _navigateToDetail(BuildContext context, Agreement agreement) {
    final bloc = context.read<AgreementListBloc>();
    Navigator.of(context)
        .push<void>(
          MaterialPageRoute<void>(
            builder: (_) => AgreementDetailPage(
              groupId: widget.groupId,
              agreementId: agreement.id,
            ),
          ),
        )
        .then((_) {
          if (mounted) {
            bloc.add(const RefreshAgreements());
          }
        });
  }

  void _recordComplete(Agreement agreement) {
    // Record completion will be implemented in a future story
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Record completion - coming soon!')),
    );
  }
}
