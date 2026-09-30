import '../../../../../models/unit.dart';
import '../models/chapter.dart';
import '../models/chapter_group.dart';
import '../models/dropdown_data.dart';
import '../models/question_paper.dart';
import '../models/question_paper_generation_response.dart';

const List<String> kAllQuestionFormats = [
  'MCQ',
  'True / False',
  'Match the following',
  'Assertion-Reason',
  'Fill in the blanks',
  'Grammar',
  'Seen passage',
  'Unseen passage',
  'Seen poem',
  'Unseen poem',
  'Numericals',
  'Equations',
  'Reaction',
  'Word problem',
  'Prove / Derive',
  'Practical / activity-based',
  'Diagram-based',
  'Data interpretation',
  'Map-based',
  'Essay',
  'Letter writing',
  'Paragraph writing',
  'Very short answer question',
  'Short answer question',
  'Long answer question',
  'Situational based',
  'Define / distinguish',
];

/// Default question count per format — used when a format is first selected.
/// Formats not listed here default to 1.
const Map<String, int> kFormatDefaultQuestionCount = {
  'MCQ': 5,
  'True / False': 5,
  'Match the following': 1,
  'Assertion-Reason': 2,
  'Fill in the blanks': 5,
  'Grammar': 10,
  'Seen passage': 1,
  'Unseen passage': 1,
  'Seen poem': 1,
  'Unseen poem': 1,
  'Numericals': 3,
  'Equations': 2,
  'Reaction': 2,
  'Word problem': 2,
  'Prove / Derive': 1,
  'Practical / activity-based': 1,
  'Diagram-based': 1,
  'Data interpretation': 1,
  'Map-based': 1,
  'Essay': 1,
  'Letter writing': 1,
  'Paragraph writing': 1,
  'Very short answer question': 5,
  'Short answer question': 4,
  'Long answer question': 3,
  'Situational based': 1,
  'Define / distinguish': 3,
};

/// Default marks-per-question per format — used when a format is first selected.
/// Formats not listed here default to 1.
const Map<String, int> kFormatDefaultMarksEach = {
  'MCQ': 1,
  'True / False': 1,
  'Match the following': 4,
  'Assertion-Reason': 1,
  'Fill in the blanks': 1,
  'Grammar': 2,
  'Seen passage': 5,
  'Unseen passage': 5,
  'Seen poem': 5,
  'Unseen poem': 5,
  'Numericals': 3,
  'Equations': 3,
  'Reaction': 2,
  'Word problem': 4,
  'Prove / Derive': 5,
  'Practical / activity-based': 5,
  'Diagram-based': 3,
  'Data interpretation': 4,
  'Map-based': 3,
  'Essay': 10,
  'Letter writing': 10,
  'Paragraph writing': 5,
  'Very short answer question': 1,
  'Short answer question': 2,
  'Long answer question': 4,
  'Situational based': 3,
  'Define / distinguish': 2,
};

enum QuestionPaperGeneratorStatus {
  initial,
  loadingDropdowns,
  loadingUnits,
  unitsLoaded,
  unitsError,
  generating,
  generatedSuccess,
  generationError,
}

/// State representation for the Question Paper Generator screen.
class QuestionPaperGeneratorState {
  final QuestionPaperGeneratorStatus status;
  final int? schoolId;
  final String? schoolName;
  final int? subjectId;
  final String? subjectName;
  final String? className;
  final int? chapterId;
  final String? chapterName;

  // Multi-chapter selection support
  final List<int> selectedChapterIds;
  final List<ChapterGroup> availableChapterGroups;

  final bool isLoadingChapters;
  final List<Chapter> availableChapters;
  final String? chaptersError;
  final List<Unit> availableUnits;
  final List<int> selectedUnitIds;
  final int marks;
  final String format;
  final String board;
  final String userPrompt;
  final String additionalInstructions;
  final String paperLanguage;
  final String difficulty;
  final String? errorMessage;
  final GeneratedPaperData? generatedPaper;

