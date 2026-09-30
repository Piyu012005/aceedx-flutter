import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aceedx_flutter/app/router/app_router.dart';
import 'package:aceedx_flutter/app/router/app_routes.dart';
import 'package:aceedx_flutter/app/theme/theme_preview_screen.dart';
import 'package:aceedx_flutter/core/storage/session_storage.dart';
import 'package:aceedx_flutter/features/auth/login_screen.dart';
import 'package:aceedx_flutter/features/placeholder/placeholder_screen.dart';
import 'package:aceedx_flutter/features/teacher/presentation/teacher_dashboard/teacher_dashboard_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SessionStorage storage;
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    storage = SessionStorage(prefs);
  });

  Widget buildTestApp(GoRouter router) {
    return MaterialApp.router(
      routerConfig: router,
    );
  }

  Future<void> pumpRouter(WidgetTester tester, GoRouter router) async {
    await tester.pumpWidget(buildTestApp(router));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  group('Day 1 Step 3F: Router & Navigation Reconstruction Tests', () {
    // ─── 1. All 41 Verified Routes are Defined ──────────────────────────────
    test('1. Master route inventory defines all 41 core routes', () {
      expect(AppRoutes.allCoreRoutes.length, equals(41));
      expect(AppRoutes.allCoreRoutes, contains('/'));
      expect(AppRoutes.allCoreRoutes, contains('/login'));
      expect(AppRoutes.allCoreRoutes, contains('/register'));
      expect(AppRoutes.allCoreRoutes, contains('/teacher-dashboard'));
      expect(AppRoutes.allCoreRoutes, contains('/school-dashboard'));
      expect(AppRoutes.allCoreRoutes, contains('/principal-dashboard'));
      expect(AppRoutes.allCoreRoutes, contains('/super-admin-dashboard'));
      expect(AppRoutes.allCoreRoutes, contains('/student-dashboard'));
      expect(AppRoutes.allCoreRoutes, contains('/parent-dashboard'));
      expect(AppRoutes.allCoreRoutes, contains('/school-management'));
      expect(AppRoutes.allCoreRoutes, contains('/pricing-module-school'));
      expect(AppRoutes.allCoreRoutes, contains('/advertisement-form'));
      expect(AppRoutes.allCoreRoutes, contains('/checkout'));
      expect(AppRoutes.allCoreRoutes, contains('/payment'));
      expect(AppRoutes.allCoreRoutes, contains('/edit-profile'));
      expect(AppRoutes.allCoreRoutes, contains('/purchase-history'));
    });

    // ─── 2. Initial / Public Route '/' ──────────────────────────────────────
    testWidgets('2. Initial route "/" redirects unauthenticated guest to /login', (tester) async {
      final router = AppRouter.createRouter(storage, initialLocation: '/');
      await pumpRouter(tester, router);

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(PlaceholderScreen), findsNothing);
      expect(router.state.uri.path, equals('/login'));
    });

    // ─── 3. Direct Navigation to /login and Protected Route Redirects ───────
    testWidgets('3a. Direct navigation to /login renders LoginScreen and NOT PlaceholderScreen', (tester) async {
      final router = AppRouter.createRouter(storage, initialLocation: '/login');
      await pumpRouter(tester, router);

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(PlaceholderScreen), findsNothing);
      expect(router.state.uri.path, equals('/login'));
      expect(find.byKey(const Key('email_field')), findsOneWidget);
      expect(find.byKey(const Key('password_field')), findsOneWidget);
      expect(find.byKey(const Key('role_dropdown')), findsOneWidget);
      expect(find.byKey(const Key('login_button')), findsOneWidget);
      expect(find.byKey(const Key('register_button')), findsOneWidget);
    });

    testWidgets('3b. Unauthenticated protected route redirects to /login', (tester) async {
      final router = AppRouter.createRouter(storage, initialLocation: '/teacher-dashboard');
      await pumpRouter(tester, router);

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(PlaceholderScreen), findsNothing);
      expect(router.state.uri.path, equals('/login'));
    });

    testWidgets('3c. Session without assigned dashboard role visiting /login is not redirected to home', (tester) async {
      await storage.setToken('tok_vendor_or_unknown');
      await storage.setSelectedRole('vendor');
      await storage.setIsAuthenticated(true);

      final router = AppRouter.createRouter(storage, initialLocation: '/login');
      await pumpRouter(tester, router);

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(PlaceholderScreen), findsNothing);
      expect(router.state.uri.path, equals('/login'));
    });

    // ─── 4. Authenticated Teacher Accesses Teacher Dashboard ────────────────
    testWidgets('4. Authenticated teacher accesses /teacher-dashboard', (tester) async {
      await storage.setToken('tok_teacher');
      await storage.setSelectedRole('teacher');
      await storage.setIsAuthenticated(true);

      final router = AppRouter.createRouter(storage, initialLocation: '/teacher-dashboard');
      await pumpRouter(tester, router);

      expect(find.text('Teacher Dashboard'), findsOneWidget);
      expect(router.state.uri.path, equals('/teacher-dashboard'));
    });

    // ─── 5. Authenticated School Admin Accesses School Dashboard ────────────
    testWidgets('5. Authenticated school_admin accesses /school-dashboard', (tester) async {
      await storage.setToken('tok_admin');
      await storage.setSelectedRole('school_admin');
      await storage.setIsAuthenticated(true);

      final router = AppRouter.createRouter(storage, initialLocation: '/school-dashboard');
      await pumpRouter(tester, router);

      expect(find.text('School Dashboard'), findsOneWidget);
      expect(router.state.uri.path, equals('/school-dashboard'));
    });

    // ─── 6. Authenticated Principal Accesses Principal Dashboard ────────────
    testWidgets('6. Authenticated principal accesses /principal-dashboard', (tester) async {
      await storage.setToken('tok_principal');
      await storage.setSelectedRole('principal');
      await storage.setIsAuthenticated(true);

      final router = AppRouter.createRouter(storage, initialLocation: '/principal-dashboard');
      await pumpRouter(tester, router);

      expect(find.text('Principal Dashboard'), findsOneWidget);
      expect(router.state.uri.path, equals('/principal-dashboard'));
    });

    // ─── 7. Authenticated Super Admin Accesses Super Admin Dashboard ────────
    testWidgets('7. Authenticated super_admin accesses /super-admin-dashboard', (tester) async {
      await storage.setToken('tok_super');
      await storage.setSelectedRole('super_admin');
      await storage.setIsAuthenticated(true);

      final router = AppRouter.createRouter(storage, initialLocation: '/super-admin-dashboard');
      await pumpRouter(tester, router);

      expect(find.text('Super Admin Dashboard'), findsOneWidget);
      expect(router.state.uri.path, equals('/super-admin-dashboard'));
    });

    // ─── 8. Authenticated Student Accesses Student Dashboard ────────────────
    testWidgets('8. Authenticated student accesses /student-dashboard', (tester) async {
      await storage.setToken('tok_student');
      await storage.setSelectedRole('student');
      await storage.setIsAuthenticated(true);

      final router = AppRouter.createRouter(storage, initialLocation: '/student-dashboard');
      await pumpRouter(tester, router);

      expect(find.text('Student Dashboard'), findsOneWidget);
      expect(router.state.uri.path, equals('/student-dashboard'));
    });

    // ─── 9. Authenticated Parent Accesses Parent Dashboard ──────────────────
    testWidgets('9. Authenticated parent accesses /parent-dashboard', (tester) async {
      await storage.setToken('tok_parent');
      await storage.setSelectedRole('parent');
      await storage.setIsAuthenticated(true);

      final router = AppRouter.createRouter(storage, initialLocation: '/parent-dashboard');
      await pumpRouter(tester, router);

      expect(find.text('Parent Dashboard'), findsOneWidget);
      expect(router.state.uri.path, equals('/parent-dashboard'));
    });

    // ─── 10. Authenticated User Visiting /login Redirects to Role Dashboard ─
    testWidgets('10. Authenticated user visiting /login redirects to their dashboard', (tester) async {
      await storage.setToken('tok_teacher');
      await storage.setSelectedRole('teacher');
      await storage.setIsAuthenticated(true);

      final router = AppRouter.createRouter(storage, initialLocation: '/login');
      await pumpRouter(tester, router);

      expect(router.state.uri.path, equals('/teacher-dashboard'));
    });

    // ─── 11. Wrong Role Accessing Protected Portal is Redirected ────────────
    testWidgets('11. Wrong role accessing protected portal redirects to their own dashboard', (tester) async {
      await storage.setToken('tok_teacher');
      await storage.setSelectedRole('teacher');
      await storage.setIsAuthenticated(true);

      // Teacher attempts to access /school-dashboard
      final router = AppRouter.createRouter(storage, initialLocation: '/school-dashboard');
      await pumpRouter(tester, router);

      expect(router.state.uri.path, equals('/teacher-dashboard'));
    });

    // ─── 12. School Admin Visiting '/' Redirects to '/school-dashboard' ─────
    testWidgets('12. School admin visiting "/" automatically redirects to /school-dashboard', (tester) async {
      await storage.setToken('tok_admin');
      await storage.setSelectedRole('school_admin');
      await storage.setIsAuthenticated(true);

      final router = AppRouter.createRouter(storage, initialLocation: '/');
      await pumpRouter(tester, router);

      expect(router.state.uri.path, equals('/school-dashboard'));
    });

    // ─── 13. skipAdminRedirect=true Prevents Auto-Redirect on '/' ───────────
    testWidgets('13. skipAdminRedirect=true allows school admin to view public "/" home', (tester) async {
      await storage.setToken('tok_admin');
      await storage.setSelectedRole('school_admin');
      await storage.setIsAuthenticated(true);

      final router = AppRouter.createRouter(storage, initialLocation: '/?skipAdminRedirect=true');
      await pumpRouter(tester, router);

      expect(router.state.uri.path, equals('/'));
      expect(find.byType(PlaceholderScreen), findsOneWidget);
      expect(find.text('Module: AceEdx Home'), findsOneWidget);
    });

    // ─── 13b. Dev Route /theme-showcase renders ThemePreviewScreen ──────────
    testWidgets('13b. /theme-showcase renders ThemePreviewScreen (dev only)', (tester) async {
      final router = AppRouter.createRouter(storage, initialLocation: '/theme-showcase');
      await pumpRouter(tester, router);

      expect(router.state.uri.path, equals('/theme-showcase'));
      expect(find.byType(ThemePreviewScreen), findsOneWidget);
    });

    // ─── 14. Dashboard Tab Query Parameter is Preserved ─────────────────────
    testWidgets('14. Dashboard tab query parameter (?tab=1) is preserved', (tester) async {
      await storage.setToken('tok_teacher');
      await storage.setSelectedRole('teacher');
      await storage.setIsAuthenticated(true);

      final router = AppRouter.createRouter(storage, initialLocation: '/teacher-dashboard?tab=1');
      await pumpRouter(tester, router);

      expect(router.state.uri.path, equals('/teacher-dashboard'));
      expect(router.state.uri.queryParameters['tab'], equals('1'));
      expect(find.byType(TeacherDashboardScreen), findsOneWidget);
    });

    // ─── 15. Register Prefill Query Parameters are Preserved ────────────────
    testWidgets('15. Register prefill query parameters are preserved in router state', (tester) async {
      final router = AppRouter.createRouter(
        storage,
        initialLocation: '/register?prefillName=John&prefillEmail=john@test.com&prefillPhone=9876543210',
      );
      await pumpRouter(tester, router);

      expect(router.state.uri.path, equals('/register'));
      expect(router.state.uri.queryParameters['prefillName'], equals('John'));
      expect(router.state.uri.queryParameters['prefillEmail'], equals('john@test.com'));
      expect(router.state.uri.queryParameters['prefillPhone'], equals('9876543210'));
    });

    // ─── 16. Unknown Route Renders 404 NotFoundScreen ───────────────────────
    testWidgets('16. Unknown route renders NotFoundScreen (404)', (tester) async {
      final router = AppRouter.createRouter(storage, initialLocation: '/non-existent-route-xyz');
      await pumpRouter(tester, router);

      expect(find.byType(NotFoundScreen), findsOneWidget);
      expect(find.text('Page Not Found (404)'), findsOneWidget);
    });

    // ─── 17. Path Parameters Preserved in Detail Routes ─────────────────────
    testWidgets('17. Path parameters (e.g. :id) are correctly extracted', (tester) async {
      final router = AppRouter.createRouter(storage, initialLocation: '/school-detail/87');
      await pumpRouter(tester, router);

      expect(router.state.uri.path, equals('/school-detail/87'));
      expect(router.state.pathParameters['id'], equals('87'));
      expect(find.text('School Detail'), findsOneWidget);
    });

    // ─── 18. Common Protected Routes Redirect Guest to Login ────────────────
    testWidgets('18. /checkout, /payment, /edit-profile, /purchase-history redirect guest to /login', (tester) async {
      final routesToTest = ['/checkout', '/payment', '/edit-profile', '/purchase-history'];

      for (final route in routesToTest) {
        final router = AppRouter.createRouter(storage, initialLocation: route);
        await pumpRouter(tester, router);

        expect(router.state.uri.path, equals('/login'),
            reason: '$route should redirect unauthenticated guest to /login');
      }
    });

    // ─── 19. Public Routes are Directly Accessible Without Auth ─────────────
    testWidgets('19. Public routes are accessible to guests without redirect', (tester) async {
      final publicRoutes = [
        '/about-us',
        '/policy-to-practice',
        '/product-demos',
        '/find-school',
        '/marketplace',
        '/all-products',
        '/featured-events',
        '/contact-us',
        '/terms-and-conditions',
        '/refund-policy',
        '/blog',
        '/home-announcements',
      ];

      for (final route in publicRoutes) {
        final router = AppRouter.createRouter(storage, initialLocation: route);
        await pumpRouter(tester, router);

        expect(router.state.uri.path, equals(route),
            reason: '$route should be directly accessible');
      }
    });

    // ─── 20. Role Submodules Accessible Only by Permitted Roles ─────────────
    testWidgets('20. /school-management and /pricing-module-school restricted to school_admin', (tester) async {
      // Unauthenticated -> /login
      var router = AppRouter.createRouter(storage, initialLocation: '/school-management');
      await pumpRouter(tester, router);
      expect(router.state.uri.path, equals('/login'));

      // Authenticated teacher -> redirected to /school-dashboard (which redirects to /teacher-dashboard)
      await storage.setToken('tok');
      await storage.setSelectedRole('teacher');
      await storage.setIsAuthenticated(true);
      router = AppRouter.createRouter(storage, initialLocation: '/school-management');
      await pumpRouter(tester, router);
      expect(router.state.uri.path, equals('/teacher-dashboard'));

      // Authenticated school_admin -> allowed
      await storage.setSelectedRole('school_admin');
      router = AppRouter.createRouter(storage, initialLocation: '/school-management');
      await pumpRouter(tester, router);
      expect(router.state.uri.path, equals('/school-management'));
    });
  });
}
