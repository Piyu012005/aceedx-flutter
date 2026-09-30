import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aceedx_flutter/core/network/api_client.dart';
import 'package:aceedx_flutter/core/network/api_exception.dart';
import 'package:aceedx_flutter/core/storage/session_storage.dart';
import 'package:aceedx_flutter/features/teacher/presentation/question_paper_generator/data/api_unit_data_source.dart';
import 'package:aceedx_flutter/features/teacher/presentation/question_paper_generator/data/question_paper_api_service.dart';
import 'package:aceedx_flutter/features/teacher/presentation/question_paper_generator/state/question_paper_generator_controller.dart';
import 'package:aceedx_flutter/features/teacher/presentation/question_paper_generator/state/question_paper_generator_state.dart';
import 'package:aceedx_flutter/features/teacher/presentation/question_paper_generator/question_paper_generator_screen.dart';
import 'package:aceedx_flutter/features/teacher/presentation/question_paper_generator/models/chapter.dart';
import 'package:aceedx_flutter/features/teacher/presentation/question_paper_generator/state/unit_selection_state.dart';
import 'package:aceedx_flutter/models/unit.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SessionStorage sessionStorage;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'aceedx_user_token': 'mock_bearer_token_12345',
    });
    final prefs = await SharedPreferences.getInstance();
    sessionStorage = SessionStorage(prefs);
  });

  group('Phase 4: ApiUnitDataSource Unit Tests', () {
    test('A & B & C: Calls correct endpoint, passes query params, and sends Bearer token', () async {
      Uri? capturedUri;
      Map<String, String>? capturedHeaders;

      final mockClient = MockClient((request) async {
        capturedUri = request.url;
        capturedHeaders = request.headers;

        final responseJson = {
          "status": true,
          "message": "Units fetched successfully",
          "data": [
            {
              "id": 101,
              "textbook_id": 10,
              "textbook_chapter_id": 1,
              "unit_number": "1",
              "unit_name": "Chemical Equations",
              "start_chunk_index": 0,
              "end_chunk_index": 4,
              "sort_order": 1
            },
            {
              "id": 102,
              "textbook_id": 10,
              "textbook_chapter_id": 1,
              "unit_number": "2",
              "unit_name": "Types of Chemical Reactions",
              "start_chunk_index": 5,
              "end_chunk_index": 10,
              "sort_order": 2
            }
          ]
        };

        return http.Response(jsonEncode(responseJson), 200, headers: {
          'content-type': 'application/json',
        });
      });

      final apiClient = ApiClient(
        httpClient: mockClient,
        sessionStorage: sessionStorage,
      );
      final dataSource = ApiUnitDataSource(
        apiClient: apiClient,
        sessionStorage: sessionStorage,
      );

      final units = await dataSource.getUnitsByContext(
        chapterId: 1,
        subject: '1',
        className: '10',
        schoolId: 5,
      );

      // Verify Endpoint & Base URL
      expect(capturedUri, isNotNull);
      expect(capturedUri!.scheme, equals('https'));
      expect(capturedUri!.host, equals('deve.aceedx.com'));
      expect(capturedUri!.path, equals('/api/teacher/units/by-context'));

      // Verify Query Parameters
      expect(capturedUri!.queryParameters['subject_id'], equals('1'));
      expect(capturedUri!.queryParameters['class'], equals('10'));
      expect(capturedUri!.queryParameters['chapter'], equals('1'));
      expect(capturedUri!.queryParameters['school_id'], equals('5'));

      // Verify Authorization Header
      expect(capturedHeaders, isNotNull);
      expect(capturedHeaders!['Authorization'], equals('Bearer mock_bearer_token_12345'));
      expect(capturedHeaders!['Accept'], equals('application/json'));

      // Verify JSON Parsing
      expect(units.length, equals(2));
      expect(units[0].id, equals(101));
      expect(units[0].unitName, equals('Chemical Equations'));
      expect(units[1].id, equals(102));
      expect(units[1].unitName, equals('Types of Chemical Reactions'));
    });

    test('D & I: Parses empty data array successfully without crashing', () async {
      final mockClient = MockClient((request) async {
        final responseJson = {
          "status": true,
          "message": "Units fetched successfully",
          "data": []
        };
        return http.Response(jsonEncode(responseJson), 200, headers: {
          'content-type': 'application/json',
        });
      });

      final apiClient = ApiClient(httpClient: mockClient, sessionStorage: sessionStorage);
      final dataSource = ApiUnitDataSource(apiClient: apiClient, sessionStorage: sessionStorage);

      final units = await dataSource.getUnitsByContext(chapterId: 4, subject: '1', className: '10');
      expect(units, isEmpty);
    });

    test('E: Throws UnauthorizedException on 401 Unauthorized', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({"status": false, "message": "Unauthorized"}),
          401,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(httpClient: mockClient, sessionStorage: sessionStorage);
      final dataSource = ApiUnitDataSource(apiClient: apiClient, sessionStorage: sessionStorage);

      expect(
        () async => await dataSource.getUnitsByContext(chapterId: 1, subject: '1', className: '10'),
        throwsA(isA<UnauthorizedException>().having((e) => e.statusCode, 'statusCode', 401)),
      );
    });

    test('F: Throws UnauthorizedException on 403 Forbidden', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({"status": false, "message": "Unauthorized access to textbook"}),
          403,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(httpClient: mockClient, sessionStorage: sessionStorage);
      final dataSource = ApiUnitDataSource(apiClient: apiClient, sessionStorage: sessionStorage);

      expect(
        () async => await dataSource.getUnitsByContext(chapterId: 1, subject: '1', className: '10'),
        throwsA(isA<ForbiddenException>().having((e) => e.statusCode, 'statusCode', 403)),
      );
    });

    test('G: Throws ApiException on 422 Validation Error', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({"status": false, "message": "subject_id and class are required"}),
          422,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(httpClient: mockClient, sessionStorage: sessionStorage);
      final dataSource = ApiUnitDataSource(apiClient: apiClient, sessionStorage: sessionStorage);

      expect(
        () async => await dataSource.getUnitsByContext(chapterId: 1, subject: '', className: ''),
        throwsA(isA<ApiException>()
            .having((e) => e.statusCode, 'statusCode', 422)
            .having((e) => e.message, 'message', contains('required'))),
      );
    });

    test('H: Throws ApiException on 500 Server Error', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({"status": false, "message": "Internal Server Error"}),
          500,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(httpClient: mockClient, sessionStorage: sessionStorage);
      final dataSource = ApiUnitDataSource(apiClient: apiClient, sessionStorage: sessionStorage);

      expect(
        () async => await dataSource.getUnitsByContext(chapterId: 1, subject: '1', className: '10'),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 500)),
      );
    });

    test('J: Throws NetworkException on client HTTP error', () async {
      final mockClient = MockClient((request) async {
        throw http.ClientException('Failed to connect to host');
      });

      final apiClient = ApiClient(httpClient: mockClient, sessionStorage: sessionStorage);
      final dataSource = ApiUnitDataSource(apiClient: apiClient, sessionStorage: sessionStorage);

      expect(
        () async => await dataSource.getUnitsByContext(chapterId: 1, subject: '1', className: '10'),
        throwsA(isA<NetworkException>().having((e) => e.message, 'message', contains('Failed to connect'))),
      );
    });

    test('Missing token throws UnauthorizedException prior to network request', () async {
      SharedPreferences.setMockInitialValues({}); // Empty token
      final emptyPrefs = await SharedPreferences.getInstance();
      final emptyStorage = SessionStorage(emptyPrefs);

      final apiClient = ApiClient(sessionStorage: emptyStorage);
      final dataSource = ApiUnitDataSource(apiClient: apiClient, sessionStorage: emptyStorage);

      expect(
        () async => await dataSource.getUnitsByContext(chapterId: 1, subject: '1', className: '10'),
        throwsA(isA<UnauthorizedException>().having((e) => e.statusCode, 'statusCode', 401)),
      );
    });
  });

  group('Phase 4: Selection & Chapter Context Integration Tests', () {
    test('K & L: Multi-selection works with API units and clears on chapter change', () {
      final state = UnitSelectionState();

      final ch1Units = [
        const Unit(id: 201, textbookChapterId: 1, unitNumber: 1, unitName: 'API Unit 1'),
        const Unit(id: 202, textbookChapterId: 1, unitNumber: 2, unitName: 'API Unit 2'),
      ];

      state.setUnits(ch1Units);
      expect(state.availableUnits.length, equals(2));
      expect(state.selectedCount, equals(0));

      state.toggle(ch1Units[0]);
      state.toggle(ch1Units[1]);
      expect(state.selectedCount, equals(2));
      expect(state.selectedUnitIds, equals([201, 202]));

      // Chapter change
      final ch2Units = [
        const Unit(id: 203, textbookChapterId: 2, unitNumber: 1, unitName: 'Ch 2 Unit 1'),
      ];
      state.setUnits(ch2Units);

      expect(state.availableUnits.length, equals(1));
      expect(state.selectedCount, equals(0));
      expect(state.selectedUnitIds, isEmpty);
    });
  });

  group('Phase 4: Widget Integration Tests (QuestionPaperGeneratorScreen & UnitSelector)', () {
    testWidgets('Renders error UI when API throws UnauthorizedException (401)', (tester) async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({"status": false, "message": "Unauthorized"}),
          401,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(httpClient: mockClient, sessionStorage: sessionStorage);
      final dataSource = ApiUnitDataSource(apiClient: apiClient, sessionStorage: sessionStorage);
      final controller = QuestionPaperGeneratorController(
        unitDataSource: dataSource,
        apiService: QuestionPaperApiService(apiClient: apiClient),
        initialState: const QuestionPaperGeneratorState(
          subjectId: 1,
          className: '10',
          availableChapters: [Chapter(id: 1, chapterNumber: '1', title: 'Chapter 1')],
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: QuestionPaperGeneratorScreen(
            controller: controller,
            unitDataSource: dataSource,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await controller.selectChapter(id: 1, name: 'Chapter 1');
      await tester.pumpAndSettle();

      expect(find.text('Your session has expired. Please log in again.'), findsOneWidget);
    });

    testWidgets('Renders error UI when API throws NetworkException', (tester) async {
      final mockClient = MockClient((request) async {
        throw http.ClientException('Network unreachable');
      });

      final apiClient = ApiClient(httpClient: mockClient, sessionStorage: sessionStorage);
      final dataSource = ApiUnitDataSource(apiClient: apiClient, sessionStorage: sessionStorage);
      final controller = QuestionPaperGeneratorController(
        unitDataSource: dataSource,
        apiService: QuestionPaperApiService(apiClient: apiClient),
        initialState: const QuestionPaperGeneratorState(
          subjectId: 1,
          className: '10',
          availableChapters: [Chapter(id: 1, chapterNumber: '1', title: 'Chapter 1')],
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: QuestionPaperGeneratorScreen(
            controller: controller,
            unitDataSource: dataSource,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await controller.selectChapter(id: 1, name: 'Chapter 1');
      await tester.pumpAndSettle();

      expect(find.text('Unable to connect to the server.'), findsOneWidget);
    });

    testWidgets('Renders loaded units from ApiUnitDataSource and allows multi-selection', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final mockClient = MockClient((request) async {
        final responseJson = {
          "status": true,
          "message": "Units fetched successfully",
          "data": [
            {
              "id": 301,
              "textbook_id": 1,
              "textbook_chapter_id": 1,
              "unit_number": "1",
              "unit_name": "API Unit Alpha"
            },
            {
              "id": 302,
              "textbook_id": 1,
              "textbook_chapter_id": 1,
              "unit_number": "2",
              "unit_name": "API Unit Beta"
            }
          ]
        };
        return http.Response(jsonEncode(responseJson), 200, headers: {
          'content-type': 'application/json',
        });
      });

      final apiClient = ApiClient(httpClient: mockClient, sessionStorage: sessionStorage);
      final dataSource = ApiUnitDataSource(apiClient: apiClient, sessionStorage: sessionStorage);
      final controller = QuestionPaperGeneratorController(
        unitDataSource: dataSource,
        apiService: QuestionPaperApiService(apiClient: apiClient),
        initialState: const QuestionPaperGeneratorState(
          subjectId: 1,
          className: '10',
          availableChapters: [Chapter(id: 1, chapterNumber: '1', title: 'Chapter 1')],
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: QuestionPaperGeneratorScreen(
            controller: controller,
            unitDataSource: dataSource,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await controller.selectChapter(id: 1, name: 'Chapter 1');
      await tester.pumpAndSettle();

      expect(find.textContaining('API Unit Alpha'), findsOneWidget);
      expect(find.textContaining('API Unit Beta'), findsOneWidget);
      expect(find.text('0 of 2 units'), findsOneWidget);

      // Select first unit
      await tester.tap(find.textContaining('API Unit Alpha'));
      await tester.pumpAndSettle();

      expect(find.text('1 of 2 units'), findsOneWidget);

      // Select second unit
      await tester.tap(find.textContaining('API Unit Beta'));
      await tester.pumpAndSettle();

      expect(find.text('2 of 2 units'), findsOneWidget);

      expect(find.text('2 of 2 units'), findsOneWidget);
    });
  });
}
