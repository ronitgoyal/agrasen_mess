class AdminStudentModel {
  final int id;
  final int userId;
  final String name;
  final String email;
  final String roomNumber;
  final String phoneNumber;
  final bool isActive;

  const AdminStudentModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.email,
    required this.roomNumber,
    required this.phoneNumber,
    required this.isActive,
  });

  factory AdminStudentModel.fromJson(Map<String, dynamic> json) {
    final userData = json['user'];

    final Map<String, dynamic> user = userData is Map
        ? Map<String, dynamic>.from(userData)
        : <String, dynamic>{};

    return AdminStudentModel(
      id: _toInt(json['id'] ?? json['student_id']),
      userId: _toInt(json['user_id'] ?? user['id']),
      name: _toText(
        json['name'] ?? user['name'],
        fallback: 'Student',
      ),
      email: _toText(
        json['email'] ?? user['email'],
        fallback: 'Not available',
      ),
      roomNumber: _toText(
        json['room_number'] ?? json['room_no'],
        fallback: 'Not available',
      ),
      phoneNumber: _toText(
        json['phone_number'] ?? json['phone'] ?? user['phone_number'],
        fallback: 'Not available',
      ),
      isActive: _toBool(
        json['is_active'] ?? user['is_active'] ?? true,
      ),
    );
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

bool _toBool(dynamic value) {
  if (value is bool) return value;
  if (value is int) return value == 1;

  final text = value?.toString().toLowerCase();

  return text == 'true' || text == '1' || text == 'yes';
}