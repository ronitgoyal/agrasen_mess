class StudentProfileModel {
  final int id;
  final String name;
  final String email;
  final String roomNumber;

  const StudentProfileModel({
    required this.id,
    required this.name,
    required this.email,
    required this.roomNumber,
  });

  factory StudentProfileModel.fromJson(Map<String, dynamic> json) {
    return StudentProfileModel(
      id: _toInt(json['id'] ?? json['student_id']),
      name: _toString(
        json['name'],
        fallback: 'Student',
      ),
      email: _toString(
        json['email'],
        fallback: 'Not available',
      ),
      roomNumber: _toString(
        json['room_number'] ?? json['room_no'],
        fallback: 'Not available',
      ),
    );
  }
}

class DashboardMealModel {
  final int mealSlotId;
  final String mealType;
  final String startTime;
  final String endTime;
  final bool isActive;
  final String status;
  final bool canGenerateQr;
  final bool attendanceRecorded;
  final int? attendanceId;
  final DateTime? attendedAt;
  final List<String> menuItems;

  const DashboardMealModel({
    required this.mealSlotId,
    required this.mealType,
    required this.startTime,
    required this.endTime,
    required this.isActive,
    required this.status,
    required this.canGenerateQr,
    required this.attendanceRecorded,
    required this.attendanceId,
    required this.attendedAt,
    required this.menuItems,
  });

  factory DashboardMealModel.fromJson(Map<String, dynamic> json) {
    return DashboardMealModel(
      mealSlotId: _toInt(json['meal_slot_id'] ?? json['id']),
      mealType: _toString(json['meal_type'], fallback: 'Meal'),
      startTime: _toString(json['start_time']),
      endTime: _toString(json['end_time']),
      isActive: _toBool(json['is_active']),
      status: _toString(json['status'], fallback: 'unknown'),
      canGenerateQr: _toBool(json['can_generate_qr']),
      attendanceRecorded: _toBool(json['attendance_recorded']),
      attendanceId: _toNullableInt(json['attendance_id']),
      attendedAt: _toNullableDateTime(json['attended_at']),
      menuItems: _toStringList(json['menu_items']),
    );
  }

  String get displayMealType {
    if (mealType.isEmpty) return 'Meal';

    return mealType
        .split('_')
        .map(
          (word) => word.isEmpty
              ? ''
              : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  String get menuText {
    if (menuItems.isEmpty) {
      return 'Menu not available';
    }

    return menuItems.join(', ');
  }
}

class StudentDashboardModel {
  final String date;
  final StudentProfileModel student;
  final List<DashboardMealModel> meals;

  const StudentDashboardModel({
    required this.date,
    required this.student,
    required this.meals,
  });

  factory StudentDashboardModel.fromJson(Map<String, dynamic> json) {
    final studentData = json['student'];

    final Map<String, dynamic> safeStudent;

    if (studentData is Map<String, dynamic>) {
      safeStudent = studentData;
    } else if (studentData is Map) {
      safeStudent = Map<String, dynamic>.from(studentData);
    } else {
      safeStudent = <String, dynamic>{};
    }

    final mealsData = json['meals'];

    final List<DashboardMealModel> parsedMeals;

    if (mealsData is List) {
      parsedMeals = mealsData
          .whereType<Map>()
          .map(
            (meal) =>
                DashboardMealModel.fromJson(Map<String, dynamic>.from(meal)),
          )
          .toList();
    } else {
      parsedMeals = <DashboardMealModel>[];
    }

    return StudentDashboardModel(
      date: _toString(json['date']),
      student: StudentProfileModel.fromJson(safeStudent),
      meals: parsedMeals,
    );
  }

  int get totalMeals => meals.length;

  int get attendedMeals {
    return meals.where((meal) => meal.attendanceRecorded).length;
  }

  int get pendingMeals {
    return meals.where((meal) => !meal.attendanceRecorded).length;
  }

  int get completedMeals {
    return meals.where((meal) => meal.attendanceRecorded).length;
  }

  int get totalActiveMeals {
    return meals.where((meal) => meal.isActive).length;
  }

  int get availableQrMeals {
    return meals.where((meal) => meal.canGenerateQr).length;
  }
}

// -----------------------------------------------------------------------------
// Safe conversion functions
// Backend se null ya unexpected value aaye to app crash nahi karegi.
// -----------------------------------------------------------------------------

String _toString(dynamic value, {String fallback = ''}) {
  if (value == null) return fallback;

  final text = value.toString().trim();

  return text.isEmpty ? fallback : text;
}

int _toInt(dynamic value) {
  if (value is int) return value;

  return int.tryParse(value?.toString() ?? '') ?? 0;
}

int? _toNullableInt(dynamic value) {
  if (value == null) return null;

  if (value is int) return value;

  return int.tryParse(value.toString());
}

bool _toBool(dynamic value) {
  if (value is bool) return value;

  if (value is int) return value == 1;

  final text = value?.toString().toLowerCase();

  return text == 'true' || text == '1' || text == 'yes';
}

DateTime? _toNullableDateTime(dynamic value) {
  if (value == null) return null;

  return DateTime.tryParse(value.toString());
}

List<String> _toStringList(dynamic value) {
  // menu_items null hai
  if (value == null) {
    return <String>[];
  }

  // menu_items list hai: ["Rice", "Dal"]
  if (value is List) {
    return value
        .where((item) => item != null)
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  // menu_items string hai: "Rice, Dal, Roti"
  if (value is String) {
    if (value.trim().isEmpty) {
      return <String>[];
    }

    return value
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  return <String>[];
}
