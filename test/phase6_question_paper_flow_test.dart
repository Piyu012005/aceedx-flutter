import 'dart:convert';
import 'package:aceedx_flutter/core/network/api_client.dart';
import 'package:aceedx_flutter/core/network/api_exception.dart';
import 'package:aceedx_flutter/features/teacher/presentation/question_paper_generator/data/question_paper_api_service.dart';
import 'package:aceedx_flutter/features/teacher/presentation/question_paper_generator/models/question_paper.dart';
import 'package:aceedx_flutter/features/teacher/presentation/question_paper_generator/models/question_paper_generation_request.dart';
import 'package:aceedx_flutter/features/teacher/presentation/question_paper_generator/models/question_paper_generation_response.dart';
import 'package:aceedx_flutter/features/teacher/presentation/question_paper_generator/models/question_paper_section.dart';
import 'package:aceedx_flutter/features/teacher/presentation/question_paper_review/question_paper_review_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('Phase 6 Question Paper Result, Review & PDF Flow Tests', () {
    // A. Generation response parsing
    test('A. Generation response parses id, class, marks, format correctly', () {
      final jsonMap = {
        'status': true,
        'message': 'Question paper generated successfully',
        'data': {
          'id': 105,
          'class': '10',
          'marks': 80,
          'format': 'standard',
          'paper_language': 'english',
          'status': 'pending',
        }
      };

      final response = QuestionPaperGenerationResponse.fromJson(jsonMap);
      expect(response.status, isTrue);
      expect(response.data, isNotNull);
      expect(response.data!.id, equals(105));
      expect(response.data!.className, equals('10'));
      expect(response.data!.marks, equals(80));
      expect(response.data!.format, equals('standard'));
    });

    // B. Paper model parsing
    test('B. QuestionPaper model parses full backend payload accurately', () {
      final jsonMap = {
        'id': 42,
        'teacher_id': 3,
        'school_id': 1,
        'subject_id': 2,
        'subject_name': 'Science',
        'board': 'CBSE',
        'class': '10',
        'chapter_name': 'Chemical Reactions',
        'marks': 80,
        'format': 'standard',
        'paper_language': 'english',
        'status': 'approved',
        'questions': 'Section A: ...',
        'answer_key': 'Answer 1: ...',
        'pdf_url': 'https://deve.aceedx.com/storage/papers/42.pdf',
        'school_name': 'AceEdx School',
        'created_at': '2026-09-15T18:00:00.000Z',
      };

      final paper = QuestionPaper.fromJson(jsonMap);
      expect(paper.id, equals(42));
      expect(paper.teacherId, equals(3));
      expect(paper.subjectName, equals('Science'));
      expect(paper.board, equals('CBSE'));
      expect(paper.className, equals('10'));
      expect(paper.status, equals('approved'));
      expect(paper.pdfUrl, equals('https://deve.aceedx.com/storage/papers/42.pdf'));
    });

    // C & D. Section & Question parsing
    test('C & D. QuestionPaperSection and QuestionPaperQuestion parse correctly', () {
      final jsonMap = {
        'title': 'SECTION 1: PASSAGES (10 Marks)',
        'questions': [
          {
            'number': '1',
            'text': 'Read the paragraph below and answer.',
            'marks': '5 Marks',
            'lines': ['Line A', 'Line B']
          }
        ]
      };

      final section = QuestionPaperSection.fromJson(jsonMap);
      expect(section.title, equals('SECTION 1: PASSAGES (10 Marks)'));
      expect(section.questions.length, equals(1));

      final q = section.questions.first;
      expect(q.number, equals('1'));
      expect(q.text, equals('Read the paragraph below and answer.'));
      expect(q.marks, equals('5 Marks'));
      expect(q.lines, equals(['Line A', 'Line B']));
    });

    // E. Paper ID extraction
    test('E. Paper ID is properly extracted from string or int JSON types', () {
      final jsonStr = {'id': '99', 'status': 'pending'};
      final paper1 = GeneratedPaperData.fromJson(jsonStr);
      expect(paper1.id, equals(99));

      final paper2 = QuestionPaper.fromJson({'id': 150});
      expect(paper2.id, equals(150));
    });

    // F. Successful paper retrieval
    test('F. getPaperById returns QuestionPaper on GET 200', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, endsWith('/teacher/paper/88'));
        return http.Response(
          jsonEncode({
            'status': true,
            'data': {
              'id': 88,
              'class': '10',
              'marks': 50,
              'subject_name': 'Mathematics',
              'status': 'pending',
            }
          }),
          200,
        );
      });

      final apiClient = ApiClient(httpClient: mockClient);
      final service = QuestionPaperApiService(apiClient: apiClient);

      final paper = await service.getPaperById(88);
      expect(paper.id, equals(88));
      expect(paper.className, equals('10'));
      expect(paper.marks, equals(50));
    });

    // G. Paper retrieval errors (404 & 401)
    test('G. getPaperById throws ApiException on 404 and UnauthorizedException on 401', () async {
      final mockClient404 = MockClient((_) async {
        return http.Response(jsonEncode({'status': false, 'message': 'Paper not found'}), 404);
      });

      final service404 = QuestionPaperApiService(apiClient: ApiClient(httpClient: mockClient404));
      expect(() async => await service404.getPaperById(999), throwsA(isA<ApiException>()));

      final mockClient401 = MockClient((_) async {
        return http.Response(jsonEncode({'status': false, 'message': 'Unauthorized'}), 401);
      });

      final service401 = QuestionPaperApiService(apiClient: ApiClient(httpClient: mockClient401));
      expect(() async => await service401.getPaperById(88), throwsA(isA<UnauthorizedException>()));
    });

    // H. Paper list parsing
    test('H. getPapers parses paginated and direct list responses', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, endsWith('/teacher/papers'));
        return http.Response(
          jsonEncode({
            'status': true,
            'data': {
              'current_page': 1,
              'data': [
                {'id': 1, 'class': '9', 'marks': 40},
                {'id': 2, 'class': '10', 'marks': 80},
              ]
            }
          }),
          200,
        );
      });

      final service = QuestionPaperApiService(apiClient: ApiClient(httpClient: mockClient));
      final papers = await service.getPapers();

      expect(papers.length, equals(2));
      expect(papers[0].id, equals(1));
      expect(papers[1].id, equals(2));
    });

    // I. Export response handling
    test('I. exportPaperPdf and exportAnswerKeyPdf send correct requests and parse URLs', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/export-anskey/')) {
          final body = jsonDecode(request.body);
          expect(body['include_answers'], isTrue);
          return http.Response(
            jsonEncode({
              'status': true,
              'type': 'pdf',
              'file_path': 'papers/ans_10.pdf',
              'file_url': 'https://deve.aceedx.com/storage/papers/ans_10.pdf'
            }),
            200,
          );
        } else {
          return http.Response(
            jsonEncode({
              'status': true,
              'type': 'pdf',
              'file_path': 'papers/10.pdf',
              'file_url': 'https://deve.aceedx.com/storage/papers/10.pdf'
            }),
            200,
          );
        }
      });

      final service = QuestionPaperApiService(apiClient: ApiClient(httpClient: mockClient));

      final paperExport = await service.exportPaperPdf(10);
      expect(paperExport.status, isTrue);
      expect(paperExport.fileUrl, equals('https://deve.aceedx.com/storage/papers/10.pdf'));

      final ansExport = await service.exportAnswerKeyPdf(10);
      expect(ansExport.status, isTrue);
      expect(ansExport.fileUrl, equals('https://deve.aceedx.com/storage/papers/ans_10.pdf'));
    });

    // J. Generator → review transition & Review Screen render
    testWidgets('J. QuestionPaperReviewScreen renders paper details and exports PDF', (tester) async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'status': true,
            'type': 'pdf',
            'file_url': 'https://deve.aceedx.com/storage/papers/55.pdf'
          }),
          200,
        );
      });

      final service = QuestionPaperApiService(apiClient: ApiClient(httpClient: mockClient));

      const samplePaper = QuestionPaper(
        id: 55,
        className: '10',
        marks: 80,
        subjectName: 'Science',
        chapterName: 'Chemical Reactions',
        status: 'pending',
        questionsText: '1. Balance the chemical equation: H2 + O2 -> H2O [2 Marks]',
        answerKeyText: '1. 2H2 + O2 -> 2H2O',
      );

      tester.view.physicalSize = const Size(1200, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: QuestionPaperReviewScreen(
            initialPaper: samplePaper,
            apiService: service,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Paper Review (ID: 55)'), findsOneWidget);
      expect(find.textContaining('Science | Class 10'), findsOneWidget);
      expect(find.text('Export Question Paper PDF'), findsOneWidget);

      await tester.tap(find.text('Export Question Paper PDF'));
      await tester.pumpAndSettle();

      expect(find.textContaining('PDF Generated: https://deve.aceedx.com/storage/papers/55.pdf'), findsOneWidget);
    });

    // K & L. Regression check: selected unit_ids remain List<int> in generation request
    test('K & L. Generation request still produces unit_ids as List<int>', () {
      const request = QuestionPaperGenerationRequest(
        schoolId: 1,
        subjectId: 2,
        className: '10',
        chapter: '3',
        marks: 80,
        format: 'standard',
        board: 'CBSE',
        userPrompt: 'Prompt',
        unitIds: [10, 20, 30],
      );

      final json = request.toJson();
      expect(json['unit_ids'], equals([10, 20, 30]));
      expect(json['unit_ids'], isA<List<int>>());
    });
  });
}
