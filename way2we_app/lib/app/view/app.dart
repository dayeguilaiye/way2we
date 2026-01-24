import 'package:flutter/material.dart';
import 'package:way2we_app/features/splash/view/splash_page.dart';
import 'package:way2we_app/l10n/l10n.dart';
import 'package:way2we_app/theme/app_theme.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const SplashPage(),
    );
  }
}
