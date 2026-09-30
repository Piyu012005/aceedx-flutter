import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aceedx_flutter/features/teacher/presentation/question_paper_generator/widgets/question_format_selector.dart';
import 'package:aceedx_flutter/features/teacher/presentation/question_paper_generator/state/question_paper_generator_controller.dart';
import 'package:aceedx_flutter/features/teacher/presentation/question_paper_generator/state/question_paper_generator_state.dart';
import 'package:aceedx_flutter/features/teacher/presentation/question_paper_generator/data/unit_data_source.dart';
import 'package:aceedx_flutter/features/teacher/presentation/question_paper_generator/data/question_paper_api_service.dart';
import 'package:aceedx_flutter/core/network/api_client.dart';
import 'package:aceedx_flutter/models/unit.dart';
import 'package:aceedx_flutter/features/teacher/presentation/question_paper_generator/models/question_paper_generation_request.dart';
import 'package:aceedx_flutter/features/teacher/presentation/question_paper_generator/models/question_paper_generation_response.dart';

class MockUnitDataSource implements UnitDataSource {
  @override
  Future<List<Unit>> getUnitsByContext({
    required int chapterId,
    String? chapterName,
    int? textbookId,
    String? subject,
    String? className,
    int? schoolId,
  }) async {
    return [];
  }
}

class MockQuestionPaperApiService extends QuestionPaperApiService {
  QuestionPaperGenerationRequest? lastRequest;

  MockQuestionPaperApiService() : super(apiClient: ApiClient());

  @override
  Future<QuestionPaperGenerationResponse> generatePaper(
    QuestionPaperGenerationRequest request,
  ) async {
    lastRequest = request;
    return QuestionPaperGenerationResponse(
      status: true,
      message: 'Success',
      data: const GeneratedPaperData(id: 1),
    );
  }
}

