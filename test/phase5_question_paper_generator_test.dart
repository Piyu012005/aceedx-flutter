import 'dart:convert';
import 'package:aceedx_flutter/core/network/api_client.dart';
import 'package:aceedx_flutter/core/network/api_exception.dart';
import 'package:aceedx_flutter/features/teacher/presentation/question_paper_generator/data/question_paper_api_service.dart';
import 'package:aceedx_flutter/features/teacher/presentation/question_paper_generator/data/unit_data_source.dart';
import 'package:aceedx_flutter/features/teacher/presentation/question_paper_generator/models/question_paper_generation_request.dart';
import 'package:aceedx_flutter/features/teacher/presentation/question_paper_generator/question_paper_generator_screen.dart';
import 'package:aceedx_flutter/features/teacher/presentation/question_paper_generator/state/question_paper_generator_controller.dart';
import 'package:aceedx_flutter/features/teacher/presentation/question_paper_generator/models/chapter.dart';
import 'package:aceedx_flutter/features/teacher/presentation/question_paper_generator/state/question_paper_generator_state.dart';
import 'package:aceedx_flutter/models/unit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class MockUnitDataSourceImpl implements UnitDataSource {
  final List<Unit> unitsToReturn;
  final Exception? exceptionToThrow;

  MockUnitDataSourceImpl({
    this.unitsToReturn = const [],
    this.exceptionToThrow,
  });

  @override
  Future<List<Unit>> getUnitsByContext({
    required int chapterId,
    String? chapterName,
    int? textbookId,
    String? subject,
    String? className,
    int? schoolId,
  }) async {
    if (exceptionToThrow != null) {
      throw exceptionToThrow!;
    }
    return unitsToReturn;
  }
}

