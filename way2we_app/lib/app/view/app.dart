import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:way2we_app/app/di.dart';
import 'package:way2we_app/features/auth/bloc/authentication_bloc.dart';
import 'package:way2we_app/features/auth/data/providers/auth_provider.dart';
import 'package:way2we_app/features/auth/view/login_page.dart';
import 'package:way2we_app/features/auth/view/onboarding_profile_setup_page.dart';
import 'package:way2we_app/features/group/data/providers/group_provider.dart';
import 'package:way2we_app/features/group/view/group_selection_page.dart';
import 'package:way2we_app/features/home/view/home_page.dart';
import 'package:way2we_app/features/splash/view/splash_page.dart';
import 'package:way2we_app/l10n/l10n.dart';
import 'package:way2we_app/theme/app_theme.dart';

/// Global navigator key for navigation outside of widget context.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

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

    // Create AuthenticationBloc and register with ServiceLocator
    // for 401 handling
    final authBloc = AuthenticationBloc(
      authProvider: authProvider,
      groupProvider: groupProvider,
    );
    ServiceLocator.instance.setAuthBloc(authBloc);

    return RepositoryProvider<AuthProvider>.value(
      value: authProvider,
      child: BlocProvider<AuthenticationBloc>.value(
        value: authBloc,
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
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
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
                  HomePage.route(),
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
