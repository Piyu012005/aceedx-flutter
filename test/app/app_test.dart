import 'package:flutter_test/flutter_test.dart';
import 'package:aceedx_flutter/app/app.dart';
import 'package:aceedx_flutter/app/config/app_config.dart';
import 'package:aceedx_flutter/app/theme/theme_preview_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AceEdx App Root Tests', () {
    test('AppConfig loads development environment as default', () {
      expect(AppConfig.current.environment, Environment.development);
      expect(AppConfig.isDev, isTrue);
      expect(AppConfig.isProd, isFalse);
      expect(AppConfig.current.apiBaseUrl, 'https://deve.aceedx.com/api');
    });

    testWidgets('AceEdxApp(showPreview: true) mounts with ThemePreviewScreen', (WidgetTester tester) async {
      await tester.pumpWidget(const AceEdxApp(showPreview: true));

      expect(find.byType(AceEdxApp), findsOneWidget);
      expect(find.byType(ThemePreviewScreen), findsOneWidget);
      expect(find.text('AceEdx Design System Preview (DEV)'), findsOneWidget);
    });

    testWidgets('AceEdxApp() mounts with router and loads correctly', (WidgetTester tester) async {
      await tester.pumpWidget(const AceEdxApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(AceEdxApp), findsOneWidget);
    });
  });
}
