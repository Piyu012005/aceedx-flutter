import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aceedx_flutter/app/theme/app_theme.dart';
import 'package:aceedx_flutter/core/api/api_client.dart';
import 'package:aceedx_flutter/core/auth/auth_result.dart';
import 'package:aceedx_flutter/core/auth/auth_service.dart';
import 'package:aceedx_flutter/core/session/session_data.dart';
import 'package:aceedx_flutter/core/storage/session_storage.dart';
import 'package:aceedx_flutter/features/teacher/presentation/teacher_dashboard/teacher_dashboard_screen.dart';
import 'package:aceedx_flutter/shared/components/role_portal_configs.dart';
import 'package:aceedx_flutter/shared/models/user.dart';

/// Fake Authentication Service for Teacher Dashboard testing.
class FakeAuthService implements AuthenticationService {
  bool logoutCalled = false;

  @override
  ApiClient get apiClient => throw UnimplementedError();

  @override
  SessionStorage get sessionStorage => throw UnimplementedError();

  @override
  bool get isAuthenticated => true;

  @override
  bool get hasActiveSession => true;

  @override
  String? get token => 'test-teacher-token';

  @override
  String? get currentRole => 'teacher';

  @override
  int? get currentUserId => 101;

  @override
  int? get currentSchoolId => 1;

  @override
  int? get currentTeacherId => 42;

  @override
  SessionData get currentSession => const SessionData(
        isAuthenticated: true,
        userToken: 'test-teacher-token',
        userId: 101,
        userName: 'Dr. Jane Doe',
        userEmail: 'jane.doe@school.edu',
        selectedRole: 'teacher',
        userRoles: ['teacher'],
      );

  @override
  Future<AuthResult> login({
    required String email,
    required String password,
    required String role,
    bool rememberMe = false,
  }) async =>
      AuthResult.failure(message: 'Not implemented in fake');

  Future<AuthResult> register({
    required String name,
    required String email,
    required String phone,
    required String role,
    required String password,
    required String passwordConfirmation,
    required bool agreeToTerms,
  }) async =>
      AuthResult.failure(message: 'Not implemented in fake');

  @override
  Future<AuthResult> logout() async {
    logoutCalled = true;
    return AuthResult.success(
      session: SessionData.empty,
      message: 'Logged out successfully',
    );
  }

  @override
  Future<AuthResult> restoreSession() async => AuthResult.success(
        session: currentSession,
      );

  @override
  Future<User?> getProfile() async => const User(
        id: 101,
        name: 'Dr. Jane Doe',
        email: 'jane.doe@school.edu',
        role: 'teacher',
      );

