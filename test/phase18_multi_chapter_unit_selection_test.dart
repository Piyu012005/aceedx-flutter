import 'package:flutter_test/flutter_test.dart';
import 'package:aceedx_flutter/core/network/api_client.dart';
import 'package:aceedx_flutter/models/unit.dart';
import 'package:aceedx_flutter/features/teacher/presentation/question_paper_generator/models/question_paper_generation_request.dart';
import 'package:aceedx_flutter/features/teacher/presentation/question_paper_generator/models/question_paper_generation_response.dart';
import 'package:aceedx_flutter/features/teacher/presentation/question_paper_generator/state/question_paper_generator_controller.dart';
import 'package:aceedx_flutter/features/teacher/presentation/question_paper_generator/data/unit_data_source.dart';
import 'package:aceedx_flutter/features/teacher/presentation/question_paper_generator/data/question_paper_api_service.dart';

class MockApiUnitSource implements UnitDataSource {
  final List<Unit> mockUnits;

  MockApiUnitSource(this.mockUnits);

  @override
  Future<List<Unit>> getUnitsByContext({
    required int chapterId,
    String? chapterName,
    int? textbookId,
    String? subject,
    String? className,
    int? schoolId,
  }) async {
    return mockUnits;
  }
}

class MockPaperService extends QuestionPaperApiService {
  QuestionPaperGenerationRequest? lastRequest;

  MockPaperService()
      : super(
          apiClient: ApiClient(),
        );

  @override
  Future<QuestionPaperGenerationResponse> generatePaper(QuestionPaperGenerationRequest request) async {
    lastRequest = request;
    return const QuestionPaperGenerationResponse(status: true, message: 'Success');
  }
}

