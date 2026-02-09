import 'package:flutter/material.dart';

/// Theme extension for home screen chrome tokens.
///
/// These tokens isolate page-level visual language (background and header)
/// from generic component tokens so we can add more theme families later.
@immutable
class AppHomeChrome extends ThemeExtension<AppHomeChrome> {
  const AppHomeChrome({
    required this.backgroundBase,
    required this.backgroundElevated,
    required this.topBarBackground,
    required this.topBarBorder,
    required this.avatarBackground,
    required this.avatarForeground,
    required this.iconBackground,
    required this.iconForeground,
    required this.notificationDot,
    required this.notificationDotBorder,
  });

  static const AppHomeChrome light = AppHomeChrome(
    backgroundBase: Color(0xFFF8F6F6),
    backgroundElevated: Color(0xFFF1EEEE),
    topBarBackground: Color(0xEAF8F6F6),
    topBarBorder: Color(0x14FFFFFF),
    avatarBackground: Color(0xFFFFE7DA),
    avatarForeground: Color(0xFFEC3713),
    iconBackground: Color(0xFFF1ECEA),
    iconForeground: Color(0xFF181311),
    notificationDot: Color(0xFFEC3713),
    notificationDotBorder: Color(0xFFF8F6F6),
  );

  static const AppHomeChrome dark = AppHomeChrome(
    backgroundBase: Color(0xFF211611),
    backgroundElevated: Color(0xFF281C17),
    topBarBackground: Color(0xE3211611),
    topBarBorder: Color(0x1FFFFFFF),
    avatarBackground: Color(0x44EC8451),
    avatarForeground: Color(0xFFFFC3A8),
    iconBackground: Color(0xFF332620),
    iconForeground: Color(0xFFFFFFFF),
    notificationDot: Color(0xFFEC8451),
    notificationDotBorder: Color(0xFF211611),
  );

  final Color backgroundBase;
  final Color backgroundElevated;
  final Color topBarBackground;
  final Color topBarBorder;
  final Color avatarBackground;
  final Color avatarForeground;
  final Color iconBackground;
  final Color iconForeground;
  final Color notificationDot;
  final Color notificationDotBorder;

  @override
  AppHomeChrome copyWith({
    Color? backgroundBase,
    Color? backgroundElevated,
    Color? topBarBackground,
    Color? topBarBorder,
    Color? avatarBackground,
    Color? avatarForeground,
    Color? iconBackground,
    Color? iconForeground,
    Color? notificationDot,
    Color? notificationDotBorder,
  }) {
    return AppHomeChrome(
      backgroundBase: backgroundBase ?? this.backgroundBase,
      backgroundElevated: backgroundElevated ?? this.backgroundElevated,
      topBarBackground: topBarBackground ?? this.topBarBackground,
      topBarBorder: topBarBorder ?? this.topBarBorder,
      avatarBackground: avatarBackground ?? this.avatarBackground,
      avatarForeground: avatarForeground ?? this.avatarForeground,
      iconBackground: iconBackground ?? this.iconBackground,
      iconForeground: iconForeground ?? this.iconForeground,
      notificationDot: notificationDot ?? this.notificationDot,
      notificationDotBorder:
          notificationDotBorder ?? this.notificationDotBorder,
    );
  }

  @override
  AppHomeChrome lerp(ThemeExtension<AppHomeChrome>? other, double t) {
    if (other is! AppHomeChrome) {
      return this;
    }
    return AppHomeChrome(
      backgroundBase: Color.lerp(backgroundBase, other.backgroundBase, t)!,
      backgroundElevated: Color.lerp(
        backgroundElevated,
        other.backgroundElevated,
        t,
      )!,
      topBarBackground: Color.lerp(
        topBarBackground,
        other.topBarBackground,
        t,
      )!,
      topBarBorder: Color.lerp(topBarBorder, other.topBarBorder, t)!,
      avatarBackground: Color.lerp(
        avatarBackground,
        other.avatarBackground,
        t,
      )!,
      avatarForeground: Color.lerp(
        avatarForeground,
        other.avatarForeground,
        t,
      )!,
      iconBackground: Color.lerp(iconBackground, other.iconBackground, t)!,
      iconForeground: Color.lerp(iconForeground, other.iconForeground, t)!,
      notificationDot: Color.lerp(notificationDot, other.notificationDot, t)!,
      notificationDotBorder: Color.lerp(
        notificationDotBorder,
        other.notificationDotBorder,
        t,
      )!,
    );
  }
}

extension AppHomeChromeTheme on ThemeData {
  AppHomeChrome get homeChrome {
    return extension<AppHomeChrome>() ??
        (brightness == Brightness.dark
            ? AppHomeChrome.dark
            : AppHomeChrome.light);
  }
}
