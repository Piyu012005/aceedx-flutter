import 'question_paper_question.dart';

/// Model representing a section (e.g. SECTION 1: PASSAGES, SECTION A, etc.) within a Question Paper.
class QuestionPaperSection {
  final String title;
  final List<QuestionPaperQuestion> questions;

  const QuestionPaperSection({
    required this.title,
    this.questions = const [],
  });

  factory QuestionPaperSection.fromJson(Map<String, dynamic> json) {
    final title = (json['title'] ?? json['name'] ?? json['section_title'] ?? 'Section').toString();

    List<QuestionPaperQuestion> questions = [];
    if (json['questions'] != null && json['questions'] is List) {
      questions = (json['questions'] as List)
          .whereType<Map<String, dynamic>>()
          .map((q) => QuestionPaperQuestion.fromJson(q))
          .toList();
    }

    return QuestionPaperSection(
      title: title,
      questions: questions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'questions': questions.map((q) => q.toJson()).toList(),
    };
  }
}
