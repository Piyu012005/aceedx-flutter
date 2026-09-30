import 'package:flutter/foundation.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../../core/network/api_exception.dart';
import '../../../../../core/storage/session_storage.dart';
import '../../../../../models/unit.dart';
import 'unit_data_source.dart';

/// Real API implementation of [UnitDataSource] consuming the Laravel backend.
///
/// Calls `GET /api/teacher/units/by-context` with required context query parameters.
class ApiUnitDataSource implements UnitDataSource {
  final ApiClient apiClient;
  final SessionStorage? sessionStorage;

  ApiUnitDataSource({
    required this.apiClient,
    this.sessionStorage,
  });

  @override
  Future<List<Unit>> getUnitsByContext({
    required int chapterId,
    String? chapterName,
    int? textbookId,
    String? subject,
    String? className,
    int? schoolId,
  }) async {
    // If SessionStorage is attached, ensure a valid user token is available
    if (sessionStorage != null) {
      final token = sessionStorage!.getToken();
      if (token == null || token.trim().isEmpty) {
        throw const UnauthorizedException(
          message: 'Your session has expired. Please log in again.',
          statusCode: 401,
        );
      }
    }

    final effectiveSchoolId = schoolId ?? sessionStorage?.getSchoolId();

    final queryParams = <String, dynamic>{};
    if (subject != null && subject.isNotEmpty) {
      queryParams['subject_id'] = subject;
    }
    if (className != null && className.isNotEmpty) {
      queryParams['class'] = className;
    }
    // Pass real database chapter ID first, or chapterName string
    final chParam = (chapterId > 0)
        ? chapterId.toString()
        : (chapterName != null && chapterName.trim().isNotEmpty ? chapterName.trim() : null);

    if (chParam != null) {
      queryParams['chapter'] = chParam;
    }
    if (effectiveSchoolId != null) {
      queryParams['school_id'] = effectiveSchoolId.toString();
    }

    debugPrint('========================================================');
    debugPrint('[QPG FORENSIC DEBUG] Unit Retrieval Request:');
    debugPrint('  Chapter ID: $chapterId');
    debugPrint('  Chapter Name: $chapterName');
    debugPrint('  Query Chapter Param: $chParam');
    debugPrint('  Subject ID: $subject');
    debugPrint('  Class: $className');
    debugPrint('  School ID: $effectiveSchoolId');
    debugPrint('  Exact URL: /teacher/units/by-context?subject_id=$subject&class=$className${chParam != null ? "&chapter=$chParam" : ""}${effectiveSchoolId != null ? "&school_id=$effectiveSchoolId" : ""}');

    try {
      final responseData = await apiClient.get(
        '/teacher/units/by-context',
        queryParameters: queryParams,
        requiresAuth: true,
      );

      debugPrint('[QPG FORENSIC DEBUG] Unit Retrieval Response:');
      debugPrint('  HTTP Status: 200 (Success)');
      debugPrint('  Full Response JSON: $responseData');

      final List<dynamic> listData;
      if (responseData is Map<String, dynamic>) {
        if (responseData['status'] == false) {
          final msg = responseData['message'] as String? ?? 'Failed to load Units';
          debugPrint('  Status: false - $msg');
          debugPrint('========================================================');
          throw ApiException(
            message: msg,
            statusCode: 400,
            data: responseData,
          );
        }
        final data = responseData['data'];
        if (data is List) {
          listData = data;
        } else {
          listData = [];
        }
      } else if (responseData is List) {
        listData = responseData;
      } else {
        listData = [];
      }

      final units = listData
          .whereType<Map<String, dynamic>>()
          .map((item) => Unit.fromJson(item))
          .toList();

      debugPrint('  Units Count Returned: ${units.length}');
      for (final u in units) {
        debugPrint('    - Unit ID: ${u.id} | Num: ${u.unitNumber} | Name: "${u.unitName}" | ChapterId: ${u.textbookChapterId}');
      }
      debugPrint('========================================================');

      return units;
    } on UnauthorizedException {
      rethrow;
    } on NetworkException {
      rethrow;
    } on ApiException catch (e) {
      debugPrint('[QPG FORENSIC DEBUG] Unit Retrieval API Error:');
      debugPrint('  Status Code: ${e.statusCode}');
      debugPrint('  Message: ${e.message}');
      debugPrint('========================================================');
      rethrow;
    } catch (e) {
      debugPrint('[QPG FORENSIC DEBUG] Unit Retrieval Unexpected Exception: $e');
      debugPrint('========================================================');
      throw ApiException(
        message: 'Unexpected error while loading units: ${e.toString()}',
      );
    }
  }
}
