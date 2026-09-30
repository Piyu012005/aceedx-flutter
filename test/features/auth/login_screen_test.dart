import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aceedx_flutter/app/router/app_router.dart';
import 'package:aceedx_flutter/app/router/app_routes.dart';
import 'package:aceedx_flutter/app/theme/app_theme.dart';
import 'package:aceedx_flutter/core/api/api_client.dart';
import 'package:aceedx_flutter/core/auth/auth_result.dart';
import 'package:aceedx_flutter/core/auth/auth_service.dart';
import 'package:aceedx_flutter/core/session/session_data.dart';
import 'package:aceedx_flutter/core/storage/session_storage.dart';
import 'package:aceedx_flutter/features/auth/login_screen.dart';
import 'package:aceedx_flutter/shared/models/user.dart';

/// Fake Authentication Service for LoginScreen testing.
class FakeAuthService implements AuthenticationService {
  final AuthResult Function(String email, String password, String role)? onLogin;
  int loginCalls = 0;
  String? lastEmail;
  String? lastPassword;
  String? lastRole;

  FakeAuthService({this.onLogin});

  @override
  ApiClient get apiClient => throw UnimplementedError();

  @override
  SessionStorage get sessionStorage => throw UnimplementedError();

  @override
  bool get isAuthenticated => false;

  @override
  bool get hasActiveSession => false;

  @override
  String? get token => null;

  @override
  String? get currentRole => null;

  @override
  int? get currentUserId => null;

  @override
  int? get currentSchoolId => null;

  @override
  int? get currentTeacherId => null;

  @override
  SessionData get currentSession => SessionData.empty;

  @override
  Future<AuthResult> login({
    required String email,
    required String password,
    required String role,
  }) async {
    loginCalls++;
    lastEmail = email;
    lastPassword = password;
    lastRole = role;

    if (onLogin != null) {
      return onLogin!(email, password, role);
    }

    final session = SessionData(
      isAuthenticated: true,
      userToken: 'fake-jwt-token',
      userId: 1,
      userName: 'Test User',
      userEmail: email,
      selectedRole: role,
    );

    return AuthResult.success(
      session: session,
      user: User(
        id: 1,
        name: 'Test User',
        email: email,
        role: role,
      ),
      selectedRole: role,
    );
  }

  @override
  Future<AuthResult> logout() async {
    return const AuthResult(success: true, message: 'Logged out');
  }



  @override
  Future<User?> getProfile() async {
    return null;
  }

