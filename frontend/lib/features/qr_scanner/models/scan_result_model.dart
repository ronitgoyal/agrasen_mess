class ScanResultModel {
  final String message;
  final String studentName;
  final String roomNumber;
  final String mealType;
  final DateTime? attendedAt;

  const ScanResultModel({
    required this.message,
    required this.studentName,
    required this.roomNumber,
    required this.mealType,
    required this.attendedAt,
  });

  factory ScanResultModel.fromJson(Map<String, dynamic> json) {
    final studentData = json['student'];
    final attendanceData = json['attendance'];

    final Map<String, dynamic> student = studentData is Map
        ? Map<String, dynamic>.from(studentData)
        : <String, dynamic>{};

    final Map<String, dynamic> attendance = attendanceData is Map
        ? Map<String, dynamic>.from(attendanceData)
        : <String, dynamic>{};

    return ScanResultModel(
      message: _text(
        json['message'],
        fallback: 'Attendance recorded successfully',
      ),
      studentName: _text(
        json['student_name'] ?? student['name'],
        fallback: 'Student',
      ),
      roomNumber: _text(
        json['room_number'] ?? student['room_number'],
        fallback: 'Not available',
      ),
      mealType: _text(
        json['meal_type'] ?? attendance['meal_type'],
        fallback: 'Meal',
      ),
      attendedAt: DateTime.tryParse(
        (
          json['scanned_at'] ??
          json['attended_at'] ??
          attendance['scanned_at'] ??
          attendance['attended_at'] ??
          ''
        ).toString(),
      ),
    );
  }
}

String _text(dynamic value, {String fallback = ''}) {
  if (value == null) return fallback;

  final result = value.toString().trim();
  return result.isEmpty ? fallback : result;
}