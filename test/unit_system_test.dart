import 'package:flutter_test/flutter_test.dart';
import 'package:aceedx_flutter/models/unit.dart';
import 'package:aceedx_flutter/features/teacher/presentation/question_paper_generator/data/unit_data_source.dart';
import 'package:aceedx_flutter/features/teacher/presentation/question_paper_generator/state/unit_selection_state.dart';

void main() {
  group('Unit Model Tests', () {
    test('A. Unit.fromJson() parses standard Laravel JSON structure', () {
      final json = {
        'id': 101,
        'textbook_id': 10,
        'textbook_chapter_id': 1,
        'unit_number': 1,
        'unit_name': 'Chemical Reactions and Balancing',
        'start_chunk_index': 0,
        'end_chunk_index': 45,
        'detection_method': 'deterministic',
        'sort_order': 1,
      };

      final unit = Unit.fromJson(json);

      expect(unit.id, 101);
      expect(unit.textbookId, 10);
      expect(unit.textbookChapterId, 1);
      expect(unit.unitNumber, 1);
      expect(unit.unitName, 'Chemical Reactions and Balancing');
      expect(unit.startChunkIndex, 0);
      expect(unit.endChunkIndex, 45);
      expect(unit.detectionMethod, 'deterministic');
      expect(unit.sortOrder, 1);
      expect(unit.displayLabel, 'Unit 1 – Chemical Reactions and Balancing');
    });

    test('B. Unit.toJson() serializes model fields accurately', () {
      const unit = Unit(
        id: 201,
        textbookId: 10,
        textbookChapterId: 2,
        unitNumber: 1,
        unitName: 'Properties of Acids and Bases',
        startChunkIndex: 131,
        endChunkIndex: 190,
        detectionMethod: 'deterministic',
        sortOrder: 1,
      );

      final json = unit.toJson();

      expect(json['id'], 201);
      expect(json['textbook_id'], 10);
      expect(json['textbook_chapter_id'], 2);
      expect(json['unit_number'], 1);
      expect(json['unit_name'], 'Properties of Acids and Bases');
      expect(json['start_chunk_index'], 131);
      expect(json['end_chunk_index'], 190);
      expect(json['detection_method'], 'deterministic');
      expect(json['sort_order'], 1);
    });

    test('C. Unit numeric ID handling (parses string and integer IDs safely)', () {
      final jsonWithStringId = {
        'id': '301',
        'textbook_chapter_id': '3',
        'unit_number': '2',
        'unit_name': 'Reactivity Series',
      };

      final unit = Unit.fromJson(jsonWithStringId);

      expect(unit.id, isA<int>());
      expect(unit.id, 301);
      expect(unit.textbookChapterId, 3);
      expect(unit.unitNumber, 2);
    });
  });

  group('UnitSelectionState Tests', () {
    late Unit unit1;
    late Unit unit2;
    late Unit unit3;
    late UnitSelectionState state;

    setUp(() {
      unit1 = const Unit(id: 101, unitNumber: 1, unitName: 'Unit 1');
      unit2 = const Unit(id: 102, unitNumber: 2, unitName: 'Unit 2');
      unit3 = const Unit(id: 103, unitNumber: 3, unitName: 'Unit 3');
      state = UnitSelectionState(initialUnits: [unit1, unit2, unit3]);
    });

    test('D. Selecting one Unit updates selected state and count', () {
      expect(state.isSelected(101), isFalse);
      expect(state.hasSelection, isFalse);

      state.toggle(unit1);

      expect(state.isSelected(101), isTrue);
      expect(state.hasSelection, isTrue);
      expect(state.selectedCount, 1);
      expect(state.selectedUnitIds, [101]);
    });

    test('E. Selecting multiple Units keeps both selected simultaneously', () {
      state.toggle(unit1);
      state.toggle(unit3);

      expect(state.isSelected(101), isTrue);
      expect(state.isSelected(102), isFalse);
      expect(state.isSelected(103), isTrue);
      expect(state.selectedCount, 2);
      expect(state.selectedUnitIds, [101, 103]);
    });

    test('F. Unselecting one Unit leaves other selected units intact', () {
      state.toggle(unit1);
      state.toggle(unit2);
      state.toggle(unit3);
      expect(state.selectedCount, 3);

      // Unselect unit2
      state.toggle(unit2);

      expect(state.isSelected(101), isTrue);
      expect(state.isSelected(102), isFalse);
      expect(state.isSelected(103), isTrue);
      expect(state.selectedCount, 2);
      expect(state.selectedUnitIds, [101, 103]);
    });

    test('G. clear() removes all selected units', () {
      state.selectAll();
      expect(state.selectedCount, 3);

      state.clear();

      expect(state.selectedCount, 0);
      expect(state.hasSelection, isFalse);
      expect(state.selectedUnitIds, isEmpty);
      expect(state.selectedUnits, isEmpty);
    });

    test('H. selectedUnitIds returns integer list and Set<int>', () {
      state.toggle(unit3);
      state.toggle(unit1);

      expect(state.selectedUnitIds, isA<List<int>>());
      expect(state.selectedUnitIds, [101, 103]);
      expect(state.selectedUnitIdsSet, isA<Set<int>>());
      expect(state.selectedUnitIdsSet.contains(101), isTrue);
      expect(state.selectedUnitIdsSet.contains(103), isTrue);
    });

    test('I. selectedUnits returns matching Unit model instances', () {
      state.toggle(unit2);
      state.toggle(unit3);

      final selected = state.selectedUnits;
      expect(selected.length, 2);
      expect(selected, contains(unit2));
      expect(selected, contains(unit3));
      expect(selected, isNot(contains(unit1)));
    });

    test('J. Changing chapter via setUnits() resets previous selection', () {
      // Select units in Chapter 1
      state.toggle(unit1);
      state.toggle(unit2);
      expect(state.selectedCount, 2);

      // Change to Chapter 2 units
      final chapter2Units = [
        const Unit(id: 201, unitNumber: 1, unitName: 'Acids & Bases'),
        const Unit(id: 202, unitNumber: 2, unitName: 'Salts'),
      ];

      state.setUnits(chapter2Units);

      // Selections must be completely cleared and new units available
      expect(state.selectedCount, 0);
      expect(state.hasSelection, isFalse);
      expect(state.availableUnits.length, 2);
      expect(state.availableUnits.first.id, 201);
    });
  });

  group('MockUnitDataSource & Mock Data Tests', () {
    test('MockUnitDataSource returns expected units for Chapter 1, 2, and 3', () async {
      const dataSource = MockUnitDataSource(simulatedDelay: Duration.zero);

      final ch1Units = await dataSource.getUnitsByContext(chapterId: 1);
      expect(ch1Units.length, 3);
      expect(ch1Units[0].unitNumber, 1);
      expect(ch1Units[1].unitNumber, 2);
      expect(ch1Units[2].unitNumber, 3);

      final ch2Units = await dataSource.getUnitsByContext(chapterId: 2);
      expect(ch2Units.length, 2);

      final ch3Units = await dataSource.getUnitsByContext(chapterId: 3);
      expect(ch3Units.length, 4);

      final emptyCh = await dataSource.getUnitsByContext(chapterId: 99);
      expect(emptyCh, isEmpty);
    });
  });
}
