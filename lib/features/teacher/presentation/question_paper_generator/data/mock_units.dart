import '../../../../../models/unit.dart';

/// MOCK DATA: Static mock unit records for Question Paper Generator testing.
/// NOTE: In Phase 4, this will be replaced by API calls to /api/teacher/units/by-context.
class MockUnitsData {
  /// Mock units grouped by chapter ID.
  static final Map<int, List<Unit>> mockUnitsByChapter = {
    // Chapter 1: Chemical Reactions and Equations (3 Units)
    1: const [
      Unit(
        id: 101,
        textbookId: 10,
        textbookChapterId: 1,
        unitNumber: 1,
        unitName: 'Chemical Equations and Balancing',
        startChunkIndex: 0,
        endChunkIndex: 45,
        detectionMethod: 'deterministic',
        sortOrder: 1,
      ),
      Unit(
        id: 102,
        textbookId: 10,
        textbookChapterId: 1,
        unitNumber: 2,
        unitName: 'Types of Chemical Reactions',
        startChunkIndex: 46,
        endChunkIndex: 95,
        detectionMethod: 'deterministic',
        sortOrder: 2,
      ),
      Unit(
        id: 103,
        textbookId: 10,
        textbookChapterId: 1,
        unitNumber: 3,
        unitName: 'Corrosion and Rancidity in Daily Life',
        startChunkIndex: 96,
        endChunkIndex: 130,
        detectionMethod: 'deterministic',
        sortOrder: 3,
      ),
    ],

    // Chapter 2: Acids, Bases and Salts (2 Units)
    2: const [
      Unit(
        id: 201,
        textbookId: 10,
        textbookChapterId: 2,
        unitNumber: 1,
        unitName: 'Properties of Acids and Bases & Indicators',
        startChunkIndex: 131,
        endChunkIndex: 190,
        detectionMethod: 'deterministic',
        sortOrder: 1,
      ),
      Unit(
        id: 202,
        textbookId: 10,
        textbookChapterId: 2,
        unitNumber: 2,
        unitName: 'pH Scale and Important Chemical Salts',
        startChunkIndex: 191,
        endChunkIndex: 260,
        detectionMethod: 'deterministic',
        sortOrder: 2,
      ),
    ],

    // Chapter 3: Metals and Non-metals (4 Units)
    3: const [
      Unit(
        id: 301,
        textbookId: 10,
        textbookChapterId: 3,
        unitNumber: 1,
        unitName: 'Physical & Chemical Properties of Metals',
        startChunkIndex: 261,
        endChunkIndex: 310,
        detectionMethod: 'deterministic',
        sortOrder: 1,
      ),
      Unit(
        id: 302,
        textbookId: 10,
        textbookChapterId: 3,
        unitNumber: 2,
        unitName: 'Reactivity Series and Formation of Ionic Compounds',
        startChunkIndex: 311,
        endChunkIndex: 365,
        detectionMethod: 'deterministic',
        sortOrder: 2,
      ),
      Unit(
        id: 303,
        textbookId: 10,
        textbookChapterId: 3,
        unitNumber: 3,
        unitName: 'Occurrence and Extraction of Metals (Metallurgy)',
        startChunkIndex: 366,
        endChunkIndex: 420,
        detectionMethod: 'deterministic',
        sortOrder: 3,
      ),
      Unit(
        id: 304,
        textbookId: 10,
        textbookChapterId: 3,
        unitNumber: 4,
        unitName: 'Corrosion Prevention and Alloys',
        startChunkIndex: 421,
        endChunkIndex: 460,
        detectionMethod: 'deterministic',
        sortOrder: 4,
      ),
    ],
  };

  /// Retrieve mock units for a given chapter ID.
  static List<Unit> getUnitsForChapter(int chapterId) {
    return mockUnitsByChapter[chapterId] ?? [];
  }
}
