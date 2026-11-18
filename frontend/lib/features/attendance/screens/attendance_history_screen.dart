import 'package:flutter/material.dart';

import '../models/attendance_model.dart';
import '../services/attendance_service.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  State<AttendanceHistoryScreen> createState() =>
      _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  static const Color _background = Color(0xFFF8FBF9);
  static const Color _green = Color(0xFF1A6E3D);
  static const Color _accentGreen = Color(0xFF298C4A);
  static const Color _orange = Color(0xFFFF7D33);
  static const Color _red = Color(0xFFD94C4C);
  static const Color _text = Color(0xFF18251E);
  static const Color _muted = Color(0xFF637369);
  static const Color _border = Color(0xFFEBE8DF);

  final AttendanceService _service = const AttendanceService();

  late DateTime _selectedMonth;

  MonthlyAttendanceModel? _report;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);

    _loadAttendance();
  }

  Future<void> _loadAttendance() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final report = await _service.getMyHistory(
        year: _selectedMonth.year,
        month: _selectedMonth.month,
      );

      if (!mounted) return;

      setState(() {
        _report = report;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _selectMonth() async {
    final selected = await showDialog<DateTime>(
      context: context,
      builder: (context) {
        int selectedYear = _selectedMonth.year;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.white,
              insetPadding: const EdgeInsets.symmetric(horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select month',
                        style: TextStyle(
                          color: _text,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 18),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            onPressed: () {
                              setDialogState(() {
                                selectedYear--;
                              });
                            },
                            icon: const Icon(
                              Icons.chevron_left_rounded,
                              color: _green,
                            ),
                          ),
                          Text(
                            selectedYear.toString(),
                            style: const TextStyle(
                              color: _text,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          IconButton(
                            onPressed: selectedYear < DateTime.now().year
                                ? () {
                                    setDialogState(() {
                                      selectedYear++;
                                    });
                                  }
                                : null,
                            icon: const Icon(Icons.chevron_right_rounded),
                            color: _green,
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: 12,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              childAspectRatio: 2.15,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                        itemBuilder: (context, index) {
                          final month = index + 1;

                          final candidate = DateTime(selectedYear, month);

                          final now = DateTime.now();

                          final isFuture =
                              candidate.year > now.year ||
                              (candidate.year == now.year &&
                                  candidate.month > now.month);

                          final isSelected =
                              selectedYear == _selectedMonth.year &&
                              month == _selectedMonth.month;

                          return Material(
                            color: isSelected ? _accentGreen : _background,
                            borderRadius: BorderRadius.circular(12),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: isFuture
                                  ? null
                                  : () {
                                      Navigator.of(context).pop(candidate);
                                    },
                              child: Center(
                                child: Text(
                                  _shortMonthName(month),
                                  style: TextStyle(
                                    color: isFuture
                                        ? _muted.withValues(alpha: 0.4)
                                        : isSelected
                                        ? Colors.white
                                        : _text,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 14),

                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text(
                            'Cancel',
                            style: TextStyle(color: _green),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (selected == null) return;

    if (selected.year == _selectedMonth.year &&
        selected.month == _selectedMonth.month) {
      return;
    }

    setState(() {
      _selectedMonth = DateTime(selected.year, selected.month);
    });

    await _loadAttendance();
  }

  String _monthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return months[month - 1];
  }

  String _shortMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return months[month - 1];
  }

  String _formatTime(DateTime? value) {
    if (value == null) return '—';

    final local = value.toLocal();

    final hour = local.hour == 0
        ? 12
        : local.hour > 12
        ? local.hour - 12
        : local.hour;

    final minute = local.minute.toString().padLeft(2, '0');

    final period = local.hour >= 12 ? 'PM' : 'AM';

    return '$hour:$minute $period';
  }

  String _dayLabel(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')} '
        '${_shortMonthName(date.month).toUpperCase()}';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final contentWidth = constraints.maxWidth > 620
                ? 560.0
                : constraints.maxWidth;

            return Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: contentWidth,
                height: constraints.maxHeight,
                child: Column(
                  children: [
                    _buildHeader(),

                    Expanded(child: _buildBody()),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: 7),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Attendance',
                  style: TextStyle(
                    color: _text,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                  ),
                ),

                const SizedBox(height: 6),

                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: _selectMonth,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 2,
                      horizontal: 1,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${_monthName(_selectedMonth.month)} '
                          '${_selectedMonth.year}',
                          style: const TextStyle(
                            color: _muted,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 17,
                          color: _green,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: _accentGreen),
      );
    }

    if (_errorMessage != null) {
      return _buildError();
    }

    final report = _report;

    if (report == null) {
      return const Center(
        child: Text(
          'Attendance report unavailable.',
          style: TextStyle(color: _muted),
        ),
      );
    }

    final visibleDays = _visibleDays(report.days);

    return RefreshIndicator(
      color: _accentGreen,
      onRefresh: _loadAttendance,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
        children: [
          _MonthlySummaryCard(report: report),

          const SizedBox(height: 26),

          const Text(
            'Daily Attendance',
            style: TextStyle(
              color: _text,
              fontSize: 19,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 12),

          if (visibleDays.isEmpty)
            const _EmptyAttendance()
          else
            ...visibleDays.map(
              (day) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _DailyAttendanceCard(
                  day: day,
                  dayLabel: _dayLabel(day.date),
                  formatTime: _formatTime,
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<DailyAttendanceModel> _visibleDays(List<DailyAttendanceModel> days) {
    final now = DateTime.now();

    final isCurrentMonth =
        _selectedMonth.year == now.year && _selectedMonth.month == now.month;

    if (!isCurrentMonth) {
      return days;
    }

    return days
        .where(
          (day) => !day.date.isAfter(DateTime(now.year, now.month, now.day)),
        )
        .toList();
  }

  Widget _buildError() {
    return RefreshIndicator(
      color: _accentGreen,
      onRefresh: _loadAttendance,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(30),
        children: [
          const SizedBox(height: 90),
          const Icon(Icons.error_outline_rounded, color: _red, size: 55),
          const SizedBox(height: 14),
          Text(
            _errorMessage ?? 'Could not load attendance.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: _muted, fontSize: 14),
          ),
          const SizedBox(height: 18),
          Center(
            child: OutlinedButton.icon(
              onPressed: _loadAttendance,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _green,
                side: const BorderSide(color: _green),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthlySummaryCard extends StatelessWidget {
  final MonthlyAttendanceModel report;

  const _MonthlySummaryCard({required this.report});

  static const Color _text = Color(0xFF18251E);
  static const Color _muted = Color(0xFF637369);
  static const Color _green = Color(0xFF298C4A);
  static const Color _orange = Color(0xFFFF7D33);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D0A1A12),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'MONTHLY SUMMARY',
            style: TextStyle(
              color: _muted,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),

          const SizedBox(height: 17),

          Row(
            children: [
              Expanded(
                child: _SummaryMeal(
                  label: 'Breakfast',
                  value: report.summary.breakfast,
                  totalDays: report.totalDays,
                ),
              ),
              const _SummaryDivider(),
              Expanded(
                child: _SummaryMeal(
                  label: 'Lunch',
                  value: report.summary.lunch,
                  totalDays: report.totalDays,
                ),
              ),
              const _SummaryDivider(),
              Expanded(
                child: _SummaryMeal(
                  label: 'Dinner',
                  value: report.summary.dinner,
                  totalDays: report.totalDays,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: _orange, size: 14),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  'Recorded meals for this month',
                  style: TextStyle(
                    color: _text.withValues(alpha: 0.62),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryMeal extends StatelessWidget {
  final String label;
  final int value;
  final int totalDays;

  const _SummaryMeal({
    required this.label,
    required this.value,
    required this.totalDays,
  });

  static const Color _green = Color(0xFF298C4A);
  static const Color _text = Color(0xFF18251E);
  static const Color _muted = Color(0xFF637369);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: _text,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 5),

        Text(
          value.toString(),
          style: const TextStyle(
            color: _green,
            fontSize: 26,
            height: 1,
            fontWeight: FontWeight.w700,
          ),
        ),

        const SizedBox(height: 5),

        Text(
          '/ $totalDays days',
          style: const TextStyle(
            color: _muted,
            fontSize: 9,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _SummaryDivider extends StatelessWidget {
  const _SummaryDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 48, color: const Color(0xFFEBE8DF));
  }
}

class _DailyAttendanceCard extends StatelessWidget {
  final DailyAttendanceModel day;
  final String dayLabel;
  final String Function(DateTime?) formatTime;

  const _DailyAttendanceCard({
    required this.day,
    required this.dayLabel,
    required this.formatTime,
  });

  static const Color _text = Color(0xFF18251E);
  static const Color _muted = Color(0xFF637369);
  static const Color _border = Color(0xFFEBE8DF);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(15, 13, 15, 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D0A1A12),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            dayLabel,
            style: const TextStyle(
              color: _text,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),

          const SizedBox(height: 10),

          Container(height: 1, color: _border),

          const SizedBox(height: 13),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _MealStatus(
                  label: 'Breakfast',
                  attendance: day.breakfast,
                  time: formatTime(day.breakfast.attendedAt),
                ),
              ),
              Expanded(
                child: _MealStatus(
                  label: 'Lunch',
                  attendance: day.lunch,
                  time: formatTime(day.lunch.attendedAt),
                ),
              ),
              Expanded(
                child: _MealStatus(
                  label: 'Dinner',
                  attendance: day.dinner,
                  time: formatTime(day.dinner.attendedAt),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MealStatus extends StatelessWidget {
  final String label;
  final MealAttendanceModel attendance;
  final String time;

  const _MealStatus({
    required this.label,
    required this.attendance,
    required this.time,
  });

  static const Color _green = Color(0xFF298C4A);
  static const Color _red = Color(0xFFD94C4C);
  static const Color _orange = Color(0xFFFF7D33);
  static const Color _text = Color(0xFF18251E);
  static const Color _muted = Color(0xFF637369);

  Color get _statusColor {
    if (attendance.isAttended) {
      return _green;
    }

    if (attendance.isMissed) {
      return _red;
    }

    if (attendance.isUpcoming) {
      return _orange;
    }

    return _muted;
  }

  Color get _statusBackground {
    if (attendance.isAttended) {
      return const Color(0xFFEAF6EE);
    }

    if (attendance.isMissed) {
      return const Color(0xFFFFEEEE);
    }

    if (attendance.isUpcoming) {
      return const Color(0xFFFFF3E9);
    }

    return const Color(0xFFF0F2F1);
  }

  IconData get _statusIcon {
    if (attendance.isAttended) {
      return Icons.check_rounded;
    }

    if (attendance.isMissed) {
      return Icons.close_rounded;
    }

    if (attendance.isUpcoming) {
      return Icons.schedule_rounded;
    }

    return Icons.remove_rounded;
  }

  String get _statusText {
    if (attendance.isAttended) {
      return time;
    }

    if (attendance.isMissed) {
      return 'Missed';
    }

    if (attendance.isUpcoming) {
      return 'Upcoming';
    }

    return 'Unavailable';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: _text,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 8),

        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: _statusBackground,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Icon(_statusIcon, color: _statusColor, size: 18),
        ),

        const SizedBox(height: 6),

        Text(
          _statusText,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _statusColor,
            fontSize: 9,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _EmptyAttendance extends StatelessWidget {
  const _EmptyAttendance();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 55),
      child: Column(
        children: [
          Icon(Icons.event_note_rounded, color: Color(0xFF637369), size: 48),
          SizedBox(height: 12),
          Text(
            'No attendance information available.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF637369), fontSize: 13),
          ),
        ],
      ),
    );
  }
}
