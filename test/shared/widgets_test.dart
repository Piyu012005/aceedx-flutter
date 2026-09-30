import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aceedx_flutter/app/theme/app_theme.dart';
import 'package:aceedx_flutter/shared/widgets/app_button.dart';
import 'package:aceedx_flutter/shared/widgets/app_card.dart';
import 'package:aceedx_flutter/shared/widgets/app_loading_indicator.dart';
import 'package:aceedx_flutter/shared/widgets/app_text.dart';
import 'package:aceedx_flutter/shared/widgets/app_text_field.dart';

void main() {
  group('AceEdx Shared Primitives Tests', () {
    testWidgets('AppButton triggers onPressed callback and handles loading state', (WidgetTester tester) async {
      bool pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AppButton(
              label: 'Click Me',
              onPressed: () {
                pressed = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('Click Me'), findsOneWidget);
      await tester.tap(find.byType(AppButton));
      expect(pressed, isTrue);

      // Test loading state
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: AppButton(
              label: 'Loading...',
              isLoading: true,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('AppCard renders child and triggers tap', (WidgetTester tester) async {
      bool cardTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AppCard(
              onTap: () {
                cardTapped = true;
              },
              child: const Text('Card Content'),
            ),
          ),
        ),
      );

      expect(find.text('Card Content'), findsOneWidget);
      await tester.tap(find.text('Card Content'));
      expect(cardTapped, isTrue);
    });

    testWidgets('AppTextField accepts input and toggles password visibility', (WidgetTester tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AppTextField(
              controller: controller,
              label: 'Password Field',
              isPassword: true,
            ),
          ),
        ),
      );

      expect(find.text('Password Field'), findsOneWidget);
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);

      await tester.tap(find.byIcon(Icons.visibility_off));
      await tester.pump();

      expect(find.byIcon(Icons.visibility), findsOneWidget);
    });

    testWidgets('AppLoadingIndicator renders spinner and optional message', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: AppLoadingIndicator(message: 'Please wait...'),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Please wait...'), findsOneWidget);
    });

    testWidgets('AppHeading, AppSubheading, AppBodyText render properly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: Column(
              children: [
                AppHeading('Main Title'),
                AppSubheading('Subtitle'),
                AppBodyText('Body description'),
                AppCaptionText('Caption note'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Main Title'), findsOneWidget);
      expect(find.text('Subtitle'), findsOneWidget);
      expect(find.text('Body description'), findsOneWidget);
      expect(find.text('Caption note'), findsOneWidget);
    });
  });
}