void main() {
  group('QuestionFormatSelector Visual Selection Tests', () {
    late QuestionPaperGeneratorController controller;
    late MockQuestionPaperApiService mockApiService;

    setUp(() {
      mockApiService = MockQuestionPaperApiService();
      controller = QuestionPaperGeneratorController(
        unitDataSource: MockUnitDataSource(),
        apiService: mockApiService,
      );
    });

    Widget buildTestableWidget() {
      return MaterialApp(
        home: Scaffold(
          body: ValueListenableBuilder<QuestionPaperGeneratorState>(
            valueListenable: controller,
            builder: (context, state, _) {
              return QuestionFormatSelector(
                selectedFormats: state.selectedFormats,
                onToggleFormat: controller.toggleFormat,
              );
            },
          ),
        ),
      );
    }

    testWidgets('A. Initially selected format displays checked in modal', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget());

      // Open modal
      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();

      // Check modal header selected count
      expect(find.text('1 selected'), findsOneWidget);

      // Verify MCQ checkbox is checked (true)
      final mcqTile = find.widgetWithText(ListTile, 'MCQ');
      expect(mcqTile, findsOneWidget);
      final mcqCheckbox = tester.widget<Checkbox>(
        find.descendant(of: mcqTile, matching: find.byType(Checkbox)),
      );
      expect(mcqCheckbox.value, isTrue);

      // Verify True / False checkbox is unchecked (false)
      final tfTile = find.widgetWithText(ListTile, 'True / False');
      expect(tfTile, findsOneWidget);
      final tfCheckbox = tester.widget<Checkbox>(
        find.descendant(of: tfTile, matching: find.byType(Checkbox)),
      );
      expect(tfCheckbox.value, isFalse);
    });

    testWidgets('B. Selecting a second format displays its checkbox as checked', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget());

      // Open modal
      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();

      // Tap "True / False"
      final tfTile = find.widgetWithText(ListTile, 'True / False');
      await tester.tap(tfTile);
      await tester.pumpAndSettle();

      // Verify True / False checkbox is now checked
      final tfCheckbox = tester.widget<Checkbox>(
        find.descendant(of: tfTile, matching: find.byType(Checkbox)),
      );
      expect(tfCheckbox.value, isTrue);

      // Verify header updated count
      expect(find.text('2 selected'), findsOneWidget);

      // Verify controller state updated
      expect(controller.value.selectedFormats, containsAll(['MCQ', 'True / False']));
    });

    testWidgets('C. Multiple selected formats all display checked', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget());

      // Open modal
      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();

      // Tap "True / False" and "Match the following"
      await tester.tap(find.widgetWithText(ListTile, 'True / False'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ListTile, 'Match the following'));
      await tester.pumpAndSettle();

      // Verify all 3 checkboxes are checked visually
      final mcqCheckbox = tester.widget<Checkbox>(
        find.descendant(of: find.widgetWithText(ListTile, 'MCQ'), matching: find.byType(Checkbox)),
      );
      final tfCheckbox = tester.widget<Checkbox>(
        find.descendant(of: find.widgetWithText(ListTile, 'True / False'), matching: find.byType(Checkbox)),
      );
      final matchCheckbox = tester.widget<Checkbox>(
        find.descendant(of: find.widgetWithText(ListTile, 'Match the following'), matching: find.byType(Checkbox)),
      );

      expect(mcqCheckbox.value, isTrue);
      expect(tfCheckbox.value, isTrue);
      expect(matchCheckbox.value, isTrue);

      expect(find.text('3 selected'), findsOneWidget);
    });

    testWidgets('D. Deselecting a format removes its visual check', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget());

      // Open modal
      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();

      // Select True / False
      await tester.tap(find.widgetWithText(ListTile, 'True / False'));
      await tester.pumpAndSettle();

      expect(controller.value.selectedFormats, contains('True / False'));

      // Deselect True / False
      await tester.tap(find.widgetWithText(ListTile, 'True / False'));
      await tester.pumpAndSettle();

      final tfCheckbox = tester.widget<Checkbox>(
        find.descendant(of: find.widgetWithText(ListTile, 'True / False'), matching: find.byType(Checkbox)),
      );

      expect(tfCheckbox.value, isFalse);
      expect(controller.value.selectedFormats.contains('True / False'), isFalse);
    });

    testWidgets('E. Selected count matches selected formats', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget());

      // Open modal
      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();

      expect(find.text('1 selected'), findsOneWidget);

      await tester.tap(find.widgetWithText(ListTile, 'True / False'));
      await tester.pumpAndSettle();
      expect(find.text('2 selected'), findsOneWidget);

      await tester.tap(find.widgetWithText(ListTile, 'Fill in the blanks'));
      await tester.pumpAndSettle();
      expect(find.text('3 selected'), findsOneWidget);

      await tester.tap(find.widgetWithText(ListTile, 'True / False'));
      await tester.pumpAndSettle();
      expect(find.text('2 selected'), findsOneWidget);

      expect(controller.value.selectedFormats.length, equals(2));
    });

    testWidgets('F. Existing generation payload still contains all selected formats', (WidgetTester tester) async {
      controller.setSchoolId(1);
      controller.selectSubject(id: 1, name: 'Science');
      controller.selectClass('10');
      await controller.selectChapter(id: 1, name: 'Chemical Reactions');
      controller.toggleFormat('True / False');
      controller.toggleFormat('Match the following');

      expect(controller.value.selectedFormats, containsAll(['MCQ', 'True / False', 'Match the following']));

      final promptPreview = controller.value.computedPromptPreview;
      expect(promptPreview, contains('MCQ | Questions: 1 | Marks each: 1'));
      expect(promptPreview, contains('True / False | Questions: 5 | Marks each: 1'));
      expect(promptPreview, contains('Match the following | Questions: 1 | Marks each: 4'));

      final success = await controller.generateQuestionPaper();
      expect(success, isTrue);

      expect(mockApiService.lastRequest, isNotNull);
      expect(mockApiService.lastRequest!.userPrompt, contains('MCQ | Questions: 1 | Marks each: 1'));
      expect(mockApiService.lastRequest!.userPrompt, contains('True / False | Questions: 5 | Marks each: 1'));
      expect(mockApiService.lastRequest!.userPrompt, contains('Match the following | Questions: 1 | Marks each: 4'));
    });
  });
}
