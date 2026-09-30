import 'package:flutter/material.dart';
import 'responsive_breakpoints.dart';

/// Builder widget that renders different layouts based on responsive breakpoints.
class ResponsiveLayout extends StatelessWidget {
  final WidgetBuilder mobile;
  final WidgetBuilder? tablet;
  final WidgetBuilder? desktop;
  final WidgetBuilder? largeDesktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
    this.largeDesktop,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        if (width >= ResponsiveBreakpoints.largeDesktopMin && largeDesktop != null) {
          return largeDesktop!(context);
        } else if (width >= ResponsiveBreakpoints.desktopMin && desktop != null) {
          return desktop!(context);
        } else if (width >= ResponsiveBreakpoints.tabletMin && tablet != null) {
          return tablet!(context);
        } else {
          return mobile(context);
        }
      },
    );
  }
}
