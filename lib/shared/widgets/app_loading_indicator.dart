import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../app/theme/design_tokens.dart';

/// Standard Loading Spinner Indicator for AceEdx Application.
class AppLoadingIndicator extends StatelessWidget {
  final double size;
  final double strokeWidth;
  final Color? color;
  final String? message;

  const AppLoadingIndicator({
    super.key,
    this.size = 36.0,
    this.strokeWidth = 3.0,
    this.color,
    this.message,
  });

  const AppLoadingIndicator.small({
    super.key,
    this.size = 18.0,
    this.strokeWidth = 2.0,
    this.color,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.primary;

    Widget indicator = SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        valueColor: AlwaysStoppedAnimation<Color>(effectiveColor),
      ),
    );

    if (message != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            indicator,
            const SizedBox(height: AppSpacing.md),
            Text(
              message!,
              style: AppTypography.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Center(child: indicator);
  }
}
