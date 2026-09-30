import 'package:aceedx_flutter/app/theme/app_theme.dart';
import 'package:aceedx_flutter/core/api/api_client.dart';
import 'package:aceedx_flutter/core/auth/auth_service.dart';
import 'package:aceedx_flutter/core/storage/session_storage.dart';
import 'package:aceedx_flutter/features/auth/register_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockApiClient extends ApiClient {
  MockApiClient({required super.sessionStorage});

  Map<String, String>? lastFields;
  String? lastPath;
  dynamic mockResponse = {
    'success': true,
    'message': 'Registration successful',
    'token': 'test-token',
  };

  @override
  Future<dynamic> postMultipart(
    String path, {
    required Map<String, String> fields,
    List<int>? fileBytes,
    String fileField = 'profile_photo',
    String fileName = 'photo.jpg',
    String mimeType = 'image/jpeg',
    bool requiresAuth = false,
    Duration? timeout,
  }) async {
    lastPath = path;
    lastFields = Map<String, String>.from(fields);
    return mockResponse;
  }
}

Widget _buildTestWidget({
  String? prefillName,
  String? prefillEmail,
  String? prefillPhone,
  AuthenticationService? authService,
  SessionStorage? sessionStorage,
  Size size = const Size(1200, 1400),
}) {
  return MaterialApp(
    theme: AppTheme.lightTheme,
    home: MediaQuery(
      data: MediaQueryData(size: size),
      child: RegisterScreen(
        prefillName: prefillName,
        prefillEmail: prefillEmail,
        prefillPhone: prefillPhone,
        authService: authService,
        sessionStorage: sessionStorage,
      ),
    ),
  );
}