  Future<bool> silentTokenRefresh() async => true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late SessionStorage sessionStorage;
  late FakeAuthService authService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'userToken': 'test-teacher-token',
      'userId': 101,
      'userName': 'Dr. Jane Doe',
      'userEmail': 'jane.doe@school.edu',
      'selectedRole': 'teacher',
      'userRoles': ['teacher'],
      'isAuthenticated': true,
      'aceedx_user_token': 'test-teacher-token',
      'aceedx_user_id': 101,
      'aceedx_user_name': 'Dr. Jane Doe',
      'aceedx_user_email': 'jane.doe@school.edu',
      'aceedx_user_role': 'teacher',
      'aceedx_user_roles': ['teacher'],
      'aceedx_is_authenticated': true,
    });
    prefs = await SharedPreferences.getInstance();
    sessionStorage = SessionStorage(prefs);
    authService = FakeAuthService();
  });

  Widget createTestWidget({
    String? initialTabTitle,
    Size screenSize = const Size(1440, 900),
  }) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: MediaQuery(
        data: MediaQueryData(size: screenSize),
        child: Material(
          child: TeacherDashboardScreen(
            initialTabTitle: initialTabTitle,
            sessionStorage: sessionStorage,
            authService: authService,
          ),
        ),
      ),
    );
  }

  group('Teacher Dashboard Tests', () {
    testWidgets('1. Teacher Dashboard loads with Welcome Back and User Name',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Welcome Back!'), findsOneWidget);
      expect(find.text('Dr. Jane Doe'), findsWidgets);
      expect(find.text('Quick access to your most-used modules.'), findsOneWidget);
    });

    testWidgets('2. Demo mode banner appears with exact text and can be dismissed',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Demo Mode (Teacher)'), findsOneWidget);
      expect(
        find.text(
          'Teacher APIs are not connected yet. Modules are visible for UI demo and will be activated once APIs are ready.',
        ),
        findsOneWidget,
      );

      final dismissButton = find.text('Don’t show again');
      expect(dismissButton, findsOneWidget);

      await tester.tap(dismissButton);
      await tester.pumpAndSettle();

      expect(find.text('Demo Mode (Teacher)'), findsNothing);
      expect(prefs.getBool('teacher_demo_banner_hidden_v1_101'), isTrue);
    });

    testWidgets('3. All 3 quick action cards appear with correct badges and text',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('My Classes'), findsWidgets);
      expect(find.text('Students & sections'), findsOneWidget);

      expect(find.text('Timetable'), findsWidgets);
      expect(find.text('Today’s schedule'), findsOneWidget);

      expect(find.text('Announcements'), findsWidgets);
      expect(find.text('School updates'), findsOneWidget);

      expect(find.text('UPCOMING'), findsNWidgets(2)); // My Classes and Timetable
    });

    testWidgets('4. Recommended modules section appears with all 8 bullet items',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Recommended modules for Teachers'), findsOneWidget);
      expect(find.text('What we should show on Teacher Dashboard'), findsOneWidget);

      expect(
        find.text('My Classes (students list, subjects, sections)'),
        findsOneWidget,
      );
      expect(find.text('Attendance (daily + period-wise)'), findsOneWidget);
      expect(
        find.text('Assignments/Homework (create, collect, review)'),
        findsOneWidget,
      );
      expect(
        find.text('AI Report Card Generator (marks, results, report cards)'),
        findsOneWidget,
      );
      expect(
        find.text('Timetable (personal schedule + substitutions)'),
        findsOneWidget,
      );
      expect(
        find.text('Announcements (view + classroom announcements)'),
        findsOneWidget,
      );
      expect(
        find.text('Messages/Chat (parents & students communication)'),
        findsOneWidget,
      );
      expect(find.text('Leave/Requests (apply/approve, if required)'), findsOneWidget);
    });

    testWidgets('5. All 15 teacher navigation items are present in sidebar config',
        (WidgetTester tester) async {
      final items = RolePortalConfigs.teacherNavItems;
      expect(items.length, 15);

      final titles = items.map((i) => i.title).toList();
      expect(titles, [
        'Dashboard',
        'My Classes',
        'Timetable',
        'Attendance',
        'Assignments',
        'AI Report Card Generator',
        'AI Question Paper Generator',
        'Evaluate Question Paper',
        'My Orders',
        'Featured Ads',
        'AI Lesson Planner',
        'AceEdx Coach for teachers',
        'Announcements',
        'Liked Schools',
        'Annual Calendar',
      ]);
    });

    testWidgets('6. Responsive layouts render without overflow on Tablet and Mobile',
        (WidgetTester tester) async {
      // Tablet view (768 x 1024)
      tester.view.physicalSize = const Size(768, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget(screenSize: const Size(768, 1024)));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Mobile view (390 x 844)
      tester.view.physicalSize = const Size(390, 844);
      await tester.pumpWidget(createTestWidget(screenSize: const Size(390, 844)));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('7. Quick action card switches to placeholder sub-module tab',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final myClassesCard = find.text('Students & sections');
      expect(myClassesCard, findsOneWidget);

      await tester.tap(myClassesCard);
      await tester.pumpAndSettle();

      expect(
        find.text('This module is currently in development and will be activated in an upcoming release.'),
        findsOneWidget,
      );

      final backButton = find.text('Back to Dashboard');
      expect(backButton, findsOneWidget);

      await tester.tap(backButton);
      await tester.pumpAndSettle();

      expect(find.text('Welcome Back!'), findsOneWidget);
    });

    testWidgets('8. Logout confirmation dialog triggers authentication logout',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final logoutBtn = find.byIcon(Icons.logout);
      expect(logoutBtn, findsOneWidget);

      await tester.tap(logoutBtn);
      await tester.pumpAndSettle();

      expect(find.text('Log Out'), findsWidgets);
      expect(
        find.text('Are you sure you want to log out of your Teacher account?'),
        findsOneWidget,
      );

      final confirmButton = find.widgetWithText(ElevatedButton, 'Log Out');
      expect(confirmButton, findsOneWidget);

      await tester.tap(confirmButton);
      await tester.pumpAndSettle();

      expect(authService.logoutCalled, isTrue);
    });

    testWidgets('9. Teacher Dashboard contains AI Question Paper Generator nav item and clicking it renders QuestionPaperGeneratorScreen',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Find navigation item
      final navItem = find.text('AI Question Paper Generator');
      expect(navItem, findsWidgets);

      // Tap on the AI Question Paper Generator nav item
      await tester.tap(navItem.first);
      await tester.pumpAndSettle();

      // Verify that PlaceholderScreen message is NOT present
      expect(
        find.text('This module is currently in development and will be activated in an upcoming release.'),
        findsNothing,
      );

      // Verify that the actual QuestionPaperGeneratorScreen form elements are present
      expect(find.text('Board *'), findsOneWidget);
      expect(find.textContaining('Subject *'), findsOneWidget);
      expect(find.textContaining('Class *'), findsOneWidget);
      expect(find.textContaining('Chapter *'), findsOneWidget);
      expect(find.text('Generate Question Paper'), findsOneWidget);
    });

    testWidgets('10. Initial tab title via query parameter ?tab=AI+Question+Paper+Generator opens QuestionPaperGeneratorScreen',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget(initialTabTitle: 'AI Question Paper Generator'));
      await tester.pumpAndSettle();

      // Verify QuestionPaperGeneratorScreen is rendered directly
      expect(
        find.text('This module is currently in development and will be activated in an upcoming release.'),
        findsNothing,
      );
      expect(find.text('Generate Question Paper'), findsOneWidget);
    });

    testWidgets('11. Alias ai_question_paper query parameter opens QuestionPaperGeneratorScreen',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget(initialTabTitle: 'ai_question_paper'));
      await tester.pumpAndSettle();

      // Verify QuestionPaperGeneratorScreen is rendered
      expect(
        find.text('This module is currently in development and will be activated in an upcoming release.'),
        findsNothing,
      );
      expect(find.text('Generate Question Paper'), findsOneWidget);
    });

    testWidgets('12. Other placeholder modules still render their placeholder views',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget(initialTabTitle: 'Timetable'));
      await tester.pumpAndSettle();

      expect(
        find.text('This module is currently in development and will be activated in an upcoming release.'),
        findsOneWidget,
      );
    });
  });
}
