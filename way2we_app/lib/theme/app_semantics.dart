import 'package:flutter/material.dart';
import 'package:way2we_app/theme/app_colors.dart';

/// Semantic color mapping for business states.
class AppSemanticPalette {
  const AppSemanticPalette({
    required this.success,
    required this.successTint,
    required this.warning,
    required this.warningTint,
    required this.error,
    required this.errorTint,
    required this.info,
    required this.infoTint,
  });

  final Color success;
  final Color successTint;
  final Color warning;
  final Color warningTint;
  final Color error;
  final Color errorTint;
  final Color info;
  final Color infoTint;
}

extension AppSemanticTheme on ThemeData {
  AppSemanticPalette get semantic => const AppSemanticPalette(
    success: AppColors.success,
    successTint: AppColors.successTint,
    warning: AppColors.warning,
    warningTint: Color(0x1Af59e0b),
    error: AppColors.error,
    errorTint: AppColors.errorTint,
    info: AppColors.info,
    infoTint: Color(0x1A3b82f6),
  );
}
