import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/app_routes.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../app/theme/design_tokens.dart';
import '../../core/api/api_client.dart';
import '../../core/auth/auth_service.dart';
import '../../core/storage/session_storage.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_text_field.dart';

/// AceEdx Login Screen.
///
/// Faithfully reconstructed from compiled Flutter Web AST (`A.DN` / `A.a2l`).
/// Features 2-column desktop layout with branding banner, single-column mobile/tablet layout,
/// role selection dropdown, client-side validation, and authentication service integration.
class LoginScreen extends StatefulWidget {
  final AuthenticationService? authService;
  final SessionStorage? sessionStorage;

  const LoginScreen({
    super.key,
    this.authService,
    this.sessionStorage,
  });

  /// The 6 verified roles extracted from compiled constant `B.WY`.
  static const List<String> availableRoles = [
    'parent',
    'student',
    'teacher',
    'vendor',
    'school_admin',
    'super_admin',
  ];

  /// Formats snake_case roles to Title Case labels matching `A.a2l.b7i`.
  static String formatRoleName(String role) {
    return role
        .split('_')
        .map((word) => word.isNotEmpty
            ? '${word[0].toUpperCase()}${word.substring(1)}'
            : '')
        .join(' ');
  }

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  AuthenticationService? _authService;

  String? _selectedRole;
  bool _isLoading = false;

  static const String _aboutAceEdxText =
      'AceEdX is an AI-powered education SaaS marketplace designed to bring '
      'schools, educators, parents, students, and education service providers '
      'together on one trusted digital platform.';

  static const String _missionText =
      'Our mission is to simplify access, improve quality, and unlock opportunities '
      'across the entire education value chain.';

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();

