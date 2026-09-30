import 'package:flutter/material.dart';

/// Standard spacing tokens for AceEdx Flutter application.
/// Eliminates magic numbers across all layout widgets.
class AppSpacing {
  const AppSpacing._();

  static const double xxs = 2.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double xxxl = 32.0;
  static const double huge = 48.0;
  static const double massive = 64.0;
}

/// Standard border radius tokens extracted from old AceEdx bundle.
class AppRadius {
  const AppRadius._();

  static const double xs = 4.0;
  static const double sm = 6.0;
  static const double md = 8.0;
  static const double lg = 10.0;
  static const double xl = 12.0;
  static const double xxl = 16.0;
  static const double round = 24.0;
  static const double full = 999.0;

  static BorderRadius get radiusXs => BorderRadius.circular(xs);
  static BorderRadius get radiusSm => BorderRadius.circular(sm);
  static BorderRadius get radiusMd => BorderRadius.circular(md);
  static BorderRadius get radiusLg => BorderRadius.circular(lg);
  static BorderRadius get radiusXl => BorderRadius.circular(xl);
  static BorderRadius get radiusXxl => BorderRadius.circular(xxl);
  static BorderRadius get radiusRound => BorderRadius.circular(round);
  static BorderRadius get radiusFull => BorderRadius.circular(full);
}

/// Standard component heights and dimensions.
class AppDimensions {
  const AppDimensions._();

  // Layout Containers
  static const double headerHeight = 70.0;
  static const double sidebarWidthDesktop = 240.0;
  static const double sidebarWidthExpanded = 260.0;
  static const double sidebarWidthCompact = 70.0;
  static const double maxContentWidth = 1440.0;
  static const double modalMaxWidth = 600.0;

  // Buttons & Controls
  static const double buttonHeight = 44.0;
  static const double buttonHeightSmall = 34.0;
  static const double buttonHeightLarge = 50.0;
  static const double inputHeight = 46.0;

  // Icons
  static const double iconXs = 14.0;
  static const double iconSm = 18.0;
  static const double iconMd = 22.0;
  static const double iconLg = 28.0;
  static const double iconXl = 36.0;

  // Responsive Content Horizontal Padding
  static const double paddingMobile = 16.0;
  static const double paddingTablet = 24.0;
  static const double paddingDesktop = 32.0;
  static const double paddingLargeDesktop = 48.0;
}

/// Reusable elevation and box shadow tokens.
class AppShadows {
  const AppShadows._();

  /// Subtle card shadow (standard card elevation)
  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x0D000000), // Black with 5% opacity
      blurRadius: 8.0,
      offset: Offset(0, 2),
    ),
  ];

  /// Elevated component / dropdown shadow
  static const List<BoxShadow> elevated = [
    BoxShadow(
      color: Color(0x1A000000), // Black with 10% opacity
      blurRadius: 14.0,
      offset: Offset(0, 4),
    ),
  ];

  /// Deep modal / dialog shadow
  static const List<BoxShadow> modal = [
    BoxShadow(
      color: Color(0x26000000), // Black with 15% opacity
      blurRadius: 24.0,
      offset: Offset(0, 8),
    ),
  ];
}
