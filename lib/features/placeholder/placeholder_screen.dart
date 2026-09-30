import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../app/theme/design_tokens.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_card.dart';

/// Temporary development placeholder screen for routes awaiting full feature rebuild.
///
/// Preserves route paths, parameters, and navigation behaviors without
/// premature business module implementations.
class PlaceholderScreen extends StatelessWidget {
  final String title;
  final String path;
  final Map<String, dynamic>? queryParameters;
  final Map<String, dynamic>? pathParameters;

  const PlaceholderScreen({
    super.key,
    required this.title,
    required this.path,
    this.queryParameters,
    this.pathParameters,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(title, style: AppTypography.headlineSmall),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.home, color: AppColors.primary),
            tooltip: 'Go to Home',
            onPressed: () => context.go('/'),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: AppCard(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: AppRadius.radiusSm,
                        ),
                        child: const Icon(
                          Icons.construction,
                          color: AppColors.primary,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Module: $title',
                              style: AppTypography.headlineMedium,
                            ),
                            Text(
                              'Reconstruction Pending',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: AppSpacing.xxxl),
                  _buildDetailRow('Route Path:', path),
                  if (pathParameters != null && pathParameters!.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    _buildDetailRow('Path Parameters:', pathParameters.toString()),
                  ],
                  if (queryParameters != null && queryParameters!.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    _buildDetailRow('Query Parameters:', queryParameters.toString()),
                  ],
                  const SizedBox(height: AppSpacing.xxl),
                  AppButton(
                    label: 'Back to Home',
                    variant: AppButtonVariant.primary,
                    leadingIcon: const Icon(Icons.arrow_back, color: Colors.white, size: 18),
                    onPressed: () => context.go('/'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ],
    );
  }
}

/// 404 Not Found Screen for unknown routes.
class NotFoundScreen extends StatelessWidget {
  final String? location;

  const NotFoundScreen({
    super.key,
    this.location,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: AppCard(
              padding: const EdgeInsets.all(AppSpacing.xxxl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: AppColors.error,
                    size: 64,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Page Not Found (404)',
                    style: AppTypography.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'The route "${location ?? 'unknown'}" does not exist.',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  AppButton(
                    label: 'Return to Home',
                    variant: AppButtonVariant.primary,
                    leadingIcon: const Icon(Icons.home, color: Colors.white, size: 18),
                    onPressed: () => context.go('/'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
