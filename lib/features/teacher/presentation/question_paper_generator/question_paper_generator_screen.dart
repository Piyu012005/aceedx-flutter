// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/storage/session_storage.dart';
import 'data/api_unit_data_source.dart';
import 'data/question_paper_api_service.dart';
import 'data/unit_data_source.dart';
import 'state/question_paper_generator_controller.dart';
import 'state/question_paper_generator_state.dart';
import 'widgets/chapter_multi_selector.dart';
import 'widgets/per_format_config_card.dart';
import 'widgets/prompt_preview_card.dart';
import 'widgets/question_format_selector.dart';
import 'widgets/school_section_card.dart';
import 'widgets/unit_selector.dart';
import '../question_paper_review/question_paper_review_screen.dart';

/// Reconstructed AI Question Paper Generator Screen matching old AceEdx compiled UI and visual specification.
///
/// Features:
/// - School ID & dynamic dropdown loader (GET /api/teacher/dropdown/{school_id})
/// - Cascade context: Board → Subject → Class → Chapter → Units (directly below Chapter)
/// - Interactive Unit multi-selection (strictly numeric `List<int>`) with auto-clear on chapter switch
/// - 27 Question Formats multi-select with per-format question counts (1–20) and marks (1–25)
/// - Real-time auto-generated prompt preview (a2e) + optional additional instructions
/// - POST /api/teacher/generate dispatching exact JSON contract
/// - Formatted paper preview with review modal transition & PDF export
class QuestionPaperGeneratorScreen extends StatefulWidget {
  final UnitDataSource? unitDataSource;
  final QuestionPaperApiService? apiService;
  final QuestionPaperGeneratorController? controller;
  final SessionStorage? sessionStorage;

  const QuestionPaperGeneratorScreen({
    super.key,
    this.unitDataSource,
    this.apiService,
    this.controller,
    this.sessionStorage,
  });

  @override
  State<QuestionPaperGeneratorScreen> createState() =>
      _QuestionPaperGeneratorScreenState();
}

