import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../models/staff_attendance_model.dart';

class StaffAttendanceService {
  const StaffAttendanceService();

  Future<List<StaffAttendanceModel>> getAttendance() async {
    try {
      final token = await SecureStorageService.getToken();

      if (token == null || token.isEmpty) {
        throw Exception('Login session expired.');
      }

      final response = await ApiClient.dio.get(
        '/attendance/',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      final responseData = response.data;
      List<dynamic> records = [];

      if (responseData is List) {
        records = responseData;
      } else if (responseData is Map) {
        final data = Map<String, dynamic>.from(responseData);

        final possibleList =
            data['items'] ??
            data['attendance'] ??
            data['records'] ??
            data['data'];

        if (possibleList is List) {
          records = possibleList;
        }
      }

      return records
          .whereType<Map>()
          .map(
            (record) => StaffAttendanceModel.fromJson(
              Map<String, dynamic>.from(record),
            ),
          )
          .toList();
    } on DioException catch (error) {
      throw Exception(_errorMessage(error));
    } catch (error) {
      throw Exception(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  String _errorMessage(DioException error) {
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

    if (error.response?.statusCode == 401) {
      return 'Your session has expired.';
}

if (error.response?.statusCode == 403) {
  return 'You do not have permission to view attendance records.';
}

if (error.type == DioExceptionType.connectionError) {
  return 'Unable to connect to the server.';
}

return 'Could not load attendance records.';
  }
}
