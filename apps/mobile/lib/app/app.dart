import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/diagnostics/presentation/diagnostics_page.dart';
import 'theme.dart';
import 'providers.dart';

const diagnosticsEnabled =
    kDebugMode && bool.fromEnvironment('DEV_DIAGNOSTICS');
final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: diagnosticsEnabled ? '/dev' : '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const WelcomePage()),
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

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('一起的小日子', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 24),
              Text(
                '平凡的日常，\n也是值得好好记录的生活。',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
