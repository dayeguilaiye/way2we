import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:way2we_app/app/di.dart';
import 'package:way2we_app/features/auth/bloc/authentication_bloc.dart';
import 'package:way2we_app/features/group/data/providers/group_provider.dart';
import 'package:way2we_app/features/group/view/invitation_page.dart';
import 'package:way2we_app/features/profile/view/profile_page.dart';
import 'package:way2we_app/l10n/l10n.dart';
import 'package:way2we_app/theme/theme.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const HomePage());
  }

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final GroupProvider _groupProvider;
  UserGroup? _currentGroup;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _groupProvider = GroupProvider(dio: ServiceLocator.instance.dio);
    _loadGroup();
  }

  Future<void> _loadGroup() async {
    try {
      final response = await _groupProvider.getUserGroups();
      if (response.groups.isNotEmpty && mounted) {
        setState(() {
          _currentGroup = response.groups.first;
          _isLoading = false;
        });
      }
    } on Exception {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentGroup != null
              ? l10n.homeGroupName(_currentGroup!.name)
              : 'Way2We',
        ),
        actions: [
          // Invite members button (only for admins)
          if (_currentGroup != null && _currentGroup!.isAdmin)
            IconButton(
              icon: const Icon(Icons.person_add),
              tooltip: l10n.homeInviteMembers,
              onPressed: () {
                Navigator.of(context).push(
                  InvitationPage.route(
                    groupId: _currentGroup!.id,
                    groupName: _currentGroup!.name,
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
              context
                  .read<AuthenticationBloc>()
                  .add(const AppLogoutRequested());
            },
          ),
        ],
      ),
      body: _isLoading
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
                  if (_currentGroup != null) ...[
                    Text(
                      _currentGroup!.name,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: AppTypography.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space2),
                    Text(
                      _currentGroup!.isAdmin ? 'Admin' : 'Member',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textMutedLight,
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
