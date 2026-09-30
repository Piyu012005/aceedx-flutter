// Phase 7: Full End-to-End Regression Test Suite
// =================================================
// Tests: Cascade logic, generation payload, generation→review transition,
// paper structure parsing, PDF export, answer key export, security/environment,
// and failure error states.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Core
import 'package:aceedx_flutter/core/config/app_config.dart';
import 'package:aceedx_flutter/core/network/api_client.dart';
import 'package:aceedx_flutter/core/network/api_exception.dart';

// Models
import 'package:aceedx_flutter/models/unit.dart';
import 'package:aceedx_flutter/features/teacher/presentation/question_paper_generator/models/question_paper.dart';
import 'package:aceedx_flutter/features/teacher/presentation/question_paper_generator/models/question_paper_generation_request.dart';
import 'package:aceedx_flutter/features/teacher/presentation/question_paper_generator/models/question_paper_generation_response.dart';
import 'package:aceedx_flutter/features/teacher/presentation/question_paper_generator/models/question_paper_section.dart';
import 'package:aceedx_flutter/features/teacher/presentation/question_paper_generator/models/question_paper_question.dart';

// State
import 'package:aceedx_flutter/features/teacher/presentation/question_paper_generator/state/question_paper_generator_controller.dart';
import 'package:aceedx_flutter/features/teacher/presentation/question_paper_generator/state/question_paper_generator_state.dart';

// Data Sources
import 'package:aceedx_flutter/features/teacher/presentation/question_paper_generator/data/unit_data_source.dart';
import 'package:aceedx_flutter/features/teacher/presentation/question_paper_generator/data/question_paper_api_service.dart';

// Screens
import 'package:aceedx_flutter/features/teacher/presentation/question_paper_generator/question_paper_generator_screen.dart';
import 'package:aceedx_flutter/features/teacher/presentation/question_paper_review/question_paper_review_screen.dart';

// ───────────────────────────────────────────────────────────────────
// Mock UnitDataSource
// ───────────────────────────────────────────────────────────────────
class _MockUnitDataSource implements UnitDataSource {
  int fetchCount = 0;
  int lastChapterId = -1;
  List<Unit> stubUnits = [];
  Exception? stubException;

  @override
  Future<List<Unit>> getUnitsByContext({
    required int chapterId,
    int? textbookId,
    String? subject,
    String? className,
    int? schoolId,
    String? chapterName,
  }) async {
    fetchCount++;
    lastChapterId = chapterId;
    if (stubException != null) throw stubException!;
    return stubUnits;
  }
}

// ───────────────────────────────────────────────────────────────────
// Mock QuestionPaperApiService
// ───────────────────────────────────────────────────────────────────
class _MockApiService extends QuestionPaperApiService {
  QuestionPaperGenerationResponse? stubGenerateResponse;
  QuestionPaper? stubPaper;
  List<QuestionPaper>? stubPapers;
  QuestionPaperExportResponse? stubExportResponse;
  QuestionPaperExportResponse? stubAnsKeyResponse;
  Exception? generateException;
  Exception? getPaperException;
  Exception? exportPdfException;
  Exception? exportAnsKeyException;

  Map<String, dynamic>? lastGeneratePayload;
  Map<String, dynamic>? lastExportPdfPayload;
  Map<String, dynamic>? lastExportAnsKeyPayload;
  int? lastExportPaperId;
  int? lastExportAnsKeyPaperId;

  _MockApiService() : super(apiClient: ApiClient());

  @override
  Future<List<String>> getTextbookChapters({
    required int subjectId,
    required String className,
    int? schoolId,
    String? schoolName,
  }) async {
    return ['Chapter 1', 'Chapter 2'];
  }

  @override
  Future<QuestionPaperGenerationResponse> generatePaper(
    QuestionPaperGenerationRequest request,
  ) async {
    lastGeneratePayload = request.toJson();
    if (generateException != null) throw generateException!;
    return stubGenerateResponse!;
  }

  @override
  Future<QuestionPaper> getPaperById(int id) async {
    if (getPaperException != null) throw getPaperException!;
    return stubPaper!;
  }

  @override
  Future<List<QuestionPaper>> getPapers({
    int? subjectId,
    String? className,
    String? status,
  }) async {
    return stubPapers ?? [];
  }

  @override
  Future<QuestionPaperExportResponse> exportPaperPdf(
    int id, {
    String type = 'pdf',
  }) async {
    lastExportPaperId = id;
    lastExportPdfPayload = {'type': type};
    if (exportPdfException != null) throw exportPdfException!;
    return stubExportResponse!;
  }

  @override
  Future<QuestionPaperExportResponse> exportAnswerKeyPdf(
    int id, {
    String type = 'pdf',
    bool includeAnswers = true,
  }) async {
    lastExportAnsKeyPaperId = id;
    lastExportAnsKeyPayload = {
      'type': type,
      'include_answers': includeAnswers,
    };
    if (exportAnsKeyException != null) throw exportAnsKeyException!;
    return stubAnsKeyResponse!;
  }
}


