/// Response model for generated question paper from POST /api/teacher/generate.
class QuestionPaperGenerationResponse {
  final bool status;
  final String message;
  final GeneratedPaperData? data;

  const QuestionPaperGenerationResponse({
    required this.status,
    required this.message,
    this.data,
  });

  factory QuestionPaperGenerationResponse.fromJson(Map<String, dynamic> json) {
    final status = json['status'] is bool
        ? json['status'] as bool
        : json['status'] == 1 || json['status'] == 'true';

    final message = (json['message'] ?? 'Question paper generated').toString();

    GeneratedPaperData? paperData;
    if (json['data'] != null && json['data'] is Map<String, dynamic>) {
      paperData = GeneratedPaperData.fromJson(json['data'] as Map<String, dynamic>);
    }

    return QuestionPaperGenerationResponse(
      status: status,
      message: message,
      data: paperData,
    );
  }
}

class GeneratedPaperData {
  final int id;
  final int? schoolId;
  final int? subjectId;
  final String? className;
  final String? chapter;
  final int? marks;
  final String? format;
  final String? board;
  final String? paperLanguage;
  final String? questions;
  final String? status;

  const GeneratedPaperData({
    required this.id,
    this.schoolId,
    this.subjectId,
    this.className,
    this.chapter,
    this.marks,
    this.format,
    this.board,
    this.paperLanguage,
    this.questions,
    this.status,
  });

  factory GeneratedPaperData.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'] ?? json['paper_id'] ?? 0;
    final int id = rawId is int ? rawId : int.parse(rawId.toString());

    return GeneratedPaperData(
      id: id,
      schoolId: json['school_id'] is int
          ? json['school_id'] as int
          : (json['school_id'] != null ? int.tryParse(json['school_id'].toString()) : null),
      subjectId: json['subject_id'] is int
          ? json['subject_id'] as int
          : (json['subject_id'] != null ? int.tryParse(json['subject_id'].toString()) : null),
      className: json['class'] as String?,
      chapter: json['chapter'] as String?,
      marks: json['marks'] is int
          ? json['marks'] as int
          : (json['marks'] != null ? int.tryParse(json['marks'].toString()) : null),
      format: json['format'] as String?,
      board: json['board'] as String?,
      paperLanguage: json['paper_language'] as String? ?? json['language'] as String?,
      questions: json['questions'] as String?,
      status: json['status'] as String?,
    );
  }
}
