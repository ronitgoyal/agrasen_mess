import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../models/meal_slot_model.dart';

class MealSlotService {
  const MealSlotService();

  Future<List<MealSlotModel>> getMealSlots() async {
    try {
      final response = await ApiClient.dio.get('/meals');

      final records = _extractList(response.data);

      return records
          .whereType<Map>()
          .map(
            (record) =>
                MealSlotModel.fromJson(Map<String, dynamic>.from(record)),
          )
          .toList();
    } on DioException catch (error) {
      throw Exception(_errorMessage(error));
    } catch (error) {
      throw Exception(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<MealSlotModel> createMeal({
    required String mealType,
    required String startTime,
    required String endTime,
    required bool isActive,
  }) async {
    try {
      final response = await ApiClient.dio.post(
        '/meals',
        data: {
          'meal_type': mealType,
          'start_time': startTime,
          'end_time': endTime,
          'is_active': isActive,
        },
      );

      return _extractMeal(response.data);
    } on DioException catch (error) {
      throw Exception(_errorMessage(error));
    } catch (error) {
      throw Exception(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<MealSlotModel> updateMeal({
    required int mealId,
    required String mealType,
    required String startTime,
    required String endTime,
    required bool isActive,
  }) async {
    try {
      final response = await ApiClient.dio.patch(
        '/meals/$mealId',
        data: {
          'meal_type': mealType,
          'start_time': startTime,
          'end_time': endTime,
          'is_active': isActive,
        },
      );

      return _extractMeal(response.data);
    } on DioException catch (error) {
      throw Exception(_errorMessage(error));
    } catch (error) {
      throw Exception(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  List<dynamic> _extractList(dynamic responseData) {
    if (responseData is List) {
      return responseData;
    }

    if (responseData is Map) {
      final data = Map<String, dynamic>.from(responseData);

      final possibleList =
          data['items'] ?? data['meals'] ?? data['records'] ?? data['data'];

      if (possibleList is List) {
        return possibleList;
      }
    }

    return <dynamic>[];
  }

  MealSlotModel _extractMeal(dynamic responseData) {
    if (responseData is! Map) {
      throw Exception('The server returned an invalid meal response.');
    }

    final data = Map<String, dynamic>.from(responseData);

    if (data['data'] is Map) {
      return MealSlotModel.fromJson(
        Map<String, dynamic>.from(data['data'] as Map),
      );
    }

    if (data['meal'] is Map) {
      return MealSlotModel.fromJson(
        Map<String, dynamic>.from(data['meal'] as Map),
      );
    }

    return MealSlotModel.fromJson(data);
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

                String field = '';

                if (location is List && location.isNotEmpty) {
                  field = location.last.toString();
                }

                if (field.isNotEmpty) {
                  return '$field: $message';
                }

                return message?.toString() ?? item.toString();
              }

              return item.toString();
            })
            .join('\n');
      }
    }

    if (error.response?.statusCode == 401) {
      return 'Your login session has expired.';
    }

    if (error.response?.statusCode == 403) {
      return 'You don’t have permission to manage meals.';
    }

    if (error.response?.statusCode == 404) {
      return 'The meal API or the selected meal was not found.';
    }

    if (error.response?.statusCode == 409) {
      return 'This meal is already available.';
    }

    if (error.response?.statusCode == 422) {
      return 'The meal data doesn’t match the expected format.';
    }

    if (error.type == DioExceptionType.connectionError) {
      return 'Unable to connect to the server.';
    }

    return 'Could not complete the meal operation.';
  }
}
