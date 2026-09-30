import 'package:flutter/material.dart';
import '../../shared/responsive/responsive_breakpoints.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/app_loading_indicator.dart';
import '../../shared/widgets/app_text.dart';
import '../../shared/widgets/app_text_field.dart';
import 'app_colors.dart';
import 'app_typography.dart';
import 'design_tokens.dart';

/// Temporary Development-Only Theme Preview Screen.
///
/// Used exclusively in development to visually verify design tokens, colors,
/// typography, buttons, cards, form fields, and responsive behavior.
/// (Not part of the production 41-route application map).
class ThemePreviewScreen extends StatefulWidget {
  const ThemePreviewScreen({super.key});

  @override
  State<ThemePreviewScreen> createState() => _ThemePreviewScreenState();
}

class _ThemePreviewScreenState extends State<ThemePreviewScreen> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoadingButton = false;

  @override
  void dispose() {
    _textController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AceEdx Design System Preview (DEV)'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: AppSpacing.lg),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withValues(alpha: 0.15),
                  borderRadius: AppRadius.radiusFull,
                ),
                child: Text(
                  '${context.screenType.name.toUpperCase()} (${context.screenWidth.toInt()}px)',
                  style: AppTypography.badgeText.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: context.responsiveHorizontalPadding,
          vertical: AppSpacing.xxl,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppDimensions.maxContentWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section 1: Color Palette
                const AppHeading('1. Color Palette'),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.md,
                  children: [
                    _ColorChip('Primary', AppColors.primary, AppColors.textOnPrimary),
                    _ColorChip('Primary Light', AppColors.primaryLight, AppColors.textOnPrimary),
                    _ColorChip('Secondary', AppColors.secondary, Colors.white),
                    _ColorChip('Success (Approved)', AppColors.success, Colors.white),
                    _ColorChip('Warning (Pending)', AppColors.warning, Colors.white),
                    _ColorChip('Error (Rejected)', AppColors.error, Colors.white),
                    _ColorChip('Dark Sidebar', AppColors.sidebarBackground, AppColors.sidebarText),
                    _ColorChip('Workspace Bg', AppColors.workspaceBackground, AppColors.textPrimary),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxxl),

                // Section 2: Typography
                const AppHeading('2. Typography Scale'),
                const SizedBox(height: AppSpacing.md),
                const AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Display Large - 32px Bold', style: AppTypography.displayLarge),
                      SizedBox(height: AppSpacing.sm),
                      Text('Headline Medium - 20px SemiBold', style: AppTypography.headlineMedium),
                      SizedBox(height: AppSpacing.sm),
                      Text('Title Large - 16px SemiBold', style: AppTypography.titleLarge),
                      SizedBox(height: AppSpacing.sm),
                      Text('Body Medium - 14px Regular: AceEdx is an education technology platform empowering schools, teachers, and students.', style: AppTypography.bodyMedium),
                      SizedBox(height: AppSpacing.sm),
                      Text('Body Small / Caption - 13px Muted text for hints and timestamps.', style: AppTypography.bodySmall),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xxxl),

                // Section 3: Buttons
                const AppHeading('3. Buttons & Actions'),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.md,
                  children: [
                    AppButton.primary(
                      label: 'Primary Button',
                      leadingIcon: const Icon(Icons.check, size: AppDimensions.iconSm),
                      onPressed: () {},
                    ),
                    AppButton.secondary(
                      label: 'Secondary Button',
                      onPressed: () {},
                    ),
                    AppButton.outline(
                      label: 'Outline Button',
                      onPressed: () {},
                    ),
                    AppButton.danger(
                      label: 'Danger / Delete',
                      leadingIcon: const Icon(Icons.delete_outline, size: AppDimensions.iconSm),
                      onPressed: () {},
                    ),
                    AppButton.primary(
                      label: 'Toggle Loading State',
                      isLoading: _isLoadingButton,
                      onPressed: () {
                        setState(() {
                          _isLoadingButton = !_isLoadingButton;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxxl),

                // Section 4: Form Fields
                const AppHeading('4. Form Controls'),
                const SizedBox(height: AppSpacing.md),
                AppCard(
                  child: Column(
                    children: [
                      AppTextField(
                        controller: _textController,
                        label: 'Email Address',
                        hint: 'Enter your institutional email',
                        prefixIcon: const Icon(Icons.email_outlined),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      AppTextField(
                        controller: _passwordController,
                        label: 'Password',
                        hint: 'Enter your secure password',
                        isPassword: true,
                        prefixIcon: const Icon(Icons.lock_outline),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      const AppTextField(
                        label: 'Field with Error',
                        hint: 'Invalid input demonstration',
                        errorText: 'This field is required',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xxxl),

                // Section 5: Loading & Card States
                const AppHeading('5. Feedback & Indicators'),
                const SizedBox(height: AppSpacing.md),
                const Row(
                  children: [
                    AppLoadingIndicator(message: 'Loading curriculum data...'),
                    SizedBox(width: AppSpacing.xxl),
                    AppLoadingIndicator.small(),
                  ],
                ),
                const SizedBox(height: AppSpacing.huge),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ColorChip extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;

  const _ColorChip(this.label, this.color, this.textColor);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color,
        borderRadius: AppRadius.radiusMd,
        border: Border.all(color: AppColors.border, width: 0.5),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.labelMedium.copyWith(
              color: textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
            style: AppTypography.labelSmall.copyWith(color: textColor.withValues(alpha: 0.85)),
          ),
        ],
      ),
    );
  }
}
