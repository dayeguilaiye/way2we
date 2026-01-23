import 'package:flutter/material.dart';
import 'package:way2we_app/theme/app_colors.dart';

/// Design system shadow tokens based on UX Design Specification.
class AppShadows {
  AppShadows._();

  // ============================================
  // Shadow Definitions
  // ============================================

  /// Soft shadow with brand color tint
  /// Used for elevated primary elements
  /// `0 4px 20px -2px rgba(240, 124, 66, 0.15)`
  static List<BoxShadow> get soft => [
    BoxShadow(
      color: AppColors.primary.withValues(alpha: 0.15),
      blurRadius: 20,
      offset: const Offset(0, 4),
      spreadRadius: -2,
    ),
  ];

  /// Card shadow - subtle elevation
  /// `0 2px 8px rgba(0, 0, 0, 0.05)`
  static List<BoxShadow> get card => [
    const BoxShadow(
      color: Color(0x0D000000), // 5% black
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  /// Elevated shadow for modals and overlays
  static List<BoxShadow> get elevated => [
    const BoxShadow(
      color: Color(0x1A000000), // 10% black
      blurRadius: 16,
      offset: Offset(0, 8),
      spreadRadius: -4,
    ),
  ];

  /// No shadow
  static List<BoxShadow> get none => [];
}
