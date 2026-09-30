import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aceedx_flutter/core/network/api_client.dart';
import 'package:aceedx_flutter/core/network/api_exception.dart';
import 'package:aceedx_flutter/features/teacher/presentation/question_paper_generator/data/question_paper_api_service.dart';
import 'package:aceedx_flutter/features/teacher/presentation/question_paper_generator/data/unit_data_source.dart';
import 'package:aceedx_flutter/features/teacher/presentation/question_paper_generator/models/question_paper_generation_request.dart';
import 'package:aceedx_flutter/features/teacher/presentation/question_paper_generator/models/question_paper_generation_response.dart';
import 'package:aceedx_flutter/features/teacher/presentation/question_paper_generator/question_paper_generator_screen.dart';
import 'package:aceedx_flutter/features/teacher/presentation/question_paper_generator/state/question_paper_generator_controller.dart';
import 'package:aceedx_flutter/features/teacher/presentation/question_paper_generator/state/question_paper_generator_state.dart';
import 'package:aceedx_flutter/features/teacher/presentation/question_paper_generator/widgets/unit_selector.dart';
import 'package:aceedx_flutter/models/unit.dart';

class MockUnitDataSource implements UnitDataSource {
  List<Unit> mockUnits = [
    const Unit(id: 143, unitNumber: 1, unitName: 'Chemical Reactions'),
    const Unit(id: 144, unitNumber: 2, unitName: 'Types of Reactions'),
    const Unit(id: 145, unitNumber: 3, unitName: 'Corrosion and Rancidity'),
  ];
  int callCount = 0;
  String? lastChapter;
  bool shouldThrow = false;

  @override
  Future<List<Unit>> getUnitsByContext({
    required int chapterId,
    String? chapterName,
    int? textbookId,
    String? subject,
    String? className,
    int? schoolId,
  }) async {
    callCount++;
    lastChapter = chapterName ?? chapterId.toString();
    if (shouldThrow) {
      throw const ApiException(message: 'Failed to fetch units from server', statusCode: 500);
    }
    if (chapterId == 999) {
      return [];
    }
    return mockUnits;
  }
}

class MockQuestionPaperApiService extends QuestionPaperApiService {
  QuestionPaperGenerationRequest? lastRequest;
  bool shouldFail = false;

  MockQuestionPaperApiService() : super(apiClient: ApiClient());

  @override
  Future<List<String>> getTextbookChapters({
    required int subjectId,
    required String className,
    int? schoolId,
    String? schoolName,
  }) async {
    return ['Chapter 1: Chemical Reactions', 'Chapter 2: Acids and Bases'];
  }

  @override
  Future<QuestionPaperGenerationResponse> generatePaper(
    QuestionPaperGenerationRequest request,
  ) async {
    lastRequest = request;
    if (shouldFail) {
      throw const ApiException(message: 'Server failed to generate question paper', statusCode: 500);
    }
    return QuestionPaperGenerationResponse(
      status: true,
      message: 'Question paper generated successfully',
      data: GeneratedPaperData(
        id: 77,
        schoolId: request.schoolId,
        subjectId: request.subjectId,
        className: request.className,
        chapter: request.chapter,
        marks: request.marks,
        format: request.format,
        board: request.board,
        paperLanguage: request.paperLanguage,
        questions: 'Sample generated questions...',
      ),
    );
  }

  @override
  Future<Map<String, dynamic>> getDropdownData(int schoolId) async {
    return {
      'boards': [
        {'id': 1, 'name': 'CBSE'},
        {'id': 2, 'name': 'ICSE'},
      ],
      'subjects': [
        {'id': 1, 'name': 'Science'},
        {'id': 2, 'name': 'Mathematics'},
      ],
      'classes': ['9', '10', '11', '12'],
    };
  }

  @override
  Future<String?> getSchoolInfo() async {
    return 'AceEdx Demonstration Academy';
  }
}

