import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../models/staff_model.dart';

class StaffService {
  const StaffService();

  Future<void> updateStaffStatus({
    required int userId,
    required bool isActive,
  }) async {
    try {
      await ApiClient.dio.patch(
        '/users/staff/$userId/status',
        data: {'is_active': isActive},
      );
    } on DioException catch (error) {
      throw Exception(_errorMessage(error));
    }
  }

  getStaff() async {
    try {
      final response = await ApiClient.dio.get('/users/staff');

      final records = _extractList(response.data);

      return records
          .whereType<Map>()
          .map(
            (record) => StaffModel.fromJson(Map<String, dynamic>.from(record)),
          )
          .toList();
    } on DioException catch (error) {
      throw Exception(_errorMessage(error));
    } catch (error) {
      throw Exception(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<StaffModel> createStaff({
    required String name,
    required String email,
    required String password,
    String? phoneNumber,
  }) async {
    try {
      final trimmedPhone = phoneNumber?.trim() ?? '';

      final data = <String, dynamic>{
        'name': name.trim(),
        'email': email.trim().toLowerCase(),
        'password': password,
      };

      if (trimmedPhone.isNotEmpty) {
        data['phone_number'] = trimmedPhone;
      }

      final response = await ApiClient.dio.post('/users/staff', data: data);

      return _extractStaff(response.data);
    } on DioException catch (error) {
      throw Exception(_errorMessage(error));
    } catch (error) {
      throw Exception(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<StaffModel> updateStaff({
    required int userId,
    required String name,
    required String email,
    required String phoneNumber,
  }) async {
    try {
      final response = await ApiClient.dio.patch(
        '/users/staff/$userId',
        data: {
          'name': name.trim(),
          'email': email.trim().toLowerCase(),
          'phone_number': phoneNumber.trim().isEmpty
              ? null
              : phoneNumber.trim(),
        },
      );

      return _extractStaff(response.data);
    } on DioException catch (error) {
      throw Exception(_errorMessage(error));
    }
  }

  List<dynamic> _extractList(dynamic responseData) {
    if (responseData is List) {
      return responseData;
    }

    if (responseData is Map) {
      final data = Map<String, dynamic>.from(responseData);

      final possibleList =
          data['items'] ??
          data['staff'] ??
          data['users'] ??
          data['records'] ??
          data['data'];

      if (possibleList is List) {
        return possibleList;
      }
    }

    return <dynamic>[];
  }

  StaffModel _extractStaff(dynamic responseData) {
    if (responseData is! Map) {
      throw Exception('The server returned an invalid staff response.');
    }

    final data = Map<String, dynamic>.from(responseData);

    if (data['data'] is Map) {
      return StaffModel.fromJson(
        Map<String, dynamic>.from(data['data'] as Map),
      );
    }

    if (data['staff'] is Map) {
      return StaffModel.fromJson(
        Map<String, dynamic>.from(data['staff'] as Map),
      );
    }

    return StaffModel.fromJson(data);
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
        return detail
            .map((item) {
              if (item is Map) {
                final location = item['loc'];
                final message = item['msg'];

                if (location is List && location.isNotEmpty) {
                  return '${location.last}: $message';
                }

                return message?.toString() ?? item.toString();
              }

              return item.toString();
            })
            .join('\n');
      }
    }

    if (error.response?.statusCode == 403) {
      return 'You do not have permission to manage staff.';
    }

    if (error.response?.statusCode == 409) {
      return 'An account with this email already exists.';
    }

    if (error.response?.statusCode == 422) {
      return 'The staff form contains invalid information.';
    }

    if (error.type == DioExceptionType.connectionError) {
      return 'Unable to connect to the server.';
    }

    return 'Could not complete the staff operation.';
  }
}
