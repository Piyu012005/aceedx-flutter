import '../../../../../models/unit.dart';
import 'mock_units.dart';

/// Abstract contract for fetching Units by academic context.
///
/// In Phase 2 & 3, [MockUnitDataSource] is used.
/// In Phase 4, [ApiUnitDataSource] will call GET /api/teacher/units/by-context.
abstract class UnitDataSource {
  /// Fetches units corresponding to the selected chapter and context.
  Future<List<Unit>> getUnitsByContext({
    required int chapterId,
    String? chapterName,
    int? textbookId,
    String? subject,
    String? className,
    int? schoolId,
  });
}

/// Mock implementation of [UnitDataSource] for development, testing, and UI preview.
class MockUnitDataSource implements UnitDataSource {
  final Duration simulatedDelay;

  const MockUnitDataSource({
    this.simulatedDelay = const Duration(milliseconds: 150),
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
    if (simulatedDelay > Duration.zero) {
      await Future.delayed(simulatedDelay);
    }
    if (chapterId == 0) {
      final all = <Unit>[];
      MockUnitsData.mockUnitsByChapter.values.forEach(all.addAll);
      return all;
    }
    return MockUnitsData.getUnitsForChapter(chapterId);
  }
}