void main() {
  group('Phase 18: Multi-Chapter & Unit Selection Tests', () {
    final unit178 = const Unit(
      id: 178,
      textbookId: 39,
      textbookChapterId: 115,
      unitNumber: '1.2',
      unitName: 'The Thiefs Story',
    );
    final unit179 = const Unit(
      id: 179,
      textbookId: 39,
      textbookChapterId: 115,
      unitNumber: '1.3',
      unitName: 'On Wings of Courage',
    );
    final unit184 = const Unit(
      id: 184,
      textbookId: 39,
      textbookChapterId: 116,
      unitNumber: '2.1',
      unitName: 'A Letter to God',
    );
    final unit185 = const Unit(
      id: 185,
      textbookId: 39,
      textbookChapterId: 116,
      unitNumber: '2.2',
      unitName: 'Nelson Mandela: Long Walk to Freedom',
    );

    late QuestionPaperGeneratorController controller;

    setUp(() {
      final unitSource = MockApiUnitSource([unit178, unit179, unit184, unit185]);
      final paperService = MockPaperService();
      controller = QuestionPaperGeneratorController(
        unitDataSource: unitSource,
        apiService: paperService,
      );
    });

    test('1. Real chapter groups are generated from textbook_chapter_id', () async {
      await controller.loadChapters(subjectId: 1, className: '10', schoolId: 87);
      final groups = controller.value.availableChapterGroups;

      expect(groups.length, 2);
      expect(groups[0].id, 115);
      expect(groups[1].id, 116);
      expect(groups[0].units.map((u) => u.id), [178, 179]);
      expect(groups[1].units.map((u) => u.id), [184, 185]);
    });

    test('2. No "Part 1", "Part 2" fake chapter labels are generated', () async {
      await controller.loadChapters(subjectId: 1, className: '10', schoolId: 87);
      final groups = controller.value.availableChapterGroups;

      for (final g in groups) {
        expect(g.displayName.contains('Part 1'), isFalse);
        expect(g.displayName.contains('Part 2'), isFalse);
      }
      expect(groups[0].displayName, 'Unit 1');
      expect(groups[1].displayName, 'Unit 2');
    });

    test('3. Multiple chapters can be selected', () async {
      await controller.loadChapters(subjectId: 1, className: '10', schoolId: 87);

      expect(controller.value.selectedChapterIds, containsAll([115, 116]));

      // Clear then select individually
      controller.clearChapterSelection();
      expect(controller.value.selectedChapterIds, isEmpty);

      controller.toggleChapterSelection(115);
      controller.toggleChapterSelection(116);

      expect(controller.value.selectedChapterIds.length, 2);
      expect(controller.value.selectedChapterIds, containsAll([115, 116]));
    });

    test('4. selectedChapterIds contains real textbook_chapter IDs', () async {
      await controller.loadChapters(subjectId: 1, className: '10', schoolId: 87);

      expect(controller.value.selectedChapterIds, isA<List<int>>());
      expect(controller.value.selectedChapterIds, equals([115, 116]));
    });

    test('5. Selecting Unit 1 (115) and Unit 2 (116) displays both groups', () async {
      await controller.loadChapters(subjectId: 1, className: '10', schoolId: 87);

      final selectedGroups = controller.value.selectedChapterGroups;
      expect(selectedGroups.length, 2);
      expect(selectedGroups.map((g) => g.id), containsAll([115, 116]));
    });

    test('6. Unit selections from Unit 1 remain when Unit 2 is selected', () async {
      await controller.loadChapters(subjectId: 1, className: '10', schoolId: 87);

      // Select unit 178 from group 115
      controller.toggleUnitSelection(178);
      expect(controller.value.selectedUnitIds, [178]);

      // Toggle chapter 116 (Unit 2) on/off
      controller.toggleChapterSelection(116);
      expect(controller.value.selectedUnitIds, contains(178));

      // Select unit 184 from group 116
      controller.toggleUnitSelection(184);
      expect(controller.value.selectedUnitIds, containsAll([178, 184]));
    });

    test('7. Clearing Unit 1 does not clear Unit 2 selections', () async {
      await controller.loadChapters(subjectId: 1, className: '10', schoolId: 87);

      // Select units from both groups
      controller.toggleUnitSelection(178);
      controller.toggleUnitSelection(184);
      expect(controller.value.selectedUnitIds, containsAll([178, 184]));

      // Clear Unit 1 group (115)
      final group115 = controller.value.availableChapterGroups.firstWhere((g) => g.id == 115);
      controller.clearUnitsForGroup(group115);

      expect(controller.value.selectedUnitIds.contains(178), isFalse);
      expect(controller.value.selectedUnitIds.contains(184), isTrue);
    });

    test('8. Select All works per chapter group', () async {
      await controller.loadChapters(subjectId: 1, className: '10', schoolId: 87);

      final group115 = controller.value.availableChapterGroups.firstWhere((g) => g.id == 115);
      controller.selectAllUnitsForGroup(group115);

      expect(controller.value.selectedUnitIds, containsAll([178, 179]));
      expect(controller.value.selectedUnitIds.contains(184), isFalse);
      expect(controller.value.selectedUnitIds.contains(185), isFalse);
    });

    test('9. Clear works per chapter group', () async {
      await controller.loadChapters(subjectId: 1, className: '10', schoolId: 87);
      controller.selectAllUnits();
      expect(controller.value.selectedUnitIds, containsAll([178, 179, 184, 185]));

      final group116 = controller.value.availableChapterGroups.firstWhere((g) => g.id == 116);
      controller.clearUnitsForGroup(group116);

      expect(controller.value.selectedUnitIds, containsAll([178, 179]));
      expect(controller.value.selectedUnitIds.contains(184), isFalse);
      expect(controller.value.selectedUnitIds.contains(185), isFalse);
    });

    test('10. Subject change clears chapters and units', () async {
      await controller.loadChapters(subjectId: 1, className: '10', schoolId: 87);
      controller.selectAllUnits();
      expect(controller.value.selectedUnitIds.isNotEmpty, isTrue);

      controller.selectSubject(id: 2, name: 'Mathematics');

      expect(controller.value.availableChapterGroups, isEmpty);
      expect(controller.value.selectedChapterIds, isEmpty);
      expect(controller.value.availableUnits, isEmpty);
      expect(controller.value.selectedUnitIds, isEmpty);
    });

    test('11. Class change clears chapters and units', () async {
      controller.selectSubject(id: 1, name: 'Science');
      await controller.loadChapters(subjectId: 1, className: '10', schoolId: 87);
      controller.selectAllUnits();
      expect(controller.value.selectedUnitIds.isNotEmpty, isTrue);

      await controller.selectClass('9');

      expect(controller.value.selectedUnitIds, isEmpty);
      expect(controller.value.availableChapterGroups.length, 2);
    });

    test('12. selectedUnitIds remains List<int>', () async {
      await controller.loadChapters(subjectId: 1, className: '10', schoolId: 87);
      controller.toggleUnitSelection(178);
      controller.toggleUnitSelection(184);

      expect(controller.value.selectedUnitIds, isA<List<int>>());
      expect(controller.value.selectedUnitIds, [178, 184]);
    });

    test('13. Generation payload contains selected real unit IDs across all selected groups', () async {
      await controller.loadChapters(subjectId: 1, className: '10', schoolId: 87);
      controller.toggleUnitSelection(178);
      controller.toggleUnitSelection(185);

      final req = QuestionPaperGenerationRequest(
        schoolId: 87,
        subjectId: 1,
        className: '10',
        chapter: '115',
        marks: 80,
        format: 'MCQ',
        board: 'CBSE',
        userPrompt: 'Test Prompt',
        unitIds: controller.value.selectedUnitIds,
      );

      final json = req.toJson();
      expect(json['unit_ids'], isA<List<int>>());
      expect(json['unit_ids'], equals([178, 185]));
    });

    test('14. No hardcoded chapter/unit/school/textbook IDs', () async {
      await controller.loadChapters(subjectId: 1, className: '10', schoolId: 87);
      final groups = controller.value.availableChapterGroups;

      expect(groups[0].id, 115);
      expect(groups[1].id, 116);
      expect(groups[0].units.first.id, 178);
      expect(groups[1].units.first.id, 184);
    });
  });
}