class _QuestionPaperGeneratorScreenState
    extends State<QuestionPaperGeneratorScreen> {
  late final QuestionPaperGeneratorController _controller;
  late final bool _ownsController;

  final TextEditingController _schoolIdController = TextEditingController();
  final TextEditingController _chapterController = TextEditingController();
  final TextEditingController _marksController = TextEditingController(text: '50');
  final TextEditingController _additionalInstructionsController = TextEditingController();

  final List<String> _languages = [
    'English',
    'Hindi',
    'Marathi',
    'Sanskrit',
    'Gujarati',
  ];

  final List<String> _difficulties = [
    'Easy',
    'Medium',
    'Difficult',
  ];

  @override
  void initState() {
    super.initState();

    if (widget.controller != null) {
      _controller = widget.controller!;
      _ownsController = false;
    } else {
      final apiClient = ApiClient();
      final unitSource = widget.unitDataSource ?? ApiUnitDataSource(apiClient: apiClient);
      final paperService = widget.apiService ?? QuestionPaperApiService(apiClient: apiClient);

      _controller = QuestionPaperGeneratorController(
        unitDataSource: unitSource,
        apiService: paperService,
      );
      _ownsController = true;
    }

    _schoolIdController.text = _controller.value.schoolId?.toString() ?? '1';
    _chapterController.text = _controller.value.chapterName ?? '';
    _marksController.text = _controller.value.marks.toString();
    _additionalInstructionsController.text = _controller.value.additionalInstructions;

    // Synchronize text listeners
    _schoolIdController.addListener(() {
      final parsed = int.tryParse(_schoolIdController.text);
      if (parsed != null && parsed != _controller.value.schoolId) {
        _controller.setSchoolId(parsed);
      }
    });

    _chapterController.addListener(() {
      final text = _chapterController.text.trim();
      if (text.isNotEmpty && text != _controller.value.chapterName) {
        _controller.selectChapter(id: 1, name: text);
      }
    });

    _marksController.addListener(() {
      final marks = int.tryParse(_marksController.text);
      if (marks != null && marks > 0 && marks != _controller.value.marks) {
        _controller.setMarks(marks);
      }
    });

    _additionalInstructionsController.addListener(() {
      _controller.setAdditionalInstructions(_additionalInstructionsController.text);
    });
  }

  bool _scopeConfigured = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_scopeConfigured) {
      if (_ownsController && widget.unitDataSource == null && widget.apiService == null) {
        final storage = widget.sessionStorage;
        final apiClient = ApiClient(sessionStorage: storage);
        final unitSource = ApiUnitDataSource(
          apiClient: apiClient,
          sessionStorage: storage,
        );
        final paperService = QuestionPaperApiService(apiClient: apiClient);

        _controller.updateDataSources(
          unitDataSource: unitSource,
          apiService: paperService,
        );

        final userSchoolId = storage?.getSchoolId();
        if (userSchoolId != null && userSchoolId > 0) {
          _schoolIdController.text = userSchoolId.toString();
          _controller.setSchoolId(userSchoolId);
          _controller.loadDropdownData(userSchoolId);
        }
        _controller.loadSchoolInfo();
        _controller.loadSavedPapers();
        _scopeConfigured = true;
      }
    }
  }

  @override
  void dispose() {
    _schoolIdController.dispose();
    _chapterController.dispose();
    _marksController.dispose();
    _additionalInstructionsController.dispose();
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onLoadDropdownData() {
    final schoolId = int.tryParse(_schoolIdController.text);
    if (schoolId != null && schoolId > 0) {
      _controller.loadDropdownData(schoolId);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid School ID')),
      );
    }
  }

  void _onSubjectChanged(int? newSubjectId) {
    if (newSubjectId != null) {
      final subjectObj = _controller.value.availableSubjects.firstWhere(
        (s) => s.id == newSubjectId,
        orElse: () => _controller.value.availableSubjects.first,
      );
      _chapterController.text = '';
      _controller.selectSubject(
        id: subjectObj.id,
        name: subjectObj.name,
      );
    }
  }

  void _onClassChanged(String? newClass) {
    if (newClass != null) {
      _chapterController.text = '';
      _controller.selectClass(newClass);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Question Paper Generator'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/teacher-dashboard');
            }
          },
        ),
      ),
      backgroundColor: AppColors.background,
      body: ValueListenableBuilder<QuestionPaperGeneratorState>(
        valueListenable: _controller,
        builder: (context, state, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 24.0,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 860),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. School Section Card
                    SchoolSectionCard(
                      schoolIdController: _schoolIdController,
                      schoolName: state.schoolName,
                      isLoading: state.isLoadingDropdowns,
                      onLoadDropdownPressed: _onLoadDropdownData,
                    ),
                    const SizedBox(height: 18),

                    // Error Banner
                    if (state.errorMessage != null &&
                        state.status != QuestionPaperGeneratorStatus.unitsError) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFFCA5A5)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                state.errorMessage!,
                                style: const TextStyle(
                                  color: Color(0xFF991B1B),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],

                    // Success Banner (Generated Paper Card)
                    if (state.status == QuestionPaperGeneratorStatus.generatedSuccess &&
                        state.generatedPaper != null) ...[
                      _buildGeneratedSuccessCard(state.generatedPaper!),
                      const SizedBox(height: 18),
                    ],

                    // 2. Main Generator Form Card
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(26.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Generate',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Configure Board, Subject, Class, Chapter & subtopic Units to generate paper.',
                              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                            ),
                            const SizedBox(height: 22),

                            // Row 1: Board
                            _buildSectionHeader('Board *'),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              isExpanded: true,
                              value: state.availableBoards.any((b) => b.name == state.board)
                                  ? state.board
                                  : (state.availableBoards.isNotEmpty
                                      ? state.availableBoards.first.name
                                      : 'CBSE'),
                              decoration: _inputDecoration(Icons.account_balance_outlined),
                              items: state.availableBoards.map((b) {
                                return DropdownMenuItem<String>(
                                  value: b.name,
                                  child: Text(b.name),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) _controller.setBoard(val);
                              },
                            ),
                            const SizedBox(height: 18),

                            // Row 2: Subject
                            _buildSectionHeader('1. Subject *'),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<int>(
                              isExpanded: true,
                              value: state.availableSubjects.any((s) => s.id == state.subjectId)
                                  ? state.subjectId
                                  : (state.availableSubjects.isNotEmpty
                                      ? state.availableSubjects.first.id
                                      : null),
                              decoration: _inputDecoration(Icons.menu_book_outlined),
                              hint: const Text('Select Subject'),
                              items: state.availableSubjects.map((s) {
                                return DropdownMenuItem<int>(
                                  value: s.id,
                                  child: Text(s.name),
                                );
                              }).toList(),
                              onChanged: _onSubjectChanged,
                            ),
                            const SizedBox(height: 18),

                            // Row 3: Class
                            _buildSectionHeader('2. Class *'),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              isExpanded: true,
                              value: state.availableClasses.contains(state.className)
                                  ? state.className
                                  : (state.availableClasses.isNotEmpty
                                      ? state.availableClasses.first
                                      : '10'),
                              decoration: _inputDecoration(Icons.grade_outlined),
                              hint: const Text('Select Class'),
                              items: state.availableClasses.map((c) {
                                return DropdownMenuItem<String>(
                                  value: c,
                                  child: Text('Class $c'),
                                );
                              }).toList(),
                              onChanged: _onClassChanged,
                            ),
                            const SizedBox(height: 18),

                            // Row 4: Chapters / Units (Multi-Select)
                            _buildSectionHeader('3. Chapter *'),
                            const SizedBox(height: 6),
                            ChapterMultiSelector(
                              chapterGroups: state.availableChapterGroups,
                              selectedChapterIds: state.selectedChapterIds,
                              selectedUnitIds: state.selectedUnitIds.toSet(),
                              isLoading: state.isLoadingChapters,
                              errorMessage: state.chaptersError,
                              onToggleChapter: _controller.toggleChapterSelection,
                              onSelectAllChapters: _controller.selectAllChapters,
                              onClearAllChapters: _controller.clearChapterSelection,
                            ),
                            const SizedBox(height: 14),

                            // Row 5: UNIT CHECKBOX GROUPS (DIRECTLY BELOW CHAPTER SELECTOR)
                            UnitSelector(
                              selectedChapterGroups: state.selectedChapterGroups,
                              selectedUnitIds: state.selectedUnitIds.toSet(),
                              isLoading: state.status == QuestionPaperGeneratorStatus.loadingUnits,
                              errorMessage: state.status == QuestionPaperGeneratorStatus.unitsError
                                  ? state.errorMessage
                                  : null,
                              onToggleGroupExpanded: _controller.toggleChapterGroupExpanded,
                              onToggleUnit: (unit) => _controller.toggleUnitSelection(unit.id),
                              onSelectAllGroupUnits: _controller.selectAllUnitsForGroup,
                              onClearGroupUnits: _controller.clearUnitsForGroup,
                            ),
                            const SizedBox(height: 20),

                            // Row 6: Marks & Language (Paired)
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildSectionHeader('Marks *'),
                                      const SizedBox(height: 6),
                                      TextField(
                                        controller: _marksController,
                                        keyboardType: TextInputType.number,
                                        decoration: _inputDecoration(Icons.score_outlined),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildSectionHeader('Paper Language'),
                                      const SizedBox(height: 6),
                                      DropdownButtonFormField<String>(
                                        isExpanded: true,
                                        value: _languages.contains(state.paperLanguage)
                                            ? state.paperLanguage
                                            : 'English',
                                        decoration: _inputDecoration(Icons.language_outlined),
                                        items: _languages.map((l) {
                                          return DropdownMenuItem<String>(
                                            value: l,
                                            child: Text(l),
                                          );
                                        }).toList(),
                                        onChanged: (val) {
                                          if (val != null) _controller.setPaperLanguage(val);
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),

                            // Row 7: Difficulty
                            _buildSectionHeader('Difficulty'),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              isExpanded: true,
                              value: _difficulties.contains(state.difficulty)
                                  ? state.difficulty
                                  : 'Easy',
                              decoration: _inputDecoration(Icons.speed_outlined),
                              items: _difficulties.map((d) {
                                return DropdownMenuItem<String>(
                                  value: d,
                                  child: Text(d),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) _controller.setDifficulty(val);
                              },
                            ),
                            const SizedBox(height: 20),

                            // Row 8: Question Formats (27 Multi-Select)
                            _buildSectionHeader('Format *'),
                            const SizedBox(height: 6),
                            QuestionFormatSelector(
                              selectedFormats: state.selectedFormats,
                              onToggleFormat: _controller.toggleFormat,
                            ),
                            const SizedBox(height: 16),

                            // Row 9: Per-Format Configuration (Questions 1–20, Marks 1–25)
                            PerFormatConfigCard(
                              selectedFormats: state.selectedFormats,
                              formatQuestionCounts: state.formatQuestionCounts,
                              formatMarksEach: state.formatMarksEach,
                              onQuestionCountChanged: _controller.setFormatQuestionCount,
                              onMarksEachChanged: _controller.setFormatMarksEach,
                            ),
                            const SizedBox(height: 16),

                            // Row 10: Automatic Prompt Preview & Instructions
                            _buildSectionHeader('Instructions / Prompt *'),
                            const SizedBox(height: 6),
                            PromptPreviewCard(
                              previewContent: state.computedPromptPreview,
                            ),
                            const SizedBox(height: 18),

                            // Row 11: Additional Instructions
                            _buildSectionHeader('Additional instructions (optional)'),
                            const SizedBox(height: 4),
                            const Text(
                              'Extra guidance for tone, syllabus focus, diagrams, marking scheme, etc. Appended after format block.',
                              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _additionalInstructionsController,
                              maxLines: 4,
                              decoration: InputDecoration(
                                hintText: 'Enter specific teacher guidance or focus topics…',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                                ),
                              ),
                            ),
                            const SizedBox(height: 28),

                            // Row 12: Generate Action Button
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton.icon(
                                onPressed: state.status == QuestionPaperGeneratorStatus.generating
                                    ? null
                                    : () => _controller.generateQuestionPaper(),
                                icon: state.status == QuestionPaperGeneratorStatus.generating
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.auto_awesome),
                                label: Text(
                                  state.status == QuestionPaperGeneratorStatus.generating
                                      ? 'Generating Question Paper...'
                                      : (state.selectedUnitIds.isNotEmpty
                                          ? 'Generate Paper (${state.selectedUnitIds.length} Unit(s) Selected)'
                                          : 'Generate Question Paper'),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGeneratedSuccessCard(dynamic generatedPaper) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF86EFAC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Question Paper Generated Successfully! (ID: ${generatedPaper.id})',
                  style: const TextStyle(
                    color: Color(0xFF15803D),
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Format: ${generatedPaper.format ?? _controller.value.format} | '
            'Marks: ${generatedPaper.marks ?? _controller.value.marks} | '
            'Language: ${generatedPaper.paperLanguage ?? _controller.value.paperLanguage}',
            style: const TextStyle(color: Color(0xFF166534), fontSize: 13),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => QuestionPaperReviewScreen(
                    paperId: generatedPaper.id,
                    apiService: _controller.apiService,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.visibility),
            label: const Text('Review Generated Paper'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Color(0xFF334155),
      ),
    );
  }

  InputDecoration _inputDecoration(IconData prefixIcon) {
    return InputDecoration(
      prefixIcon: Icon(prefixIcon, color: const Color(0xFF64748B), size: 20),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
      ),
    );
  }
}
