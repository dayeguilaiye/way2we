import 'package:flutter/material.dart';

/// Motion tokens for micro-interactions.
class AppMotion {
  AppMotion._();

  /// Quick transitions for hover/press feedback.
  static const Duration fast = Duration(milliseconds: 120);

  /// Standard transitions for most UI state changes.
  static const Duration normal = Duration(milliseconds: 180);

  /// Slower transitions for larger layout/content shifts.
  static const Duration slow = Duration(milliseconds: 240);

  /// Returns [Duration.zero] when reduced motion is enabled.
  static Duration resolve(BuildContext context, Duration duration) {
    final mediaQuery = MediaQuery.maybeOf(context);
    final disableAnimations =
        mediaQuery?.disableAnimations ??
        WidgetsBinding
            .instance
            .platformDispatcher
            .accessibilityFeatures
            .disableAnimations;
    return disableAnimations ? Duration.zero : duration;
  }
}
