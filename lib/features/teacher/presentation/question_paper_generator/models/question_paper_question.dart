/// Model representing an individual question within a question paper section.
class QuestionPaperQuestion {
  final String number;
  final String text;
  final String? marks;
  final List<String>? lines;

  const QuestionPaperQuestion({
    required this.number,
    required this.text,
    this.marks,
    this.lines,
  });

  factory QuestionPaperQuestion.fromJson(Map<String, dynamic> json) {
    List<String>? parsedLines;
    if (json['lines'] != null && json['lines'] is List) {
      parsedLines = (json['lines'] as List).map((e) => e.toString()).toList();
    }

    return QuestionPaperQuestion(
      number: (json['number'] ?? json['q_num'] ?? '').toString(),
      text: (json['text'] ?? json['question'] ?? '').toString(),
      marks: json['marks']?.toString(),
      lines: parsedLines,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'number': number,
      'text': text,
      if (marks != null) 'marks': marks,
      if (lines != null) 'lines': lines,
    };
  }
}
