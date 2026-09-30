import 'package:flutter/material.dart';
import '../../app/theme/design_tokens.dart';

/// Screen classification tiers extracted from AceEdx forensic analysis.
enum DeviceScreenType {
  mobile,
  tablet,
  desktop,
  largeDesktop,
}

/// Standard Responsive Breakpoint Constants.
class ResponsiveBreakpoints {
  const ResponsiveBreakpoints._();

  static const double mobileMax = 599.0;
  static const double tabletMin = 600.0;
  static const double tabletMax = 899.0;
  static const double desktopMin = 900.0;
  static const double desktopMax = 1199.0;
  static const double largeDesktopMin = 1200.0;
}

/// Responsive Helper Utilities for BuildContext.
extension ResponsiveContext on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;
  double get screenHeight => MediaQuery.sizeOf(this).height;

  bool get isMobile => screenWidth < ResponsiveBreakpoints.tabletMin;
  bool get isTablet =>
      screenWidth >= ResponsiveBreakpoints.tabletMin &&
      screenWidth < ResponsiveBreakpoints.desktopMin;
  bool get isDesktop =>
      screenWidth >= ResponsiveBreakpoints.desktopMin &&
      screenWidth < ResponsiveBreakpoints.largeDesktopMin;
  bool get isLargeDesktop =>
      screenWidth >= ResponsiveBreakpoints.largeDesktopMin;

  DeviceScreenType get screenType {
    final width = screenWidth;
    if (width < ResponsiveBreakpoints.tabletMin) {
      return DeviceScreenType.mobile;
    } else if (width < ResponsiveBreakpoints.desktopMin) {
      return DeviceScreenType.tablet;
    } else if (width < ResponsiveBreakpoints.largeDesktopMin) {
      return DeviceScreenType.desktop;
    } else {
      return DeviceScreenType.largeDesktop;
    }
  }

  /// Calculates responsive page horizontal padding according to old AceEdx bundle rules (`cSg(a)`).
  double get responsiveHorizontalPadding {
    final width = screenWidth;
    if (width < 400) return AppSpacing.md;
    if (width < ResponsiveBreakpoints.tabletMin) return AppDimensions.paddingMobile;
    if (width < ResponsiveBreakpoints.desktopMin) return AppDimensions.paddingTablet;
    if (width < ResponsiveBreakpoints.largeDesktopMin) return AppDimensions.paddingDesktop;
    return AppDimensions.paddingLargeDesktop;
  }

  /// Returns value based on screen type.
  T responsiveValue<T>({
    required T mobile,
    T? tablet,
    T? desktop,
    T? largeDesktop,
  }) {
    switch (screenType) {
      case DeviceScreenType.mobile:
        return mobile;
      case DeviceScreenType.tablet:
        return tablet ?? mobile;
      case DeviceScreenType.desktop:
        return desktop ?? tablet ?? mobile;
      case DeviceScreenType.largeDesktop:
        return largeDesktop ?? desktop ?? tablet ?? mobile;
    }
  }
}
