import 'package:flutter/foundation.dart';
import '../../../../../core/network/api_exception.dart';
import '../../../../../models/unit.dart';
import '../data/question_paper_api_service.dart';
import '../data/unit_data_source.dart';
import '../models/chapter.dart';
import '../models/chapter_group.dart';
import '../models/dropdown_data.dart';
import '../models/question_paper_generation_request.dart';
import 'question_paper_generator_state.dart';

/// State Controller managing business logic for the Question Paper Generator.
class QuestionPaperGeneratorController extends ValueNotifier<QuestionPaperGeneratorState> {
  UnitDataSource unitDataSource;
  QuestionPaperApiService apiService;
  bool _disposed = false;

  QuestionPaperGeneratorController({
    required this.unitDataSource,
    required this.apiService,
    QuestionPaperGeneratorState initialState = const QuestionPaperGeneratorState(),
  }) : super(initialState);

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  set value(QuestionPaperGeneratorState newValue) {
    if (_disposed) return;
    super.value = newValue;
  }

  /// Updates underlying data sources with authenticated instances.
  void updateDataSources({
    UnitDataSource? unitDataSource,
    QuestionPaperApiService? apiService,
  }) {
    if (unitDataSource != null) this.unitDataSource = unitDataSource;
    if (apiService != null) this.apiService = apiService;
  }

  /// Loads school info (name) from GET /api/teacher/school-info.
  Future<void> loadSchoolInfo() async {
    try {
      final name = await apiService.getSchoolInfo();
      if (name != null && name.isNotEmpty) {
        value = value.copyWith(schoolName: name);
      }
    } catch (_) {}
  }

  /// Loads dropdown data (boards, subjects, classes) via GET /api/teacher/dropdown/{school_id}.
  Future<void> loadDropdownData(int schoolId) async {
    value = value.copyWith(
      isLoadingDropdowns: true,
      clearError: true,
    );

    try {
      final rawData = await apiService.getDropdownData(schoolId);
      final dropdownData = TeacherDropdownData.fromJson(rawData);

      // Derive initial board/subject if available
      String? initialBoard = value.board;
      if (dropdownData.boards.isNotEmpty) {
        final matchingBoard = dropdownData.boards.any((b) => b.name == value.board);
        if (!matchingBoard) {
          initialBoard = dropdownData.boards.first.name;
        }
      }

      int? initialSubjectId = value.subjectId;
      String? initialSubjectName = value.subjectName;
      if (dropdownData.subjects.isNotEmpty && initialSubjectId == null) {
        initialSubjectId = dropdownData.subjects.first.id;
        initialSubjectName = dropdownData.subjects.first.name;
      }

      String? initialClass = value.className;
      if (dropdownData.classes.isNotEmpty && initialClass == null) {
        initialClass = dropdownData.classes.first;
      }

      value = value.copyWith(
        isLoadingDropdowns: false,
        schoolId: schoolId,
        board: initialBoard,
        subjectId: initialSubjectId,
        subjectName: initialSubjectName,
        className: initialClass,
        availableBoards: dropdownData.boards.isNotEmpty ? dropdownData.boards : value.availableBoards,
        availableSubjects: dropdownData.subjects.isNotEmpty ? dropdownData.subjects : value.availableSubjects,
        availableClasses: dropdownData.classes.isNotEmpty ? dropdownData.classes : value.availableClasses,
      );

      // If initial subject and class are available, load their chapters
      if (initialSubjectId != null && initialClass != null && initialClass.isNotEmpty) {
        loadChapters(
          subjectId: initialSubjectId,
          className: initialClass,
          schoolId: schoolId,
          schoolName: value.schoolName,
        );
      }
    } catch (e) {
      value = value.copyWith(
        isLoadingDropdowns: false,
      );
    }
  }

  /// Loads saved papers history via GET /api/teacher/papers.
  Future<void> loadSavedPapers() async {
    value = value.copyWith(isLoadingPapers: true);
    try {
      final papers = await apiService.getPapers();
      value = value.copyWith(
        isLoadingPapers: false,
        savedPapers: papers,
      );
    } catch (_) {
      value = value.copyWith(isLoadingPapers: false);
    }
  }

