class StaffModel {
  final int id;
  final String name;
  final String email;
  final String phoneNumber;
  final String role;
  final bool isActive;
  final DateTime? createdAt;

  const StaffModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.role,
    required this.isActive,
    required this.createdAt,
  });

  factory StaffModel.fromJson(Map<String, dynamic> json) {
    return StaffModel(
      id: _toInt(json['id'] ?? json['user_id']),
      name: _toText(json['name'], fallback: 'Mess Staff'),
      email: _toText(json['email'], fallback: 'Not available'),
      phoneNumber: _toText(
        json['phone_number'] ?? json['phone'],
        fallback: 'Not available',
      ),
      role: _toText(json['role'], fallback: 'staff'),
      isActive: _toBool(json['is_active'] ?? true),
      createdAt: _toDateTime(json['created_at']),
    );
  }

  String get displayRole {
    return role
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

  final result = value.toString().trim();

  return result.isEmpty ? fallback : result;
}

int _toInt(dynamic value) {
  if (value is int) return value;

  return int.tryParse(value?.toString() ?? '') ?? 0;
}

bool _toBool(dynamic value) {
  if (value is bool) return value;
  if (value is int) return value == 1;

  final result = value?.toString().toLowerCase();

  return result == 'true' || result == '1' || result == 'yes';
}

DateTime? _toDateTime(dynamic value) {
  if (value == null) return null;

  return DateTime.tryParse(value.toString());
}
