import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/auth/auth_service.dart';
import '../../core/storage/session_storage.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/placeholder/placeholder_screen.dart';
import '../../features/teacher/presentation/question_paper_generator/question_paper_generator_screen.dart';
import '../../features/teacher/presentation/teacher_dashboard/teacher_dashboard_screen.dart';
import '../theme/theme_preview_screen.dart';
import 'app_routes.dart';

/// Centralized GoRouter routing configuration for AceEdx Flutter application.
///
/// Reconstructs all 41 verified routes and navigation guard rules from the
/// original AceEdx Flutter Web frontend (`main.dart.js`).
class AppRouter {
  static GoRouter? _router;

  /// Creates a configured [GoRouter] instance wired to [sessionStorage].
  static GoRouter createRouter(
    SessionStorage sessionStorage, {
    AuthenticationService? authService,
    String? initialLocation,
    Listenable? refreshListenable,
  }) {
    final effectiveAuthService = authService ??
        AuthenticationService(
          apiClient: ApiClient(sessionStorage: sessionStorage),
          sessionStorage: sessionStorage,
        );
    _router = GoRouter(
      initialLocation: initialLocation ?? AppRoutes.home,
      refreshListenable: refreshListenable,
      errorBuilder: (BuildContext context, GoRouterState state) =>
          NotFoundScreen(location: state.uri.toString()),
      redirect: (BuildContext context, GoRouterState state) {
        final location = state.uri.path;
        final isAuthenticated = sessionStorage.isAuthenticated();
        final role = sessionStorage.getSelectedRole();
        final token = sessionStorage.getToken();
        final tokenPresent = token != null && token.isNotEmpty;

        String? redirectDestination;
        String reason = 'Direct access allowed';
        String? targetDashboard;

        // 1. Root "/" check with skipAdminRedirect support
        if (location == AppRoutes.home) {
          final skipAdmin =
              state.uri.queryParameters['skipAdminRedirect'] == 'true';
          if (isAuthenticated && !skipAdmin) {
            if (AppRoutes.hasRole(
                role, ['school_admin', 'school admin', 'school'])) {
              redirectDestination = AppRoutes.schoolDashboard;
              reason = 'Authenticated school_admin accessing root /';
            }
          }
        } else if (isAuthenticated && AppRoutes.guestOnlyRoutes.contains(location)) {
          // 2. Guest-only auth flow routes (/login, /register, /password-reset)
          final effectiveRole = role ??
              (sessionStorage.getRoles()?.isNotEmpty == true
                  ? sessionStorage.getRoles()!.first
                  : null);
          targetDashboard = AppRoutes.getDashboardForRole(effectiveRole);
          if (targetDashboard != AppRoutes.home) {
            redirectDestination = targetDashboard;
            reason = 'Authenticated user on guest-only route $location redirected to $targetDashboard';
          } else {
            reason = 'Authenticated user with unassigned role allowed on $location';
          }
        } else if (AppRoutes.commonProtectedRoutes.contains(location)) {
          // 3. Common protected routes (/checkout, /payment, /edit-profile, /purchase-history)
          if (!isAuthenticated) {
            redirectDestination = AppRoutes.login;
            reason = 'Unauthenticated guest accessing protected route $location';
          }
        } else if (location == AppRoutes.teacherDashboard ||
            location == AppRoutes.questionPaperGenerator) {
          // 4. Role-specific protected portals & submodules
          if (!isAuthenticated) {
            redirectDestination = AppRoutes.login;
            reason = 'Unauthenticated guest accessing teacher portal';
          } else if (!AppRoutes.hasRole(role, ['teacher'])) {
            redirectDestination = AppRoutes.getDashboardForRole(role);
            reason = 'Role mismatch: user with role $role accessing teacher portal';
          }
        } else if (location == AppRoutes.schoolDashboard) {
          if (!isAuthenticated) {
            redirectDestination = AppRoutes.login;
            reason = 'Unauthenticated guest accessing school dashboard';
          } else if (!AppRoutes.hasRole(
              role, ['school_admin', 'school admin', 'school'])) {
            redirectDestination = AppRoutes.getDashboardForRole(role);
            reason = 'Role mismatch: user with role $role accessing school dashboard';
          }
        } else if (location == AppRoutes.schoolManagement ||
            location == AppRoutes.pricingModuleSchool) {
          if (!isAuthenticated) {
            redirectDestination = AppRoutes.login;
            reason = 'Unauthenticated guest accessing school submodule $location';
          } else if (!AppRoutes.hasRole(
              role, ['school_admin', 'school admin', 'school'])) {
            redirectDestination = AppRoutes.schoolDashboard;
            reason = 'Non school_admin accessing school submodule $location';
          }
        } else if (location == AppRoutes.advertisementForm) {
          if (!isAuthenticated) {
            redirectDestination = AppRoutes.login;
            reason = 'Unauthenticated guest accessing advertisement form';
          } else if (!AppRoutes.hasRole(role, [
            'school_admin',
            'school admin',
            'school',
            'super_admin',
            'superadmin'
          ])) {
            redirectDestination = AppRoutes.getDashboardForRole(role);
            reason = 'Role mismatch on advertisement form';
          }
        } else if (location == AppRoutes.principalDashboard) {
          if (!isAuthenticated) {
            redirectDestination = AppRoutes.login;
            reason = 'Unauthenticated guest accessing principal dashboard';
          } else if (!AppRoutes.hasRole(role, ['principal'])) {
            redirectDestination = AppRoutes.getDashboardForRole(role);
            reason = 'Role mismatch on principal dashboard';
          }
        } else if (location == AppRoutes.superAdminDashboard) {
          if (!isAuthenticated) {
            redirectDestination = AppRoutes.login;
            reason = 'Unauthenticated guest accessing super admin dashboard';
          } else if (!AppRoutes.hasRole(role, ['super_admin', 'superadmin'])) {
            redirectDestination = AppRoutes.getDashboardForRole(role);
            reason = 'Role mismatch on super admin dashboard';
          }
        } else if (location == AppRoutes.studentDashboard) {
          if (!isAuthenticated) {
            redirectDestination = AppRoutes.login;
            reason = 'Unauthenticated guest accessing student dashboard';
          } else if (!AppRoutes.hasRole(role, ['student'])) {
            redirectDestination = AppRoutes.getDashboardForRole(role);
            reason = 'Role mismatch on student dashboard';
          }
        } else if (location == AppRoutes.parentDashboard) {
          if (!isAuthenticated) {
            redirectDestination = AppRoutes.login;
            reason = 'Unauthenticated guest accessing parent dashboard';
          } else if (!AppRoutes.hasRole(role, ['parent'])) {
            redirectDestination = AppRoutes.getDashboardForRole(role);
            reason = 'Role mismatch on parent dashboard';
          }
        }

        debugPrint('''
[ROUTER DEBUG]
rawUri=${state.uri}
location=$location
matchedLocation=${state.matchedLocation}
urlStrategy=HashUrlStrategy
isAuthenticated=$isAuthenticated
tokenPresent=$tokenPresent
selectedRole=$role
targetDashboard=$targetDashboard
redirect=$redirectDestination
reason=$reason
''');

        return redirectDestination;
      },
      routes: <RouteBase>[
        // ─── Public Landing & Informational Routes ─────────────────────────
        GoRoute(
          path: AppRoutes.home,
          name: 'home',
          builder: (BuildContext context, GoRouterState state) =>
              PlaceholderScreen(
            title: 'AceEdx Home',
            path: state.matchedLocation,
            queryParameters: state.uri.queryParameters,
          ),
        ),
        GoRoute(
          path: AppRoutes.aboutUs,
          name: 'about-us',
          builder: (BuildContext context, GoRouterState state) =>
              PlaceholderScreen(
            title: 'About Us',
            path: state.matchedLocation,
            queryParameters: state.uri.queryParameters,
          ),
        ),
        GoRoute(
          path: AppRoutes.policyToPractice,
          name: 'policy-to-practice',
          builder: (BuildContext context, GoRouterState state) =>
              PlaceholderScreen(
            title: 'Policy To Practice',
            path: state.matchedLocation,
            queryParameters: state.uri.queryParameters,
          ),
        ),
        GoRoute(
          path: AppRoutes.productDemos,
          name: 'product-demos',
          builder: (BuildContext context, GoRouterState state) =>
              PlaceholderScreen(
            title: 'Product Demos',
            path: state.matchedLocation,
            queryParameters: state.uri.queryParameters,
          ),
        ),
        GoRoute(
          path: AppRoutes.findSchool,
          name: 'find-school',
          builder: (BuildContext context, GoRouterState state) =>
              PlaceholderScreen(
            title: 'Find School',
            path: state.matchedLocation,
            queryParameters: state.uri.queryParameters,
          ),
        ),
        GoRoute(
          path: AppRoutes.schoolDetail,
          name: 'school-detail',
          builder: (BuildContext context, GoRouterState state) =>
              PlaceholderScreen(
            title: 'School Detail',
            path: state.matchedLocation,
            pathParameters: state.pathParameters,
            queryParameters: state.uri.queryParameters,
          ),
        ),
        GoRoute(
          path: AppRoutes.marketplace,
          name: 'marketplace',
          builder: (BuildContext context, GoRouterState state) =>
              PlaceholderScreen(
            title: 'Marketplace',
            path: state.matchedLocation,
            queryParameters: state.uri.queryParameters,
          ),
        ),
        GoRoute(
          path: AppRoutes.allProducts,
          name: 'all-products',
          builder: (BuildContext context, GoRouterState state) =>
              PlaceholderScreen(
            title: 'All Products',
            path: state.matchedLocation,
            queryParameters: state.uri.queryParameters,
          ),
        ),
        GoRoute(
          path: AppRoutes.featuredMarketplaceDetail,
          name: 'featured-marketplace-detail',
          builder: (BuildContext context, GoRouterState state) =>
              PlaceholderScreen(
            title: 'Featured Marketplace Detail',
            path: state.matchedLocation,
            pathParameters: state.pathParameters,
            queryParameters: state.uri.queryParameters,
          ),
        ),
        GoRoute(
          path: AppRoutes.schoolFilter,
          name: 'school-filter',
          builder: (BuildContext context, GoRouterState state) =>
              PlaceholderScreen(
            title: 'School Filter',
            path: state.matchedLocation,
            queryParameters: state.uri.queryParameters,
          ),
        ),
        GoRoute(
          path: AppRoutes.compareSchools,
          name: 'compare-schools',
          builder: (BuildContext context, GoRouterState state) =>
              PlaceholderScreen(
            title: 'Compare Schools',
            path: state.matchedLocation,
            queryParameters: state.uri.queryParameters,
          ),
        ),
        GoRoute(
          path: AppRoutes.compareSchoolsSelect,
          name: 'compare-schools-select',
          builder: (BuildContext context, GoRouterState state) =>
              PlaceholderScreen(
            title: 'Compare Schools Selection',
            path: state.matchedLocation,
            queryParameters: state.uri.queryParameters,
          ),
        ),
        GoRoute(
          path: AppRoutes.allSchools,
          name: 'all-schools',
          builder: (BuildContext context, GoRouterState state) =>
              PlaceholderScreen(
            title: 'All Schools',
            path: state.matchedLocation,
            queryParameters: state.uri.queryParameters,
          ),
        ),
        GoRoute(
          path: AppRoutes.cart,
          name: 'cart',
          builder: (BuildContext context, GoRouterState state) =>
              PlaceholderScreen(
            title: 'Shopping Cart',
            path: state.matchedLocation,
            queryParameters: state.uri.queryParameters,
          ),
        ),
        GoRoute(
          path: AppRoutes.featuredEvents,
          name: 'featured-events',
          builder: (BuildContext context, GoRouterState state) =>
              PlaceholderScreen(
            title: 'Featured Events',
            path: state.matchedLocation,
            queryParameters: state.uri.queryParameters,
          ),
        ),
        GoRoute(
          path: AppRoutes.featuredEventDetail,
          name: 'featured-event-detail',
          builder: (BuildContext context, GoRouterState state) =>
              PlaceholderScreen(
            title: 'Featured Event Detail',
            path: state.matchedLocation,
            pathParameters: state.pathParameters,
            queryParameters: state.uri.queryParameters,
          ),
        ),
        GoRoute(
          path: AppRoutes.contactUs,
          name: 'contact-us',
          builder: (BuildContext context, GoRouterState state) =>
              PlaceholderScreen(
            title: 'Contact Us',
            path: state.matchedLocation,
            queryParameters: state.uri.queryParameters,
          ),
        ),
        GoRoute(
          path: AppRoutes.termsAndConditions,
          name: 'terms-and-conditions',
          builder: (BuildContext context, GoRouterState state) =>
              PlaceholderScreen(
            title: 'Terms and Conditions',
            path: state.matchedLocation,
            queryParameters: state.uri.queryParameters,
          ),
        ),
        GoRoute(
          path: AppRoutes.refundPolicy,
          name: 'refund-policy',
          builder: (BuildContext context, GoRouterState state) =>
              PlaceholderScreen(
            title: 'Refund Policy',
            path: state.matchedLocation,
            queryParameters: state.uri.queryParameters,
          ),
        ),
        GoRoute(
          path: AppRoutes.feedbackForm,
          name: 'feedback-form',
          builder: (BuildContext context, GoRouterState state) =>
              PlaceholderScreen(
            title: 'Feedback Form',
            path: state.matchedLocation,
            queryParameters: state.uri.queryParameters,
          ),
        ),
        GoRoute(
          path: AppRoutes.search,
          name: 'search',
          builder: (BuildContext context, GoRouterState state) =>
              PlaceholderScreen(
            title: 'Search Results',
            path: state.matchedLocation,
            queryParameters: state.uri.queryParameters,
          ),
        ),
        GoRoute(
          path: AppRoutes.blog,
          name: 'blog',
          builder: (BuildContext context, GoRouterState state) =>
              PlaceholderScreen(
            title: 'Blog',
            path: state.matchedLocation,
            queryParameters: state.uri.queryParameters,
          ),
        ),
        GoRoute(
          path: AppRoutes.homeAnnouncements,
          name: 'home-announcements',
          builder: (BuildContext context, GoRouterState state) =>
              PlaceholderScreen(
            title: 'Announcements',
            path: state.matchedLocation,
            queryParameters: state.uri.queryParameters,
          ),
        ),

        // ─── Guest / Auth Flows ─────────────────────────────────────────────
        GoRoute(
          path: AppRoutes.login,
          name: 'login',
          builder: (BuildContext context, GoRouterState state) =>
              LoginScreen(
            authService: effectiveAuthService,
            sessionStorage: sessionStorage,
          ),
        ),
        GoRoute(
          path: AppRoutes.register,
          name: 'register',
          builder: (BuildContext context, GoRouterState state) {
            final qParams = state.uri.queryParameters;
            final extra = state.extra is Map ? state.extra as Map : null;
            final prefillName = qParams['prefillName'] ??
                qParams['name'] ??
                extra?['prefillName']?.toString();
            final prefillEmail = qParams['prefillEmail'] ??
                qParams['email'] ??
                extra?['prefillEmail']?.toString();
            final prefillPhone = qParams['prefillPhone'] ??
                qParams['phone'] ??
                extra?['prefillPhone']?.toString();

            return RegisterScreen(
              prefillName: prefillName,
              prefillEmail: prefillEmail,
              prefillPhone: prefillPhone,
              authService: effectiveAuthService,
              sessionStorage: sessionStorage,
            );
          },
        ),
        GoRoute(
          path: AppRoutes.passwordReset,
          name: 'password-reset',
          builder: (BuildContext context, GoRouterState state) =>
              PlaceholderScreen(
            title: 'Password Reset',
            path: state.matchedLocation,
            queryParameters: state.uri.queryParameters,
          ),
        ),
        GoRoute(
          path: AppRoutes.verifyOtp,
          name: 'verify-otp',
          builder: (BuildContext context, GoRouterState state) =>
              PlaceholderScreen(
            title: 'Verify OTP',
            path: state.matchedLocation,
            queryParameters: state.uri.queryParameters,
          ),
        ),
        GoRoute(
          path: AppRoutes.updatePassword,
          name: 'update-password',
          builder: (BuildContext context, GoRouterState state) =>
              PlaceholderScreen(
            title: 'Update Password',
            path: state.matchedLocation,
            queryParameters: state.uri.queryParameters,
          ),
        ),

        // ─── Authenticated Common Routes ────────────────────────────────────
        GoRoute(
          path: AppRoutes.checkout,
          name: 'checkout',
          builder: (BuildContext context, GoRouterState state) =>
              PlaceholderScreen(
            title: 'Checkout',
            path: state.matchedLocation,
            queryParameters: state.uri.queryParameters,
          ),
        ),
        GoRoute(
          path: AppRoutes.payment,
          name: 'payment',
          builder: (BuildContext context, GoRouterState state) =>
              PlaceholderScreen(
            title: 'Payment',
            path: state.matchedLocation,
            queryParameters: state.uri.queryParameters,
          ),
        ),
        GoRoute(
          path: AppRoutes.editProfile,
          name: 'edit-profile',
          builder: (BuildContext context, GoRouterState state) =>
              PlaceholderScreen(
            title: 'Edit Profile',
            path: state.matchedLocation,
            queryParameters: state.uri.queryParameters,
          ),
        ),
        GoRoute(
          path: AppRoutes.purchaseHistory,
          name: 'purchase-history',
          builder: (BuildContext context, GoRouterState state) =>
              PlaceholderScreen(
            title: 'Purchase History',
            path: state.matchedLocation,
            queryParameters: state.uri.queryParameters,
          ),
        ),

        // ─── Role-Specific Protected Portals & Submodules ───────────────────
        GoRoute(
          path: AppRoutes.teacherDashboard,
          name: 'teacher-dashboard',
          builder: (BuildContext context, GoRouterState state) {
            final tabParam = state.uri.queryParameters['tab'] ??
                (state.extra is Map ? (state.extra as Map)['initialTabTitle']?.toString() : null);
            return TeacherDashboardScreen(
              initialTabTitle: tabParam,
              sessionStorage: sessionStorage,
              authService: effectiveAuthService,
            );
          },
        ),
        GoRoute(
          path: AppRoutes.questionPaperGenerator,
          name: 'question-paper-generator',
          builder: (BuildContext context, GoRouterState state) =>
              QuestionPaperGeneratorScreen(
            sessionStorage: sessionStorage,
          ),
        ),
        GoRoute(
          path: AppRoutes.schoolDashboard,
          name: 'school-dashboard',
          builder: (BuildContext context, GoRouterState state) =>
              PlaceholderScreen(
            title: 'School Dashboard',
            path: state.matchedLocation,
            queryParameters: state.uri.queryParameters,
          ),
        ),
        GoRoute(
          path: AppRoutes.schoolManagement,
          name: 'school-management',
          builder: (BuildContext context, GoRouterState state) =>
              PlaceholderScreen(
            title: 'School Management',
            path: state.matchedLocation,
            queryParameters: state.uri.queryParameters,
          ),
        ),
        GoRoute(
          path: AppRoutes.pricingModuleSchool,
          name: 'pricing-module-school',
          builder: (BuildContext context, GoRouterState state) =>
              PlaceholderScreen(
            title: 'Pricing Modules (School)',
            path: state.matchedLocation,
            queryParameters: state.uri.queryParameters,
          ),
        ),
        GoRoute(
          path: AppRoutes.advertisementForm,
          name: 'advertisement-form',
          builder: (BuildContext context, GoRouterState state) =>
              PlaceholderScreen(
            title: 'Advertisement Form',
            path: state.matchedLocation,
            queryParameters: state.uri.queryParameters,
          ),
        ),
        GoRoute(
          path: AppRoutes.principalDashboard,
          name: 'principal-dashboard',
          builder: (BuildContext context, GoRouterState state) =>
              PlaceholderScreen(
            title: 'Principal Dashboard',
            path: state.matchedLocation,
            queryParameters: state.uri.queryParameters,
          ),
        ),
        GoRoute(
          path: AppRoutes.superAdminDashboard,
          name: 'super-admin-dashboard',
          builder: (BuildContext context, GoRouterState state) =>
              PlaceholderScreen(
            title: 'Super Admin Dashboard',
            path: state.matchedLocation,
            queryParameters: state.uri.queryParameters,
          ),
        ),
        GoRoute(
          path: AppRoutes.studentDashboard,
          name: 'student-dashboard',
          builder: (BuildContext context, GoRouterState state) =>
              PlaceholderScreen(
            title: 'Student Dashboard',
            path: state.matchedLocation,
            queryParameters: state.uri.queryParameters,
          ),
        ),
        GoRoute(
          path: AppRoutes.parentDashboard,
          name: 'parent-dashboard',
          builder: (BuildContext context, GoRouterState state) =>
              PlaceholderScreen(
            title: 'Parent Dashboard',
            path: state.matchedLocation,
            queryParameters: state.uri.queryParameters,
          ),
        ),

        // ─── Dev Only ───────────────────────────────────────────────────────
        GoRoute(
          path: AppRoutes.themeShowcase,
          name: 'theme-showcase',
          builder: (BuildContext context, GoRouterState state) =>
              const ThemePreviewScreen(),
        ),
      ],
    );

    return _router!;
  }
}