  @override
  Future<AuthResult> restoreSession() async {
    throw UnimplementedError();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SessionStorage storage;
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    storage = SessionStorage(prefs);
  });

  Future<void> pumpLoginScreen(
    WidgetTester tester, {
    required AuthenticationService authService,
    double width = 1200,
    double height = 800,
  }) async {
    tester.view.physicalSize = Size(width, height);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: LoginScreen(
          authService: authService,
          sessionStorage: storage,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('Day 1 Step 3H: Login UI Reconstruction Tests', () {
    // ─── 1. UI Elements Rendering ───────────────────────────────────────────
    testWidgets('1. Login screen renders title, fields, and action buttons', (tester) async {
      final fakeAuth = FakeAuthService();
      await pumpLoginScreen(tester, authService: fakeAuth, width: 1200);

      // Desktop Branding Banner elements
      expect(find.text('Welcome Back!'), findsOneWidget);
      expect(find.textContaining('AceEdX is an AI-powered education SaaS marketplace'), findsOneWidget);

      // Form Header elements
      expect(find.text('Login to Your Account'), findsOneWidget);
      expect(find.text('Welcome back! Please enter your details.'), findsOneWidget);

      // Role Dropdown, Email, Password
      expect(find.byKey(const Key('role_dropdown')), findsOneWidget);
      expect(find.byKey(const Key('email_field')), findsOneWidget);
      expect(find.byKey(const Key('password_field')), findsOneWidget);

      // Buttons & Links
      expect(find.byKey(const Key('forgot_password_button')), findsOneWidget);
      expect(find.byKey(const Key('login_button')), findsOneWidget);
      expect(find.byKey(const Key('register_button')), findsOneWidget);
    });

    // ─── 2. Role Selector Options ───────────────────────────────────────────
    testWidgets('2. Role dropdown contains all 6 verified roles', (tester) async {
      final fakeAuth = FakeAuthService();
      await pumpLoginScreen(tester, authService: fakeAuth, width: 1200);

      expect(LoginScreen.availableRoles, equals([
        'parent',
        'student',
        'teacher',
        'vendor',
        'school_admin',
        'super_admin',
      ]));

      expect(LoginScreen.formatRoleName('parent'), equals('Parent'));
      expect(LoginScreen.formatRoleName('school_admin'), equals('School Admin'));
      expect(LoginScreen.formatRoleName('super_admin'), equals('Super Admin'));

      // Open dropdown
      await tester.tap(find.byKey(const Key('role_dropdown')));
      await tester.pumpAndSettle();

      expect(find.text('Parent'), findsWidgets);
      expect(find.text('Student'), findsWidgets);
      expect(find.text('Teacher'), findsWidgets);
      expect(find.text('Vendor'), findsWidgets);
      expect(find.text('School Admin'), findsWidgets);
      expect(find.text('Super Admin'), findsWidgets);
    });

    // ─── 3. Client-Side Validations ─────────────────────────────────────────
    testWidgets('3. Form validation triggers for empty fields', (tester) async {
      final fakeAuth = FakeAuthService();
      await pumpLoginScreen(tester, authService: fakeAuth, width: 1200);

      // Tap Login with all fields empty
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pumpAndSettle();

      expect(find.text('Please select a role'), findsOneWidget);
      expect(find.text('Please enter your email'), findsOneWidget);
      expect(find.text('Please enter your password'), findsOneWidget);
      expect(fakeAuth.loginCalls, equals(0));
    });

    testWidgets('4. Email validation triggers for invalid format', (tester) async {
      final fakeAuth = FakeAuthService();
      await pumpLoginScreen(tester, authService: fakeAuth, width: 1200);

      await tester.enterText(find.byKey(const Key('email_field')), 'not-an-email');
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a valid email'), findsOneWidget);
      expect(fakeAuth.loginCalls, equals(0));
    });

    testWidgets('5. Password validation triggers for short password (<6 chars)', (tester) async {
      final fakeAuth = FakeAuthService();
      await pumpLoginScreen(tester, authService: fakeAuth, width: 1200);

      await tester.enterText(find.byKey(const Key('password_field')), '12345');
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pumpAndSettle();

      expect(find.text('Password must be at least 6 characters'), findsOneWidget);
      expect(fakeAuth.loginCalls, equals(0));
    });

    // ─── 4. Submission & Authentication Invocation ──────────────────────────
    testWidgets('6. Valid form invokes AuthenticationService.login with exact payload', (tester) async {
      final fakeAuth = FakeAuthService();
      await pumpLoginScreen(tester, authService: fakeAuth, width: 1200);

      // Select Teacher Role
      await tester.tap(find.byKey(const Key('role_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Teacher').last);
      await tester.pumpAndSettle();

      // Enter valid email & password
      await tester.enterText(find.byKey(const Key('email_field')), 'teacher@aceedx.com');
      await tester.enterText(find.byKey(const Key('password_field')), 'secret123');

      // Submit
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pump();

      expect(fakeAuth.loginCalls, equals(1));
      expect(fakeAuth.lastEmail, equals('teacher@aceedx.com'));
      expect(fakeAuth.lastPassword, equals('secret123'));
      expect(fakeAuth.lastRole, equals('teacher'));
    });

    // ─── 5. Error Handling & SnackBar ───────────────────────────────────────
    testWidgets('7. Authentication failure displays error via SnackBar', (tester) async {
      final fakeAuth = FakeAuthService(
        onLogin: (email, password, role) => AuthResult.failure(
          message: 'Invalid email or password.',
          statusCode: 401,
        ),
      );

      await pumpLoginScreen(tester, authService: fakeAuth, width: 1200);

      // Select Role
      await tester.tap(find.byKey(const Key('role_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Teacher').last);
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('email_field')), 'teacher@aceedx.com');
      await tester.enterText(find.byKey(const Key('password_field')), 'wrongpass');

      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pumpAndSettle();

      expect(find.text('Invalid email or password.'), findsOneWidget);
    });

    // ─── 6. Role-Based Successful Navigation via AppRouter ───────────────────
    testWidgets('8. Teacher login navigates to /teacher-dashboard', (tester) async {
      final fakeAuth = FakeAuthService();
      final router = AppRouter.createRouter(storage, authService: fakeAuth, initialLocation: '/login');

      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      // Select Teacher Role
      await tester.tap(find.byKey(const Key('role_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Teacher').last);
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('email_field')), 'teacher@aceedx.com');
      await tester.enterText(find.byKey(const Key('password_field')), 'password123');

      // Pre-populate authenticated session in storage for router redirection
      await storage.setToken('test-token');
      await storage.setUserId(101);
      await storage.setSelectedRole('teacher');

      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(router.state.matchedLocation, equals(AppRoutes.teacherDashboard));
    });

    testWidgets('9. School Admin login navigates to /school-dashboard', (tester) async {
      final fakeAuth = FakeAuthService();
      final router = AppRouter.createRouter(storage, authService: fakeAuth, initialLocation: '/login');

      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      // Select School Admin Role
      await tester.tap(find.byKey(const Key('role_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('School Admin').last);
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('email_field')), 'admin@school.com');
      await tester.enterText(find.byKey(const Key('password_field')), 'password123');

      // Pre-populate authenticated session in storage
      await storage.setToken('test-token');
      await storage.setUserId(102);
      await storage.setSelectedRole('school_admin');

      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(router.state.matchedLocation, equals(AppRoutes.schoolDashboard));
    });

    testWidgets('10. Super Admin login navigates to /super-admin-dashboard', (tester) async {
      final fakeAuth = FakeAuthService();
      final router = AppRouter.createRouter(storage, authService: fakeAuth, initialLocation: '/login');

      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      // Select Super Admin Role
      await tester.tap(find.byKey(const Key('role_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Super Admin').last);
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('email_field')), 'super@aceedx.com');
      await tester.enterText(find.byKey(const Key('password_field')), 'password123');

      // Pre-populate authenticated session in storage
      await storage.setToken('test-token');
      await storage.setUserId(103);
      await storage.setSelectedRole('super_admin');

      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(router.state.matchedLocation, equals(AppRoutes.superAdminDashboard));
    });

    testWidgets('11. Student login navigates to /student-dashboard', (tester) async {
      final fakeAuth = FakeAuthService();
      final router = AppRouter.createRouter(storage, authService: fakeAuth, initialLocation: '/login');

      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      // Select Student Role
      await tester.tap(find.byKey(const Key('role_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Student').last);
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('email_field')), 'student@aceedx.com');
      await tester.enterText(find.byKey(const Key('password_field')), 'password123');

      // Pre-populate authenticated session in storage
      await storage.setToken('test-token');
      await storage.setUserId(104);
      await storage.setSelectedRole('student');

      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(router.state.matchedLocation, equals(AppRoutes.studentDashboard));
    });

    testWidgets('12. Parent login navigates to /parent-dashboard', (tester) async {
      final fakeAuth = FakeAuthService();
      final router = AppRouter.createRouter(storage, authService: fakeAuth, initialLocation: '/login');

      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      // Select Parent Role
      await tester.tap(find.byKey(const Key('role_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Parent').last);
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('email_field')), 'parent@aceedx.com');
      await tester.enterText(find.byKey(const Key('password_field')), 'password123');

      // Pre-populate authenticated session in storage
      await storage.setToken('test-token');
      await storage.setUserId(105);
      await storage.setSelectedRole('parent');

      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(router.state.matchedLocation, equals(AppRoutes.parentDashboard));
    });

    // ─── 7. Responsive Layouts ──────────────────────────────────────────────
    testWidgets('11. Responsive Mobile Layout renders on screen width < 600px', (tester) async {
      final fakeAuth = FakeAuthService();
      await pumpLoginScreen(tester, authService: fakeAuth, width: 450, height: 800);

      // Mobile layout has "Login" header, "Login" button, and "About AceEdX" card
      expect(find.text('Login'), findsNWidgets(2));
      expect(find.text('About AceEdX'), findsOneWidget);
      expect(find.byKey(const Key('email_field')), findsOneWidget);
      expect(find.byKey(const Key('password_field')), findsOneWidget);
      expect(find.byKey(const Key('login_button')), findsOneWidget);
    });

    testWidgets('12. Responsive Desktop Layout renders 2-column on screen width >= 900px', (tester) async {
      final fakeAuth = FakeAuthService();
      await pumpLoginScreen(tester, authService: fakeAuth, width: 1200, height: 800);

      // Desktop layout has "Welcome Back!" and "Login to Your Account"
      expect(find.text('Welcome Back!'), findsOneWidget);
      expect(find.text('Login to Your Account'), findsOneWidget);
      expect(find.byKey(const Key('email_field')), findsOneWidget);
      expect(find.byKey(const Key('password_field')), findsOneWidget);
    });
  });
}
