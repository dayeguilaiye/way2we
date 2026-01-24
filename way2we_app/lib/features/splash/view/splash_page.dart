import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:way2we_app/features/auth/view/login_page.dart';
import 'package:way2we_app/features/home/view/home_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // Artificial delay for splash effect
    await Future<void>.delayed(const Duration(milliseconds: 1000));

    // Check for token
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'auth_token');

    if (mounted) {
      if (token != null) {
        // Logged in -> Home
        await Navigator.of(context).pushReplacement(HomePage.route());
      } else {
        // Not logged in -> Login
        await Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(builder: (_) => const LoginPage()),
        );
      }
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
