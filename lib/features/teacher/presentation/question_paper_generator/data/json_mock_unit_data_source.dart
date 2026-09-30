import 'dart:convert';
import 'package:flutter/services.dart';
import '../../../../../models/unit.dart';
import 'unit_data_source.dart';

/// JSON-backed mock implementation of [UnitDataSource].
///
/// Loads [assets/mock_unit_response.json] — which replicates the real
/// Laravel /api/teacher/units/by-context response shape — and filters
/// the result by [chapterId] (and optionally [textbookId]).
///
/// This class exists ONLY for Phase 3 API-contract validation.
/// In Phase 4, [ApiUnitDataSource] will replace this with a real HTTP call.
class JsonMockUnitDataSource implements UnitDataSource {
  /// Path to the mock JSON asset (registered in pubspec.yaml).
  static const String _assetPath = 'assets/mock_unit_response.json';

  final Duration simulatedDelay;

  const JsonMockUnitDataSource({
    this.simulatedDelay = const Duration(milliseconds: 150),
  });

  /// Loads and parses the mock JSON asset into a [List<Unit>].
  Future<List<Unit>> _loadAllUnits() async {
    final jsonString = await rootBundle.loadString(_assetPath);
    final List<dynamic> rawList = jsonDecode(jsonString) as List<dynamic>;
    return rawList
        .map((item) => Unit.fromJson(item as Map<String, dynamic>))
        .toList();
  }

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

    final allUnits = await _loadAllUnits();

    return allUnits.where((unit) {
      final chapterMatch = unit.textbookChapterId == chapterId;
      final textbookMatch =
          textbookId == null || unit.textbookId == textbookId;
      return chapterMatch && textbookMatch;
    }).toList();
  }
}

/// Utility: parse a raw JSON list string directly into [List<Unit>].
/// Used in tests to avoid asset loading.
List<Unit> parseUnitsFromJsonString(String jsonString) {
  final List<dynamic> rawList = jsonDecode(jsonString) as List<dynamic>;
  return rawList
      .map((item) => Unit.fromJson(item as Map<String, dynamic>))
      .toList();
}