  // Dropdown lists fetched from API
  final bool isLoadingDropdowns;
  final List<DropdownBoard> availableBoards;
  final List<DropdownSubject> availableSubjects;
  final List<String> availableClasses;

  // Question Formats multi-select & per-format configurations
  final Set<String> selectedFormats;
  final Map<String, int> formatQuestionCounts;
  final Map<String, int> formatMarksEach;

  // Unit section accordion toggle
  final bool isUnitAccordionExpanded;

  // Saved papers history
  final bool isLoadingPapers;
  final List<QuestionPaper> savedPapers;

  const QuestionPaperGeneratorState({
    this.status = QuestionPaperGeneratorStatus.initial,
    this.schoolId,
    this.schoolName,
    this.subjectId,
    this.subjectName,
    this.className,
    this.chapterId,
    this.chapterName,
    this.selectedChapterIds = const [],
    this.availableChapterGroups = const [],
    this.isLoadingChapters = false,
    this.availableChapters = const [],
    this.chaptersError,
    this.availableUnits = const [],
    this.selectedUnitIds = const [],
    this.marks = 80,
    this.format = 'standard',
    this.board = 'CBSE',
    this.userPrompt = 'Generate standard question paper',
    this.additionalInstructions = '',
    this.paperLanguage = 'English',
    this.difficulty = 'Easy',
    this.errorMessage,
    this.generatedPaper,
    this.isLoadingDropdowns = false,
    this.availableBoards = const [
      DropdownBoard(id: 1, name: 'CBSE'),
      DropdownBoard(id: 2, name: 'ICSE'),
      DropdownBoard(id: 3, name: 'State Board'),
    ],
    this.availableSubjects = const [
      DropdownSubject(id: 1, name: 'Science'),
      DropdownSubject(id: 2, name: 'Mathematics'),
      DropdownSubject(id: 3, name: 'Social Science'),
      DropdownSubject(id: 4, name: 'English'),
    ],
    this.availableClasses = const ['9', '10', '11', '12'],
    this.selectedFormats = const {'MCQ'},
    this.formatQuestionCounts = const {'MCQ': 1},
    this.formatMarksEach = const {'MCQ': 1},
    this.isUnitAccordionExpanded = true,
    this.isLoadingPapers = false,
    this.savedPapers = const [],
  });

  /// Helper returning selected ChapterGroup instances based on selectedChapterIds.
  List<ChapterGroup> get selectedChapterGroups {
    return availableChapterGroups
        .where((g) => selectedChapterIds.contains(g.id))
        .toList();
  }

  /// Helper returning string list of chapter names for backwards compatibility
  List<String> get availableChapterNames =>
      availableChapters.map((c) => c.displayName).toList();

  /// Computes the automatic prompt preview string matching recovered a2e() behavior.
  String get computedPromptPreview {
    final buffer = StringBuffer();
    for (final fmt in kAllQuestionFormats) {
      if (selectedFormats.contains(fmt)) {
        final qCount = formatQuestionCounts[fmt] ?? 1;
        final marksEach = formatMarksEach[fmt] ?? 1;
        buffer.writeln('$fmt | Questions: $qCount | Marks each: $marksEach');
      }
    }
    return buffer.toString().trim();
  }

  /// Full combined prompt for API transmission.
  String get fullGeneratedPrompt {
    final preview = computedPromptPreview;
    if (additionalInstructions.trim().isEmpty) {
      return preview;
    }
    if (preview.isEmpty) {
      return additionalInstructions.trim();
    }
    return '$preview\n\n---\n\n${additionalInstructions.trim()}';
  }

