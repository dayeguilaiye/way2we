import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppTheme {
  apricot('暖杏'),
  celadon('青瓷'),
  rose('雾玫');

  const AppTheme(this.label);
  final String label;
}

class ThemeChoice extends Notifier<AppTheme> {
  @override
  AppTheme build() => AppTheme.apricot;
  void select(AppTheme value) => state = value;
}

final themeProvider = NotifierProvider<ThemeChoice, AppTheme>(ThemeChoice.new);

@immutable
class BrandColors extends ThemeExtension<BrandColors> {
  const BrandColors({
    required this.background,
    required this.surface,
    required this.tint,
    required this.primary,
    required this.ink,
    required this.secondary,
    required this.divider,
    required this.outline,
  });
  final Color background,
      surface,
      tint,
      primary,
      ink,
      secondary,
      divider,
      outline;
  Color get positive => const Color(0xff4f754d);
  Color get negative => const Color(0xffaf493b);
  @override
  BrandColors copyWith({
    Color? background,
    Color? surface,
    Color? tint,
    Color? primary,
    Color? ink,
    Color? secondary,
    Color? divider,
    Color? outline,
  }) => BrandColors(
    background: background ?? this.background,
    surface: surface ?? this.surface,
    tint: tint ?? this.tint,
    primary: primary ?? this.primary,
    ink: ink ?? this.ink,
    secondary: secondary ?? this.secondary,
    divider: divider ?? this.divider,
    outline: outline ?? this.outline,
  );
  @override
  BrandColors lerp(covariant BrandColors? other, double t) {
    if (other == null) return this;
    return BrandColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      tint: Color.lerp(tint, other.tint, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      outline: Color.lerp(outline, other.outline, t)!,
    );
  }

  static BrandColors forTheme(AppTheme theme) => switch (theme) {
    AppTheme.apricot => const BrandColors(
      background: Color(0xfff8f4ee),
      surface: Color(0xfffffcf8),
      tint: Color(0xfff0dbce),
      primary: Color(0xffa65a40),
      ink: Color(0xff352d29),
      secondary: Color(0xff71685f),
      divider: Color(0xffe4d9cf),
      outline: Color(0xff978779),
    ),
    AppTheme.celadon => const BrandColors(
      background: Color(0xfff5f6ef),
      surface: Color(0xfffcfcf7),
      tint: Color(0xffe1e8dd),
      primary: Color(0xff506d5d),
      ink: Color(0xff2d3931),
      secondary: Color(0xff606d61),
      divider: Color(0xffd8dfd3),
      outline: Color(0xff829280),
    ),
    AppTheme.rose => const BrandColors(
      background: Color(0xfffaf4f2),
      surface: Color(0xfffffbf8),
      tint: Color(0xffefdfe2),
      primary: Color(0xff935d69),
      ink: Color(0xff3d3034),
      secondary: Color(0xff79676c),
      divider: Color(0xffe3d6d8),
      outline: Color(0xffa0878e),
    ),
  };
}

ThemeData buildTheme(AppTheme theme) {
  final c = BrandColors.forTheme(theme);
  final scheme =
      ColorScheme.fromSeed(
        seedColor: c.primary,
        brightness: Brightness.light,
      ).copyWith(
        primary: c.primary,
        onPrimary: Colors.white,
        surface: c.surface,
        onSurface: c.ink,
        onSurfaceVariant: c.secondary,
        outline: c.outline,
        outlineVariant: c.divider,
        error: c.negative,
        secondaryContainer: c.tint,
        onSecondaryContainer: c.ink,
      );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: c.background,
    extensions: [c],
    appBarTheme: AppBarTheme(
      backgroundColor: c.background,
      foregroundColor: c.ink,
      surfaceTintColor: Colors.transparent,
    ),
    dividerColor: c.divider,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.surface,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );
}
