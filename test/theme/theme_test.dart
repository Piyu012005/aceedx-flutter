import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aceedx_flutter/app/theme/app_colors.dart';
import 'package:aceedx_flutter/app/theme/app_theme.dart';
import 'package:aceedx_flutter/app/theme/design_tokens.dart';

void main() {
  group('AceEdx Theme & Design Tokens Tests', () {
    test('AppColors contains valid non-null brand colors', () {
      expect(AppColors.primary, const Color(0xFF1E3A8A));
      expect(AppColors.secondary, const Color(0xFF06B6D4));
      expect(AppColors.success, const Color(0xFF10B981));
      expect(AppColors.warning, const Color(0xFFF59E0B));
      expect(AppColors.error, const Color(0xFFEF4444));
      expect(AppColors.background, const Color(0xFFF8FAFC));
      expect(AppColors.surface, const Color(0xFFFFFFFF));
    });

    test('AppSpacing and AppDimensions have expected scale', () {
      expect(AppSpacing.xs, 4.0);
      expect(AppSpacing.sm, 8.0);
      expect(AppSpacing.md, 12.0);
      expect(AppSpacing.lg, 16.0);
      expect(AppSpacing.xl, 20.0);
      expect(AppSpacing.xxl, 24.0);

      expect(AppDimensions.headerHeight, 70.0);
      expect(AppDimensions.sidebarWidthDesktop, 240.0);
      expect(AppDimensions.buttonHeight, 44.0);
    });

    test('AppTheme initializes valid ThemeData', () {
      final theme = AppTheme.lightTheme;

      expect(theme.colorScheme.primary, AppColors.primary);
      expect(theme.scaffoldBackgroundColor, AppColors.background);
      expect(theme.useMaterial3, isTrue);
    });
  });
}
