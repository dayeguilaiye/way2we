import 'package:flutter/material.dart';

/// Design system typography tokens based on UX Design Specification.
/// Primary Font: Plus Jakarta Sans
/// Chinese Fallback: PingFang SC (iOS) / Noto Sans SC (Android)
class AppTypography {
  AppTypography._();

  // ============================================
  // Font Family
  // ============================================

  /// Primary font family with fallbacks
  static const String fontFamily = 'Plus Jakarta Sans';

  /// Chinese font fallback for iOS
  static const String fontFamilyChinese = 'PingFang SC';

  /// Font family fallback list
  static const List<String> fontFamilyFallback = [
    'PingFang SC',
    'Noto Sans SC',
    'sans-serif',
  ];

  // ============================================
  // Font Weights
  // ============================================

  /// Regular - 正文
  static const FontWeight regular = FontWeight.w400;

  /// Medium - 强调正文
  static const FontWeight medium = FontWeight.w500;

  /// Bold - 标题、按钮
  static const FontWeight bold = FontWeight.w700;

  /// ExtraBold - 大数字
  static const FontWeight extraBold = FontWeight.w800;

  // ============================================
  // Type Scale (Size in logical pixels)
  // ============================================

  /// Display - 48px, ExtraBold
  static const double displaySize = 48;

  /// H1 - 20px, Bold
  static const double h1Size = 20;

  /// H2 - 18px, Bold
  static const double h2Size = 18;

  /// Body Large - 16px
  static const double bodyLargeSize = 16;

  /// Body - 14px
  static const double bodySize = 14;

  /// Caption - 12px
  static const double captionSize = 12;

  /// Small - 10px, Bold
  static const double smallSize = 10;
}

/// Create TextTheme based on UX specification
TextTheme createTextTheme(Color textColor, Color mutedColor) {
  return TextTheme(
    // Display styles
    displayLarge: TextStyle(
      fontSize: AppTypography.displaySize,
      fontWeight: AppTypography.extraBold,
      fontFamily: AppTypography.fontFamily,
      fontFamilyFallback: AppTypography.fontFamilyFallback,
      color: textColor,
      height: 1.2,
    ),
    displayMedium: TextStyle(
      fontSize: 36,
      fontWeight: AppTypography.extraBold,
      fontFamily: AppTypography.fontFamily,
      fontFamilyFallback: AppTypography.fontFamilyFallback,
      color: textColor,
      height: 1.2,
    ),
    displaySmall: TextStyle(
      fontSize: 32,
      fontWeight: AppTypography.bold,
      fontFamily: AppTypography.fontFamily,
      fontFamilyFallback: AppTypography.fontFamilyFallback,
      color: textColor,
      height: 1.2,
    ),

    // Headline styles (H1, H2)
    headlineLarge: TextStyle(
      fontSize: AppTypography.h1Size,
      fontWeight: AppTypography.bold,
      fontFamily: AppTypography.fontFamily,
      fontFamilyFallback: AppTypography.fontFamilyFallback,
      color: textColor,
      height: 1.3,
    ),
    headlineMedium: TextStyle(
      fontSize: AppTypography.h2Size,
      fontWeight: AppTypography.bold,
      fontFamily: AppTypography.fontFamily,
      fontFamilyFallback: AppTypography.fontFamilyFallback,
      color: textColor,
      height: 1.3,
    ),
    headlineSmall: TextStyle(
      fontSize: 16,
      fontWeight: AppTypography.bold,
      fontFamily: AppTypography.fontFamily,
      fontFamilyFallback: AppTypography.fontFamilyFallback,
      color: textColor,
      height: 1.3,
    ),

    // Title styles
    titleLarge: TextStyle(
      fontSize: AppTypography.h1Size,
      fontWeight: AppTypography.medium,
      fontFamily: AppTypography.fontFamily,
      fontFamilyFallback: AppTypography.fontFamilyFallback,
      color: textColor,
      height: 1.4,
    ),
    titleMedium: TextStyle(
      fontSize: AppTypography.bodyLargeSize,
      fontWeight: AppTypography.medium,
      fontFamily: AppTypography.fontFamily,
      fontFamilyFallback: AppTypography.fontFamilyFallback,
      color: textColor,
      height: 1.4,
    ),
    titleSmall: TextStyle(
      fontSize: AppTypography.bodySize,
      fontWeight: AppTypography.medium,
      fontFamily: AppTypography.fontFamily,
      fontFamilyFallback: AppTypography.fontFamilyFallback,
      color: textColor,
      height: 1.4,
    ),

    // Body styles
    bodyLarge: TextStyle(
      fontSize: AppTypography.bodyLargeSize,
      fontWeight: AppTypography.regular,
      fontFamily: AppTypography.fontFamily,
      fontFamilyFallback: AppTypography.fontFamilyFallback,
      color: textColor,
      height: 1.5,
    ),
    bodyMedium: TextStyle(
      fontSize: AppTypography.bodySize,
      fontWeight: AppTypography.regular,
      fontFamily: AppTypography.fontFamily,
      fontFamilyFallback: AppTypography.fontFamilyFallback,
      color: textColor,
      height: 1.5,
    ),
    bodySmall: TextStyle(
      fontSize: AppTypography.captionSize,
      fontWeight: AppTypography.regular,
      fontFamily: AppTypography.fontFamily,
      fontFamilyFallback: AppTypography.fontFamilyFallback,
      color: mutedColor,
      height: 1.5,
    ),

    // Label styles
    labelLarge: TextStyle(
      fontSize: AppTypography.bodySize,
      fontWeight: AppTypography.medium,
      fontFamily: AppTypography.fontFamily,
      fontFamilyFallback: AppTypography.fontFamilyFallback,
      color: textColor,
      letterSpacing: 0.1,
    ),
    labelMedium: TextStyle(
      fontSize: AppTypography.captionSize,
      fontWeight: AppTypography.medium,
      fontFamily: AppTypography.fontFamily,
      fontFamilyFallback: AppTypography.fontFamilyFallback,
      color: textColor,
      letterSpacing: 0.5,
    ),
    labelSmall: TextStyle(
      fontSize: AppTypography.smallSize,
      fontWeight: AppTypography.bold,
      fontFamily: AppTypography.fontFamily,
      fontFamilyFallback: AppTypography.fontFamilyFallback,
      color: mutedColor,
      letterSpacing: 0.5,
    ),
  );
}
