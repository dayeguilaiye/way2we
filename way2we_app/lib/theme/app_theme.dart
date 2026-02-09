import 'package:flutter/material.dart';
import 'package:way2we_app/theme/app_colors.dart';
import 'package:way2we_app/theme/app_home_chrome.dart';
import 'package:way2we_app/theme/app_spacing.dart';
import 'package:way2we_app/theme/app_typography.dart';

/// App theme configuration based on UX Design Specification.
///
/// Design System: Themeable Design System
/// Current Theme: Warm Orange (温暖橙)
///
/// Key Features:
/// - Primary color: #ec8451 (Warm Orange)
/// - Pill-shaped inputs and buttons (rounded-full)
/// - Light/Dark mode support
/// - Plus Jakarta Sans typography with Chinese fallback
/// - 4px-based spacing system
class AppTheme {
  AppTheme._();

  /// Light theme based on UX specification
  static ThemeData get light {
    final colorScheme = lightColorScheme;
    final textTheme = createTextTheme(
      AppColors.textMainLight,
      AppColors.textMutedLight,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.backgroundLight,
      textTheme: textTheme,
      extensions: const <ThemeExtension<dynamic>>[
        AppHomeChrome.light,
      ],

      // AppBar
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.backgroundLight,
        foregroundColor: AppColors.textMainLight,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.headlineLarge,
      ),

      // Cards
      cardTheme: CardThemeData(
        color: AppColors.cardLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radius),
        ),
        margin: EdgeInsets.zero,
      ),

      // Filled Button (Primary)
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: colorScheme.outline,
          disabledForegroundColor: colorScheme.onSurfaceVariant,
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.buttonPaddingV,
            horizontal: AppSpacing.buttonPaddingH,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: AppTypography.bold,
          ),
          minimumSize: const Size(0, AppSpacing.minTouchTarget),
        ),
      ),

      // Outlined Button (Ghost)
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.buttonPaddingV,
            horizontal: AppSpacing.buttonPaddingH,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: AppTypography.bold,
          ),
          minimumSize: const Size(0, AppSpacing.minTouchTarget),
        ),
      ),

      // Text Button (Secondary)
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          backgroundColor: AppColors.primaryTint,
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.buttonPaddingV,
            horizontal: AppSpacing.buttonPaddingH,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: AppTypography.bold,
          ),
          minimumSize: const Size(0, AppSpacing.minTouchTarget),
        ),
      ),

      // Input Decoration - Pill-shaped, borderless design per UX spec
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.cardLight,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space12, // Extra padding for pill shape
          vertical: AppSpacing.space4,
        ),
        // Pill-shaped border radius
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          borderSide: const BorderSide(
            color: AppColors.borderFocus,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        labelStyle: textTheme.labelSmall?.copyWith(
          color: AppColors.textMutedLight,
          fontWeight: AppTypography.bold,
          letterSpacing: 0.5,
        ),
        hintStyle: textTheme.bodyLarge?.copyWith(
          color: AppColors.textPlaceholderLight,
        ),
        errorStyle: textTheme.bodySmall?.copyWith(
          color: AppColors.error,
        ),
        // Add shadow effect for inputs
        floatingLabelBehavior: FloatingLabelBehavior.never,
      ),

      // Segmented Button
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.primary;
            }
            return AppColors.cardLight;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return Colors.white;
            }
            return AppColors.textMainLight;
          }),
          side: WidgetStateProperty.all(
            BorderSide(color: colorScheme.outline),
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            ),
          ),
          minimumSize: WidgetStateProperty.all(
            const Size(0, AppSpacing.minTouchTarget),
          ),
        ),
      ),

      // Snackbar (for feedback)
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textMainLight,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: Colors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.cardLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radius),
        ),
        titleTextStyle: textTheme.headlineMedium,
        contentTextStyle: textTheme.bodyMedium,
      ),

      // Divider
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),

      // Bottom Navigation Bar
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.cardLight,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMutedLight,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: textTheme.labelSmall?.copyWith(
          fontWeight: AppTypography.medium,
        ),
        unselectedLabelStyle: textTheme.labelSmall,
      ),
    );
  }

  /// Dark theme based on UX specification
  static ThemeData get dark {
    final colorScheme = darkColorScheme;
    final textTheme = createTextTheme(
      AppColors.textMainDark,
      AppColors.textMutedDark,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      textTheme: textTheme,
      extensions: const <ThemeExtension<dynamic>>[
        AppHomeChrome.dark,
      ],

      // AppBar
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.backgroundDark,
        foregroundColor: AppColors.textMainDark,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.headlineLarge,
      ),

      // Cards
      cardTheme: CardThemeData(
        color: AppColors.cardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radius),
        ),
        margin: EdgeInsets.zero,
      ),

      // Filled Button (Primary)
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: colorScheme.outline,
          disabledForegroundColor: colorScheme.onSurfaceVariant,
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.buttonPaddingV,
            horizontal: AppSpacing.buttonPaddingH,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: AppTypography.bold,
          ),
          minimumSize: const Size(0, AppSpacing.minTouchTarget),
        ),
      ),

      // Outlined Button (Ghost)
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.buttonPaddingV,
            horizontal: AppSpacing.buttonPaddingH,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: AppTypography.bold,
          ),
          minimumSize: const Size(0, AppSpacing.minTouchTarget),
        ),
      ),

      // Text Button (Secondary)
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          backgroundColor: colorScheme.secondaryContainer,
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.buttonPaddingV,
            horizontal: AppSpacing.buttonPaddingH,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: AppTypography.bold,
          ),
          minimumSize: const Size(0, AppSpacing.minTouchTarget),
        ),
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.cardDark,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space4,
          vertical: AppSpacing.space3,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: AppColors.textMutedDark,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: AppColors.textMutedDark,
        ),
        errorStyle: textTheme.bodySmall?.copyWith(
          color: AppColors.error,
        ),
      ),

      // Segmented Button
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.primary;
            }
            return AppColors.cardDark;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return Colors.white;
            }
            return AppColors.textMainDark;
          }),
          side: WidgetStateProperty.all(
            BorderSide(color: colorScheme.outline),
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            ),
          ),
          minimumSize: WidgetStateProperty.all(
            const Size(0, AppSpacing.minTouchTarget),
          ),
        ),
      ),

      // Snackbar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.cardDark,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: AppColors.textMainDark,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radius),
        ),
        titleTextStyle: textTheme.headlineMedium,
        contentTextStyle: textTheme.bodyMedium,
      ),

      // Divider
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),

      // Bottom Navigation Bar
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.cardDark,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMutedDark,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: textTheme.labelSmall?.copyWith(
          fontWeight: AppTypography.medium,
        ),
        unselectedLabelStyle: textTheme.labelSmall,
      ),
    );
  }
}