void main() {
  group('Phase 5 Question Paper Generation Contract & Logic Tests', () {
    // A. Request model JSON
    test('A. Request model JSON serializes correctly according to Laravel contract', () {
      const request = QuestionPaperGenerationRequest(
        schoolId: 10,
        subjectId: 2,
        className: '10',
        chapter: '3',
        marks: 80,
        format: 'standard',
        board: 'CBSE',
        userPrompt: 'Generate conceptual question paper',
        paperLanguage: 'english',
        unitIds: [101, 102],
        difficulty: 'medium',
      );

      final jsonMap = request.toJson();

      expect(jsonMap['school_id'], equals(10));
      expect(jsonMap['subject_id'], equals(2));
      expect(jsonMap['class'], equals('10'));
      expect(jsonMap['chapter'], equals('3'));
      expect(jsonMap['marks'], equals(80));
      expect(jsonMap['format'], equals('standard'));
      expect(jsonMap['board'], equals('CBSE'));
      expect(jsonMap['user_prompt'], equals('Generate conceptual question paper'));
      expect(jsonMap['paper_language'], equals('english'));
      expect(jsonMap['unit_ids'], equals([101, 102]));
    });

    // B. Selected Unit IDs remain List<int>
    test('B. Selected Unit IDs remain List<int> in request model', () {
      const request = QuestionPaperGenerationRequest(
        schoolId: 1,
        subjectId: 1,
        className: '10',
        chapter: 'Chapter 1',
        marks: 50,
        format: 'standard',
        board: 'CBSE',
        userPrompt: 'Prompt',
        unitIds: [5, 12, 19],
      );

      expect(request.unitIds, isA<List<int>>());
      expect(request.unitIds, equals([5, 12, 19]));
      expect(request.toJson()['unit_ids'], isA<List<int>>());
    });

    // C. Generator request contains correct unit field 'unit_ids'
    test('C. Generator request contains correct unit field name unit_ids', () {
      const request = QuestionPaperGenerationRequest(
        schoolId: 1,
        subjectId: 2,
        className: '9',
        chapter: '1',
        marks: 40,
        format: 'standard',
        board: 'CBSE',
        userPrompt: 'Prompt',
        unitIds: [42],
      );

      final json = request.toJson();
      expect(json.containsKey('unit_ids'), isTrue);
      expect(json.containsKey('units'), isFalse);
      expect(json.containsKey('unitIds'), isFalse);
    });

    // D. Required field validation
    test('D. Form validation fails when required fields are missing', () {
      final mockUnitSource = MockUnitDataSourceImpl();
      final mockClient = MockClient((_) async => http.Response('{}', 200));
      final apiClient = ApiClient(httpClient: mockClient);
      final apiService = QuestionPaperApiService(apiClient: apiClient);

      final controller = QuestionPaperGeneratorController(
        unitDataSource: mockUnitSource,
        apiService: apiService,
      );

      // Initially missing school ID
      expect(controller.validateForm(), isNotNull);
      expect(controller.validateForm(), contains('School ID'));

      controller.setSchoolId(1);
      expect(controller.validateForm(), contains('Subject'));

      controller.selectSubject(id: 1, name: 'Science');
      expect(controller.validateForm(), contains('Class'));

      controller.selectClass('10');
      expect(controller.validateForm(), contains('Chapter'));
    });

    // E. API service success response
    test('E. API service handles 200 success response', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, endsWith('/teacher/generate'));
        return http.Response(
          jsonEncode({
            'status': true,
            'message': 'Question paper generated successfully',
            'data': {
              'id': 99,
              'class': '10',
              'marks': 80,
              'format': 'standard',
              'paper_language': 'english',
              'status': 'pending',
            }
          }),
          200,
        );
      });

      final apiClient = ApiClient(httpClient: mockClient);
      final apiService = QuestionPaperApiService(apiClient: apiClient);

      const req = QuestionPaperGenerationRequest(
        schoolId: 1,
        subjectId: 1,
        className: '10',
        chapter: '1',
        marks: 80,
        format: 'standard',
        board: 'CBSE',
        userPrompt: 'Test prompt',
      );

      final response = await apiService.generatePaper(req);
      expect(response.status, isTrue);
      expect(response.data?.id, equals(99));
    });

    // F. 401 Unauthorized
    test('F. API service throws UnauthorizedException on 401 response', () async {
      final mockClient = MockClient((_) async {
        return http.Response(
          jsonEncode({'status': false, 'message': 'Unauthenticated.'}),
          401,
        );
      });

      final apiClient = ApiClient(httpClient: mockClient);
      final apiService = QuestionPaperApiService(apiClient: apiClient);

      const req = QuestionPaperGenerationRequest(
        schoolId: 1,
        subjectId: 1,
        className: '10',
        chapter: '1',
        marks: 80,
        format: 'standard',
        board: 'CBSE',
        userPrompt: 'Test prompt',
      );

      expect(
        () async => await apiService.generatePaper(req),
        throwsA(isA<UnauthorizedException>()),
      );
    });

    // G. 403 Forbidden
    test('G. API service throws ForbiddenException on 403 response', () async {
      final mockClient = MockClient((_) async {
        return http.Response(
          jsonEncode({'status': false, 'message': 'Forbidden'}),
          403,
        );
      });

      final apiClient = ApiClient(httpClient: mockClient);
      final apiService = QuestionPaperApiService(apiClient: apiClient);

      const req = QuestionPaperGenerationRequest(
        schoolId: 1,
        subjectId: 1,
        className: '10',
        chapter: '1',
        marks: 80,
        format: 'standard',
        board: 'CBSE',
        userPrompt: 'Test prompt',
      );

      expect(
        () async => await apiService.generatePaper(req),
        throwsA(isA<ForbiddenException>()),
      );
    });

    // H. 422 Validation Error
    test('H. API service throws ApiException on 422 validation response', () async {
      final mockClient = MockClient((_) async {
        return http.Response(
          jsonEncode({
            'status': false,
            'message': 'One or more selected unit IDs are invalid for this textbook'
          }),
          422,
        );
      });

      final apiClient = ApiClient(httpClient: mockClient);
      final apiService = QuestionPaperApiService(apiClient: apiClient);

      const req = QuestionPaperGenerationRequest(
        schoolId: 1,
        subjectId: 1,
        className: '10',
        chapter: '1',
        marks: 80,
        format: 'standard',
        board: 'CBSE',
        userPrompt: 'Test prompt',
        unitIds: [9999],
      );

      expect(
        () async => await apiService.generatePaper(req),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 422)),
      );
    });

    // I. 500 Server Error
    test('I. API service throws ApiException on 500 response', () async {
      final mockClient = MockClient((_) async {
        return http.Response(
          jsonEncode({'status': false, 'message': 'Internal Server Error'}),
          500,
        );
      });

      final apiClient = ApiClient(httpClient: mockClient);
      final apiService = QuestionPaperApiService(apiClient: apiClient);

      const req = QuestionPaperGenerationRequest(
        schoolId: 1,
        subjectId: 1,
        className: '10',
        chapter: '1',
        marks: 80,
        format: 'standard',
        board: 'CBSE',
        userPrompt: 'Test prompt',
      );

      expect(
        () async => await apiService.generatePaper(req),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 500)),
      );
    });

    // J. Network failure
    test('J. API service throws NetworkException on socket or client failure', () async {
      final mockClient = MockClient((_) async {
        throw http.ClientException('Failed to connect to host');
      });

      final apiClient = ApiClient(httpClient: mockClient);
      final apiService = QuestionPaperApiService(apiClient: apiClient);

      const req = QuestionPaperGenerationRequest(
        schoolId: 1,
        subjectId: 1,
        className: '10',
        chapter: '1',
        marks: 80,
        format: 'standard',
        board: 'CBSE',
        userPrompt: 'Test prompt',
      );

      expect(
        () async => await apiService.generatePaper(req),
        throwsA(isA<NetworkException>()),
      );
    });

    // K. Unit selection included in request
    test('K. Selected Unit IDs are properly sent in request payload', () async {
      Map<String, dynamic>? capturedBody;

      final mockClient = MockClient((request) async {
        capturedBody = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(
          jsonEncode({
            'status': true,
            'message': 'Success',
            'data': {'id': 1}
          }),
          200,
        );
      });

      final apiClient = ApiClient(httpClient: mockClient);
      final apiService = QuestionPaperApiService(apiClient: apiClient);

      final mockUnitSource = MockUnitDataSourceImpl(
        unitsToReturn: [
          const Unit(
            id: 101,
            unitNumber: 1,
            unitName: 'Unit 1: Chemical Reactions',
            textbookId: 10,
            textbookChapterId: 1,
            startChunkIndex: 0,
            endChunkIndex: 5,
            sortOrder: 1,
          )
        ],
      );

      final controller = QuestionPaperGeneratorController(
        unitDataSource: mockUnitSource,
        apiService: apiService,
      );

      controller.setSchoolId(10);
      controller.selectSubject(id: 1, name: 'Science');
      controller.selectClass('10');
      await controller.selectChapter(id: 1, name: 'Chapter 1');
      controller.toggleUnitSelection(101);

      final success = await controller.generateQuestionPaper();
      expect(success, isTrue);
      expect(capturedBody, isNotNull);
      expect(capturedBody!['unit_ids'], equals([101]));
    });

    // L & M. Subject/Class/Chapter context preserved & Chapter change clears Unit selection
    test('L & M. Cascade resets clear selections and chapter change clears unit selection', () async {
      final mockUnitSource = MockUnitDataSourceImpl(
        unitsToReturn: [
          const Unit(
            id: 201,
            unitNumber: 1,
            unitName: 'Unit 1',
            textbookId: 10,
            textbookChapterId: 2,
            startChunkIndex: 0,
            endChunkIndex: 3,
            sortOrder: 1,
          )
        ],
      );

      final mockClient = MockClient((_) async => http.Response('{}', 200));
      final apiClient = ApiClient(httpClient: mockClient);
      final apiService = QuestionPaperApiService(apiClient: apiClient);

      final controller = QuestionPaperGeneratorController(
        unitDataSource: mockUnitSource,
        apiService: apiService,
      );

      controller.setSchoolId(10);
      controller.selectSubject(id: 2, name: 'Mathematics');
      controller.selectClass('10');
      await controller.selectChapter(id: 2, name: 'Chapter 2');
      controller.toggleUnitSelection(201);

      expect(controller.value.selectedUnitIds, contains(201));

      // Changing chapter MUST clear unit selection (Rule M)
      await controller.selectChapter(id: 3, name: 'Chapter 3');
      expect(controller.value.selectedUnitIds, isEmpty);

      // Changing subject MUST clear class, chapter, units (Rule L)
      controller.selectSubject(id: 1, name: 'Science');
      expect(controller.value.className, isNull);
      expect(controller.value.chapterId, isNull);
      expect(controller.value.selectedUnitIds, isEmpty);
    });

    // N. Generate loading state
    test('N. Controller sets state to generating during API execution', () async {
      final mockClient = MockClient((_) async {
        await Future.delayed(const Duration(milliseconds: 50));
        return http.Response(
          jsonEncode({
            'status': true,
            'message': 'Generated',
            'data': {'id': 55}
          }),
          200,
        );
      });

      final apiClient = ApiClient(httpClient: mockClient);
      final apiService = QuestionPaperApiService(apiClient: apiClient);
      final mockUnitSource = MockUnitDataSourceImpl();

      final controller = QuestionPaperGeneratorController(
        unitDataSource: mockUnitSource,
        apiService: apiService,
      );

      controller.setSchoolId(10);
      controller.selectSubject(id: 1, name: 'Science');
      controller.selectClass('10');
      controller.selectChapter(id: 1, name: 'Chapter 1');

      final genFuture = controller.generateQuestionPaper();
      expect(controller.value.status, equals(QuestionPaperGeneratorStatus.generating));

      final result = await genFuture;
      expect(result, isTrue);
      expect(controller.value.status, equals(QuestionPaperGeneratorStatus.generatedSuccess));
      expect(controller.value.generatedPaper?.id, equals(55));
    });

    // Widget Integration Test for QuestionPaperGeneratorScreen
    testWidgets('Widget Test: QuestionPaperGeneratorScreen renders and triggers generation flow', (tester) async {
      final mockClient = MockClient((_) async {
        return http.Response(
          jsonEncode({
            'status': true,
            'message': 'Success',
            'data': {'id': 77, 'class': '10', 'marks': 80, 'format': 'standard', 'paper_language': 'english'}
          }),
          200,
        );
      });

      final apiClient = ApiClient(httpClient: mockClient);
      final apiService = QuestionPaperApiService(apiClient: apiClient);
      final mockUnitSource = MockUnitDataSourceImpl();

      final controller = QuestionPaperGeneratorController(
        unitDataSource: mockUnitSource,
        apiService: apiService,
        initialState: const QuestionPaperGeneratorState(
          schoolId: 1,
          subjectId: 1,
          subjectName: 'Science',
          className: '10',
          availableChapters: [
            Chapter(id: 1, chapterNumber: '1', title: 'Chapter 1: Chemical Reactions and Equations'),
          ],
        ),
      );

      controller.setSchoolId(1);
      controller.selectSubject(id: 1, name: 'Science');
      controller.selectClass('10');
      await controller.selectChapter(id: 1, name: 'Chapter 1: Chemical Reactions and Equations');

      tester.view.physicalSize = const Size(1200, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: QuestionPaperGeneratorScreen(
            controller: controller,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('AI Question Paper Generator'), findsOneWidget);
      await tester.ensureVisible(find.text('Generate Question Paper'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Generate Question Paper'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Question Paper Generated Successfully!'), findsOneWidget);
    });

    test('Controller rejects duplicate concurrent generateQuestionPaper calls', () async {
      final mockUnitSource = MockUnitDataSourceImpl();
      var callCount = 0;
      final mockClient = MockClient((_) async {
        callCount++;
        await Future.delayed(const Duration(milliseconds: 50));
        return http.Response(
          jsonEncode({
            'status': true,
            'message': 'Success',
            'data': {'id': 88, 'class': '10', 'marks': 80, 'format': 'standard', 'paper_language': 'english'}
          }),
          200,
        );
      });
      final apiClient = ApiClient(httpClient: mockClient);
      final apiService = QuestionPaperApiService(apiClient: apiClient);

      final controller = QuestionPaperGeneratorController(
        unitDataSource: mockUnitSource,
        apiService: apiService,
      );

      controller.setSchoolId(10);
      controller.selectSubject(id: 1, name: 'Science');
      controller.selectClass('10');
      controller.selectChapter(id: 1, name: 'Chapter 1');

      // Launch first generation
      final future1 = controller.generateQuestionPaper();
      expect(controller.value.status, equals(QuestionPaperGeneratorStatus.generating));

      // Attempt second generation while first is still running
      final future2 = controller.generateQuestionPaper();

      final res2 = await future2;
      expect(res2, isFalse, reason: 'Second concurrent call must be rejected');

      final res1 = await future1;
      expect(res1, isTrue);
      expect(callCount, equals(1), reason: 'Only 1 HTTP request should have been sent');
    });

    testWidgets('Generate button is disabled and shows loading indicator while generating', (tester) async {
      final mockUnitSource = MockUnitDataSourceImpl();
      final mockClient = MockClient((_) async => http.Response(
        jsonEncode({'status': true, 'data': {'id': 1}}), 200,
      ));
      final apiClient = ApiClient(httpClient: mockClient);
      final apiService = QuestionPaperApiService(apiClient: apiClient);

      final controller = QuestionPaperGeneratorController(
        unitDataSource: mockUnitSource,
        apiService: apiService,
        initialState: const QuestionPaperGeneratorState(
          status: QuestionPaperGeneratorStatus.generating,
          schoolId: 1,
          subjectId: 1,
          subjectName: 'Science',
          className: '10',
        ),
      );

      tester.view.physicalSize = const Size(1200, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: QuestionPaperGeneratorScreen(
            controller: controller,
          ),
        ),
      );

      await tester.pump();

      // Button should display generating text and CircularProgressIndicator
      expect(find.text('Generating Question Paper...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsWidgets);

      final elevatedBtn = tester.widget<ElevatedButton>(find.byType(ElevatedButton).last);
      expect(elevatedBtn.onPressed, isNull, reason: 'Button must be disabled when generating');
    });
  });
}
