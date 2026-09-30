import 'package:flutter/foundation.dart';
import '../../../../../core/constants/api_timeouts.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../../core/network/api_exception.dart';
import '../../../../../models/unit.dart';
import '../models/chapter.dart';
import '../models/question_paper.dart';
import '../models/question_paper_generation_request.dart';
import '../models/question_paper_generation_response.dart';

/// Service responsible for calling the Laravel backend Question Paper APIs.
class QuestionPaperApiService {
  final ApiClient apiClient;

  QuestionPaperApiService({
    required this.apiClient,
  });

  /// Dispatches POST /api/teacher/generate request to the backend.
  Future<QuestionPaperGenerationResponse> generatePaper(
    QuestionPaperGenerationRequest request,
  ) async {
    try {
      final responseData = await apiClient.post(
        '/teacher/generate',
        body: request.toJson(),
        requiresAuth: true,
        timeout: ApiTimeouts.aiGeneration,
      );

      if (responseData is Map<String, dynamic>) {
        if (responseData['status'] == false) {
          final msg = responseData['message'] as String? ?? 'Question paper generation failed';
          throw ApiException(
            message: msg,
            statusCode: 400,
            data: responseData,
          );
        }
        return QuestionPaperGenerationResponse.fromJson(responseData);
      }

      throw const ApiException(
        message: 'Invalid response format received from server',
      );
    } on UnauthorizedException {
      rethrow;
    } on NetworkException {
      rethrow;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Unexpected error during paper generation: ${e.toString()}',
      );
    }
  }

  /// Fetches full question paper details via GET /api/teacher/paper/{id}.
  Future<QuestionPaper> getPaperById(int id) async {
    try {
      final responseData = await apiClient.get(
        '/teacher/paper/$id',
        requiresAuth: true,
      );

      if (responseData is Map<String, dynamic>) {
        if (responseData['status'] == false) {
          final msg = responseData['message'] as String? ?? 'Question paper not found';
          throw ApiException(
            message: msg,
            statusCode: 404,
            data: responseData,
          );
        }

        final data = responseData['data'];
        if (data is Map<String, dynamic>) {
          return QuestionPaper.fromJson(data);
        }
      }

      throw const ApiException(
        message: 'Invalid response structure received for paper retrieval',
      );
    } on UnauthorizedException {
      rethrow;
    } on NetworkException {
      rethrow;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Unexpected error while retrieving paper: ${e.toString()}',
      );
    }
  }

  /// Fetches a list of question papers via GET /api/teacher/papers.
  Future<List<QuestionPaper>> getPapers({
    int? subjectId,
    String? className,
    String? status,
  }) async {
    final queryParams = <String, dynamic>{};
    if (subjectId != null) queryParams['subject_id'] = subjectId.toString();
    if (className != null && className.isNotEmpty) queryParams['class'] = className;
    if (status != null && status.isNotEmpty) queryParams['status'] = status;

    try {
      final responseData = await apiClient.get(
        '/teacher/papers',
        queryParameters: queryParams,
        requiresAuth: true,
      );

      if (responseData is Map<String, dynamic>) {
        if (responseData['status'] == false) {
          final msg = responseData['message'] as String? ?? 'Failed to load papers';
          throw ApiException(
            message: msg,
            statusCode: 400,
            data: responseData,
          );
        }

        final data = responseData['data'];
        List<dynamic> rawList = [];

        if (data is List) {
          rawList = data;
        } else if (data is Map<String, dynamic> && data['data'] is List) {
          // Paginated Laravel response structure
          rawList = data['data'] as List;
        }

        return rawList
            .whereType<Map<String, dynamic>>()
            .map((item) => QuestionPaper.fromJson(item))
            .toList();
      }

      return [];
    } on UnauthorizedException {
      rethrow;
    } on NetworkException {
      rethrow;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Unexpected error while fetching paper list: ${e.toString()}',
      );
    }
  }

  /// Exports question paper PDF via POST /api/teacher/paper/export/{id}.
  Future<QuestionPaperExportResponse> exportPaperPdf(
    int id, {
    String type = 'pdf',
  }) async {
    try {
      final responseData = await apiClient.post(
        '/teacher/paper/export/$id',
        body: {'type': type},
        requiresAuth: true,
      );

      if (responseData is Map<String, dynamic>) {
        if (responseData['status'] == false) {
          final msg = responseData['message'] as String? ?? 'Export failed';
          throw ApiException(
            message: msg,
            statusCode: 400,
            data: responseData,
          );
        }
        return QuestionPaperExportResponse.fromJson(responseData);
      }

      throw const ApiException(
        message: 'Invalid response format received from export endpoint',
      );
    } on UnauthorizedException {
      rethrow;
    } on NetworkException {
      rethrow;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Unexpected error during paper export: ${e.toString()}',
      );
    }
  }

  /// Exports answer key PDF via POST /api/paper/export-anskey/{id}.
  Future<QuestionPaperExportResponse> exportAnswerKeyPdf(
    int id, {
    String type = 'pdf',
    bool includeAnswers = true,
  }) async {
    try {
      final responseData = await apiClient.post(
        '/paper/export-anskey/$id',
        body: {
          'type': type,
          'include_answers': includeAnswers,
        },
        requiresAuth: true,
      );

      if (responseData is Map<String, dynamic>) {
        if (responseData['status'] == false) {
          final msg = responseData['message'] as String? ?? 'Answer key export failed';
          throw ApiException(
            message: msg,
            statusCode: 400,
            data: responseData,
          );
        }
        return QuestionPaperExportResponse.fromJson(responseData);
      }

      throw const ApiException(
        message: 'Invalid response format received from answer key export endpoint',
      );
    } on UnauthorizedException {
      rethrow;
    } on NetworkException {
      rethrow;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Unexpected error during answer key export: ${e.toString()}',
      );
    }
  }

  /// Fetches real structured chapters via GET /api/teacher/units/by-context?subject_id={subject_id}&class={class}&school_id={school_id}.
  Future<List<Chapter>> getChaptersByContext({
    required int subjectId,
    required String className,
    int? schoolId,
    String? schoolName,
  }) async {
    final queryParams = <String, dynamic>{
      'subject_id': subjectId.toString(),
      'class': className,
    };
    if (schoolId != null) {
      queryParams['school_id'] = schoolId.toString();
    }

    final userId = apiClient.sessionStorage?.getUserId();
    final teacherId = apiClient.sessionStorage?.getTeacherId();
    final effectiveSchoolId = schoolId ?? apiClient.sessionStorage?.getSchoolId();

    debugPrint('========================================================');
    debugPrint('[QPG FORENSIC DEBUG] Chapter Retrieval Request:');
    debugPrint('  Authenticated User ID: $userId');
    debugPrint('  Teacher ID: $teacherId');
    debugPrint('  School ID: $effectiveSchoolId');
    debugPrint('  Selected Subject ID: $subjectId');
    debugPrint('  Selected Class: $className');
    debugPrint('  Exact URL: /teacher/units/by-context?subject_id=$subjectId&class=$className${schoolId != null ? "&school_id=$schoolId" : ""}');

    try {
      final responseData = await apiClient.get(
        '/teacher/units/by-context',
        queryParameters: queryParams,
        requiresAuth: true,
      );

      debugPrint('[QPG FORENSIC DEBUG] Chapter Retrieval Response:');
      debugPrint('  HTTP Status: 200 (Success)');
      debugPrint('  Full Response JSON: $responseData');

      if (responseData is Map<String, dynamic>) {
        if (responseData['status'] == false) {
          debugPrint('  Status: false - ${responseData['message']}');
          debugPrint('========================================================');
          return [];
        }

        final data = responseData['data'];
        if (data is List) {
          final unitsList = data
              .whereType<Map<String, dynamic>>()
              .map((item) => Unit.fromJson(item))
              .toList();

          final textbookIds = unitsList.map((u) => u.textbookId).whereType<int>().toSet().toList();
          final chapterIds = unitsList.map((u) => u.textbookChapterId).whereType<int>().toSet().toList();

          // Group units by textbook_chapter_id to construct actual Chapter records
          final Map<int, List<Unit>> unitsByChapter = {};
          for (final unit in unitsList) {
            final chId = unit.textbookChapterId ?? 0;
            if (chId > 0) {
              unitsByChapter.putIfAbsent(chId, () => []).add(unit);
            }
          }

          final List<Chapter> chapters = [];
          unitsByChapter.forEach((chId, units) {
            final firstUnit = units.first;
            String chNum = '';
            final uNumStr = firstUnit.unitNumber?.toString() ?? '';
            if (uNumStr.contains('.')) {
              chNum = uNumStr.split('.').first.trim();
            } else if (uNumStr.isNotEmpty) {
              chNum = uNumStr;
            }

            chapters.add(
              Chapter(
                id: chId,
                textbookId: firstUnit.textbookId,
                chapterNumber: chNum.isNotEmpty ? chNum : chId.toString(),
                title: chNum.isNotEmpty ? 'Chapter $chNum' : 'Chapter $chId',
                schoolId: effectiveSchoolId,
                subjectId: subjectId,
                className: className,
              ),
            );
          });

          debugPrint('  Textbook IDs Found: $textbookIds');
          debugPrint('  Textbook Chapter IDs Found: $chapterIds');
          debugPrint('  Chapter Names Found: ${chapters.map((c) => c.displayName).toList()}');
          debugPrint('========================================================');

          return chapters;
        }
      }

      debugPrint('========================================================');
      return [];
    } on UnauthorizedException {
      rethrow;
    } on NetworkException {
      rethrow;
    } on ApiException catch (e) {
      debugPrint('[QPG FORENSIC DEBUG] Chapter Retrieval Error:');
      debugPrint('  Status Code: ${e.statusCode}');
      debugPrint('  Message: ${e.message}');
      debugPrint('========================================================');
      if (e.statusCode == 404) {
        return [];
      }
      rethrow;
    } catch (e) {
      debugPrint('[QPG FORENSIC DEBUG] Chapter Retrieval Unexpected Exception: $e');
      debugPrint('========================================================');
      throw ApiException(
        message: 'Unexpected error while fetching chapters: ${e.toString()}',
      );
    }
  }

  /// Backward-compatible chapter name list fetcher.
  Future<List<String>> getTextbookChapters({
    required int subjectId,
    required String className,
    int? schoolId,
    String? schoolName,
  }) async {
    final chapters = await getChaptersByContext(
      subjectId: subjectId,
      className: className,
      schoolId: schoolId,
      schoolName: schoolName,
    );
    return chapters.map((c) => c.displayName).toList();
  }

  /// Fetches dropdown options (boards, subjects, classes) via GET /api/teacher/dropdown/{school_id}.
  Future<Map<String, dynamic>> getDropdownData(int schoolId) async {
    try {
      final responseData = await apiClient.get(
        '/teacher/dropdown/$schoolId',
        requiresAuth: true,
      );

      if (responseData is Map<String, dynamic>) {
        if (responseData['status'] == false) {
          final msg = responseData['message'] as String? ?? 'Failed to load dropdown data';
          throw ApiException(
            message: msg,
            statusCode: 400,
            data: responseData,
          );
        }
        final data = responseData['data'];
        if (data is Map<String, dynamic>) {
          return data;
        }
      }
      return {};
    } on UnauthorizedException {
      rethrow;
    } on NetworkException {
      rethrow;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Unexpected error while loading dropdown data: ${e.toString()}',
      );
    }
  }

  /// Fetches school info for authenticated teacher via GET /api/teacher/school-info.
  Future<String?> getSchoolInfo() async {
    try {
      final responseData = await apiClient.get(
        '/teacher/school-info',
        requiresAuth: true,
      );

      if (responseData is Map<String, dynamic>) {
        final data = responseData['data'];
        if (data is Map<String, dynamic>) {
          return (data['name'] ?? data['school_name'] ?? data['schoolName'])?.toString();
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Deletes a question paper via DELETE /api/teacher/paper/{id}.
  Future<bool> deletePaper(int id) async {
    try {
      final responseData = await apiClient.delete(
        '/teacher/paper/$id',
        requiresAuth: true,
      );

      if (responseData is Map<String, dynamic>) {
        return responseData['status'] == true;
      }
      return true;
    } on UnauthorizedException {
      rethrow;
    } on NetworkException {
      rethrow;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Unexpected error while deleting paper: ${e.toString()}',
      );
    }
  }
}
