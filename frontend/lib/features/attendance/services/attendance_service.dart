import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../models/attendance_model.dart';

class AttendanceService {
  const AttendanceService();

  static const String _historyEndpoint = '/attendance/me';

  Future<MonthlyAttendanceModel> getMyHistory({
    required int year,
    required int month,
  }) async {
    try {
      final token = await SecureStorageService.getToken();

      if (token == null || token.isEmpty) {
        throw Exception('Login session has expired.');
      }

      final response = await ApiClient.dio.get(
        _historyEndpoint,
        queryParameters: {'year': year, 'month': month},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      final responseData = response.data;

      if (responseData is! Map) {
        throw Exception('Invalid attendance report received from server.');
      }

      return MonthlyAttendanceModel.fromJson(
        Map<String, dynamic>.from(responseData),
      );
    } on DioException catch (error) {
      throw Exception(_getErrorMessage(error));
    } catch (error) {
      throw Exception(error.toString().replaceFirst('Exception: ', ''));
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

    if (error.response?.statusCode == 404) {
      return 'Attendance history is unavailable.';
    }

    if (error.response?.statusCode == 401) {
      return 'Your session has expired. Please log in again.';
    }

    if (error.type == DioExceptionType.connectionError) {
      return 'Unable to connect to the server.';
    }

    return 'Could not load attendance history.';
  }
}
