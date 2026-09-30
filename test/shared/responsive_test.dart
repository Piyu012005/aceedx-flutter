import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aceedx_flutter/shared/responsive/responsive_breakpoints.dart';
import 'package:aceedx_flutter/shared/responsive/responsive_layout.dart';

void main() {
  group('AceEdx Responsive System Tests', () {
    test('ResponsiveBreakpoints constants are correctly defined', () {
      expect(ResponsiveBreakpoints.mobileMax, 599.0);
      expect(ResponsiveBreakpoints.tabletMin, 600.0);
      expect(ResponsiveBreakpoints.desktopMin, 900.0);
      expect(ResponsiveBreakpoints.largeDesktopMin, 1200.0);
    });

    testWidgets('ResponsiveLayout renders mobile builder on small screen', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: ResponsiveLayout(
            mobile: (_) => const Text('Mobile Layout'),
            desktop: (_) => const Text('Desktop Layout'),
          ),
        ),
      );

      expect(find.text('Mobile Layout'), findsOneWidget);
      expect(find.text('Desktop Layout'), findsNothing);
    });

    testWidgets('ResponsiveLayout renders desktop builder on wide screen', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: ResponsiveLayout(
            mobile: (_) => const Text('Mobile Layout'),
            desktop: (_) => const Text('Desktop Layout'),
          ),
        ),
      );

      expect(find.text('Desktop Layout'), findsOneWidget);
      expect(find.text('Mobile Layout'), findsNothing);
    });
  });
}
