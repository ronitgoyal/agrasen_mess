import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../../admin_menus/services/weekly_menu_service.dart';
import '../models/dashboard_model.dart';

class DashboardService {
  final WeeklyMenuService _menuService = const WeeklyMenuService();

  Future<StudentDashboardModel> getStudentDashboard() async {
    try {
      final response = await ApiClient.dio.get('/dashboard/student');

      final data = Map<String, dynamic>.from(response.data as Map);
      final dashboardDate = DateTime.tryParse(data['date']?.toString() ?? '');

      // Menu request fail ho to attendance/QR dashboard phir bhi load ho.
      if (dashboardDate != null && data['meals'] is List) {
        try {
          final menus = await _menuService.getWeeklyMenus();
          final weekday = dashboardDate.weekday;

          data['meals'] = (data['meals'] as List).map((rawMeal) {
            final meal = Map<String, dynamic>.from(rawMeal as Map);
            final slotId = int.tryParse(
              (meal['meal_slot_id'] ?? meal['id']).toString(),
            );

            final matchingMenus = menus.where(
              (menu) =>
                  menu.dayOfWeek == weekday &&
                  menu.mealSlotId == slotId &&
                  menu.isActive,
            );

            meal['menu_items'] = matchingMenus.isEmpty
                ? <String>[]
                : matchingMenus.first.menuItems;

            return meal;
          }).toList();
        } catch (error) {
          if (kDebugMode) {
            debugPrint('Dashboard weekly menu could not load: $error');
          }
        }
      } else if (kDebugMode) {
        debugPrint('Dashboard date or meals format is invalid.');
      }

      return StudentDashboardModel.fromJson(data);
    } on DioException catch (error) {
      throw Exception(_extractError(error));
    }
  }

  String _extractError(DioException error) {
    final data = error.response?.data;

    if (data is Map<String, dynamic> && data['detail'] is String) {
      return data['detail'] as String;
    }

    if (error.response?.statusCode == 401) {
      return 'Your session has expired';
    }

    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return 'Unable to connect to server';
    }

    return 'Unable to load dashboard';
  }
}
