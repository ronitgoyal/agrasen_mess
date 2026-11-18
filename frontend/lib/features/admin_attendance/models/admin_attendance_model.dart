class AdminAttendanceModel {
  final int year;
  final int month;
  final DateTime throughDate;
  final int totalStudents;
  final AdminDailySummary dailySummary;
  final AdminMonthlySummary monthlySummary;
  final int totalCouponCount;
  final List<DailyCouponCount> dailyCouponCounts;

  const AdminAttendanceModel({
    required this.year,
    required this.month,
    required this.throughDate,
    required this.totalStudents,
    required this.dailySummary,
    required this.monthlySummary,
    required this.totalCouponCount,
    required this.dailyCouponCounts,
  });

  factory AdminAttendanceModel.fromJson(Map<String, dynamic> json) {
    return AdminAttendanceModel(
      year: json['year'] as int? ?? 0,
      month: json['month'] as int? ?? 0,
      throughDate: DateTime.parse(
        json['through_date'] as String,
      ),
      totalStudents: json['total_students'] as int? ?? 0,
      dailySummary: AdminDailySummary.fromJson(
        json['daily_summary'] as Map<String, dynamic>? ?? {},
      ),
      monthlySummary: AdminMonthlySummary.fromJson(
        json['monthly_summary'] as Map<String, dynamic>? ?? {},
      ),
      totalCouponCount: json['total_coupon_count'] as int? ?? 0,
      dailyCouponCounts: (json['daily_coupon_counts'] as List<dynamic>? ?? [])
          .map(
            (item) => DailyCouponCount.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList(),
    );
  }
}

class AdminDailySummary {
  final DateTime date;
  final int totalStudents;
  final int breakfast;
  final int lunch;
  final int dinner;
  final int couponCount;

  const AdminDailySummary({
    required this.date,
    required this.totalStudents,
    required this.breakfast,
    required this.lunch,
    required this.dinner,
    required this.couponCount,
  });

  factory AdminDailySummary.fromJson(Map<String, dynamic> json) {
    return AdminDailySummary(
      date: DateTime.parse(
        json['date'] as String,
      ),
      totalStudents: json['total_students'] as int? ?? 0,
      breakfast: json['breakfast'] as int? ?? 0,
      lunch: json['lunch'] as int? ?? 0,
      dinner: json['dinner'] as int? ?? 0,
      couponCount: json['coupon_count'] as int? ?? 0,
    );
  }
}

class AdminMonthlySummary {
  final int breakfast;
  final int lunch;
  final int dinner;

  const AdminMonthlySummary({
    required this.breakfast,
    required this.lunch,
    required this.dinner,
  });

  factory AdminMonthlySummary.fromJson(Map<String, dynamic> json) {
    return AdminMonthlySummary(
      breakfast: json['breakfast'] as int? ?? 0,
      lunch: json['lunch'] as int? ?? 0,
      dinner: json['dinner'] as int? ?? 0,
    );
  }

  int get total => breakfast + lunch + dinner;
}

class DailyCouponCount {
  final DateTime date;
  final int count;

  const DailyCouponCount({
    required this.date,
    required this.count,
  });

  factory DailyCouponCount.fromJson(Map<String, dynamic> json) {
    return DailyCouponCount(
      date: DateTime.parse(
        json['date'] as String,
      ),
      count: json['count'] as int? ?? 0,
    );
  }
}