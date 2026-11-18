class MealSlotModel {
  final int id;
  final String mealType;
  final String startTime;
  final String endTime;
  final bool isActive;

  const MealSlotModel({
    required this.id,
    required this.mealType,
    required this.startTime,
    required this.endTime,
    required this.isActive,
  });

  factory MealSlotModel.fromJson(Map<String, dynamic> json) {
    return MealSlotModel(
      id: _toInt(json['id'] ?? json['meal_id']),
      mealType: _toText(json['meal_type'], fallback: 'meal'),
      startTime: _toText(json['start_time'], fallback: '00:00:00'),
      endTime: _toText(json['end_time'], fallback: '00:00:00'),
      isActive: _toBool(json['is_active'] ?? true),
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

  String get displayStartTime {
    return _formatTime(startTime);
  }

  String get displayEndTime {
    return _formatTime(endTime);
  }

  static String _formatTime(String value) {
    try {
      final cleanValue = value.split('.').first;
      final parts = cleanValue.split(':');

      if (parts.length < 2) return value;

      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);

      final period = hour >= 12 ? 'PM' : 'AM';

      final displayHour = hour == 0
          ? 12
          : hour > 12
          ? hour - 12
          : hour;

      return '$displayHour:'
          '${minute.toString().padLeft(2, '0')} '
          '$period';
    } catch (_) {
      return value;
    }
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
