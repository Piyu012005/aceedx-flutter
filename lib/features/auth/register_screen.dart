import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/app_routes.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../app/theme/design_tokens.dart';
import '../../core/api/api_client.dart';
import '../../core/auth/auth_service.dart';
import '../../core/errors/api_exception.dart';
import '../../core/storage/session_storage.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_text_field.dart';

/// AceEdx Register Screen.
///
/// Faithfully reconstructed from compiled Flutter Web AST (`A.EZ` / `A.a3P` / `A.cxB`).
/// Features responsive card layout, role-driven dynamic fields (Parent / School Admin),
/// client-side validation, query parameter prefill support, and navigation.
class RegisterScreen extends StatefulWidget {
  final String? prefillName;
  final String? prefillEmail;
  final String? prefillPhone;
  final AuthenticationService? authService;
  final SessionStorage? sessionStorage;

  const RegisterScreen({
    super.key,
    this.prefillName,
    this.prefillEmail,
    this.prefillPhone,
    this.authService,
    this.sessionStorage,
  });

  /// The 6 verified roles extracted from compiled AST constants.
  static const List<String> availableRoles = [
    'parent',
    'student',
    'teacher',
    'vendor',
    'school_admin',
    'super_admin',
  ];

  /// Formats snake_case roles to Title Case labels matching `A.a3P.aYV`.
  static String formatRoleName(String role) {
    return role
        .split('_')
        .map((word) => word.isNotEmpty
            ? '${word[0].toUpperCase()}${word.substring(1)}'
            : '')
        .join(' ');
  }

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _schoolNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmPasswordController;
  late final TextEditingController _childrenNameController;
  late final TextEditingController _childrenStandardController;

