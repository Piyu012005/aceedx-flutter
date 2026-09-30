import 'package:flutter/foundation.dart';
import '../../../../../models/unit.dart';

/// State management controller for Unit selection in Question Paper Generator.
///
/// Handles multi-selection with numeric integer IDs (`Set<int>`).
class UnitSelectionState extends ChangeNotifier {
  List<Unit> _availableUnits = [];
  final Set<int> _selectedUnitIds = <int>{};

  UnitSelectionState({List<Unit>? initialUnits}) {
    if (initialUnits != null) {
      _availableUnits = List.unmodifiable(initialUnits);
    }
  }

  /// All available units for the currently active chapter.
  List<Unit> get availableUnits => List.unmodifiable(_availableUnits);

  /// Set of currently selected unit integer IDs.
  Set<int> get selectedUnitIdsSet => Set.unmodifiable(_selectedUnitIds);

  /// List of selected unit IDs as integers.
  List<int> get selectedUnitIds => _selectedUnitIds.toList()..sort();

  /// List of selected [Unit] model instances.
  List<Unit> get selectedUnits {
    return _availableUnits
        .where((unit) => _selectedUnitIds.contains(unit.id))
        .toList();
  }

  /// Total count of selected units.
  int get selectedCount => _selectedUnitIds.length;

  /// Returns true if at least one unit is selected.
  bool get hasSelection => _selectedUnitIds.isNotEmpty;

  /// Returns true if all available units are selected.
  bool get isAllSelected =>
      _availableUnits.isNotEmpty &&
      _selectedUnitIds.length == _availableUnits.length;

  /// Checks if a specific unit ID is selected.
  bool isSelected(int unitId) => _selectedUnitIds.contains(unitId);

  /// Updates available units (e.g. when changing chapters) and automatically resets previous selections.
  void setUnits(List<Unit> units) {
    _availableUnits = List.unmodifiable(units);
    _selectedUnitIds.clear();
    notifyListeners();
  }

  /// Toggles selection of a specific [Unit].
  void toggle(Unit unit) {
    if (_selectedUnitIds.contains(unit.id)) {
      _selectedUnitIds.remove(unit.id);
    } else {
      _selectedUnitIds.add(unit.id);
    }
    notifyListeners();
  }

  /// Explicitly selects a [Unit].
  void select(Unit unit) {
    if (_selectedUnitIds.add(unit.id)) {
      notifyListeners();
    }
  }

  /// Explicitly unselects a unit by numeric ID.
  void unselect(int unitId) {
    if (_selectedUnitIds.remove(unitId)) {
      notifyListeners();
    }
  }

  /// Selects all available units.
  void selectAll() {
    _selectedUnitIds.clear();
    for (final unit in _availableUnits) {
      _selectedUnitIds.add(unit.id);
    }
    notifyListeners();
  }

  /// Clears all selected units.
  void clear() {
    if (_selectedUnitIds.isNotEmpty) {
      _selectedUnitIds.clear();
      notifyListeners();
    }
  }
}
