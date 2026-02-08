import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:way2we_app/app/di.dart';
import 'package:way2we_app/features/agreement/completion/data/providers/agreement_completion_provider.dart';
import 'package:way2we_app/features/agreement/data/providers/agreement_provider.dart';
import 'package:way2we_app/features/auth/bloc/authentication_bloc.dart';
import 'package:way2we_app/features/auth/data/providers/auth_provider.dart';
import 'package:way2we_app/features/auth/view/login_page.dart';
import 'package:way2we_app/features/auth/view/onboarding_profile_setup_page.dart';
import 'package:way2we_app/features/group/bloc/group_control_bloc.dart';
import 'package:way2we_app/features/group/data/providers/group_provider.dart';
import 'package:way2we_app/features/group/view/group_selection_page.dart';
import 'package:way2we_app/features/home/view/main_shell_page.dart';
import 'package:way2we_app/features/redemption/data/providers/redemption_provider.dart';
import 'package:way2we_app/features/reward/data/providers/reward_provider.dart';
import 'package:way2we_app/features/splash/view/splash_page.dart';
import 'package:way2we_app/l10n/l10n.dart';
import 'package:way2we_app/theme/app_theme.dart';

/// Global navigator key for navigation outside of widget context.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final RouteObserver<PageRoute<dynamic>> routeObserver =
    RouteObserver<PageRoute<dynamic>>();

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final dio = ServiceLocator.instance.dio;

    // Create global providers using ServiceLocator
    final authProvider = AuthProvider(
      dio: dio,
      storage: ServiceLocator.instance.storage,
    );
    final groupProvider = GroupProvider(dio: dio);
    final agreementProvider = AgreementProvider(dio: dio);
    final agreementCompletionProvider = AgreementCompletionProvider(dio: dio);
    final rewardProvider = RewardProvider(dio: dio);
    final redemptionProvider = RedemptionProvider(dio: dio);

    // Create AuthenticationBloc and register with ServiceLocator
    // for 401 handling
    final authBloc = AuthenticationBloc(
      authProvider: authProvider,
      groupProvider: groupProvider,
    );
    ServiceLocator.instance.setAuthBloc(authBloc);

    // Create GroupControlBloc
    final groupControlBloc = GroupControlBloc(groupProvider: groupProvider);

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthProvider>.value(value: authProvider),
        RepositoryProvider<GroupProvider>.value(value: groupProvider),
        RepositoryProvider<AgreementProvider>.value(value: agreementProvider),
        RepositoryProvider<AgreementCompletionProvider>.value(
          value: agreementCompletionProvider,
        ),
        RepositoryProvider<RewardProvider>.value(value: rewardProvider),
        RepositoryProvider<RedemptionProvider>.value(value: redemptionProvider),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthenticationBloc>.value(value: authBloc),
          BlocProvider<GroupControlBloc>.value(value: groupControlBloc),
        ],
        child: const _AppView(),
      ),
    );
  }
}

class _AppView extends StatefulWidget {
  const _AppView();

  @override
  State<_AppView> createState() => _AppViewState();
}

class _AppViewState extends State<_AppView> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      navigatorObservers: [routeObserver],
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.light,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      // Use builder to wrap all routes with BlocListener
      builder: (context, child) {
        return BlocListener<AuthenticationBloc, AuthenticationState>(
          listener: (context, state) {
            final navigator = navigatorKey.currentState;
            if (navigator == null) return;

            if (state is AuthenticationUnauthenticated) {
              // Navigate to login and clear stack
              navigator.pushAndRemoveUntil(
                MaterialPageRoute<void>(builder: (_) => const LoginPage()),
                (route) => false,
              );
            } else if (state is AuthenticationAuthenticated) {
              // Trigger group load
              context.read<GroupControlBloc>().add(
                const GroupControlGroupsLoaded(),
              );

              if (state.needsOnboarding) {
                // Navigate to onboarding
                navigator.pushAndRemoveUntil(
                  OnboardingProfileSetupPage.route(),
                  (route) => false,
                );
              } else if (!state.hasGroup) {
                // Navigate to group selection
                navigator.pushAndRemoveUntil(
                  GroupSelectionPage.route(),
                  (route) => false,
                );
              } else {
                // Navigate to home and clear stack
                navigator.pushAndRemoveUntil(
                  MainShellPage.route(),
                  (route) => false,
                );
              }
            }
          },
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const SplashPage(),
    );
  }
}
