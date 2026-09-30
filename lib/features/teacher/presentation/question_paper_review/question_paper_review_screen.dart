import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/url_opener.dart';
import '../question_paper_generator/data/question_paper_api_service.dart';
import '../question_paper_generator/models/question_paper.dart';

/// Screen for reviewing generated Question Papers, viewing sections/questions,
/// viewing answer keys, and triggering PDF export calls.
class QuestionPaperReviewScreen extends StatefulWidget {
  final int? paperId;
  final QuestionPaper? initialPaper;
  final QuestionPaperApiService? apiService;

  const QuestionPaperReviewScreen({
    super.key,
    this.paperId,
    this.initialPaper,
    this.apiService,
  });

  @override
  State<QuestionPaperReviewScreen> createState() =>
      _QuestionPaperReviewScreenState();
}

class _QuestionPaperReviewScreenState extends State<QuestionPaperReviewScreen>
    with SingleTickerProviderStateMixin {
  late final QuestionPaperApiService _apiService;
  late TabController _tabController;

  QuestionPaper? _paper;
  bool _isLoading = false;
  String? _errorMessage;

  bool _isExportingPdf = false;
  bool _isExportingAnsKey = false;
  String? _exportedPdfUrl;
  String? _exportedAnsKeyUrl;
  String? _exportErrorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _apiService = widget.apiService ?? QuestionPaperApiService(apiClient: ApiClient());

    if (widget.initialPaper != null) {
      _paper = widget.initialPaper;
    } else if (widget.paperId != null) {
      _fetchPaper(widget.paperId!);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchPaper(int id) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final paper = await _apiService.getPaperById(id);
      if (mounted) {
        setState(() {
          _paper = paper;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  Future<void> _exportPaperPdf() async {
    if (_paper == null) return;
    setState(() {
      _isExportingPdf = true;
      _exportErrorMessage = null;
    });

    try {
      final response = await _apiService.exportPaperPdf(_paper!.id, type: 'pdf');
      if (mounted) {
        setState(() {
          _isExportingPdf = false;
          _exportedPdfUrl = response.fileUrl;
        });
        final url = response.fileUrl;
        if (url != null && url.isNotEmpty) {
          openUrlInNewTab(url);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isExportingPdf = false;
          _exportErrorMessage = 'PDF Export Failed: ${e.toString().replaceFirst('Exception: ', '')}';
        });
      }
    }
  }

  Future<void> _exportAnswerKeyPdf() async {
    if (_paper == null) return;
    setState(() {
      _isExportingAnsKey = true;
      _exportErrorMessage = null;
    });

    try {
      final response = await _apiService.exportAnswerKeyPdf(_paper!.id, type: 'pdf');
      if (mounted) {
        setState(() {
          _isExportingAnsKey = false;
          _exportedAnsKeyUrl = response.fileUrl;
        });
        final url = response.fileUrl;
        if (url != null && url.isNotEmpty) {
          openUrlInNewTab(url);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isExportingAnsKey = false;
          _exportErrorMessage = 'Answer Key Export Failed: ${e.toString().replaceFirst('Exception: ', '')}';
        });
      }
    }
  }

  void _handleBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      final router = GoRouter.maybeOf(context);
      if (router != null) {
        router.go(
          '${AppRoutes.teacherDashboard}?tab=${Uri.encodeComponent('AI Question Paper Generator')}',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_paper != null ? 'Paper Review (ID: ${_paper!.id})' : 'Question Paper Review'),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _handleBack,
        ),
        bottom: _paper != null
            ? TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                tabs: const [
                  Tab(icon: Icon(Icons.description), text: 'Question Paper'),
                  Tab(icon: Icon(Icons.fact_check), text: 'Answer Key'),
                ],
              )
            : null,
      ),
      backgroundColor: const Color(0xFFF8FAFC),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Loading Question Paper Details...',
                    style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Color(0xFFDC2626)),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          style: const TextStyle(fontSize: 16, color: Color(0xFF991B1B)),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: widget.paperId != null ? () => _fetchPaper(widget.paperId!) : null,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : _paper == null
                  ? const Center(child: Text('No paper details available.'))
                  : Column(
                      children: [
                        // Metadata & Export Header Card
                        _buildHeaderCard(),

                        // Error or Export Link Banners
                        if (_exportErrorMessage != null) ...[
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFFCA5A5)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error, color: Color(0xFFDC2626), size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _exportErrorMessage!,
                                    style: const TextStyle(color: Color(0xFF991B1B), fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        if (_exportedPdfUrl != null) ...[
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFF86EFAC)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'PDF Generated: $_exportedPdfUrl',
                                    style: const TextStyle(color: Color(0xFF15803D), fontSize: 13),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: () => openUrlInNewTab(_exportedPdfUrl!),
                                  icon: const Icon(Icons.open_in_new, size: 16, color: Color(0xFF15803D)),
                                  label: const Text('Open', style: TextStyle(color: Color(0xFF15803D), fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ),
                        ],

                        if (_exportedAnsKeyUrl != null) ...[
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFF86EFAC)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Answer Key Generated: $_exportedAnsKeyUrl',
                                    style: const TextStyle(color: Color(0xFF15803D), fontSize: 13),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: () => openUrlInNewTab(_exportedAnsKeyUrl!),
                                  icon: const Icon(Icons.open_in_new, size: 16, color: Color(0xFF15803D)),
                                  label: const Text('Open', style: TextStyle(color: Color(0xFF15803D), fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // Main Content View
                        Expanded(
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              _buildQuestionsView(),
                              _buildAnswerKeyView(),
                            ],
                          ),
                        ),
                      ],
                    ),
    );
  }

  Widget _buildHeaderCard() {
    final p = _paper!;
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.schoolName ?? 'AceEdx School',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${p.subjectName ?? 'Subject'} | Class ${p.className ?? '-'} | ${p.chapterName ?? ''}',
                      style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(p.status),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _buildChip(Icons.score, '${p.marks ?? 0} Marks'),
              _buildChip(Icons.format_list_bulleted, 'Format: ${p.format ?? "standard"}'),
              _buildChip(Icons.language, 'Language: ${p.paperLanguage ?? "english"}'),
              if (p.board != null) _buildChip(Icons.account_balance, 'Board: ${p.board}'),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isExportingPdf ? null : _exportPaperPdf,
                  icon: _isExportingPdf
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.picture_as_pdf),
                  label: Text(_isExportingPdf ? 'Exporting PDF...' : 'Export Question Paper PDF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isExportingAnsKey ? null : _exportAnswerKeyPdf,
                  icon: _isExportingAnsKey
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.fact_check_outlined),
                  label: Text(_isExportingAnsKey ? 'Exporting...' : 'Export Answer Key PDF'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color fg;
    switch (status.toLowerCase()) {
      case 'approved':
        bg = const Color(0xFFDCFCE7);
        fg = const Color(0xFF15803D);
        break;
      case 'rejected':
      case 'failed':
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFFB91C1C);
        break;
      default:
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFB45309);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF475569)),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF334155), fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildQuestionsView() {
    final p = _paper!;
    if (p.sections != null && p.sections!.isNotEmpty) {
      return ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: p.sections!.length,
        itemBuilder: (context, index) {
          final section = p.sections![index];
          return Card(
            margin: const EdgeInsets.only(bottom: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    section.title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                  ),
                  const Divider(height: 24),
                  ...section.questions.map((q) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (q.number.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              margin: const EdgeInsets.only(right: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                q.number,
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2563EB), fontSize: 13),
                              ),
                            ),
                          Expanded(
                            child: Text(
                              q.text,
                              style: const TextStyle(fontSize: 14, height: 1.5, color: Color(0xFF1E293B)),
                            ),
                          ),
                          if (q.marks != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              q.marks!,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                            ),
                          ],
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          );
        },
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SelectableText(
            p.questionsText ?? 'No question content available.',
            style: const TextStyle(fontSize: 14, height: 1.6, color: Color(0xFF0F172A)),
          ),
        ),
      ),
    );
  }

  Widget _buildAnswerKeyView() {
    final p = _paper!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SelectableText(
            p.answerKeyText ?? 'Answer key not available for this question paper.',
            style: const TextStyle(fontSize: 14, height: 1.6, color: Color(0xFF0F172A)),
          ),
        ),
      ),
    );
  }
}
