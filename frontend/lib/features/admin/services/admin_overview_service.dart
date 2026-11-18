import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../admin_meal_slots/services/meal_slot_service.dart';
import '../../admin_staff/services/staff_service.dart';
import '../../admin_students/services/admin_student_service.dart';
import '../models/admin_overview_model.dart';

class AdminOverviewService {
  const AdminOverviewService();

  Future<AdminOverviewModel> getOverview() async {
    const studentService = AdminStudentService();
    const staffService = StaffService();
    const mealService = MealSlotService();

    // Start all API calls together.
    final studentsFuture = studentService.getStudents();
    final staffFuture = staffService.getStaff();
    final mealsFuture = mealService.getMealSlots();
    final attendanceSummaryFuture = _getTodayAttendanceSummary();

    // Wait for API responses.
    final students = await studentsFuture;
    final staff = await staffFuture;
    final meals = await mealsFuture;
    final attendanceSummary = await attendanceSummaryFuture;

    var activeStaffCount = 0;
    for (final member in staff) {
      if (member.isActive) {
        activeStaffCount++;
      }
    }

    var activeMealCount = 0;
    for (final meal in meals) {
      if (meal.isActive) {
        activeMealCount++;
      }
    }

    return AdminOverviewModel(
      totalStudents: students.length,
      activeStudents: attendanceSummary.totalStudents,
      totalStaff: staff.length,
      activeStaff: activeStaffCount,
      totalAttendance:
          attendanceSummary.breakfast +
          attendanceSummary.lunch +
          attendanceSummary.dinner,
      activeMeals: activeMealCount,
      breakfastAttendance: attendanceSummary.breakfast,
      lunchAttendance: attendanceSummary.lunch,
      dinnerAttendance: attendanceSummary.dinner,
    );
  }

  Future<AdminTodayAttendanceSummary> _getTodayAttendanceSummary() async {
    final token = await SecureStorageService.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Login session expired.');
    }

    final now = DateTime.now();

    final response = await ApiClient.dio.get(
      '/attendance/summary',
      queryParameters: {'year': now.year, 'month': now.month},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    final responseData = response.data;

    if (responseData is! Map) {
      throw Exception('Invalid attendance summary response.');
    }

    return AdminTodayAttendanceSummary.fromJson(
      Map<String, dynamic>.from(responseData),
    );
  }
}
