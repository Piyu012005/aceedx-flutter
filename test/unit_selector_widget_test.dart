import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aceedx_flutter/models/unit.dart';
import 'package:aceedx_flutter/core/network/api_client.dart';
import 'package:aceedx_flutter/features/teacher/presentation/question_paper_generator/data/question_paper_api_service.dart';
import 'package:aceedx_flutter/features/teacher/presentation/question_paper_generator/state/question_paper_generator_controller.dart';
import 'package:aceedx_flutter/features/teacher/presentation/question_paper_generator/state/question_paper_generator_state.dart';
import 'package:aceedx_flutter/features/teacher/presentation/question_paper_generator/widgets/unit_selector.dart';
import 'package:aceedx_flutter/features/teacher/presentation/question_paper_generator/question_paper_generator_screen.dart';
import 'package:aceedx_flutter/features/teacher/presentation/question_paper_generator/data/unit_data_source.dart';
import 'package:aceedx_flutter/features/teacher/presentation/question_paper_generator/models/chapter_group.dart';

void main() {
  group('UnitSelector Widget Tests', () {
    final mockGroup = ChapterGroup(
      id: 115,
      displayName: 'Unit 1',
      units: const [
        Unit(id: 101, unitNumber: '1.1', unitName: 'Chemical Equations'),
        Unit(id: 102, unitNumber: '1.2', unitName: 'Reaction Types'),
      ],
    );

    testWidgets('Renders units and toggles selection on click', (tester) async {
      Unit? toggledUnit;
      final selectedIds = <int>{101};

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: UnitSelector(
                selectedChapterGroups: [mockGroup],
                selectedUnitIds: selectedIds,
                onToggleUnit: (unit) => toggledUnit = unit,
                onSelectAllGroupUnits: (_) {},
                onClearGroupUnits: (_) {},
                onToggleGroupExpanded: (_) {},
              ),
            ),
          ),
        ),
      );

      // Verify unit labels appear
      expect(find.text('Chapter 1.1 \u2014 Chemical Equations'), findsOneWidget);
      expect(find.text('Chapter 1.2 \u2014 Reaction Types'), findsOneWidget);
      expect(find.text('Unit 1 (1 selected)'), findsOneWidget);

      // Tap on the second unit
      await tester.tap(find.text('Chapter 1.2 \u2014 Reaction Types'));
      await tester.pump();

      expect(toggledUnit?.id, 102);
    });

    testWidgets('Displays graceful message when unit list is empty', (tester) async {
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

      expect(find.text('Select one or more chapters above to view and select subtopic units.'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('Displays loading indicator when isLoading is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UnitSelector(
              selectedChapterGroups: const [],
              selectedUnitIds: const {},
              isLoading: true,
              onToggleUnit: (_) {},
              onSelectAllGroupUnits: (_) {},
              onClearGroupUnits: (_) {},
              onToggleGroupExpanded: (_) {},
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading units for selected chapters…'), findsOneWidget);
    });
  });

  group('QuestionPaperGeneratorScreen Integration Tests', () {
    testWidgets('Loads chapters and displays units for selected chapters', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final controller = QuestionPaperGeneratorController(
        unitDataSource: const MockUnitDataSource(simulatedDelay: Duration.zero),
        apiService: QuestionPaperApiService(apiClient: ApiClient()),
        initialState: const QuestionPaperGeneratorState(
          subjectId: 1,
          subjectName: 'Science',
          className: '10',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: QuestionPaperGeneratorScreen(
            controller: controller,
            unitDataSource: const MockUnitDataSource(simulatedDelay: Duration.zero),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify screen renders
      expect(find.text('AI Question Paper Generator'), findsOneWidget);
    });
  });
}
