import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../models/admin_student_model.dart';

class AdminStudentService {
  Future<AdminStudentModel> createStudent({
    required String name,
    required String email,
    required String phoneNumber,
    required String password,
    required String roomNumber,
  }) async {
    try {
      final response = await ApiClient.dio.post(
        '/students',
        data: {
          'name': name.trim(),
          'email': email.trim().toLowerCase(),
          'phone_number': phoneNumber.trim(),
          'password': password,
          'room_number': roomNumber.trim(),
        },
      );

      final responseData = response.data;

      if (responseData is! Map) {
        throw Exception('The server returned an invalid student response.');
      }

      final data = Map<String, dynamic>.from(responseData);

      if (data['data'] is Map) {
        return AdminStudentModel.fromJson(
          Map<String, dynamic>.from(data['data'] as Map),
        );
      }

      return AdminStudentModel.fromJson(data);
    } on DioException catch (error) {
      throw Exception(_errorMessage(error));
    } catch (error) {
      throw Exception(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  const AdminStudentService();

  Future<void> updateStudentStatus({
    required int studentId,
    required bool isActive,
  }) async {
    try {
      await ApiClient.dio.patch(
        '/students/$studentId/status',
        data: {'is_active': isActive},
      );
    } on DioException catch (error) {
      throw Exception(_errorMessage(error));
    }
  }

  getStudents() async {
    try {
      final response = await ApiClient.dio.get(
        '/students',
        queryParameters: {'skip': 0, 'limit': 100},
      );

      final responseData = response.data;
      List<dynamic> students = [];

      if (responseData is List) {
        students = responseData;
      } else if (responseData is Map) {
        final data = Map<String, dynamic>.from(responseData);

        final possibleList =
            data['items'] ??
            data['students'] ??
            data['records'] ??
            data['data'];

        if (possibleList is List) {
          students = possibleList;
        }
      }

      return students
          .whereType<Map>()
          .map(
            (student) =>
                AdminStudentModel.fromJson(Map<String, dynamic>.from(student)),
          )
          .toList();
    } on DioException catch (error) {
      throw Exception(_errorMessage(error));
    } catch (error) {
      throw Exception(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<AdminStudentModel> updateStudent({
    required int studentId,
    required String name,
    required String email,
    required String phoneNumber,
    required String roomNumber,
  }) async {
    try {
      final response = await ApiClient.dio.patch(
        '/students/$studentId',
        data: {
          'name': name.trim(),
          'email': email.trim().toLowerCase(),
          'phone_number': phoneNumber.trim().isEmpty
              ? null
              : phoneNumber.trim(),
          'room_number': roomNumber.trim(),
        },
      );

      final responseData = response.data;

      if (responseData is! Map) {
        throw Exception('Invalid student update response.');
      }

      final data = Map<String, dynamic>.from(responseData);

      if (data['data'] is Map) {
        return AdminStudentModel.fromJson(
          Map<String, dynamic>.from(data['data'] as Map),
        );
      }

      return AdminStudentModel.fromJson(data);
    } on DioException catch (error) {
      throw Exception(_errorMessage(error));
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

      if (detail is List && detail.isNotEmpty) {
        final messages = detail
            .map((item) {
              if (item is Map) {
                final fieldLocation = item['loc'];
                final message = item['msg'];

                String field = '';

                if (fieldLocation is List && fieldLocation.isNotEmpty) {
                  field = fieldLocation.last.toString();
                }

                if (field.isNotEmpty) {
                  return '$field: $message';
                }

                return message?.toString() ?? item.toString();
              }

              return item.toString();
            })
            .join('\n');

        return messages;
      }
    }

    if (error.response?.statusCode == 400) {
      return 'Invalid student information.';
    }

    if (error.response?.statusCode == 403) {
      return 'You do not have permission to add students.';
    }

    if (error.response?.statusCode == 409) {
      return 'This email is already registered.';
    }

    if (error.response?.statusCode == 422) {
      return 'The form data does not match the required format.';
    }

    if (error.type == DioExceptionType.connectionError) {
      return 'Unable to connect to the server.';
    }

    return 'Could not create the student.';
  }
}
