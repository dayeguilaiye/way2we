import 'package:flutter/material.dart';

/// Design system color tokens based on UX Design Specification.
/// Theme: Warm Orange (温暖橙)
/// Updated to match example design: #ec8451
class AppColors {
  AppColors._();

  // ============================================
  // Brand Colors
  // ============================================

  /// Primary brand color - Warm Orange
  /// 主操作、品牌色、强调元素
  static const Color primary = Color(0xFFec8451);

  /// Primary dark - for hover/pressed states
  /// 按钮 hover/pressed 状态
  static const Color primaryDark = Color(0xFFd97544);

  /// Primary tint - for secondary button backgrounds, selected state
  static const Color primaryTint = Color(0x1Aec8451); // 10% opacity

  /// Primary shadow color for elevated buttons
  static const Color primaryShadow = Color(0x4Dec8451); // 30% opacity

  // ============================================
  // Background & Surface - Light Mode
  // ============================================

  static const Color backgroundLight = Color(0xFFf8f6f6);
  static const Color cardLight = Color(0xFFffffff);
  static const Color cardHoverLight = Color(0xFFfafafa);
  static const Color surfaceMutedLight = Color(0xFFebe8e6);

  // ============================================
  // Background & Surface - Dark Mode
  // ============================================

  static const Color backgroundDark = Color(0xFF211611);
  static const Color cardDark = Color(0xFF2a201c);
  static const Color cardHoverDark = Color(0xFF352924);
  static const Color surfaceMutedDark = Color(0xFF2a201c);

  // ============================================
  // Text Colors - Light Mode
  // ============================================

  /// 标题、主要内容
  static const Color textMainLight = Color(0xFF181311);

  /// 辅助信息、标签、占位符
  static const Color textMutedLight = Color(0xFF886f63);

  /// 输入框占位符
  static const Color textPlaceholderLight = Color(0xFF9ca3af);

  // ============================================
  // Text Colors - Dark Mode
  // ============================================

  static const Color textMainDark = Color(0xFFffffff);
  static const Color textMutedDark = Color(0xFF9ca3af);
  static const Color textPlaceholderDark = Color(0xFF6b7280);

  // ============================================
  // Border Colors
  // ============================================

  /// 聚焦边框
  static const Color borderFocus = Color(0x80ec8451); // 50% opacity

  /// 分隔线、微弱边框
  static const Color borderSubtleLight = Color(0xFFe5e7eb);
  static const Color borderSubtleDark = Color(0xFF3d2e28);

  // ============================================
  // Semantic Colors
  // ============================================

  /// 积分增加、完成确认
  static const Color success = Color(0xFF22c55e);
  static const Color successTint = Color(0x1A22c55e);

  /// Error state
  static const Color error = Color(0xFFef4444);
  static const Color errorTint = Color(0x1Aef4444);

  /// Warning state
  static const Color warning = Color(0xFFf59e0b);

  /// Info state
  static const Color info = Color(0xFF3b82f6);
}

/// Light mode color scheme based on UX specification
ColorScheme get lightColorScheme => const ColorScheme(
  brightness: Brightness.light,
  primary: AppColors.primary,
  onPrimary: Colors.white,
  primaryContainer: AppColors.primaryTint,
  onPrimaryContainer: AppColors.primaryDark,
  secondary: AppColors.primaryDark,
  onSecondary: Colors.white,
  secondaryContainer: AppColors.primaryTint,
  onSecondaryContainer: AppColors.primaryDark,
  error: AppColors.error,
  onError: Colors.white,
  errorContainer: Color(0xFFfee2e2),
  onErrorContainer: Color(0xFF991b1b),
  surface: AppColors.cardLight,
  onSurface: AppColors.textMainLight,
  surfaceContainerHighest: AppColors.backgroundLight,
  onSurfaceVariant: AppColors.textMutedLight,
  outline: AppColors.borderSubtleLight,
  outlineVariant: Color(0xFFe5e7eb),
);

/// Dark mode color scheme based on UX specification
ColorScheme get darkColorScheme => const ColorScheme(
  brightness: Brightness.dark,
  primary: AppColors.primary,
  onPrimary: Colors.white,
  primaryContainer: AppColors.primaryDark,
  onPrimaryContainer: Colors.white,
  secondary: AppColors.primaryDark,
  onSecondary: Colors.white,
  secondaryContainer: Color(0xFF3d2a22),
  onSecondaryContainer: AppColors.primary,
  error: AppColors.error,
  onError: Colors.white,
  errorContainer: Color(0xFF7f1d1d),
  onErrorContainer: Color(0xFFfecaca),
  surface: AppColors.cardDark,
  onSurface: AppColors.textMainDark,
  surfaceContainerHighest: AppColors.backgroundDark,
  onSurfaceVariant: AppColors.textMutedDark,
  outline: AppColors.borderSubtleDark,
  outlineVariant: Color(0xFF374151),
);