    if (widget.authService != null) {
      _authService = widget.authService!;
    } else if (widget.sessionStorage != null) {
      final storage = widget.sessionStorage!;
      final apiClient = ApiClient(sessionStorage: storage);
      _authService = AuthenticationService(
        apiClient: apiClient,
        sessionStorage: storage,
      );
    } else {
      _initDefaultAuthService();
    }
  }

  Future<void> _initDefaultAuthService() async {
    final storage = await SessionStorage.init();
    final apiClient = ApiClient(sessionStorage: storage);
    if (mounted) {
      setState(() {
        _authService = AuthenticationService(
          apiClient: apiClient,
          sessionStorage: storage,
        );
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (_isLoading) return;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedRole == null || _selectedRole!.isEmpty) {
      _showErrorSnackBar('Please select a role');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      final role = _selectedRole!;

      if (_authService == null) {
        _showErrorSnackBar('Authentication service initializing. Please retry.');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final result = await _authService!.login(
        email: email,
        password: password,
        role: role,
      );

      if (!mounted) return;

      if (result.success) {
        final destination = AppRoutes.getDashboardForRole(role);
        context.go(destination);
      } else {
        _showErrorSnackBar(result.message);
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar(e.toString().replaceAll('Exception: ', ''));
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _handleBackNavigation() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < 600;
    final isTablet = width >= 600 && width < 900;
    final isDesktop = width >= 900;

    final horizontalPadding = isMobile ? 16.0 : (isTablet ? 32.0 : 80.0);
    final verticalPadding = isMobile ? 20.0 : (isTablet ? 32.0 : 48.0);
    final maxContainerWidth = isDesktop ? 1200.0 : (isTablet ? 700.0 : double.infinity);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxContainerWidth),
              child: isDesktop
                  ? _buildDesktopLayout(context)
                  : _buildMobileTabletLayout(context, isMobile: isMobile),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left Banner Card (Branding & Overview)
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.huge),
              decoration: BoxDecoration(
                borderRadius: AppRadius.radiusXxl,
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Image.asset(
                      'assets/images/AceEdxLogo-removebg-preview.png',
                      width: 180,
                      height: 180,
                      errorBuilder: (_, _, _) => Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Text(
                            'AceEdX',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  Text(
                    'Welcome Back!',
                    style: AppTypography.displayMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    _aboutAceEdxText,
                    style: AppTypography.bodyMedium.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    _missionText,
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: AppSpacing.xxl),

          // Right Form Card
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.xxxl),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadius.radiusXxl,
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: _buildForm(context, isDesktop: true),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileTabletLayout(BuildContext context, {required bool isMobile}) {
    final logoSize = isMobile ? 120.0 : 140.0;
    final cardPadding = isMobile ? AppSpacing.xxl : AppSpacing.xxxl;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Top Back Button
        Align(
          alignment: Alignment.centerLeft,
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            tooltip: 'Back to Home',
            onPressed: _handleBackNavigation,
          ),
        ),

        // Brand Logo
        Center(
          child: Image.asset(
            'assets/images/AceEdxLogo-removebg-preview.png',
            width: logoSize,
            height: logoSize,
            errorBuilder: (_, _, _) => Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text(
                  'AceEdX',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.xl),

        // About AceEdx Card
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.radiusXl,
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'About AceEdX',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                _aboutAceEdxText,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.xl),

        // Form Card
        Container(
          padding: EdgeInsets.all(cardPadding),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.radiusXxl,
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: _buildForm(context, isDesktop: false),
        ),
      ],
    );
  }

  Widget _buildForm(BuildContext context, {required bool isDesktop}) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isDesktop) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                  tooltip: 'Back to Home',
                  onPressed: _handleBackNavigation,
                ),
                Text(
                  'AceEdX Portal',
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Login to Your Account',
              style: AppTypography.headlineMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Welcome back! Please enter your details.',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
          ] else ...[
            Text(
              'Login',
              style: AppTypography.headlineMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],

          // Role Dropdown
          DropdownButtonFormField<String>(
            key: const Key('role_dropdown'),
            initialValue: _selectedRole,
            decoration: InputDecoration(
              labelText: 'Role *',
              prefixIcon: const Icon(Icons.person_outline, color: AppColors.textMuted),
              border: OutlineInputBorder(
                borderRadius: AppRadius.radiusMd,
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: AppRadius.radiusMd,
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: AppRadius.radiusMd,
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md,
              ),
            ),
            items: LoginScreen.availableRoles.map((role) {
              return DropdownMenuItem<String>(
                value: role,
                child: Text(
                  LoginScreen.formatRoleName(role),
                  style: AppTypography.bodyMedium,
                ),
              );
            }).toList(),
            onChanged: _isLoading
                ? null
                : (value) {
                    setState(() {
                      _selectedRole = value;
                    });
                  },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select a role';
              }
              return null;
            },
          ),

          const SizedBox(height: AppSpacing.lg),

          // Email Field
          AppTextField(
            key: const Key('email_field'),
            controller: _emailController,
            label: 'Email',
            keyboardType: TextInputType.emailAddress,
            prefixIcon: const Icon(Icons.email_outlined),
            enabled: !_isLoading,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your email';
              }
              final emailRegex =
                  RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
              if (!emailRegex.hasMatch(value.trim())) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),

          const SizedBox(height: AppSpacing.lg),

          // Password Field
          AppTextField(
            key: const Key('password_field'),
            controller: _passwordController,
            label: 'Password',
            isPassword: true,
            prefixIcon: const Icon(Icons.lock_outline),
            enabled: !_isLoading,
            onSubmitted: (_) {
              if (!_isLoading) {
                _handleLogin();
              }
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your password';
              }
              if (value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ),

          const SizedBox(height: AppSpacing.xs),

          // Forgot Password Link
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              key: const Key('forgot_password_button'),
              onPressed: _isLoading
                  ? null
                  : () {
                      context.push(AppRoutes.passwordReset);
                    },
              child: Text(
                'Forgot Password?',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // Login Button
          AppButton(
            key: const Key('login_button'),
            label: 'Login',
            isLoading: _isLoading,
            isFullWidth: true,
            size: AppButtonSize.large,
            onPressed: _isLoading ? null : _handleLogin,
          ),

          const SizedBox(height: AppSpacing.lg),

          // Register Link
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                "Don't have an account? ",
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              TextButton(
                key: const Key('register_button'),
                onPressed: _isLoading
                    ? null
                    : () {
                        context.push(AppRoutes.register);
                      },
                child: Text(
                  'Register',
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
