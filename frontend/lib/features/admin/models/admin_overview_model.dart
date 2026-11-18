class AdminOverviewModel {
  final int totalStudents;
  final int activeStudents;
  final int totalStaff;
  final int activeStaff;
  final int totalAttendance;
  final int activeMeals;
  final int breakfastAttendance;
  final int lunchAttendance;
  final int dinnerAttendance;

  const AdminOverviewModel({
    required this.totalStudents,
    required this.activeStudents,
    required this.totalStaff,
    required this.activeStaff,
    required this.totalAttendance,
    required this.activeMeals,
    required this.breakfastAttendance,
    required this.lunchAttendance,
    required this.dinnerAttendance,
  });

  int _percentage(int attendance) {
    if (activeStudents <= 0) return 0;
    return ((attendance / activeStudents) * 100).round().clamp(0, 100).toInt();
  }

  int get breakfastPerformance => _percentage(breakfastAttendance);
  int get lunchPerformance => _percentage(lunchAttendance);
  int get dinnerPerformance => _percentage(dinnerAttendance);
}

class AdminTodayAttendanceSummary {
  final int totalStudents;
  final int breakfast;
  final int lunch;
  final int dinner;

  const AdminTodayAttendanceSummary({
    required this.totalStudents,
    required this.breakfast,
    required this.lunch,
    required this.dinner,
  });

  factory AdminTodayAttendanceSummary.fromJson(Map<String, dynamic> json) {
    final dailyData = json['daily_summary'];

    final daily = dailyData is Map
        ? Map<String, dynamic>.from(dailyData)
        : <String, dynamic>{};

    return AdminTodayAttendanceSummary(
      totalStudents: _overviewToInt(
        daily['total_students'] ?? json['total_students'],
      ),
      breakfast: _overviewToInt(daily['breakfast']),
      lunch: _overviewToInt(daily['lunch']),
      dinner: _overviewToInt(daily['dinner']),
    );
  }
}

int _overviewToInt(dynamic value) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
