import 'question_paper_section.dart';

/// Full Question Paper domain model representing data returned from GET /api/teacher/paper/:id and GET /api/teacher/papers.
class QuestionPaper {
  final int id;
  final int? teacherId;
  final int? schoolId;
  final int? subjectId;
  final String? subjectName;
  final String? board;
  final String? className;
  final String? chapterName;
  final int? marks;
  final String? format;
  final String? paperLanguage;
  final String status;
  final String? questionsText;
  final String? answerKeyText;
  final String? pdfUrl;
  final String? schoolName;
  final List<QuestionPaperSection>? sections;
  final DateTime? createdAt;

  const QuestionPaper({
    required this.id,
    this.teacherId,
    this.schoolId,
    this.subjectId,
    this.subjectName,
    this.board,
    this.className,
    this.chapterName,
    this.marks,
    this.format,
    this.paperLanguage,
    this.status = 'pending',
    this.questionsText,
    this.answerKeyText,
    this.pdfUrl,
    this.schoolName,
    this.sections,
    this.createdAt,
  });

  factory QuestionPaper.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'] ?? json['paper_id'] ?? 0;
    final int id = rawId is int ? rawId : int.parse(rawId.toString());

    int? parseInt(dynamic val) {
      if (val == null) return null;
      if (val is int) return val;
      return int.tryParse(val.toString());
    }

    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      try {
        return DateTime.parse(val.toString());
      } catch (_) {
        return null;
      }
    }

    String? extractSubjectName(dynamic subjectVal) {
      if (subjectVal == null) return json['subject_name']?.toString() ?? json['subjectName']?.toString();
      if (subjectVal is String) return subjectVal;
      if (subjectVal is Map && subjectVal['name'] != null) return subjectVal['name'].toString();
      return subjectVal.toString();
    }

    List<QuestionPaperSection>? parsedSections;
    if (json['sections'] != null && json['sections'] is List) {
      parsedSections = (json['sections'] as List)
          .whereType<Map<String, dynamic>>()
          .map((s) => QuestionPaperSection.fromJson(s))
          .toList();
    }

    final questionsTextStr = json['questions']?.toString() ??
        json['questions_text']?.toString() ??
        json['content']?.toString() ??
        json['paper_content']?.toString();

    return QuestionPaper(
      id: id,
      teacherId: parseInt(json['teacher_id']),
      schoolId: parseInt(json['school_id']),
      subjectId: parseInt(json['subject_id']),
      subjectName: extractSubjectName(json['subject']),
      board: json['board']?.toString(),
      className: json['class']?.toString(),
      chapterName: json['chapter_name']?.toString() ?? json['chapter']?.toString(),
      marks: parseInt(json['marks']),
      format: json['format']?.toString(),
      paperLanguage: json['paper_language']?.toString() ?? json['language']?.toString(),
      status: (json['status'] ?? 'pending').toString(),
      questionsText: questionsTextStr,
      answerKeyText: json['answer_key']?.toString(),
      pdfUrl: json['pdf_url']?.toString() ?? json['file_url']?.toString(),
      schoolName: json['school_name']?.toString() ?? json['schoolName']?.toString(),
      sections: parsedSections,
      createdAt: parseDate(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (teacherId != null) 'teacher_id': teacherId,
      if (schoolId != null) 'school_id': schoolId,
      if (subjectId != null) 'subject_id': subjectId,
      if (subjectName != null) 'subject_name': subjectName,
      if (board != null) 'board': board,
      if (className != null) 'class': className,
      if (chapterName != null) 'chapter_name': chapterName,
      if (marks != null) 'marks': marks,
      if (format != null) 'format': format,
      if (paperLanguage != null) 'paper_language': paperLanguage,
      'status': status,
      if (questionsText != null) 'questions': questionsText,
      if (answerKeyText != null) 'answer_key': answerKeyText,
      if (pdfUrl != null) 'pdf_url': pdfUrl,
      if (schoolName != null) 'school_name': schoolName,
      if (sections != null) 'sections': sections!.map((s) => s.toJson()).toList(),
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }
}

/// Model representing PDF/Export API response.
class QuestionPaperExportResponse {
  final bool status;
  final String type;
  final String? filePath;
  final String? fileUrl;

  const QuestionPaperExportResponse({
    required this.status,
    required this.type,
    this.filePath,
    this.fileUrl,
  });

  factory QuestionPaperExportResponse.fromJson(Map<String, dynamic> json) {
    final status = json['status'] is bool
        ? json['status'] as bool
        : json['status'] == 1 || json['status'] == 'true';

    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;

    return QuestionPaperExportResponse(
      status: status,
      type: (json['type'] ?? data['type'] ?? 'pdf').toString(),
      filePath: (data['file_path'] ?? json['file_path'])?.toString(),
      fileUrl: (data['file_url'] ??
              data['pdf_url'] ??
              json['file_url'] ??
              json['pdf_url'])
          ?.toString(),
    );
  }
}
