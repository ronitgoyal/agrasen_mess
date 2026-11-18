class StaffAttendanceModel {
  final int id;
  final int studentId;
  final String studentName;
  final String roomNumber;
  final String mealType;
  final DateTime? attendedAt;

  const StaffAttendanceModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.roomNumber,
    required this.mealType,
    required this.attendedAt,
  });

  factory StaffAttendanceModel.fromJson(Map<String, dynamic> json) {
    final studentData = json['student'];
    final mealSlotData = json['meal_slot'];

    final Map<String, dynamic> student = studentData is Map
        ? Map<String, dynamic>.from(studentData)
        : <String, dynamic>{};

    final Map<String, dynamic> mealSlot = mealSlotData is Map
        ? Map<String, dynamic>.from(mealSlotData)
        : <String, dynamic>{};

    return StaffAttendanceModel(
      id: _toInt(json['id'] ?? json['attendance_id']),
      studentId: _toInt(json['student_id'] ?? student['id']),
      studentName: _toText(
        json['student_name'] ?? student['name'],
        fallback: 'Student',
      ),
      roomNumber: _toText(
        json['room_number'] ?? student['room_number'] ?? student['room_no'],
        fallback: 'Not available',
      ),
      mealType: _toText(
        json['meal_type'] ?? mealSlot['meal_type'],
        fallback: 'meal',
      ),
      attendedAt: _toDateTime(
        json['scanned_at'] ??
            json['attended_at'] ??
            json['created_at'],
      ),
    );
  }

  String get displayMealType {
    return mealType
        .split('_')
        .map(
          (word) => word.isEmpty
              ? ''
              : '${word[0].toUpperCase()}'
                    '${word.substring(1).toLowerCase()}',
        )
        .join(' ');
  }
}

String _toText(dynamic value, {String fallback = ''}) {
  if (value == null) return fallback;

  final text = value.toString().trim();
  return text.isEmpty ? fallback : text;
}

int _toInt(dynamic value) {
  if (value is int) return value;

  return int.tryParse(value?.toString() ?? '') ?? 0;
}

DateTime? _toDateTime(dynamic value) {
  if (value == null) return null;

  return DateTime.tryParse(value.toString());
}