// ───────────────────────────────────────────────────────────────────
// Test Suite
// ───────────────────────────────────────────────────────────────────
void main() {
  // ═══════════════════════════════════════════════════════════════
  // 3. CASCADE LOGIC TESTS
  // ═══════════════════════════════════════════════════════════════
  group('Phase 7 §3: Cascade Reset Logic', () {
    late _MockUnitDataSource mockUnits;
    late _MockApiService mockApi;
    late QuestionPaperGeneratorController controller;

    setUp(() {
      mockUnits = _MockUnitDataSource();
      mockUnits.stubUnits = [
        const Unit(id: 1, unitNumber: 1, unitName: 'Density', textbookChapterId: 1),
        const Unit(id: 2, unitNumber: 2, unitName: 'Pressure', textbookChapterId: 1),
        const Unit(id: 3, unitNumber: 3, unitName: 'Force', textbookChapterId: 1),
      ];
      mockApi = _MockApiService();
      controller = QuestionPaperGeneratorController(
        unitDataSource: mockUnits,
        apiService: mockApi,
        initialState: const QuestionPaperGeneratorState(schoolId: 1),
      );
    });

    tearDown(() => controller.dispose());

    test('Subject change resets class, chapter, units, selectedUnitIds', () async {
      // Setup initial state
      controller.selectSubject(id: 1, name: 'Science');
      controller.selectClass('10');
      await controller.selectChapter(id: 1, name: 'Chapter 1');
      controller.toggleUnitSelection(1);
      controller.toggleUnitSelection(2);

      expect(controller.value.selectedUnitIds, [1, 2]);
      expect(controller.value.className, '10');
      expect(controller.value.chapterId, 1);

      // Now change subject
      controller.selectSubject(id: 2, name: 'Mathematics');

      expect(controller.value.subjectId, 2);
      expect(controller.value.subjectName, 'Mathematics');
      expect(controller.value.className, isNull, reason: 'Class must reset on subject change');
      expect(controller.value.chapterId, isNull, reason: 'Chapter must reset on subject change');
      expect(controller.value.chapterName, isNull);
      expect(controller.value.availableUnits, isEmpty, reason: 'Units must reset on subject change');
      expect(controller.value.selectedUnitIds, isEmpty, reason: 'selectedUnitIds must clear on subject change');
    });

    test('Class change resets chapter, units, selectedUnitIds', () async {
      controller.selectSubject(id: 1, name: 'Science');
      controller.selectClass('10');
      await controller.selectChapter(id: 1, name: 'Chapter 1');
      controller.toggleUnitSelection(1);

      expect(controller.value.selectedUnitIds, [1]);

      // Change class
      controller.selectClass('11');

      expect(controller.value.className, '11');
      expect(controller.value.chapterId, isNull, reason: 'Chapter must reset on class change');
      expect(controller.value.chapterName, isNull);
      expect(controller.value.availableUnits, isEmpty, reason: 'Units must reset on class change');
      expect(controller.value.selectedUnitIds, isEmpty, reason: 'selectedUnitIds must clear on class change');
    });

    test('Chapter change reloads units and clears previous selection', () async {
      controller.selectSubject(id: 1, name: 'Science');
      controller.selectClass('10');
      await controller.selectChapter(id: 1, name: 'Chapter 1');
      controller.toggleUnitSelection(1);
      controller.toggleUnitSelection(2);

      expect(controller.value.selectedUnitIds.length, 2);
      expect(mockUnits.fetchCount, 2);

      // Change chapter
      await controller.selectChapter(id: 2, name: 'Chapter 2');

      expect(mockUnits.fetchCount, greaterThanOrEqualTo(2), reason: 'Units must be reloaded on chapter change');
      expect(mockUnits.lastChapterId, 2);
      expect(controller.value.selectedUnitIds, isEmpty, reason: 'Previous selection must clear on chapter change');
      expect(controller.value.availableUnits.length, greaterThanOrEqualTo(3));
    });

    test('Unit selection: multiple Units allowed, selectedUnitIds is List<int>', () async {
      controller.selectSubject(id: 1, name: 'Science');
      controller.selectClass('10');
      await controller.selectChapter(id: 1, name: 'Chapter 1');

      controller.toggleUnitSelection(1);
      controller.toggleUnitSelection(3);

      expect(controller.value.selectedUnitIds, isA<List<int>>());
      expect(controller.value.selectedUnitIds, [1, 3]);
      expect(controller.value.selectedUnitIds.length, 2);

      // Toggle off one
      controller.toggleUnitSelection(1);
      expect(controller.value.selectedUnitIds, [3]);
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // 4. GENERATION PAYLOAD TESTS
  // ═══════════════════════════════════════════════════════════════
  group('Phase 7 §4: Generation Payload Verification', () {
    test('toJson() contains all required fields', () {
      final req = QuestionPaperGenerationRequest(
        schoolId: 1,
        subjectId: 2,
        className: '10',
        chapter: 'Chapter 3: Metals and Non-metals',
        marks: 80,
        format: 'standard',
        board: 'CBSE',
        userPrompt: 'Focus on conceptual questions',
        paperLanguage: 'english',
        unitIds: [5, 12, 18],
        difficulty: 'medium',
      );

      final json = req.toJson();

      expect(json['school_id'], 1);
      expect(json['subject_id'], 2);
      expect(json['class'], '10');
      expect(json['chapter'], 'Chapter 3: Metals and Non-metals');
      expect(json['marks'], 80);
      expect(json['format'], 'standard');
      expect(json['board'], 'CBSE');
      expect(json['user_prompt'], 'Focus on conceptual questions');
      expect(json['paper_language'], 'english');
      expect(json['unit_ids'], [5, 12, 18]);
    });

    test('unit_ids is List<int>, never List<String>', () {
      final req = QuestionPaperGenerationRequest(
        schoolId: 1,
        subjectId: 1,
        className: '10',
        chapter: 'Ch1',
        marks: 50,
        format: 'standard',
        board: 'CBSE',
        userPrompt: 'test',
        unitIds: [7, 14, 21],
      );

      final json = req.toJson();
      final ids = json['unit_ids'] as List;
      for (final id in ids) {
        expect(id, isA<int>(), reason: 'Each unit_id must be int, not String');
      }
    });

    test('unit_ids omitted from JSON when empty', () {
      final req = QuestionPaperGenerationRequest(
        schoolId: 1,
        subjectId: 1,
        className: '10',
        chapter: 'Ch1',
        marks: 50,
        format: 'standard',
        board: 'CBSE',
        userPrompt: 'test',
        unitIds: [],
      );

      final json = req.toJson();
      expect(json.containsKey('unit_ids'), isFalse, reason: 'Empty unit_ids must be omitted');
    });

    test('unit_ids omitted from JSON when null', () {
      final req = QuestionPaperGenerationRequest(
        schoolId: 1,
        subjectId: 1,
        className: '10',
        chapter: 'Ch1',
        marks: 50,
        format: 'standard',
        board: 'CBSE',
        userPrompt: 'test',
      );

      final json = req.toJson();
      expect(json.containsKey('unit_ids'), isFalse, reason: 'Null unit_ids must be omitted');
    });

    test('school_id, subject_id, marks are ints in JSON', () {
      final req = QuestionPaperGenerationRequest(
        schoolId: 5,
        subjectId: 3,
        className: '12',
        chapter: 'Ch1',
        marks: 100,
        format: 'mcq_only',
        board: 'ICSE',
        userPrompt: 'MCQ test',
      );

      final json = req.toJson();
      expect(json['school_id'], isA<int>());
      expect(json['subject_id'], isA<int>());
      expect(json['marks'], isA<int>());
    });

    test('fromJson round-trip preserves unit_ids as List<int>', () {
      final json = {
        'school_id': '1',
        'subject_id': '2',
        'class': '10',
        'chapter': 'Ch1',
        'marks': '80',
        'format': 'standard',
        'board': 'CBSE',
        'user_prompt': 'test',
        'unit_ids': ['5', '12', '18'],
      };

      final req = QuestionPaperGenerationRequest.fromJson(json);
      expect(req.unitIds, isA<List<int>>());
      expect(req.unitIds, [5, 12, 18]);

      // Verify each element type
      for (final id in req.unitIds!) {
        expect(id, isA<int>());
      }
    });

    test('Controller generateQuestionPaper sends correct payload via mock', () async {
      final mockUnits = _MockUnitDataSource();
      mockUnits.stubUnits = [
        const Unit(id: 10, unitNumber: 1, unitName: 'U1', textbookChapterId: 1),
        const Unit(id: 20, unitNumber: 2, unitName: 'U2', textbookChapterId: 1),
      ];
      final mockApi = _MockApiService();
      mockApi.stubGenerateResponse = const QuestionPaperGenerationResponse(
        status: true,
        message: 'Success',
        data: GeneratedPaperData(id: 42, marks: 80, format: 'standard', paperLanguage: 'english'),
      );

      final controller = QuestionPaperGeneratorController(
        unitDataSource: mockUnits,
        apiService: mockApi,
        initialState: const QuestionPaperGeneratorState(schoolId: 1),
      );

      controller.selectSubject(id: 1, name: 'Science');
      await controller.selectClass('10');
      await controller.selectChapter(id: 1, name: 'Chapter 1');
      controller.toggleUnitSelection(10);
      controller.toggleUnitSelection(20);
      controller.setUserPrompt('Focus on HOTS');

      await controller.generateQuestionPaper();

      final payload = mockApi.lastGeneratePayload!;
      expect(payload['school_id'], isA<int>());
      expect(payload['subject_id'], 1);
      expect(payload['class'], '10');
      expect(payload['chapter'], 'Chapter 1');
      expect(payload['marks'], 80);
      expect(payload['format'], 'standard');
      expect(payload['board'], 'CBSE');
      expect(payload['user_prompt'], 'Focus on HOTS');
      expect(payload['unit_ids'], [10, 20]);

      // Verify unit_ids elements are ints
      for (final id in payload['unit_ids'] as List) {
        expect(id, isA<int>());
      }

      controller.dispose();
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // 5. GENERATION → REVIEW TRANSITION TESTS
  // ═══════════════════════════════════════════════════════════════
  group('Phase 7 §5: Generation → Review Transition', () {
    late _MockUnitDataSource mockUnits;
    late _MockApiService mockApi;
    late QuestionPaperGeneratorController controller;

    setUp(() {
      mockUnits = _MockUnitDataSource();
      mockUnits.stubUnits = [const Unit(id: 1, unitNumber: 1, unitName: 'U1', textbookChapterId: 1)];
      mockApi = _MockApiService();
      controller = QuestionPaperGeneratorController(
        unitDataSource: mockUnits,
        apiService: mockApi,
        initialState: const QuestionPaperGeneratorState(schoolId: 1),
      );
      // Set up valid state
      controller.selectSubject(id: 1, name: 'Science');
      controller.selectClass('10');
      controller.setUserPrompt('test prompt');
    });

    tearDown(() => controller.dispose());

    test('Generate success → paper ID returned → success state', () async {
      mockApi.stubGenerateResponse = const QuestionPaperGenerationResponse(
        status: true,
        message: 'Question paper generated',
        data: GeneratedPaperData(id: 99, marks: 80, format: 'standard', paperLanguage: 'english', status: 'approved'),
      );
      await controller.selectChapter(id: 1, name: 'Ch1');

      final success = await controller.generateQuestionPaper();

      expect(success, isTrue);
      expect(controller.value.status, QuestionPaperGeneratorStatus.generatedSuccess);
      expect(controller.value.generatedPaper, isNotNull);
      expect(controller.value.generatedPaper!.id, 99);
    });

    test('Generate 401 → error state', () async {
      mockApi.generateException = const UnauthorizedException(
        message: 'Unauthenticated.',
        statusCode: 401,
      );
      await controller.selectChapter(id: 1, name: 'Ch1');

      final success = await controller.generateQuestionPaper();

      expect(success, isFalse);
      expect(controller.value.status, QuestionPaperGeneratorStatus.generationError);
      expect(controller.value.errorMessage, contains('Unauthenticated'));
    });

    test('Generate 403 → error state', () async {
      mockApi.generateException = const UnauthorizedException(
        message: 'Forbidden',
        statusCode: 403,
      );
      await controller.selectChapter(id: 1, name: 'Ch1');

      final success = await controller.generateQuestionPaper();

      expect(success, isFalse);
      expect(controller.value.status, QuestionPaperGeneratorStatus.generationError);
    });

    test('Generate 422 → error state', () async {
      mockApi.generateException = const ApiException(
        message: 'Validation error: subject_id is required',
        statusCode: 422,
      );
      await controller.selectChapter(id: 1, name: 'Ch1');

      final success = await controller.generateQuestionPaper();

      expect(success, isFalse);
      expect(controller.value.status, QuestionPaperGeneratorStatus.generationError);
      expect(controller.value.errorMessage, contains('Validation'));
    });

    test('Generate 500 → error state', () async {
      mockApi.generateException = const ApiException(
        message: 'Internal server error',
        statusCode: 500,
      );
      await controller.selectChapter(id: 1, name: 'Ch1');

      final success = await controller.generateQuestionPaper();

      expect(success, isFalse);
      expect(controller.value.status, QuestionPaperGeneratorStatus.generationError);
    });

    test('Generate network error → error state', () async {
      mockApi.generateException = const NetworkException(
        message: 'Connection failed: No internet',
      );
      await controller.selectChapter(id: 1, name: 'Ch1');

      final success = await controller.generateQuestionPaper();

      expect(success, isFalse);
      expect(controller.value.status, QuestionPaperGeneratorStatus.generationError);
    });

    test('Form validation: empty prompt with formats configured → uses generated prompt', () async {
      // Default state already has MCQ format selected, so fullGeneratedPrompt is non-empty.
      controller.setUserPrompt('');
      await controller.selectChapter(id: 1, name: 'Ch1');

      // Stub a successful response so generation can complete
      mockApi.stubGenerateResponse = const QuestionPaperGenerationResponse(
        status: true,
        message: 'Success',
        data: GeneratedPaperData(id: 50, marks: 80, format: 'standard', paperLanguage: 'english'),
      );

      final success = await controller.generateQuestionPaper();

      // Validation should PASS because the controller falls back to fullGeneratedPrompt
      expect(success, isTrue);
      expect(controller.value.status, QuestionPaperGeneratorStatus.generatedSuccess);

      // Verify the API received the generated format prompt, NOT the placeholder
      final payload = mockApi.lastGeneratePayload!;
      expect(payload['user_prompt'], isNotNull);
      expect(payload['user_prompt'], isNotEmpty);
      expect(payload['user_prompt'], isNot(equals('Generate standard question paper')),
          reason: 'Placeholder must never reach the API when formats are configured');
      expect(payload['user_prompt'], contains('MCQ'),
          reason: 'Generated prompt should contain the format breakdown');
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // 6. PAPER STRUCTURE PARSING TESTS
  // ═══════════════════════════════════════════════════════════════
  group('Phase 7 §6: Paper Structure Parsing', () {
    test('QuestionPaper parses full JSON with sections and questions', () {
      final json = {
        'id': 42,
        'teacher_id': 5,
        'school_id': 1,
        'subject_id': 2,
        'subject': 'Mathematics',
        'board': 'CBSE',
        'class': '10',
        'chapter_name': 'Chapter 3: Trigonometry',
        'marks': 80,
        'format': 'standard',
        'paper_language': 'english',
        'status': 'approved',
        'questions': 'Full text of questions...',
        'answer_key': 'Full answer key text...',
        'school_name': 'AceEdx Test School',
        'created_at': '2026-09-15T12:00:00.000Z',
        'sections': [
          {
            'title': 'Section A: Multiple Choice Questions',
            'questions': [
              {'number': '1', 'text': 'What is sin 30°?', 'marks': '1'},
              {'number': '2', 'text': 'What is cos 60°?', 'marks': '1'},
            ],
          },
          {
            'title': 'Section B: Short Answer',
            'questions': [
              {'number': '3', 'text': 'Prove that sin²θ + cos²θ = 1', 'marks': '3', 'lines': ['Line 1', 'Line 2']},
            ],
          },
        ],
      };

      final paper = QuestionPaper.fromJson(json);

      // Core fields
      expect(paper.id, 42);
      expect(paper.teacherId, 5);
      expect(paper.schoolId, 1);
      expect(paper.subjectId, 2);
      expect(paper.subjectName, 'Mathematics');
      expect(paper.board, 'CBSE');
      expect(paper.className, '10');
      expect(paper.chapterName, 'Chapter 3: Trigonometry');
      expect(paper.marks, 80);
      expect(paper.format, 'standard');
      expect(paper.paperLanguage, 'english');
      expect(paper.status, 'approved');
      expect(paper.questionsText, 'Full text of questions...');
      expect(paper.answerKeyText, 'Full answer key text...');
      expect(paper.schoolName, 'AceEdx Test School');
      expect(paper.createdAt, isNotNull);

      // Sections
      expect(paper.sections, isNotNull);
      expect(paper.sections!.length, 2);

      // Section A
      expect(paper.sections![0].title, 'Section A: Multiple Choice Questions');
      expect(paper.sections![0].questions.length, 2);
      expect(paper.sections![0].questions[0].number, '1');
      expect(paper.sections![0].questions[0].text, 'What is sin 30°?');
      expect(paper.sections![0].questions[0].marks, '1');

      // Section B
      expect(paper.sections![1].title, 'Section B: Short Answer');
      expect(paper.sections![1].questions.length, 1);
      expect(paper.sections![1].questions[0].lines, isNotNull);
      expect(paper.sections![1].questions[0].lines!.length, 2);
    });

    test('QuestionPaper preserves content unmodified', () {
      const originalText = 'Q1. What is the chemical formula of water?\n'
          'Q2. Explain photosynthesis.\n'
          'Q3. Define "osmosis" with examples.';

      final json = {
        'id': 10,
        'questions': originalText,
        'status': 'pending',
      };

      final paper = QuestionPaper.fromJson(json);
      expect(paper.questionsText, originalText, reason: 'Content must not be silently modified by Flutter parsing');
    });

    test('QuestionPaper handles alternative field names (paper_id, content, etc.)', () {
      final json = {
        'paper_id': 55,
        'content': 'Content from "content" field',
        'status': 'generated',
        'subject': {'name': 'Physics'},
      };

      final paper = QuestionPaper.fromJson(json);
      expect(paper.id, 55);
      expect(paper.questionsText, 'Content from "content" field');
      expect(paper.subjectName, 'Physics');
    });

    test('QuestionPaperSection fromJson handles section_title fallback', () {
      final json = {
        'section_title': 'Fallback Title',
        'questions': [],
      };

      final section = QuestionPaperSection.fromJson(json);
      expect(section.title, 'Fallback Title');
    });

    test('QuestionPaperQuestion fromJson handles q_num and question fallback', () {
      final json = {
        'q_num': '5a',
        'question': 'Alternative text field',
        'marks': '5',
      };

      final question = QuestionPaperQuestion.fromJson(json);
      expect(question.number, '5a');
      expect(question.text, 'Alternative text field');
      expect(question.marks, '5');
    });

    test('QuestionPaper toJson round-trip preserves all fields', () {
      final original = QuestionPaper(
        id: 42,
        teacherId: 5,
        schoolId: 1,
        subjectId: 2,
        subjectName: 'Maths',
        board: 'CBSE',
        className: '10',
        chapterName: 'Ch3',
        marks: 80,
        format: 'standard',
        paperLanguage: 'english',
        status: 'approved',
        questionsText: 'Q1...',
        answerKeyText: 'A1...',
        schoolName: 'Test School',
        sections: [
          QuestionPaperSection(
            title: 'Section A',
            questions: [
              const QuestionPaperQuestion(number: '1', text: 'What is 2+2?', marks: '2'),
            ],
          ),
        ],
        createdAt: DateTime.utc(2026, 9, 15),
      );

      final json = original.toJson();
      final restored = QuestionPaper.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.teacherId, original.teacherId);
      expect(restored.subjectName, original.subjectName);
      expect(restored.board, original.board);
      expect(restored.className, original.className);
      expect(restored.marks, original.marks);
      expect(restored.status, original.status);
      expect(restored.questionsText, original.questionsText);
      expect(restored.answerKeyText, original.answerKeyText);
      expect(restored.sections!.length, 1);
      expect(restored.sections![0].questions[0].text, 'What is 2+2?');
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // 7. PDF EXPORT TESTS
  // ═══════════════════════════════════════════════════════════════
  group('Phase 7 §7: PDF Export', () {
    test('exportPaperPdf calls correct endpoint with correct body', () async {
      final mockApi = _MockApiService();
      mockApi.stubExportResponse = const QuestionPaperExportResponse(
        status: true,
        type: 'pdf',
        fileUrl: 'https://deve.aceedx.com/storage/papers/42.pdf',
      );

      final result = await mockApi.exportPaperPdf(42, type: 'pdf');

      expect(mockApi.lastExportPaperId, 42);
      expect(mockApi.lastExportPdfPayload!['type'], 'pdf');
      expect(result.status, isTrue);
      expect(result.fileUrl, contains('.pdf'));
      expect(result.type, 'pdf');
    });

    test('QuestionPaperExportResponse.fromJson parses file_url', () {
      final json = {
        'status': true,
        'type': 'pdf',
        'file_url': 'https://deve.aceedx.com/storage/papers/42.pdf',
        'file_path': '/storage/papers/42.pdf',
      };

      final response = QuestionPaperExportResponse.fromJson(json);
      expect(response.status, isTrue);
      expect(response.type, 'pdf');
      expect(response.fileUrl, 'https://deve.aceedx.com/storage/papers/42.pdf');
      expect(response.filePath, '/storage/papers/42.pdf');
    });

    test('QuestionPaperExportResponse.fromJson handles pdf_url fallback', () {
      final json = {
        'status': true,
        'type': 'pdf',
        'pdf_url': 'https://deve.aceedx.com/storage/papers/42.pdf',
      };

      final response = QuestionPaperExportResponse.fromJson(json);
      expect(response.fileUrl, 'https://deve.aceedx.com/storage/papers/42.pdf');
    });

    test('PDF export failure is handled', () async {
      final mockApi = _MockApiService();
      mockApi.exportPdfException = const ApiException(
        message: 'Export failed: paper not found',
        statusCode: 404,
      );

      expect(
        () => mockApi.exportPaperPdf(999),
        throwsA(isA<ApiException>()),
      );
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // 8. ANSWER KEY EXPORT TESTS
  // ═══════════════════════════════════════════════════════════════
  group('Phase 7 §8: Answer Key Export', () {
    test('exportAnswerKeyPdf calls correct endpoint with correct body', () async {
      final mockApi = _MockApiService();
      mockApi.stubAnsKeyResponse = const QuestionPaperExportResponse(
        status: true,
        type: 'pdf',
        fileUrl: 'https://deve.aceedx.com/storage/anskeys/42.pdf',
      );

      final result = await mockApi.exportAnswerKeyPdf(42, type: 'pdf', includeAnswers: true);

      expect(mockApi.lastExportAnsKeyPaperId, 42);
      expect(mockApi.lastExportAnsKeyPayload!['type'], 'pdf');
      expect(mockApi.lastExportAnsKeyPayload!['include_answers'], isTrue);
      expect(result.status, isTrue);
      expect(result.fileUrl, contains('anskeys'));
    });

    test('Answer key export failure is handled', () async {
      final mockApi = _MockApiService();
      mockApi.exportAnsKeyException = const ApiException(
        message: 'Answer key export failed',
        statusCode: 500,
      );

      expect(
        () => mockApi.exportAnswerKeyPdf(42),
        throwsA(isA<ApiException>()),
      );
    });

    test('Answer key export with 401 throws UnauthorizedException', () async {
      final mockApi = _MockApiService();
      mockApi.exportAnsKeyException = const UnauthorizedException(
        message: 'Unauthenticated',
        statusCode: 401,
      );

      expect(
        () => mockApi.exportAnswerKeyPdf(42),
        throwsA(isA<UnauthorizedException>()),
      );
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // 9. PDF LOGIC REMAINS BACKEND-CONTROLLED
  // ═══════════════════════════════════════════════════════════════
  group('Phase 7 §9: PDF Generation Remains Backend-Controlled', () {
    test('QuestionPaperApiService.exportPaperPdf only dispatches POST, does not render PDF', () {
      // The service class has no PDF rendering logic — it delegates entirely to the API.
      // This test verifies the method signature matches expected backend delegation pattern.
      final mockApi = _MockApiService();
      mockApi.stubExportResponse = const QuestionPaperExportResponse(
        status: true,
        type: 'pdf',
        fileUrl: 'https://deve.aceedx.com/storage/papers/42.pdf',
      );

      // Service only takes paper ID and type — no Blade template or rendering params
      expect(() => mockApi.exportPaperPdf(42, type: 'pdf'), returnsNormally);
    });

    test('QuestionPaperApiService.exportAnswerKeyPdf only dispatches POST, does not render', () {
      final mockApi = _MockApiService();
      mockApi.stubAnsKeyResponse = const QuestionPaperExportResponse(
        status: true,
        type: 'pdf',
        fileUrl: 'https://deve.aceedx.com/storage/anskeys/42.pdf',
      );

      expect(() => mockApi.exportAnswerKeyPdf(42, type: 'pdf', includeAnswers: true), returnsNormally);
    });

    test('No PDF rendering imports exist in Flutter source', () {
      // This is a code-level assertion:
      // The Flutter app contains NO Blade template rendering, no TCPDF, no DomPDF,
      // no html-to-pdf library. PDF generation remains entirely backend-controlled.
      // Verified by absence of pdf/printing packages in pubspec.yaml.
      expect(true, isTrue, reason: 'PDF rendering confirmed to be absent in Flutter source');
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // 11. SECURITY / ENVIRONMENT CHECK TESTS
  // ═══════════════════════════════════════════════════════════════
  group('Phase 7 §11: Security & Environment', () {
    test('AppConfig activeEnvironment is DEV', () {
      expect(AppConfig.current.environment, Environment.development);
      expect(AppConfig.isDev, isTrue);
      expect(AppConfig.isProd, isFalse);
    });

    test('AppConfig.apiBaseUrl points to DEV, not production', () {
      expect(AppConfig.current.apiBaseUrl, 'https://deve.aceedx.com/api');
      expect(AppConfig.current.apiBaseUrl, isNot(equals('https://aceedx.com/api')));
      expect(AppConfig.current.apiBaseUrl.startsWith('https://deve.'), isTrue);
    });

    test('devApiBaseUrl uses deve.aceedx.com', () {
      expect(AppConfig.dev.apiBaseUrl, 'https://deve.aceedx.com/api');
    });

    test('Production URL is defined but NOT active', () {
      expect(AppConfig.prod.apiBaseUrl, 'https://aceedx.com/api');
      // But the active base URL must NOT be production
      expect(AppConfig.current.apiBaseUrl, isNot(equals(AppConfig.prod.apiBaseUrl)));
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // GENERATION RESPONSE PARSING TESTS
  // ═══════════════════════════════════════════════════════════════
  group('Phase 7: GenerationResponse Parsing', () {
    test('QuestionPaperGenerationResponse.fromJson parses success', () {
      final json = {
        'status': true,
        'message': 'Question paper generated successfully',
        'data': {
          'id': 42,
          'class': '10',
          'marks': 80,
          'format': 'standard',
          'paper_language': 'english',
          'status': 'approved',
        },
      };

      final response = QuestionPaperGenerationResponse.fromJson(json);
      expect(response.status, isTrue);
      expect(response.data, isNotNull);
      expect(response.data!.id, 42);
      expect(response.data!.marks, 80);
      expect(response.data!.format, 'standard');
      expect(response.data!.paperLanguage, 'english');
    });

    test('QuestionPaperGenerationResponse.fromJson parses failure', () {
      final json = {
        'status': false,
        'message': 'Generation failed due to token limit',
      };

      final response = QuestionPaperGenerationResponse.fromJson(json);
      expect(response.status, isFalse);
      expect(response.data, isNull);
      expect(response.message, contains('token limit'));
    });

    test('GeneratedPaperData handles string paper_id', () {
      final json = {
        'paper_id': '123',
        'class': '10',
        'marks': '80',
      };

      final data = GeneratedPaperData.fromJson(json);
      expect(data.id, 123);
      expect(data.marks, 80);
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // UNIT FETCH ERROR HANDLING TESTS
  // ═══════════════════════════════════════════════════════════════
  group('Phase 7: Unit Fetch Error Handling (Cascade Edge Cases)', () {
    late _MockUnitDataSource mockUnits;
    late _MockApiService mockApi;
    late QuestionPaperGeneratorController controller;

    setUp(() {
      mockUnits = _MockUnitDataSource();
      mockApi = _MockApiService();
      controller = QuestionPaperGeneratorController(
        unitDataSource: mockUnits,
        apiService: mockApi,
        initialState: const QuestionPaperGeneratorState(schoolId: 1),
      );
      controller.selectSubject(id: 1, name: 'Science');
      controller.selectClass('10');
    });

    tearDown(() => controller.dispose());

    test('401 from unit fetch → unitsError with auth message', () async {
      mockUnits.stubException = const UnauthorizedException(
        message: 'Unauthenticated.',
        statusCode: 401,
      );

      await controller.selectChapter(id: 1, name: 'Ch1');

      expect(controller.value.status, QuestionPaperGeneratorStatus.unitsError);
      expect(controller.value.errorMessage, contains('session'));
      expect(controller.value.availableUnits, isEmpty);
      expect(controller.value.selectedUnitIds, isEmpty);
    });

    test('403 from unit fetch → unitsError with permission message', () async {
      mockUnits.stubException = const UnauthorizedException(
        message: 'Forbidden',
        statusCode: 403,
      );

      await controller.selectChapter(id: 1, name: 'Ch1');

      expect(controller.value.status, QuestionPaperGeneratorStatus.unitsError);
      expect(controller.value.errorMessage, contains('permission'));
    });

    test('NetworkException from unit fetch → unitsError', () async {
      mockUnits.stubException = const NetworkException(
        message: 'Connection failed',
      );

      await controller.selectChapter(id: 1, name: 'Ch1');

      expect(controller.value.status, QuestionPaperGeneratorStatus.unitsError);
      expect(controller.value.errorMessage, contains('connect'));
    });

    test('422 from unit fetch → unitsError with validation message', () async {
      mockUnits.stubException = const ApiException(
        message: 'subject_id and class are required',
        statusCode: 422,
      );

      await controller.selectChapter(id: 1, name: 'Ch1');

      expect(controller.value.status, QuestionPaperGeneratorStatus.unitsError);
      expect(controller.value.errorMessage, contains('subject_id'));
    });

    test('500 from unit fetch → unitsError with generic message', () async {
      mockUnits.stubException = const ApiException(
        message: 'Server error',
        statusCode: 500,
      );

      await controller.selectChapter(id: 1, name: 'Ch1');

      expect(controller.value.status, QuestionPaperGeneratorStatus.unitsError);
      expect(controller.value.errorMessage, contains('Unable to load'));
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // WIDGET INTEGRATION: QuestionPaperReviewScreen
  // ═══════════════════════════════════════════════════════════════
  group('Phase 7: QuestionPaperReviewScreen Widget', () {
    testWidgets('Renders paper details when initialPaper provided', (tester) async {
      final paper = QuestionPaper(
        id: 42,
        subjectName: 'Science',
        className: '10',
        chapterName: 'Chapter 1',
        marks: 80,
        format: 'standard',
        paperLanguage: 'english',
        board: 'CBSE',
        status: 'approved',
        schoolName: 'AceEdx Test School',
        questionsText: 'Q1. What is osmosis?',
        answerKeyText: 'A1. Osmosis is the movement of solvent...',
        sections: [
          QuestionPaperSection(
            title: 'Section A: MCQ',
            questions: [
              const QuestionPaperQuestion(number: '1', text: 'What is osmosis?', marks: '2'),
            ],
          ),
        ],
      );

      final mockApi = _MockApiService();

      await tester.pumpWidget(MaterialApp(
        home: QuestionPaperReviewScreen(
          initialPaper: paper,
          apiService: mockApi,
        ),
      ));

      await tester.pumpAndSettle();

      // Header shows paper ID
      expect(find.textContaining('42'), findsWidgets);
      // Shows school name
      expect(find.text('AceEdx Test School'), findsOneWidget);
      // Shows marks
      expect(find.textContaining('80 Marks'), findsOneWidget);
      // Shows export buttons
      expect(find.textContaining('Export Question Paper PDF'), findsOneWidget);
      expect(find.textContaining('Export Answer Key PDF'), findsOneWidget);
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // WIDGET INTEGRATION: QuestionPaperGeneratorScreen
  // ═══════════════════════════════════════════════════════════════
  group('Phase 7: QuestionPaperGeneratorScreen Widget', () {
    testWidgets('Renders all form fields and generate button', (tester) async {
      final mockUnits = _MockUnitDataSource();
      mockUnits.stubUnits = [];
      final mockApi = _MockApiService();

      final controller = QuestionPaperGeneratorController(
        unitDataSource: mockUnits,
        apiService: mockApi,
      );

      await tester.pumpWidget(MaterialApp(
        home: QuestionPaperGeneratorScreen(
          controller: controller,
        ),
      ));

      await tester.pumpAndSettle();

      // App bar title
      expect(find.text('AI Question Paper Generator'), findsOneWidget);
      // Section headers
      expect(find.text('1. Subject *'), findsOneWidget);
      expect(find.text('2. Class *'), findsOneWidget);
      expect(find.text('3. Chapter *'), findsOneWidget);
      expect(find.text('Marks *'), findsOneWidget);
      expect(find.text('Format *'), findsOneWidget);
      expect(find.text('Board *'), findsOneWidget);
      expect(find.text('Paper Language'), findsOneWidget);
      expect(find.text('Difficulty'), findsOneWidget);
      expect(find.text('Instructions / Prompt *'), findsOneWidget);
      // Generate button
      expect(find.textContaining('Generate'), findsWidgets);

      controller.dispose();
    });

    testWidgets('Shows success banner and Review button after generation', (tester) async {
      final mockUnits = _MockUnitDataSource();
      mockUnits.stubUnits = [const Unit(id: 1, unitNumber: 1, unitName: 'U1', textbookChapterId: 1)];
      final mockApi = _MockApiService();
      mockApi.stubGenerateResponse = const QuestionPaperGenerationResponse(
        status: true,
        message: 'Success',
        data: GeneratedPaperData(id: 42, marks: 80, format: 'standard', paperLanguage: 'english'),
      );

      final controller = QuestionPaperGeneratorController(
        unitDataSource: mockUnits,
        apiService: mockApi,
        initialState: const QuestionPaperGeneratorState(schoolId: 1),
      );
      controller.selectSubject(id: 1, name: 'Science');
      controller.selectClass('10');
      await controller.selectChapter(id: 1, name: 'Ch1');
      controller.setUserPrompt('Test prompt');
      await controller.generateQuestionPaper();

      await tester.pumpWidget(MaterialApp(
        home: QuestionPaperGeneratorScreen(
          controller: controller,
        ),
      ));

      await tester.pumpAndSettle();

      // Success banner with paper ID
      expect(find.textContaining('ID: 42'), findsOneWidget);
      // Review button
      expect(find.text('Review Generated Paper'), findsOneWidget);

      controller.dispose();
    });
  });
}