  AuthenticationService? _authService;
  String? _selectedRole;
  DateTime? _selectedBirthday;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.prefillName ?? '');
    _schoolNameController = TextEditingController();
    _emailController = TextEditingController(text: widget.prefillEmail ?? '');
    _phoneController = TextEditingController(text: widget.prefillPhone ?? '');
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    _childrenNameController = TextEditingController();
    _childrenStandardController = TextEditingController();

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
    _nameController.dispose();
    _schoolNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _childrenNameController.dispose();
    _childrenStandardController.dispose();
    super.dispose();
  }

  bool _isSchoolAdmin() {
    if (_selectedRole == null) return false;
    final r = _selectedRole!.toLowerCase();
    return r == 'school_admin' || r == 'school admin';
  }

  bool _isParent() {
    if (_selectedRole == null) return false;
    return _selectedRole!.toLowerCase() == 'parent';
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

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  bool _validatePhoneNumber(String? phone) {
    if (phone == null || phone.isEmpty) return false;
    final cleaned = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (cleaned.startsWith('+91')) {
      if (cleaned.length == 13) {
        return RegExp(r'^\+91[6-9]\d{9}$').hasMatch(cleaned);
      }
      return false;
    }
    if (cleaned.length == 10) {
      return RegExp(r'^[6-9]\d{9}$').hasMatch(cleaned);
    }
    return false;
  }

  Future<void> _pickBirthday() async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year - 30, 1, 1);
    final initial = _selectedBirthday ?? DateTime(now.year - 10, 1, 1);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstDate,
      lastDate: now,
    );
    if (picked != null && mounted) {
      setState(() {
        _selectedBirthday = picked;
      });
    }
  }

  Future<void> _handleRegister() async {
    if (_isLoading) return;

    if (_selectedRole == null || _selectedRole!.isEmpty) {
      _showErrorSnackBar('Please select a role');
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_isParent() && _selectedBirthday == null) {
      _showErrorSnackBar('Please select children birthday');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final name = _isSchoolAdmin()
          ? _schoolNameController.text.trim()
          : _nameController.text.trim();
      final email = _emailController.text.trim();
      final phone = _phoneController.text.trim();
      final password = _passwordController.text;
      final role = _selectedRole!;

      final schoolName = _isSchoolAdmin() ? _schoolNameController.text.trim() : '';
      final childrenName = _isParent() ? _childrenNameController.text.trim() : '';
      final childrenStandard = _isParent() ? _childrenStandardController.text.trim() : '';
      final childrenBirthday = (_isParent() && _selectedBirthday != null)
          ? '${_selectedBirthday!.year.toString().padLeft(4, '0')}-${_selectedBirthday!.month.toString().padLeft(2, '0')}-${_selectedBirthday!.day.toString().padLeft(2, '0')}'
          : '';

      if (_authService == null) {
        _showErrorSnackBar('Authentication service initializing. Please retry.');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Build multipart form fields — old AceEdx sent multipart/form-data
      // to support the optional profile_photo upload.
      final fields = <String, String>{
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
        'password_confirmation': _confirmPasswordController.text,
        'role': role,
        'school_name': schoolName,
        'children_name': childrenName,
        'children_standard': childrenStandard,
        'children_birthday': childrenBirthday,
      };

      // Safe debug payload log — passwords are NEVER printed.
      assert(() {
        // ignore: avoid_print
        print('[REGISTER DEBUG] payload (multipart):\n'
            '  name=${fields['name']}\n'
            '  email=${fields['email']}\n'
            '  phone=${fields['phone']}\n'
            '  role=${fields['role']}\n'
            '  school_name=${fields['school_name']}\n'
            '  children_name=${fields['children_name']}\n'
            '  children_standard=${fields['children_standard']}\n'
            '  children_birthday=${fields['children_birthday']}');
        return true;
      }());

      final response = await _authService!.apiClient.postMultipart(
        '/auth/register',
        fields: fields,
        requiresAuth: false,
      );

      if (!mounted) return;

      final isSuccess = response is Map<String, dynamic> &&
          (response['success'] == true ||
              response['status'] == 'success' ||
              response['token'] != null);

      if (isSuccess) {
        _showSuccessSnackBar('Registration successful!');
        if (_isSchoolAdmin()) {
          context.go(AppRoutes.schoolDashboard);
        } else {
          context.go(AppRoutes.login);
        }
      } else {
        final message = (response is Map<String, dynamic> &&
                response['message'] != null)
            ? response['message'].toString()
            : 'Registration failed';
        _showErrorSnackBar(message);
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      String errorMsg;
      if (e is ValidationException) {
        if (e.allErrors.isNotEmpty) {
          errorMsg = e.allErrors.join('\n');
        } else {
          errorMsg = e.message;
        }
      } else if (e is ApiException) {
        errorMsg = e.message;
      } else {
        errorMsg = e.toString().replaceAll('Exception: ', '');
      }
      _showErrorSnackBar(errorMsg);
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
    final maxContainerWidth = isDesktop ? 900.0 : (isTablet ? 700.0 : double.infinity);
    final cardPadding = isMobile ? AppSpacing.xxl : (isTablet ? AppSpacing.xxxl : 48.0);

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
              child: Container(
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
                child: _buildForm(context, isMobile: isMobile, isTablet: isTablet),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context, {required bool isMobile, required bool isTablet}) {
    final titleFontSize = isMobile ? 24.0 : (isTablet ? 28.0 : 32.0);
    final subtitleFontSize = isMobile ? 14.0 : 16.0;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top Bar with Back Button & Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                key: const Key('register_back_button'),
                icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                tooltip: 'Back to Home',
                onPressed: _handleBackNavigation,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Create Your Account',
                      style: AppTypography.headlineMedium.copyWith(
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Join AceEdX and start your educational journey',
                      style: AppTypography.bodyMedium.copyWith(
                        fontSize: subtitleFontSize,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xxl),

          // Profile Photo Picker Section
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: isMobile ? 40 : 50,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: Icon(
                    Icons.person,
                    size: isMobile ? 44 : 54,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                TextButton.icon(
                  onPressed: () {
                    // Photo upload UI action
                  },
                  icon: const Icon(Icons.camera_alt_outlined, size: 18),
                  label: const Text('Upload Photo'),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Role Dropdown
          DropdownButtonFormField<String>(
            key: const Key('register_role_dropdown'),
            initialValue: _selectedRole,
            decoration: InputDecoration(
              labelText: 'Role *',
              prefixIcon: const Icon(Icons.badge_outlined, color: AppColors.textMuted),
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
            items: RegisterScreen.availableRoles.map((role) {
              return DropdownMenuItem<String>(
                value: role,
                child: Text(
                  RegisterScreen.formatRoleName(role),
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

          // School Name (if school_admin) OR Full Name (if other roles)
          if (_isSchoolAdmin()) ...[
            AppTextField(
              key: const Key('register_school_name_field'),
              controller: _schoolNameController,
              label: 'School Name *',
              prefixIcon: const Icon(Icons.school_outlined),
              enabled: !_isLoading,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter school name';
                }
                if (value.trim().length < 2) {
                  return 'School name must be at least 2 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.lg),
          ] else ...[
            AppTextField(
              key: const Key('register_name_field'),
              controller: _nameController,
              label: 'Full Name *',
              prefixIcon: const Icon(Icons.person_outline),
              enabled: !_isLoading,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your name';
                }
                if (value.trim().length < 2) {
                  return 'Name must be at least 2 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.lg),
          ],

          // Email Field
          AppTextField(
            key: const Key('register_email_field'),
            controller: _emailController,
            label: 'Email *',
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
                return 'Please enter a valid email address';
              }
              return null;
            },
          ),

          const SizedBox(height: AppSpacing.lg),

          // Phone Number Field
          AppTextField(
            key: const Key('register_phone_field'),
            controller: _phoneController,
            label: 'Phone Number *',
            hint: '10-digit mobile number',
            keyboardType: TextInputType.phone,
            prefixIcon: const Icon(Icons.phone_outlined),
            enabled: !_isLoading,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your phone number';
              }
              if (!_validatePhoneNumber(value.trim())) {
                return 'Please enter a valid 10-digit mobile number';
              }
              return null;
            },
          ),

          const SizedBox(height: AppSpacing.lg),

          // Password Field
          AppTextField(
            key: const Key('register_password_field'),
            controller: _passwordController,
            label: 'Password *',
            isPassword: true,
            prefixIcon: const Icon(Icons.lock_outline),
            enabled: !_isLoading,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a password';
              }
              if (value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ),

          const SizedBox(height: AppSpacing.lg),

          // Confirm Password Field
          AppTextField(
            key: const Key('register_confirm_password_field'),
            controller: _confirmPasswordController,
            label: 'Confirm Password *',
            isPassword: true,
            prefixIcon: const Icon(Icons.lock_outline),
            enabled: !_isLoading,
            onSubmitted: (_) {
              if (!_isLoading) {
                _handleRegister();
              }
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please confirm your password';
              }
              if (value != _passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),

          // Parent-Specific Dynamic Fields
          if (_isParent()) ...[
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              key: const Key('register_children_name_field'),
              controller: _childrenNameController,
              label: 'Children Name *',
              prefixIcon: const Icon(Icons.child_care_outlined),
              enabled: !_isLoading,
              validator: (value) {
                if (_isParent()) {
                  if (value == null || value.trim().isEmpty) {
                    return "Please enter your child's name";
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              key: const Key('register_children_standard_field'),
              controller: _childrenStandardController,
              label: 'Children Standard/Grade *',
              hint: 'e.g., 1st, 2nd, 3rd, etc.',
              prefixIcon: const Icon(Icons.grade_outlined),
              enabled: !_isLoading,
              validator: (value) {
                if (_isParent()) {
                  if (value == null || value.trim().isEmpty) {
                    return "Please enter your child's standard";
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            InkWell(
              key: const Key('register_children_birthday_picker'),
              onTap: _isLoading ? null : _pickBirthday,
              borderRadius: AppRadius.radiusMd,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Children Birthday *',
                  prefixIcon: const Icon(Icons.calendar_today_outlined, color: AppColors.textMuted),
                  border: OutlineInputBorder(
                    borderRadius: AppRadius.radiusMd,
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: AppRadius.radiusMd,
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  filled: true,
                  fillColor: AppColors.surface,
                ),
                child: Text(
                  _selectedBirthday != null
                      ? '${_selectedBirthday!.year}-${_selectedBirthday!.month.toString().padLeft(2, '0')}-${_selectedBirthday!.day.toString().padLeft(2, '0')}'
                      : 'Select birthday',
                  style: TextStyle(
                    color: _selectedBirthday != null ? AppColors.textPrimary : AppColors.textMuted,
                  ),
                ),
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.xxl),

          // Create Account / Submit Button
          AppButton(
            key: const Key('register_submit_button'),
            label: 'Create Account',
            isLoading: _isLoading,
            isFullWidth: true,
            size: AppButtonSize.large,
            onPressed: _isLoading ? null : _handleRegister,
          ),

          const SizedBox(height: AppSpacing.lg),

          // Login Link
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Already have an account? ',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              TextButton(
                key: const Key('register_login_button'),
                onPressed: _isLoading
                    ? null
                    : () {
                        context.go(AppRoutes.login);
                      },
                child: Text(
                  'Login',
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
