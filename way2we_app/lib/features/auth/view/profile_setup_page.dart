import 'package:flutter/material.dart';

class ProfileSetupPage extends StatelessWidget {
  const ProfileSetupPage({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const ProfileSetupPage());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile Setup')),
      body: const Center(
        child: Text('Profile Setup Page'),
      ),
    );
  }
}
