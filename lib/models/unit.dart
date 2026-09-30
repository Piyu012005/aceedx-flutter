/// Unit model representing a textbook unit for question paper generation.
class Unit {
  final int id;
  final int? textbookId;
  final int? textbookChapterId;
  final dynamic unitNumber; // supports int, String ("1.1", "2.1"), etc.
  final String unitName;
  final int? startChunkIndex;
  final int? endChunkIndex;
  final String? detectionMethod;
  final int? sortOrder;

  const Unit({
    required this.id,
    this.textbookId,
    this.textbookChapterId,
    required this.unitNumber,
    required this.unitName,
    this.startChunkIndex,
    this.endChunkIndex,
    this.detectionMethod,
    this.sortOrder,
  });

  /// Factory constructor to parse Unit from backend JSON map.
  factory Unit.fromJson(Map<String, dynamic> json) {
    int parseId(dynamic value) {
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    int? parseOptionalInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      return null;
    }

    dynamic parseUnitNumber(dynamic value) {
      if (value == null) return 1;
      if (value is int) return value;
      if (value is String) {
        final str = value.trim();
        final asInt = int.tryParse(str);
        if (asInt != null) return asInt;
        return str.isNotEmpty ? str : 1;
      }
      return value.toString();
    }

    return Unit(
      id: parseId(json['id']),
      textbookId: parseOptionalInt(json['textbook_id']),
      textbookChapterId: parseOptionalInt(json['textbook_chapter_id']),
      unitNumber: parseUnitNumber(json['unit_number']),
      unitName: json['unit_name'] as String? ?? '',
      startChunkIndex: parseOptionalInt(json['start_chunk_index']),
      endChunkIndex: parseOptionalInt(json['end_chunk_index']),
      detectionMethod: json['detection_method'] as String?,
      sortOrder: parseOptionalInt(json['sort_order']),
    );
  }

  /// Converts Unit instance to JSON map matching backend schema.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (textbookId != null) 'textbook_id': textbookId,
      if (textbookChapterId != null) 'textbook_chapter_id': textbookChapterId,
      'unit_number': unitNumber,
      'unit_name': unitName,
      if (startChunkIndex != null) 'start_chunk_index': startChunkIndex,
      if (endChunkIndex != null) 'end_chunk_index': endChunkIndex,
      if (detectionMethod != null) 'detection_method': detectionMethod,
      if (sortOrder != null) 'sort_order': sortOrder,
    };
  }

  /// Formatted display label (e.g. "1.1 - Where the Mind is Without Fear" or "Unit 1 – Introduction").
  String get displayLabel {
    final numStr = unitNumber?.toString().trim() ?? '';
    if (numStr.isEmpty) return unitName;
    if (numStr.toLowerCase().startsWith('unit') || numStr.contains('.')) {
      return '$numStr - $unitName';
    }
    return 'Unit $numStr – $unitName';
  }

  /// Safe numeric representation if integer or parseable.
  int? get numericUnitNumber {
    if (unitNumber is int) return unitNumber as int;
    if (unitNumber is String) {
      final parts = (unitNumber as String).split('.');
      if (parts.isNotEmpty) {
        return int.tryParse(parts.first);
      }
    }
    return null;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Unit &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          textbookId == other.textbookId &&
          textbookChapterId == other.textbookChapterId &&
          unitNumber.toString() == other.unitNumber.toString() &&
          unitName == other.unitName;

  @override
  int get hashCode =>
      id.hashCode ^
      textbookId.hashCode ^
      textbookChapterId.hashCode ^
      unitNumber.hashCode ^
      unitName.hashCode;

  @override
  String toString() =>
      'Unit(id: $id, unitNumber: $unitNumber, unitName: "$unitName", chapterId: $textbookChapterId)';
}
