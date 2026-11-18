class MonthlyAttendanceModel {
  final int year;
  final int month;
  final int totalDays;
  final AttendanceSummary summary;
  final List<DailyAttendanceModel> days;

  const MonthlyAttendanceModel({
    required this.year,
    required this.month,
    required this.totalDays,
    required this.summary,
    required this.days,
  });

  factory MonthlyAttendanceModel.fromJson(Map<String, dynamic> json) {
    return MonthlyAttendanceModel(
      year: _toInt(json['year']),
      month: _toInt(json['month']),
      totalDays: _toInt(json['total_days']),
      summary: AttendanceSummary.fromJson(
        Map<String, dynamic>.from(json['summary'] ?? <String, dynamic>{}),
      ),
      days: (json['days'] as List? ?? const [])
          .whereType<Map>()
          .map(
            (item) =>
                DailyAttendanceModel.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(),
    );
  }
}

class AttendanceSummary {
  final int breakfast;
  final int lunch;
  final int dinner;

  const AttendanceSummary({
    required this.breakfast,
    required this.lunch,
    required this.dinner,
  });

  factory AttendanceSummary.fromJson(Map<String, dynamic> json) {
    return AttendanceSummary(
      breakfast: _toInt(json['breakfast']),
      lunch: _toInt(json['lunch']),
      dinner: _toInt(json['dinner']),
    );
  }
}

class DailyAttendanceModel {
  final DateTime date;
  final MealAttendanceModel breakfast;
  final MealAttendanceModel lunch;
  final MealAttendanceModel dinner;

  const DailyAttendanceModel({
    required this.date,
    required this.breakfast,
    required this.lunch,
    required this.dinner,
  });

  factory DailyAttendanceModel.fromJson(Map<String, dynamic> json) {
    return DailyAttendanceModel(
      date: DateTime.parse(json['date'].toString()),
      breakfast: MealAttendanceModel.fromJson(
        Map<String, dynamic>.from(json['breakfast'] ?? <String, dynamic>{}),
      ),
      lunch: MealAttendanceModel.fromJson(
        Map<String, dynamic>.from(json['lunch'] ?? <String, dynamic>{}),
      ),
      dinner: MealAttendanceModel.fromJson(
        Map<String, dynamic>.from(json['dinner'] ?? <String, dynamic>{}),
      ),
    );
  }
}

class MealAttendanceModel {
  final String status;
  final DateTime? attendedAt;

  const MealAttendanceModel({required this.status, required this.attendedAt});

  factory MealAttendanceModel.fromJson(Map<String, dynamic> json) {
    return MealAttendanceModel(
      status: json['status']?.toString().toLowerCase() ?? 'unavailable',
      attendedAt: _toDateTime(json['attended_at']),
    );
  }

  bool get isAttended => status == 'attended';

  bool get isMissed => status == 'missed';

  bool get isUpcoming => status == 'upcoming';

  bool get isUnavailable => status == 'unavailable';
}

int _toInt(dynamic value) {
  if (value is int) {
    return value;
  }

  return int.tryParse(value?.toString() ?? '') ?? 0;
}

DateTime? _toDateTime(dynamic value) {
  if (value == null) {
    return null;
  }

  return DateTime.tryParse(value.toString());
}
