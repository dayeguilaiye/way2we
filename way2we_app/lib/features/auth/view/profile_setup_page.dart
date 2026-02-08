import 'package:flutter/material.dart';
import 'package:way2we_app/features/auth/view/onboarding_profile_setup_page.dart';

class ProfileSetupPage extends StatelessWidget {
  const ProfileSetupPage({super.key});

  static Route<void> route() {
    return OnboardingProfileSetupPage.route();
  }

  @override
  Widget build(BuildContext context) {
    return const OnboardingProfileSetupPage();
  }
}
