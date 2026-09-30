import '../../../../../models/unit.dart';

/// Represents a group of textbook units belonging to a single textbook chapter (`textbook_chapter_id`).
class ChapterGroup {
  final int id; // textbook_chapter_id (e.g. 115)
  final String displayName; // e.g. "Unit 1"
  final List<Unit> units; // Units belonging strictly to this textbook_chapter_id
  final bool isExpanded;

  const ChapterGroup({
    required this.id,
    required this.displayName,
    required this.units,
    this.isExpanded = true,
  });

  /// Group factory that groups units strictly by `textbook_chapter_id`.
  factory ChapterGroup.fromUnits({
    required int chapterId,
    required List<Unit> units,
    int? groupIndex,
  }) {
    String name = '';
    if (units.isNotEmpty) {
      final firstUnit = units.first;
      final uNumStr = firstUnit.unitNumber?.toString().trim() ?? '';
      if (uNumStr.contains('.')) {
        final prefix = uNumStr.split('.').first.trim();
        if (prefix.isNotEmpty) {
          name = 'Unit $prefix';
        }
      } else if (uNumStr.isNotEmpty) {
        name = 'Unit $uNumStr';
      }
    }
    if (name.isEmpty) {
      final idx = groupIndex != null ? (groupIndex + 1) : chapterId;
      name = 'Unit $idx';
    }

    return ChapterGroup(
      id: chapterId,
      displayName: name,
      units: List.unmodifiable(units),
      isExpanded: true,
    );
  }

  /// Number of units in this group that are present in [selectedUnitIds].
  int getSelectedCount(Set<int> selectedUnitIds) {
    return units.where((u) => selectedUnitIds.contains(u.id)).length;
  }

  /// True if all units in this group are selected.
  bool isAllSelected(Set<int> selectedUnitIds) {
    return units.isNotEmpty && units.every((u) => selectedUnitIds.contains(u.id));
  }

  /// True if no units in this group are selected.
  bool isNoneSelected(Set<int> selectedUnitIds) {
    return units.every((u) => !selectedUnitIds.contains(u.id));
  }

  /// True if some (but not all) units in this group are selected.
  bool isIndeterminate(Set<int> selectedUnitIds) {
    final count = getSelectedCount(selectedUnitIds);
    return count > 0 && count < units.length;
  }

  ChapterGroup copyWith({
    int? id,
    String? displayName,
    List<Unit>? units,
    bool? isExpanded,
  }) {
    return ChapterGroup(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      units: units ?? this.units,
      isExpanded: isExpanded ?? this.isExpanded,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChapterGroup &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'ChapterGroup(id: $id, name: "$displayName", unitCount: ${units.length}, expanded: $isExpanded)';
}
