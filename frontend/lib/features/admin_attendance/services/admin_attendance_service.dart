import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../models/admin_attendance_model.dart';

class AdminAttendanceService {
  const AdminAttendanceService();

  static const String _summaryEndpoint = '/attendance/summary';

  Future<AdminAttendanceModel> getMonthlySummary({
    required int year,
    required int month,
  }) async {
    try {
      final token = await SecureStorageService.getToken();

      if (token == null || token.isEmpty) {
        throw Exception('Login session has expired.');
      }

      final response = await ApiClient.dio.get(
        _summaryEndpoint,
        queryParameters: {
          'year': year,
          'month': month,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      final responseData = response.data;

      if (responseData is! Map) {
        throw Exception(
          'Invalid attendance summary received from server.',
        );
      }

      return AdminAttendanceModel.fromJson(
        Map<String, dynamic>.from(responseData),
      );
    } on DioException catch (error) {
      throw Exception(_getErrorMessage(error));
    } catch (error) {
      throw Exception(
        error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  String _getErrorMessage(DioException error) {
    final responseData = error.response?.data;

    if (responseData is Map) {
      final detail =
          responseData['detail'] ??
          responseData['message'] ??
          responseData['error'];

      if (detail is String && detail.isNotEmpty) {
        return detail;
      }
    }

    if (error.response?.statusCode == 400) {
      return 'Attendance summary is unavailable for the selected month.';
    }

    if (error.response?.statusCode == 401) {
      return 'Your session has expired. Please log in again.';
    }

    if (error.response?.statusCode == 403) {
      return 'You do not have permission to view attendance summary.';
    }

    if (error.response?.statusCode == 404) {
      return 'Attendance summary is unavailable.';
    }

    if (error.type == DioExceptionType.connectionError) {
      return 'Unable to connect to the server.';
    }

    return 'Could not load attendance summary.';
  }
}