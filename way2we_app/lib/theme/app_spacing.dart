/// Design system spacing and layout tokens based on UX Design Specification.
/// Base unit: 4px
class AppSpacing {
  AppSpacing._();

  // ============================================
  // Spacing Scale (based on 4px unit)
  // ============================================

  /// 4px - Minimal spacing
  static const double space1 = 4;

  /// 8px - Tight spacing
  static const double space2 = 8;

  /// 12px - Compact spacing
  static const double space3 = 12;

  /// 16px - Default spacing
  static const double space4 = 16;

  /// 20px - Medium spacing
  static const double space5 = 20;

  /// 24px - Comfortable spacing
  static const double space6 = 24;

  /// 32px - Loose spacing
  static const double space8 = 32;

  /// 40px - Large spacing
  static const double space10 = 40;

  /// 48px - Extra large spacing
  static const double space12 = 48;

  /// Extra horizontal padding for pill-shaped inputs
  static const double inputPaddingH = 48;

  // ============================================
  // Border Radius
  // ============================================

  /// 8px - Small cards, buttons
  static const double radiusLg = 8;

  /// 16px - Large cards
  static const double radius = 16;

  /// 9999px - Full rounded (pills, avatars)
  static const double radiusFull = 9999;

  // ============================================
  // Component Specific
  // ============================================

  /// Page horizontal padding
  static const double pagePaddingH = space6; // 24px

  /// Page vertical padding
  static const double pagePaddingV = space4; // 16px

  /// Card internal padding
  static const double cardPadding = space4; // 16px

  /// Card compact padding (for horizontal scroll cards)
  static const double cardPaddingCompact = space3; // 12px

  /// Section gap between major sections
  static const double sectionGap = space8; // 32px

  /// Item gap in lists
  static const double itemGap = space3; // 12px

  /// Button internal vertical padding
  static const double buttonPaddingV = space3; // 12px

  /// Button internal horizontal padding
  static const double buttonPaddingH = space6; // 24px

  /// Minimum touch target size (44dp per UX accessibility spec)
  static const double minTouchTarget = 44;

  /// Unified input/button height for consistent UI
  static const double inputHeight = 56;
}