  QuestionPaperGeneratorState copyWith({
    QuestionPaperGeneratorStatus? status,
    int? schoolId,
    bool clearSchoolId = false,
    String? schoolName,
    int? subjectId,
    String? subjectName,
    String? className,
    int? chapterId,
    String? chapterName,
    List<int>? selectedChapterIds,
    List<ChapterGroup>? availableChapterGroups,
    bool? isLoadingChapters,
    List<Chapter>? availableChapters,
    String? chaptersError,
    List<Unit>? availableUnits,
    List<int>? selectedUnitIds,
    int? marks,
    String? format,
    String? board,
    String? userPrompt,
    String? additionalInstructions,
    String? paperLanguage,
    String? difficulty,
    String? errorMessage,
    GeneratedPaperData? generatedPaper,
    bool? isLoadingDropdowns,
    List<DropdownBoard>? availableBoards,
    List<DropdownSubject>? availableSubjects,
    List<String>? availableClasses,
    Set<String>? selectedFormats,
    Map<String, int>? formatQuestionCounts,
    Map<String, int>? formatMarksEach,
    bool? isUnitAccordionExpanded,
    bool? isLoadingPapers,
    List<QuestionPaper>? savedPapers,
    bool clearSubject = false,
    bool clearClass = false,
    bool clearChapters = false,
    bool clearChapter = false,
    bool clearUnits = false,
    bool clearError = false,
    bool clearGeneratedPaper = false,
  }) {
    final resetChapters = clearSubject || clearClass || clearChapters;
    final resetUnits = clearSubject || clearClass || clearChapter || clearUnits;

    return QuestionPaperGeneratorState(
      status: status ?? this.status,
      schoolId: clearSchoolId ? null : (schoolId ?? this.schoolId),
      schoolName: schoolName ?? this.schoolName,
      subjectId: clearSubject ? null : (subjectId ?? this.subjectId),
      subjectName: clearSubject ? null : (subjectName ?? this.subjectName),
      className: (clearSubject || clearClass) ? null : (className ?? this.className),
      chapterId: (clearSubject || clearClass || clearChapter) ? null : (chapterId ?? this.chapterId),
      chapterName: (clearSubject || clearClass || clearChapter) ? null : (chapterName ?? this.chapterName),
      selectedChapterIds: resetChapters
          ? const []
          : (selectedChapterIds ?? this.selectedChapterIds),
      availableChapterGroups: resetChapters
          ? const []
          : (availableChapterGroups ?? this.availableChapterGroups),
      isLoadingChapters: isLoadingChapters ?? this.isLoadingChapters,
      availableChapters: resetChapters
          ? const []
          : (availableChapters ?? this.availableChapters),
      chaptersError: resetChapters
          ? null
          : (chaptersError ?? this.chaptersError),
      availableUnits: resetUnits
          ? const []
          : (availableUnits ?? this.availableUnits),
      selectedUnitIds: resetUnits
          ? const []
          : (selectedUnitIds ?? this.selectedUnitIds),
      marks: marks ?? this.marks,
      format: format ?? this.format,
      board: board ?? this.board,
      userPrompt: userPrompt ?? this.userPrompt,
      additionalInstructions: additionalInstructions ?? this.additionalInstructions,
      paperLanguage: paperLanguage ?? this.paperLanguage,
      difficulty: difficulty ?? this.difficulty,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      generatedPaper: clearGeneratedPaper ? null : (generatedPaper ?? this.generatedPaper),
      isLoadingDropdowns: isLoadingDropdowns ?? this.isLoadingDropdowns,
      availableBoards: availableBoards ?? this.availableBoards,
      availableSubjects: availableSubjects ?? this.availableSubjects,
      availableClasses: availableClasses ?? this.availableClasses,
      selectedFormats: selectedFormats ?? this.selectedFormats,
      formatQuestionCounts: formatQuestionCounts ?? this.formatQuestionCounts,
      formatMarksEach: formatMarksEach ?? this.formatMarksEach,
      isUnitAccordionExpanded: isUnitAccordionExpanded ?? this.isUnitAccordionExpanded,
      isLoadingPapers: isLoadingPapers ?? this.isLoadingPapers,
      savedPapers: savedPapers ?? this.savedPapers,
    );
  }
}
