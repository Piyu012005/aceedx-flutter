/// Request model for generating a question paper via POST /api/teacher/generate.
class QuestionPaperGenerationRequest {
  final int? schoolId;
  final int subjectId;
  final String className;
  final String chapter;
  final int marks;
  final String format;
  final String board;
  final String userPrompt;
  final String? paperLanguage;
  final List<int>? unitIds;
  final String? difficulty;

  const QuestionPaperGenerationRequest({
    this.schoolId,
    required this.subjectId,
    required this.className,
    required this.chapter,
    required this.marks,
    required this.format,
    required this.board,
    required this.userPrompt,
    this.paperLanguage,
    this.unitIds,
    this.difficulty,
  });

  /// Serializes the request model to a JSON map conforming strictly to the Laravel API contract.
  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'subject_id': subjectId,
      'class': className,
      'chapter': chapter,
      'marks': marks,
      'format': format,
      'board': board,
      'user_prompt': userPrompt,
    };

    if (schoolId != null) {
      data['school_id'] = schoolId;
    }

    if (paperLanguage != null && paperLanguage!.isNotEmpty) {
      data['paper_language'] = paperLanguage;
      data['language'] = paperLanguage; // Compatibility fallback for backend variants
    }

    if (unitIds != null && unitIds!.isNotEmpty) {
      data['unit_ids'] = unitIds;
    }

    if (difficulty != null && difficulty!.isNotEmpty) {
      data['difficulty'] = difficulty;
      data['difficulty_level'] = difficulty;
    }

    return data;
  }

  /// Factory method to construct [QuestionPaperGenerationRequest] from JSON.
  factory QuestionPaperGenerationRequest.fromJson(Map<String, dynamic> json) {
    List<int>? parsedUnitIds;
    if (json['unit_ids'] != null && json['unit_ids'] is List) {
      parsedUnitIds = (json['unit_ids'] as List)
          .map((e) => e is int ? e : int.parse(e.toString()))
          .toList();
    }

    int? parsedSchoolId;
    if (json['school_id'] != null) {
      parsedSchoolId = json['school_id'] is int
          ? json['school_id'] as int
          : int.tryParse(json['school_id'].toString());
    }

    return QuestionPaperGenerationRequest(
      schoolId: parsedSchoolId,
      subjectId: json['subject_id'] is int
          ? json['subject_id'] as int
          : int.parse(json['subject_id'].toString()),
      className: (json['class'] ?? '').toString(),
      chapter: (json['chapter'] ?? '').toString(),
      marks: json['marks'] is int
          ? json['marks'] as int
          : int.parse(json['marks'].toString()),
      format: (json['format'] ?? 'standard').toString(),
      board: (json['board'] ?? 'CBSE').toString(),
      userPrompt: (json['user_prompt'] ?? '').toString(),
      paperLanguage: json['paper_language'] as String? ?? json['language'] as String?,
      unitIds: parsedUnitIds,
      difficulty: json['difficulty'] as String? ?? json['difficulty_level'] as String?,
    );
  }
}
