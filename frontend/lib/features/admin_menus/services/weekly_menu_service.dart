import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../models/weekly_menu_model.dart';

class WeeklyMenuService {
  Future<List<WeeklyMenuModel>> getTodayMenus() async {
    try {
      final response = await ApiClient.dio.get('/menus/today');

      final records = _extractList(response.data);

      return records
          .whereType<Map>()
          .map(
            (record) =>
                WeeklyMenuModel.fromJson(Map<String, dynamic>.from(record)),
          )
          .toList();
    } on DioException catch (error) {
      throw Exception(_errorMessage(error));
    } catch (error) {
      throw Exception(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  const WeeklyMenuService();

  Future<List<WeeklyMenuModel>> getWeeklyMenus() async {
    try {
      final response = await ApiClient.dio.get('/menus/weekly');

      final records = _extractList(response.data);

      return records
          .whereType<Map>()
          .map(
            (record) =>
                WeeklyMenuModel.fromJson(Map<String, dynamic>.from(record)),
          )
          .toList();
    } on DioException catch (error) {
      throw Exception(_errorMessage(error));
    } catch (error) {
      throw Exception(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<WeeklyMenuModel> createMenu({
    required int dayOfWeek,
    required int mealSlotId,
    required List<String> menuItems,
    required bool isActive,
  }) async {
    try {
      final response = await ApiClient.dio.post(
        '/menus',
        data: {
          'day_of_week': dayOfWeek,
          'meal_slot_id': mealSlotId,
          'menu_items': menuItems,
          'is_active': isActive,
        },
      );

      return _extractMenu(response.data);
    } on DioException catch (error) {
      throw Exception(_errorMessage(error));
    } catch (error) {
      throw Exception(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<WeeklyMenuModel> updateMenu({
    required int menuId,
    required int dayOfWeek,
    required int mealSlotId,
    required List<String> menuItems,
    required bool isActive,
  }) async {
    try {
      final response = await ApiClient.dio.patch(
        '/menus/$menuId',
        data: {
          'day_of_week': dayOfWeek,
          'meal_slot_id': mealSlotId,
          'menu_items': menuItems,
          'is_active': isActive,
        },
      );

      return _extractMenu(response.data);
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
          data['items'] ?? data['menus'] ?? data['records'] ?? data['data'];

      if (possibleList is List) {
        return possibleList;
      }
    }

    return <dynamic>[];
  }

  WeeklyMenuModel _extractMenu(dynamic responseData) {
    if (responseData is! Map) {
      throw Exception('The server returned an invalid menu response.');
    }

    final data = Map<String, dynamic>.from(responseData);

    if (data['data'] is Map) {
      return WeeklyMenuModel.fromJson(
        Map<String, dynamic>.from(data['data'] as Map),
      );
    }

    if (data['menu'] is Map) {
      return WeeklyMenuModel.fromJson(
        Map<String, dynamic>.from(data['menu'] as Map),
      );
    }

    return WeeklyMenuModel.fromJson(data);
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
  return 'You do not have permission to manage menus.';
}

if (error.response?.statusCode == 404) {
  return 'The menu API or selected menu was not found.';
}

if (error.response?.statusCode == 409) {
  return 'A menu already exists for this day and meal.';
}

if (error.type == DioExceptionType.connectionError) {
  return 'Unable to connect to the server.';
}

return 'Could not complete the menu operation.';
  }
}