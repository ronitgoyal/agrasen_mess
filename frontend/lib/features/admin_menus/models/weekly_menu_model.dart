class WeeklyMenuModel {
  final int id;
  final int dayOfWeek;
  final int mealSlotId;
  final List<String> menuItems;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const WeeklyMenuModel({
    required this.id,
    required this.dayOfWeek,
    required this.mealSlotId,
    required this.menuItems,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory WeeklyMenuModel.fromJson(Map<String, dynamic> json) {
    return WeeklyMenuModel(
      id: _toInt(json['id'] ?? json['menu_id']),
      dayOfWeek: _toInt(json['day_of_week']),
      mealSlotId: _toInt(json['meal_slot_id']),
      menuItems: _toStringList(json['menu_items']),
      isActive: _toBool(json['is_active'] ?? true),
      createdAt: _toDateTime(json['created_at']),
      updatedAt: _toDateTime(json['updated_at']),
    );
  }
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

DateTime? _toDateTime(dynamic value) {
  if (value == null) return null;

  return DateTime.tryParse(value.toString());
}

List<String> _toStringList(dynamic value) {
  if (value == null) {
    return <String>[];
  }

  if (value is List) {
    return value
        .where((item) => item != null)
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  if (value is String) {
    return value
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  return <String>[];
}
