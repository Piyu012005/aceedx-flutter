import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/design_tokens.dart';

/// Standard Card Container for AceEdx Application.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final BorderSide? border;
  final BorderRadius? borderRadius;
  final List<BoxShadow>? shadows;
  final double? width;
  final double? height;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.margin,
    this.onTap,
    this.backgroundColor,
    this.border,
    this.borderRadius,
    this.shadows,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = borderRadius ?? AppRadius.radiusXl;
    final effectiveBorder = border ??
        const BorderSide(
          color: AppColors.border,
          width: 1.0,
        );

    Widget cardContent = Container(
      width: width,
      height: height,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.card,
        borderRadius: effectiveRadius,
        border: Border.fromBorderSide(effectiveBorder),
        boxShadow: shadows ?? AppShadows.card,
      ),
      child: child,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        borderRadius: effectiveRadius,
        child: InkWell(
          onTap: onTap,
          borderRadius: effectiveRadius,
          child: cardContent,
        ),
      );
    }

    return cardContent;
  }
}