  /// Deletes a paper and refreshes list.
  Future<bool> deletePaper(int id) async {
    try {
      final success = await apiService.deletePaper(id);
      if (success) {
        final currentPapers = List.of(value.savedPapers)..removeWhere((p) => p.id == id);
        value = value.copyWith(savedPapers: currentPapers);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Selection Handler: Change Subject
  void selectSubject({required int id, required String name}) {
    value = value.copyWith(
      subjectId: id,
      subjectName: name,
      clearClass: true,
      clearChapters: true,
      clearChapter: true,
      clearUnits: true,
      clearError: true,
      status: QuestionPaperGeneratorStatus.initial,
    );
  }

  /// Selection Handler: Change Class & Fetch Chapters
  Future<void> selectClass(String className) async {
    value = value.copyWith(
      className: className,
      clearChapters: true,
      clearChapter: true,
      clearUnits: true,
      clearError: true,
      status: QuestionPaperGeneratorStatus.initial,
    );

    if (value.subjectId != null) {
      await loadChapters(
        subjectId: value.subjectId!,
        className: className,
        schoolId: value.schoolId,
        schoolName: value.schoolName,
      );
    }
  }

  /// Loads dynamic chapters and units for current subject and class from backend (`GET /api/teacher/units/by-context`).
  /// Groups units strictly by `textbook_chapter_id`.
  Future<void> loadChapters({
    required int subjectId,
    required String className,
    int? schoolId,
    String? schoolName,
  }) async {
    value = value.copyWith(
      isLoadingChapters: true,
      chaptersError: null,
      clearChapters: true,
      clearChapter: true,
      clearUnits: true,
      status: QuestionPaperGeneratorStatus.loadingUnits,
    );

    try {
      // 1. Fetch units for context using existing GET /api/teacher/units/by-context
      final units = await unitDataSource.getUnitsByContext(
        chapterId: 0,
        subject: subjectId.toString(),
        className: className,
        schoolId: schoolId,
      );

      // 2. Group units strictly by textbook_chapter_id
      final Map<int, List<Unit>> unitsByChapterId = {};
      for (final unit in units) {
        final chId = unit.textbookChapterId ?? 0;
        if (chId > 0) {
          unitsByChapterId.putIfAbsent(chId, () => []).add(unit);
        }
      }

      final List<ChapterGroup> groups = [];
      int groupIndex = 0;
      unitsByChapterId.forEach((chId, groupUnits) {
        groups.add(
          ChapterGroup.fromUnits(
            chapterId: chId,
            units: groupUnits,
            groupIndex: groupIndex++,
          ),
        );
      });

      // Backward-compatible List<Chapter>
      final List<Chapter> chapters = groups.map((g) {
        return Chapter(
          id: g.id,
          chapterNumber: g.displayName,
          title: g.displayName,
          subjectId: subjectId,
          className: className,
        );
      }).toList();

      final initialSelectedChapterIds = groups.map((g) => g.id).toList();
      final firstGroup = groups.isNotEmpty ? groups.first : null;

      value = value.copyWith(
        isLoadingChapters: false,
        status: QuestionPaperGeneratorStatus.unitsLoaded,
        availableChapterGroups: groups,
        availableChapters: chapters,
        availableUnits: units,
        selectedChapterIds: initialSelectedChapterIds,
        selectedUnitIds: const [],
        chapterId: firstGroup?.id,
        chapterName: firstGroup?.displayName,
      );
    } catch (e) {
      value = value.copyWith(
        isLoadingChapters: false,
        status: QuestionPaperGeneratorStatus.unitsError,
        chaptersError: 'Failed to load chapters for this subject and class.',
        availableChapterGroups: const [],
        availableChapters: const [],
        availableUnits: const [],
        selectedChapterIds: const [],
        selectedUnitIds: const [],
        errorMessage: e is ApiException ? e.message : null,
      );
    }
  }

  /// Single Chapter selection (backward & test compatibility)
  Future<void> selectChapter({required int id, required String name}) async {
    final currentChapterIds = List<int>.from(value.selectedChapterIds);
    if (!currentChapterIds.contains(id)) {
      currentChapterIds.add(id);
    }

    value = value.copyWith(
      chapterId: id,
      chapterName: name,
      selectedChapterIds: currentChapterIds,
      clearUnits: true,
      clearError: true,
      status: QuestionPaperGeneratorStatus.loadingUnits,
    );

    try {
      final units = await unitDataSource.getUnitsByContext(
        chapterId: id,
        chapterName: name,
        subject: value.subjectId?.toString(),
        className: value.className,
        schoolId: value.schoolId,
      );

      final currentGroups = List<ChapterGroup>.from(value.availableChapterGroups);
      final existingIdx = currentGroups.indexWhere((g) => g.id == id);
      final newGroup = ChapterGroup.fromUnits(
        chapterId: id,
        units: units,
      );
      if (existingIdx >= 0) {
        currentGroups[existingIdx] = newGroup;
      } else {
        currentGroups.add(newGroup);
      }

      // Combine all loaded units across groups
      final allUnits = <Unit>[];
      for (final g in currentGroups) {
        allUnits.addAll(g.units);
      }

      value = value.copyWith(
        status: QuestionPaperGeneratorStatus.unitsLoaded,
        availableChapterGroups: currentGroups,
        availableUnits: allUnits,
        selectedUnitIds: const [],
      );
    } on UnauthorizedException catch (e) {
      final msg = e.statusCode == 403
          ? 'You do not have permission to access Units.'
          : 'Your session has expired. Please log in again.';
      value = value.copyWith(
        status: QuestionPaperGeneratorStatus.unitsError,
        availableUnits: const [],
        selectedUnitIds: const [],
        errorMessage: msg,
      );
    } on NetworkException catch (_) {
      value = value.copyWith(
        status: QuestionPaperGeneratorStatus.unitsError,
        availableUnits: const [],
        selectedUnitIds: const [],
        errorMessage: 'Unable to connect to the server.',
      );
    } on ApiException catch (e) {
      final msg = e.statusCode == 422
          ? (e.message.isNotEmpty ? e.message : 'subject_id and class are required')
          : e.statusCode == 500
              ? 'Unable to load Units. Please try again.'
              : e.message;
      value = value.copyWith(
        status: QuestionPaperGeneratorStatus.unitsError,
        availableUnits: const [],
        selectedUnitIds: const [],
        errorMessage: msg,
      );
    } catch (_) {
      value = value.copyWith(
        status: QuestionPaperGeneratorStatus.unitsError,
        availableUnits: const [],
        selectedUnitIds: const [],
        errorMessage: 'Unable to load Units. Please try again.',
      );
    }
  }

  /// Toggle selection of a specific Chapter Group ID (`textbook_chapter_id`).
  /// Preserves unit selections from other active chapters.
  void toggleChapterSelection(int chapterId) {
    final currentChapterIds = List<int>.from(value.selectedChapterIds);
    final currentUnitIds = List<int>.from(value.selectedUnitIds);

    if (currentChapterIds.contains(chapterId)) {
      currentChapterIds.remove(chapterId);
      // Remove units belonging to this chapter group
      final matches = value.availableChapterGroups.where((g) => g.id == chapterId);
      if (matches.isNotEmpty) {
        final targetGroup = matches.first;
        final groupUnitIds = targetGroup.units.map((u) => u.id).toSet();
        currentUnitIds.removeWhere((id) => groupUnitIds.contains(id));
      }
    } else {
      currentChapterIds.add(chapterId);
    }

    final primaryChapterId = currentChapterIds.isNotEmpty ? currentChapterIds.first : null;
    ChapterGroup? primaryGroup;
    if (primaryChapterId != null && value.availableChapterGroups.isNotEmpty) {
      final matches = value.availableChapterGroups.where((g) => g.id == primaryChapterId);
      primaryGroup = matches.isNotEmpty ? matches.first : value.availableChapterGroups.first;
    }

    value = value.copyWith(
      selectedChapterIds: currentChapterIds,
      selectedUnitIds: currentUnitIds,
      chapterId: primaryChapterId,
      chapterName: primaryGroup?.displayName,
    );
  }

  /// Select all available chapter groups
  void selectAllChapters() {
    final allIds = value.availableChapterGroups.map((g) => g.id).toList();
    final firstGroup = value.availableChapterGroups.isNotEmpty ? value.availableChapterGroups.first : null;
    value = value.copyWith(
      selectedChapterIds: allIds,
      chapterId: firstGroup?.id,
      chapterName: firstGroup?.displayName,
    );
  }

  /// Clear all selected chapter groups and unit selections
  void clearChapterSelection() {
    value = value.copyWith(
      selectedChapterIds: const [],
      selectedUnitIds: const [],
      clearChapter: true,
    );
  }

  /// Toggle expand/collapse state for a specific chapter group
  void toggleChapterGroupExpanded(ChapterGroup group) {
    final updatedGroups = value.availableChapterGroups.map((g) {
      if (g.id == group.id) {
        return g.copyWith(isExpanded: !g.isExpanded);
      }
      return g;
    }).toList();

    value = value.copyWith(
      availableChapterGroups: updatedGroups,
    );
  }

  /// Select all units belonging to a specific chapter group without affecting other groups.
  void selectAllUnitsForGroup(ChapterGroup group) {
    final currentSelected = Set<int>.from(value.selectedUnitIds);
    for (final unit in group.units) {
      currentSelected.add(unit.id);
    }

    // Ensure chapter is included in selectedChapterIds
    final currentChapterIds = List<int>.from(value.selectedChapterIds);
    if (!currentChapterIds.contains(group.id)) {
      currentChapterIds.add(group.id);
    }

    value = value.copyWith(
      selectedChapterIds: currentChapterIds,
      selectedUnitIds: currentSelected.toList()..sort(),
    );
  }

  /// Clear units belonging to a specific chapter group without affecting other groups.
  void clearUnitsForGroup(ChapterGroup group) {
    final groupUnitIds = group.units.map((u) => u.id).toSet();
    final currentSelected = List<int>.from(value.selectedUnitIds)
      ..removeWhere((id) => groupUnitIds.contains(id));

    value = value.copyWith(
      selectedUnitIds: currentSelected,
    );
  }

  /// Unit Selection Toggle Handler (Strictly integer unit IDs)
  void toggleUnitSelection(int unitId) {
    final currentSelected = List<int>.from(value.selectedUnitIds);
    if (currentSelected.contains(unitId)) {
      currentSelected.remove(unitId);
    } else {
      currentSelected.add(unitId);
    }

    value = value.copyWith(
      selectedUnitIds: currentSelected,
    );
  }

  /// Select All loaded units across all active chapter groups
  void selectAllUnits() {
    final allIds = value.availableUnits.map((u) => u.id).toList();
    value = value.copyWith(
      selectedUnitIds: allIds,
    );
  }

  /// Clear all selected units across all groups
  void clearUnitSelection() {
    value = value.copyWith(
      selectedUnitIds: const [],
    );
  }

  /// Toggle Unit Accordion Expand/Collapse
  void toggleUnitAccordion() {
    value = value.copyWith(
      isUnitAccordionExpanded: !value.isUnitAccordionExpanded,
    );
  }

  /// Toggle Question Format Selection
  void toggleFormat(String format) {
    final currentFormats = Set<String>.from(value.selectedFormats);
    final currentCounts = Map<String, int>.from(value.formatQuestionCounts);
    final currentMarks = Map<String, int>.from(value.formatMarksEach);

    if (currentFormats.contains(format)) {
      if (currentFormats.length > 1) {
        currentFormats.remove(format);
        currentCounts.remove(format);
        currentMarks.remove(format);
      }
    } else {
      currentFormats.add(format);
      currentCounts[format] = currentCounts[format] ?? kFormatDefaultQuestionCount[format] ?? 1;
      currentMarks[format] = currentMarks[format] ?? kFormatDefaultMarksEach[format] ?? 1;
    }

    final formatLabel = currentFormats.length == 1 ? currentFormats.first : 'Mixed';

    value = value.copyWith(
      selectedFormats: currentFormats,
      formatQuestionCounts: currentCounts,
      formatMarksEach: currentMarks,
      format: formatLabel,
    );
  }

  /// Set question count for specific format (1–20)
  void setFormatQuestionCount(String format, int count) {
    final currentCounts = Map<String, int>.from(value.formatQuestionCounts);
    currentCounts[format] = count.clamp(1, 20);
    value = value.copyWith(formatQuestionCounts: currentCounts);
  }

  /// Set marks each for specific format (1–25)
  void setFormatMarksEach(String format, int marks) {
    final currentMarks = Map<String, int>.from(value.formatMarksEach);
    currentMarks[format] = marks.clamp(1, 25);
    value = value.copyWith(formatMarksEach: currentMarks);
  }

  /// Setters for form parameters
  void setMarks(int marks) {
    value = value.copyWith(marks: marks);
  }

  void setFormat(String format) {
    value = value.copyWith(format: format);
  }

  void setBoard(String board) {
    value = value.copyWith(board: board);
  }

  void setUserPrompt(String prompt) {
    value = value.copyWith(userPrompt: prompt);
  }

  void setAdditionalInstructions(String instructions) {
    value = value.copyWith(additionalInstructions: instructions);
  }

  void setPaperLanguage(String language) {
    value = value.copyWith(paperLanguage: language);
  }

  void setSchoolId(int? schoolId) {
    value = value.copyWith(
      schoolId: schoolId,
      clearSchoolId: schoolId == null,
    );
  }

  void setDifficulty(String difficulty) {
    value = value.copyWith(difficulty: difficulty);
  }

  /// Form Validation
  String? validateForm() {
    if (value.schoolId == null || value.schoolId! <= 0) {
      return 'Enter a valid School ID';
    }
    if (value.subjectId == null) {
      return 'Select a Subject';
    }
    if (value.className == null || value.className!.trim().isEmpty) {
      return 'Enter Class (e.g. 10)';
    }
    if (value.selectedChapterIds.isEmpty && (value.chapterName == null || value.chapterName!.trim().isEmpty)) {
      return 'Select at least one Chapter';
    }
    if (value.marks <= 0) {
      return 'Enter valid Marks';
    }
    if (value.board.trim().isEmpty) {
      return 'Select Board';
    }
// Compute the effective prompt: use custom prompt unless it is the default placeholder.
    final effectivePrompt = (value.userPrompt.trim().isNotEmpty && value.userPrompt != 'Generate standard question paper')
        ? value.userPrompt
        : value.fullGeneratedPrompt;

    // Ensure we have a prompt to send.
    if (effectivePrompt.trim().isEmpty) {
      return 'Please enter a prompt or configure formats for the paper.';
    }
    return null;
  }

  /// Core Generate Action
  Future<bool> generateQuestionPaper() async {
    // Prevent duplicate submission while generation is in progress
    if (value.status == QuestionPaperGeneratorStatus.generating) {
      return false;
    }

    final validationError = validateForm();
    if (validationError != null) {
      value = value.copyWith(
        status: QuestionPaperGeneratorStatus.generationError,
        errorMessage: validationError,
      );
      return false;
    }

    value = value.copyWith(
      status: QuestionPaperGeneratorStatus.generating,
      clearError: true,
      clearGeneratedPaper: true,
    );

    final effectivePrompt = (value.userPrompt.trim().isNotEmpty && value.userPrompt != 'Generate standard question paper')
        ? value.userPrompt
        : value.fullGeneratedPrompt;

    final primaryChapter = (value.chapterName != null && value.chapterName!.isNotEmpty)
        ? value.chapterName!
        : (value.selectedChapterIds.isNotEmpty ? value.selectedChapterIds.first.toString() : '1');

    final request = QuestionPaperGenerationRequest(
      schoolId: value.schoolId,
      subjectId: value.subjectId!,
      className: value.className!,
      chapter: primaryChapter,
      marks: value.marks,
      format: value.format,
      board: value.board,
      userPrompt: effectivePrompt,
      paperLanguage: value.paperLanguage.toLowerCase(),
      unitIds: value.selectedUnitIds.isNotEmpty ? value.selectedUnitIds : null,
      difficulty: value.difficulty.toLowerCase(),
    );

    try {
      final response = await apiService.generatePaper(request);
      if (response.status && response.data != null) {
        value = value.copyWith(
          status: QuestionPaperGeneratorStatus.generatedSuccess,
          generatedPaper: response.data,
        );
        // Refresh paper list history
        loadSavedPapers();
        return true;
      } else {
        value = value.copyWith(
          status: QuestionPaperGeneratorStatus.generationError,
          errorMessage: response.message,
        );
        return false;
      }
    } catch (e) {
      final cleanMsg = e.toString().replaceFirst('Exception: ', '');
      value = value.copyWith(
        status: QuestionPaperGeneratorStatus.generationError,
        errorMessage: cleanMsg,
      );
      return false;
    }
  }
}