void main() {
  group('AI Question Paper Generator Unit & Controller Tests', () {
    late MockUnitDataSource mockUnitDataSource;
    late MockQuestionPaperApiService mockApiService;
    late QuestionPaperGeneratorController controller;

    setUp(() {
      mockUnitDataSource = MockUnitDataSource();
      mockApiService = MockQuestionPaperApiService();
      controller = QuestionPaperGeneratorController(
        unitDataSource: mockUnitDataSource,
        apiService: mockApiService,
      );
    });

    test('1. Initial state has default values matching forensic analysis', () {
      final state = controller.value;
      expect(state.marks, equals(80));
      expect(state.board, equals('CBSE'));
      expect(state.paperLanguage, equals('English'));
      expect(state.difficulty, equals('Easy'));
      expect(state.selectedFormats, contains('MCQ'));
      expect(state.selectedUnitIds, isEmpty);
      expect(state.computedPromptPreview, equals('MCQ | Questions: 1 | Marks each: 1'));
    });

    test('2. Changing Chapter clears old selectedUnitIds and fetches new units', () async {
      // Setup initial chapter & select units
      await controller.selectChapter(id: 1, name: 'Chapter 1: Chemical Reactions');
      expect(controller.value.availableUnits.length, equals(3));
      controller.toggleUnitSelection(143);
      controller.toggleUnitSelection(144);
      expect(controller.value.selectedUnitIds, equals([143, 144]));

      // Change Chapter to Chapter 2
      await controller.selectChapter(id: 2, name: 'Chapter 2: Acids and Bases');
      // Crucial requirement: selectedUnitIds must be empty!
      expect(controller.value.selectedUnitIds, isEmpty);
      expect(controller.value.chapterName, equals('Chapter 2: Acids and Bases'));
      expect(mockUnitDataSource.callCount, equals(2));
    });

    test('3. Changing Subject clears Class, Chapter, Units, and selectedUnitIds', () async {
      await controller.selectChapter(id: 1, name: 'Chapter 1');
      controller.toggleUnitSelection(143);
      expect(controller.value.selectedUnitIds, isNotEmpty);

      controller.selectSubject(id: 2, name: 'Mathematics');
      expect(controller.value.subjectId, equals(2));
      expect(controller.value.className, isNull);
      expect(controller.value.chapterName, isNull);
      expect(controller.value.availableUnits, isEmpty);
      expect(controller.value.selectedUnitIds, isEmpty);
    });

    test('4. Unit multi-selection maintains strictly numeric List<int>', () async {
      await controller.selectChapter(id: 1, name: 'Chapter 1');
      controller.toggleUnitSelection(143);
      controller.toggleUnitSelection(145);

      expect(controller.value.selectedUnitIds, isA<List<int>>());
      expect(controller.value.selectedUnitIds, equals([143, 145]));

      // Toggle off 143
      controller.toggleUnitSelection(143);
      expect(controller.value.selectedUnitIds, equals([145]));
    });

    test('5. Select All & Clear actions update selectedUnitIds correctly', () async {
      await controller.selectChapter(id: 1, name: 'Chapter 1');
      controller.selectAllUnits();
      expect(controller.value.selectedUnitIds, equals([143, 144, 145]));

      controller.clearUnitSelection();
      expect(controller.value.selectedUnitIds, isEmpty);
    });

    test('6. Question formats multi-select and per-format settings update a2e preview', () {
      controller.toggleFormat('True / False');
      controller.setFormatQuestionCount('MCQ', 5);
      controller.setFormatMarksEach('MCQ', 2);
      controller.setFormatQuestionCount('True / False', 4);
      controller.setFormatMarksEach('True / False', 1);

      final preview = controller.value.computedPromptPreview;
      expect(preview, contains('MCQ | Questions: 5 | Marks each: 2'));
      expect(preview, contains('True / False | Questions: 4 | Marks each: 1'));
    });

    test('7. Additional instructions append after prompt preview with divider', () {
      controller.setAdditionalInstructions('Ensure diagrams are included for questions.');
      final fullPrompt = controller.value.fullGeneratedPrompt;
      expect(fullPrompt, contains('MCQ | Questions: 1 | Marks each: 1'));
      expect(fullPrompt, contains('\n\n---\n\n'));
      expect(fullPrompt, contains('Ensure diagrams are included for questions.'));
    });

    test('8. POST /api/teacher/generate constructs exact required JSON payload', () async {
      controller.setSchoolId(1);
      controller.selectSubject(id: 1, name: 'Science');
      controller.selectClass('10');
      await controller.selectChapter(id: 1, name: 'Chapter 1: Chemical Reactions');
      controller.toggleUnitSelection(143);
      controller.toggleUnitSelection(144);
      controller.setMarks(80);
      controller.setBoard('CBSE');
      controller.setPaperLanguage('English');
      controller.setDifficulty('Medium');

      final success = await controller.generateQuestionPaper();
      expect(success, isTrue);

      final req = mockApiService.lastRequest;
      expect(req, isNotNull);
      expect(req!.schoolId, equals(1));
      expect(req.subjectId, equals(1));
      expect(req.className, equals('10'));
      expect(req.chapter, equals('Chapter 1: Chemical Reactions'));
      expect(req.marks, equals(80));
      expect(req.board, equals('CBSE'));
      expect(req.paperLanguage, equals('english'));
      expect(req.difficulty, equals('medium'));
      expect(req.unitIds, equals([143, 144]));
      expect(req.unitIds, isA<List<int>>());

      // Verify JSON serialization
      final json = req.toJson();
      expect(json['unit_ids'], equals([143, 144]));
      expect(json['marks'], equals(80));
      expect(json['class'], equals('10'));
      expect(json['chapter'], equals('Chapter 1: Chemical Reactions'));
    });

    test('9. Empty units state still allows question paper generation without unit_ids', () async {
      controller.setSchoolId(1);
      controller.selectSubject(id: 1, name: 'Science');
      controller.selectClass('10');
      await controller.selectChapter(id: 999, name: 'Chapter with No Units');
      expect(controller.value.availableUnits, isEmpty);
      expect(controller.value.selectedUnitIds, isEmpty);

      final success = await controller.generateQuestionPaper();
      expect(success, isTrue);
      expect(mockApiService.lastRequest!.unitIds, isNull);
      expect(mockApiService.lastRequest!.toJson().containsKey('unit_ids'), isFalse);
    });

    test('10. Generation error state properly captured and displayed', () async {
      mockApiService.shouldFail = true;
      controller.setSchoolId(1);
      controller.selectSubject(id: 1, name: 'Science');
      controller.selectClass('10');
      await controller.selectChapter(id: 1, name: 'Chapter 1');

      final success = await controller.generateQuestionPaper();
      expect(success, isFalse);
      expect(controller.value.status, equals(QuestionPaperGeneratorStatus.generationError));
      expect(controller.value.errorMessage, contains('Server failed to generate'));
    });
  });

  group('AI Question Paper Generator Widget Tests', () {
    late MockUnitDataSource mockUnitDataSource;
    late MockQuestionPaperApiService mockApiService;
    late QuestionPaperGeneratorController controller;

    setUp(() {
      mockUnitDataSource = MockUnitDataSource();
      mockApiService = MockQuestionPaperApiService();
      controller = QuestionPaperGeneratorController(
        unitDataSource: mockUnitDataSource,
        apiService: mockApiService,
      );
    });

    testWidgets('11. Screen renders title, school section, generate form, and unit selector', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: QuestionPaperGeneratorScreen(
            controller: controller,
            unitDataSource: mockUnitDataSource,
            apiService: mockApiService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('AI Question Paper Generator'), findsWidgets);
      expect(find.text('School'), findsOneWidget);
      expect(find.text('Generate'), findsOneWidget);
      expect(find.text('Board *'), findsOneWidget);
      expect(find.textContaining('Subject *'), findsOneWidget);
      expect(find.textContaining('Class *'), findsOneWidget);
      expect(find.textContaining('Chapter *'), findsOneWidget);
      expect(find.textContaining('Select one or more chapters'), findsOneWidget);
      expect(find.text('Generate Question Paper'), findsOneWidget);
    });

    testWidgets('12. Unit checkboxes appear directly below chapter and allow multi-selection', (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: QuestionPaperGeneratorScreen(
            controller: controller,
            unitDataSource: mockUnitDataSource,
            apiService: mockApiService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await controller.selectChapter(id: 1, name: 'Chapter 1: Chemical Reactions');
      await tester.pumpAndSettle();

      // Units loaded from mock
      expect(find.textContaining('Chemical Reactions'), findsWidgets);
      expect(find.textContaining('Types of Reactions'), findsWidgets);

      // Tap on first unit checkbox
      await tester.ensureVisible(find.textContaining('Chemical Reactions').first);
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Chemical Reactions').first);
      await tester.pumpAndSettle();

      expect(controller.value.selectedUnitIds, contains(143));
      expect(find.textContaining('1 selected'), findsWidgets);
      expect(find.text('Generate Paper (1 Unit(s) Selected)'), findsOneWidget);
    });

    testWidgets('13. Select All and Clear buttons function in UnitSelector', (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: QuestionPaperGeneratorScreen(
            controller: controller,
            unitDataSource: mockUnitDataSource,
            apiService: mockApiService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await controller.selectChapter(id: 1, name: 'Chapter 1: Chemical Reactions');
      await tester.pumpAndSettle();

      // Tap Select All
      await tester.ensureVisible(find.text('Select All'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Select All'));
      await tester.pumpAndSettle();
      expect(controller.value.selectedUnitIds.length, equals(3));
      expect(find.textContaining('3 selected'), findsWidgets);

      // Tap Clear
      await tester.ensureVisible(find.text('Clear'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Clear'));
      await tester.pumpAndSettle();
      expect(controller.value.selectedUnitIds, isEmpty);
      expect(find.textContaining('0 selected'), findsWidgets);
    });

    testWidgets('14. UnitSelector renders empty state when no units available', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UnitSelector(
              selectedChapterGroups: const [],
              selectedUnitIds: const {},
              onToggleUnit: (_) {},
              onSelectAllGroupUnits: (_) {},
              onClearGroupUnits: (_) {},
              onToggleGroupExpanded: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Select one or more chapters above to view and select subtopic units.'), findsOneWidget);
    });

    testWidgets('15. UnitSelector renders error message when units fail to load', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UnitSelector(
              selectedChapterGroups: const [],
              selectedUnitIds: const {},
              errorMessage: 'Unable to connect to the server.',
              onToggleUnit: (_) {},
              onSelectAllGroupUnits: (_) {},
              onClearGroupUnits: (_) {},
              onToggleGroupExpanded: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Unable to connect to the server.'), findsOneWidget);
    });
  });
}
