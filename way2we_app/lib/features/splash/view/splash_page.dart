import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:way2we_app/features/auth/bloc/authentication_bloc.dart';

/// Splash page that dispatches AppStarted event to check authentication.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _startAuthCheck();
  }

  Future<void> _startAuthCheck() async {
    // Artificial delay for splash effect
    await Future<void>.delayed(const Duration(milliseconds: 1000));

    if (mounted) {
      // Dispatch AppStarted event to check authentication status
      // The AuthenticationBloc listener in App will handle navigation
      context.read<AuthenticationBloc>().add(const AppStarted());
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
