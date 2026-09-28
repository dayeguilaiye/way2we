import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/account/application/account_controller.dart';
import '../features/account/presentation/login_page.dart';
import '../features/account/presentation/profile_pages.dart';

import '../features/diagnostics/presentation/diagnostics_page.dart';
import 'theme.dart';
import 'providers.dart';

const diagnosticsEnabled =
    kDebugMode && bool.fromEnvironment('DEV_DIAGNOSTICS');
final routerProvider = Provider<GoRouter>((ref) {
  final sessions = ref.watch(sessionProvider);
  final router = GoRouter(
    initialLocation:
        diagnosticsEnabled && const bool.fromEnvironment('START_DIAGNOSTICS')
        ? '/dev'
        : '/me',
    refreshListenable: sessions,
    redirect: (context, state) {
      if (diagnosticsEnabled && state.matchedLocation == '/dev') return null;
      if (sessions.current == null) {
        return state.matchedLocation == '/login' ? null : '/login';
      }
      if (state.matchedLocation == '/login' || state.matchedLocation == '/') {
        return '/me';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/', redirect: (context, state) => '/me'),
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(
        path: '/me',
        builder: (context, state) => const ProfilePage(),
        routes: [
          GoRoute(
            path: 'account',
            builder: (context, state) => const AccountInfoPage(),
          ),
          GoRoute(
            path: 'appearance',
            builder: (context, state) => const AppearancePage(),
          ),
        ],
      ),
      if (diagnosticsEnabled)
        GoRoute(
          path: '/dev',
          builder: (context, state) => const DiagnosticsPage(),
        ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

class Way2WeApp extends ConsumerWidget {
  const Way2WeApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bootstrap = ref.watch(bootstrapProvider);
    if (!bootstrap.hasValue) {
      return MaterialApp(
        theme: buildTheme(ref.watch(themeProvider)),
        home: Scaffold(
          body: SafeArea(
            child: Center(
              child: bootstrap.hasError
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('暂时无法读取登录信息。'),
                        TextButton(
                          onPressed: () => ref.invalidate(bootstrapProvider),
                          child: const Text('重试'),
                        ),
                      ],
                    )
                  : const CircularProgressIndicator(),
            ),
          ),
        ),
      );
    }
    ref.watch(accountProvider);
    return MaterialApp.router(
      title: '一起的小日子',
      debugShowCheckedModeBanner: false,
      locale: const Locale('zh', 'CN'),
      supportedLocales: const [Locale('zh', 'CN')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: buildTheme(ref.watch(themeProvider)),
      themeMode: ThemeMode.light,
      routerConfig: ref.watch(routerProvider),
    );
  }
}
