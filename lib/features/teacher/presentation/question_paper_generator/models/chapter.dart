/// Strongly-typed Chapter model representing a textbook chapter in the Question Paper Generator.
class Chapter {
  final int id; // textbook_chapter_id (e.g. 83)
  final int? textbookId; // textbook_id (e.g. 39)
  final String chapterNumber; // e.g. "1" or "One"
  final String title; // e.g. "Chapter 1" or "Unit One" or chapter title from DB
  final int? schoolId;
  final int? subjectId;
  final String? className;

  const Chapter({
    required this.id,
    this.textbookId,
    required this.chapterNumber,
    required this.title,
    this.schoolId,
    this.subjectId,
    this.className,
  });

  /// User-facing display title.
  String get displayName {
    if (title.isNotEmpty) {
      // If title is just a number like "1", format as "Chapter 1"
      if (RegExp(r'^\d+$').hasMatch(title)) {
        return 'Chapter $title';
      }
      return title;
    }
    if (chapterNumber.isNotEmpty) {
      if (RegExp(r'^\d+$').hasMatch(chapterNumber)) {
        return 'Chapter $chapterNumber';
      }
      return chapterNumber;
    }
    return 'Chapter $id';
  }

  factory Chapter.fromJson(Map<String, dynamic> json) {
    int parseId(dynamic val) {
      if (val is int) return val;
      if (val is String) return int.tryParse(val) ?? 0;
      return 0;
    }

    int? parseOptionalInt(dynamic val) {
      if (val == null) return null;
      if (val is int) return val;
      if (val is String) return int.tryParse(val);
      return null;
    }

    return Chapter(
      id: parseId(json['id'] ?? json['textbook_chapter_id'] ?? json['chapter_id']),
      textbookId: parseOptionalInt(json['textbook_id']),
      chapterNumber: (json['chapter_number'] ?? json['chapter_num'] ?? json['number'] ?? '')?.toString() ?? '',
      title: (json['title'] ?? json['chapter_name'] ?? json['name'] ?? '')?.toString() ?? '',
      schoolId: parseOptionalInt(json['school_id']),
      subjectId: parseOptionalInt(json['subject_id']),
      className: json['class']?.toString() ?? json['class_name']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (textbookId != null) 'textbook_id': textbookId,
      'chapter_number': chapterNumber,
      'title': title,
      if (schoolId != null) 'school_id': schoolId,
      if (subjectId != null) 'subject_id': subjectId,
      if (className != null) 'class': className,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Chapter &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Chapter(id: $id, num: "$chapterNumber", title: "$title", textbookId: $textbookId)';
}