void main() {
  group('Register UI Reconstruction Tests', () {
    late SessionStorage sessionStorage;
    late MockApiClient mockApi;
    late AuthenticationService authService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      sessionStorage = await SessionStorage.init();
      mockApi = MockApiClient(sessionStorage: sessionStorage);
      authService = AuthenticationService(
        apiClient: mockApi,
        sessionStorage: sessionStorage,
      );
    });

    testWidgets('1. Renders all standard Register UI elements correctly',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1400));
      await tester.pumpWidget(_buildTestWidget(authService: authService));
      await tester.pumpAndSettle();

      expect(find.text('Create Your Account'), findsOneWidget);
      expect(find.text('Join AceEdX and start your educational journey'),
          findsOneWidget);
      expect(find.byKey(const Key('register_role_dropdown')), findsOneWidget);
      expect(find.byKey(const Key('register_name_field')), findsOneWidget);
      expect(find.byKey(const Key('register_email_field')), findsOneWidget);
      expect(find.byKey(const Key('register_phone_field')), findsOneWidget);
      expect(find.byKey(const Key('register_password_field')), findsOneWidget);
      expect(find.byKey(const Key('register_confirm_password_field')),
          findsOneWidget);
      expect(find.byKey(const Key('register_submit_button')), findsOneWidget);
      expect(find.byKey(const Key('register_login_button')), findsOneWidget);
      expect(find.byKey(const Key('register_back_button')), findsOneWidget);
    });

    testWidgets('2. Role dropdown contains all 6 verified roles',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1400));
      await tester.pumpWidget(_buildTestWidget(authService: authService));
      await tester.pumpAndSettle();

      expect(RegisterScreen.availableRoles, containsAll([
        'parent', 'student', 'teacher', 'vendor', 'school_admin', 'super_admin',
      ]));

      expect(RegisterScreen.formatRoleName('school_admin'), 'School Admin');
      expect(RegisterScreen.formatRoleName('super_admin'), 'Super Admin');
      expect(RegisterScreen.formatRoleName('teacher'), 'Teacher');
      expect(RegisterScreen.formatRoleName('student'), 'Student');
      expect(RegisterScreen.formatRoleName('parent'), 'Parent');
      expect(RegisterScreen.formatRoleName('vendor'), 'Vendor');
    });

    testWidgets('3. Role selection triggers dynamic School Name field for school_admin',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1400));
      await tester.pumpWidget(_buildTestWidget(authService: authService));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('register_name_field')), findsOneWidget);
      expect(find.byKey(const Key('register_school_name_field')), findsNothing);

      await tester.tap(find.byKey(const Key('register_role_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('School Admin').last);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('register_school_name_field')), findsOneWidget);
      expect(find.byKey(const Key('register_name_field')), findsNothing);
    });

    testWidgets('4. Role selection triggers dynamic parent fields for parent',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1400));
      await tester.pumpWidget(_buildTestWidget(authService: authService));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('register_children_name_field')), findsNothing);
      expect(find.byKey(const Key('register_children_standard_field')), findsNothing);
      expect(find.byKey(const Key('register_children_birthday_picker')), findsNothing);

      await tester.tap(find.byKey(const Key('register_role_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Parent').last);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('register_children_name_field')), findsOneWidget);
      expect(find.byKey(const Key('register_children_standard_field')), findsOneWidget);
      expect(find.byKey(const Key('register_children_birthday_picker')), findsOneWidget);
    });

    testWidgets('5. Form validation triggers error on empty fields',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1400));
      await tester.pumpWidget(_buildTestWidget(authService: authService));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const Key('register_submit_button')));
      await tester.tap(find.byKey(const Key('register_submit_button')));
      await tester.pumpAndSettle();

      expect(find.text('Please select a role'), findsOneWidget);

      await tester.ensureVisible(find.byKey(const Key('register_role_dropdown')));
      await tester.tap(find.byKey(const Key('register_role_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Teacher').last);
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const Key('register_submit_button')));
      await tester.tap(find.byKey(const Key('register_submit_button')));
      await tester.pumpAndSettle();

      expect(find.text('Please enter your name'), findsOneWidget);
      expect(find.text('Please enter your email'), findsOneWidget);
      expect(find.text('Please enter your phone number'), findsOneWidget);
      expect(find.text('Please enter a password'), findsOneWidget);
      expect(find.text('Please confirm your password'), findsOneWidget);
    });

    testWidgets('6. Email and phone format validations trigger correctly',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1400));
      await tester.pumpWidget(_buildTestWidget(authService: authService));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const Key('register_role_dropdown')));
      await tester.tap(find.byKey(const Key('register_role_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Student').last);
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('register_name_field')), 'Jane Doe');
      await tester.enterText(find.byKey(const Key('register_email_field')), 'invalid-email');
      await tester.enterText(find.byKey(const Key('register_phone_field')), '12345');
      await tester.enterText(find.byKey(const Key('register_password_field')), '123456');
      await tester.enterText(find.byKey(const Key('register_confirm_password_field')), '123456');

      await tester.ensureVisible(find.byKey(const Key('register_submit_button')));
      await tester.tap(find.byKey(const Key('register_submit_button')));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a valid email address'), findsOneWidget);
      expect(find.text('Please enter a valid 10-digit mobile number'), findsOneWidget);
    });

    testWidgets('7. Password mismatch validation triggers correctly',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1400));
      await tester.pumpWidget(_buildTestWidget(authService: authService));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const Key('register_role_dropdown')));
      await tester.tap(find.byKey(const Key('register_role_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Teacher').last);
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('register_name_field')), 'Teacher One');
      await tester.enterText(find.byKey(const Key('register_email_field')), 'teacher@example.com');
      await tester.enterText(find.byKey(const Key('register_phone_field')), '9876543210');
      await tester.enterText(find.byKey(const Key('register_password_field')), 'password123');
      await tester.enterText(find.byKey(const Key('register_confirm_password_field')), 'different123');

      await tester.ensureVisible(find.byKey(const Key('register_submit_button')));
      await tester.tap(find.byKey(const Key('register_submit_button')));
      await tester.pumpAndSettle();

      expect(find.text('Passwords do not match'), findsOneWidget);
    });

    testWidgets('8. Prefill parameters populate initial form values',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1400));
      await tester.pumpWidget(_buildTestWidget(
        prefillName: 'Prefilled Name',
        prefillEmail: 'prefill@example.com',
        prefillPhone: '9876543210',
        authService: authService,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Prefilled Name'), findsOneWidget);
      expect(find.text('prefill@example.com'), findsOneWidget);
      expect(find.text('9876543210'), findsOneWidget);
    });

    testWidgets('9. Responsive mobile layout (<600px) renders cleanly',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(_buildTestWidget(
        size: const Size(390, 844),
        authService: authService,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Create Your Account'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('10. Responsive desktop layout (>=900px) renders cleanly',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      await tester.pumpWidget(_buildTestWidget(
        size: const Size(1280, 800),
        authService: authService,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Create Your Account'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('11. Valid form submission sends expected multipart payload',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1400));
      await tester.pumpWidget(_buildTestWidget(authService: authService));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const Key('register_role_dropdown')));
      await tester.tap(find.byKey(const Key('register_role_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Teacher').last);
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('register_name_field')), 'John Doe');
      await tester.enterText(find.byKey(const Key('register_email_field')), 'john@example.com');
      await tester.enterText(find.byKey(const Key('register_phone_field')), '9876543210');
      await tester.enterText(find.byKey(const Key('register_password_field')), 'secret123');
      await tester.enterText(find.byKey(const Key('register_confirm_password_field')), 'secret123');

      await tester.ensureVisible(find.byKey(const Key('register_submit_button')));
      await tester.tap(find.byKey(const Key('register_submit_button')));
      await tester.pump();

      expect(mockApi.lastPath, '/auth/register');
      expect(mockApi.lastFields?['name'], 'John Doe');
      expect(mockApi.lastFields?['email'], 'john@example.com');
      expect(mockApi.lastFields?['phone'], '9876543210');
      expect(mockApi.lastFields?['password'], 'secret123');
      expect(mockApi.lastFields?['role'], 'teacher');
    });
  });
}
