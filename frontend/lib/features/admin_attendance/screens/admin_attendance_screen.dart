import 'package:flutter/material.dart';

import '../models/admin_attendance_model.dart';
import '../services/admin_attendance_service.dart';

class AdminAttendanceScreen extends StatefulWidget {
  const AdminAttendanceScreen({super.key});

  @override
  State<AdminAttendanceScreen> createState() =>
      _AdminAttendanceScreenState();
}

class _AdminAttendanceScreenState extends State<AdminAttendanceScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // ===========================================================================
  // COLORS
  // ===========================================================================

  static const Color _background = Color(0xFFF8FBF9);
  static const Color _green = Color(0xFF1A6E3D);
  static const Color _accentGreen = Color(0xFF298C4A);
  static const Color _orange = Color(0xFFFF7D33);
  static const Color _text = Color(0xFF18251E);
  static const Color _muted = Color(0xFF637369);
  static const Color _border = Color(0xFFEBE8DF);

  // ===========================================================================
  // DATA
  // ===========================================================================

  final AdminAttendanceService _service =
      const AdminAttendanceService();

  late DateTime _selectedMonth;

  AdminAttendanceModel? _report;

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();

    _selectedMonth = DateTime(
      now.year,
      now.month,
    );

    _loadAttendance();
  }

  // ===========================================================================
  // LOAD ATTENDANCE
  // ===========================================================================

  Future<void> _loadAttendance({
    bool showLoading = true,
  }) async {
    if (showLoading && mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final report = await _service.getMonthlySummary(
        year: _selectedMonth.year,
        month: _selectedMonth.month,
      );

      if (!mounted) return;

      setState(() {
        _report = report;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = error
            .toString()
            .replaceFirst('Exception: ', '');
      });
    }
  }

  // ===========================================================================
  // MONTH
  // ===========================================================================

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

  String get _selectedMonthLabel {
    return '${_monthName(_selectedMonth.month)} '
        '${_selectedMonth.year}';
  }

  Future<void> _selectMonth() async {
    final now = DateTime.now();

    int selectedYear = _selectedMonth.year;
    int selectedMonth = _selectedMonth.month;

    final result = await showModalBottomSheet<DateTime>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            bool isFutureMonth(int year, int month) {
              if (year > now.year) return true;

              if (year == now.year &&
                  month > now.month) {
                return true;
              }

              return false;
            }

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  4,
                  20,
                  24,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment:
                      CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Select Month',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _text,
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 22),

                    Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            setSheetState(() {
                              selectedYear--;
                            });
                          },
                          icon: const Icon(
                            Icons.chevron_left_rounded,
                          ),
                        ),

                        Expanded(
                          child: Text(
                            '$selectedYear',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: _text,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),

                        IconButton(
                          onPressed:
                              selectedYear >= now.year
                                  ? null
                                  : () {
                                      setSheetState(() {
                                        selectedYear++;
                                      });
                                    },
                          icon: const Icon(
                            Icons.chevron_right_rounded,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    GridView.builder(
                      shrinkWrap: true,
                      physics:
                          const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 2.3,
                        crossAxisSpacing: 9,
                        mainAxisSpacing: 9,
                      ),
                      itemCount: 12,
                      itemBuilder: (context, index) {
                        final month = index + 1;

                        final disabled =
                            isFutureMonth(
                          selectedYear,
                          month,
                        );

                        final selected =
                            selectedMonth == month;

                        return Material(
                          color: selected
                              ? _accentGreen
                              : const Color(0xFFF8FBF9),
                          borderRadius:
                              BorderRadius.circular(12),
                          child: InkWell(
                            onTap: disabled
                                ? null
                                : () {
                                    setSheetState(() {
                                      selectedMonth = month;
                                    });
                                  },
                            borderRadius:
                                BorderRadius.circular(12),
                            child: Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                borderRadius:
                                    BorderRadius.circular(
                                  12,
                                ),
                                border: Border.all(
                                  color: selected
                                      ? _accentGreen
                                      : _border,
                                ),
                              ),
                              child: Text(
                                _monthName(month)
                                    .substring(0, 3),
                                style: TextStyle(
                                  color: disabled
                                      ? _muted.withValues(
                                          alpha: 0.35,
                                        )
                                      : selected
                                          ? Colors.white
                                          : _text,
                                  fontSize: 12,
                                  fontWeight:
                                      FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 22),

                    SizedBox(
                      height: 50,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor:
                              _accentGreen,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(sheetContext).pop(
                            DateTime(
                              selectedYear,
                              selectedMonth,
                            ),
                          );
                        },
                        child: const Text(
                          'View Attendance',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (result == null || !mounted) return;

    if (result.year == _selectedMonth.year &&
        result.month == _selectedMonth.month) {
      return;
    }

    setState(() {
      _selectedMonth = result;
    });

    await _loadAttendance();
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double contentWidth =
                constraints.maxWidth > 600
                    ? 560
                    : constraints.maxWidth;

            return Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: contentWidth,
                height: constraints.maxHeight,
                child: Column(
                  children: [
                    _buildHeader(),

                    Expanded(
                      child: _buildBody(),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ===========================================================================
  // HEADER
  // ===========================================================================

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        22,
        18,
        22,
        12,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Attendance',
                  style: TextStyle(
                    color: _text,
                    fontSize: 22,
                    height: 1.1,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 9),

                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _selectMonth,
                    borderRadius:
                        BorderRadius.circular(10),
                    child: Padding(
                      padding:
                          const EdgeInsets.symmetric(
                        vertical: 4,
                        horizontal: 2,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _selectedMonthLabel,
                            style: const TextStyle(
                              color: _muted,
                              fontSize: 12,
                              fontWeight:
                                  FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 3),
                          const Icon(
                            Icons
                                .keyboard_arrow_down_rounded,
                            size: 18,
                            color: _accentGreen,
                          ),
                        ],
                      ),
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

  // ===========================================================================
  // BODY
  // ===========================================================================

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: _accentGreen,
        ),
      );
    }

    if (_errorMessage != null) {
      return _buildError();
    }

    final report = _report;

    if (report == null) {
      return _buildError(
        message: 'Attendance data is unavailable.',
      );
    }

    return RefreshIndicator(
      color: _accentGreen,
      onRefresh: () =>
          _loadAttendance(showLoading: false),
      child: ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          17,
          10,
          17,
          30,
        ),
        children: [
          _buildDailySummary(report),

          const SizedBox(height: 20),

          _buildMonthlySummary(report),

          const SizedBox(height: 20),

          _buildCouponSummary(report),
        ],
      ),
    );
  }

  // ===========================================================================
  // DAILY SUMMARY
  // ===========================================================================

  Widget _buildDailySummary(
    AdminAttendanceModel report,
  ) {
    final summary = report.dailySummary;

    return _SectionCard(
      title: 'DAILY SUMMARY',
      subtitle:
          '${summary.date.day} '
          '${_monthName(summary.date.month)}',
      child: Row(
        children: [
          Expanded(
            child: _MealStat(
              label: 'Breakfast',
              value:
                  '${summary.breakfast}'
                  '/${summary.totalStudents}',
              icon: Icons.free_breakfast_rounded,
            ),
          ),

          _verticalDivider(),

          Expanded(
            child: _MealStat(
              label: 'Lunch',
              value:
                  '${summary.lunch}'
                  '/${summary.totalStudents}',
              icon: Icons.lunch_dining_rounded,
            ),
          ),

          _verticalDivider(),

          Expanded(
            child: _MealStat(
              label: 'Dinner',
              value:
                  '${summary.dinner}'
                  '/${summary.totalStudents}',
              icon: Icons.dinner_dining_rounded,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // MONTHLY SUMMARY
  // ===========================================================================

  Widget _buildMonthlySummary(
    AdminAttendanceModel report,
  ) {
    final summary = report.monthlySummary;

    return _SectionCard(
      title: 'MONTHLY SUMMARY',
      subtitle:
          'Through ${report.throughDate.day} '
          '${_monthName(report.throughDate.month)}',
      child: Row(
        children: [
          Expanded(
            child: _MealStat(
              label: 'Breakfast',
              value: '${summary.breakfast}',
              icon: Icons.free_breakfast_rounded,
            ),
          ),

          _verticalDivider(),

          Expanded(
            child: _MealStat(
              label: 'Lunch',
              value: '${summary.lunch}',
              icon: Icons.lunch_dining_rounded,
            ),
          ),

          _verticalDivider(),

          Expanded(
            child: _MealStat(
              label: 'Dinner',
              value: '${summary.dinner}',
              icon: Icons.dinner_dining_rounded,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // COUPON SUMMARY
  // ===========================================================================

  Widget _buildCouponSummary(
    AdminAttendanceModel report,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        16,
        17,
        16,
        16,
      ),
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
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'COUPON SUMMARY',
            style: TextStyle(
              color: _green,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),

          const SizedBox(height: 15),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F9F2),
              borderRadius:
                  BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration:
                      const BoxDecoration(
                    color: Color(0xFFE2F3E6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons
                        .confirmation_number_outlined,
                    color: _accentGreen,
                    size: 21,
                  ),
                ),

                const SizedBox(width: 13),

                const Expanded(
                  child: Text(
                    'Total Coupons',
                    style: TextStyle(
                      color: _text,
                      fontSize: 14,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                ),

                Text(
                  '${report.totalCouponCount}',
                  style: const TextStyle(
                    color: _green,
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),

          const Text(
            'Daily Coupon Count',
            style: TextStyle(
              color: _text,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 10),

          if (report.dailyCouponCounts.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(
                vertical: 20,
              ),
              child: Center(
                child: Text(
                  'No coupon data available.',
                  style: TextStyle(
                    color: _muted,
                    fontSize: 13,
                  ),
                ),
              ),
            )
          else
            ...report.dailyCouponCounts
                .reversed
                .map(
                  (item) =>
                      _buildCouponRow(item),
                ),
        ],
      ),
    );
  }

  Widget _buildCouponRow(
    DailyCouponCount item,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 12,
      ),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: _border,
            width: 0.8,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xFFFFF1E8),
              shape: BoxShape.circle,
            ),
            child: Text(
              '${item.date.day}',
              style: const TextStyle(
                color: _orange,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Text(
              '${item.date.day} '
              '${_monthName(item.date.month)}',
              style: const TextStyle(
                color: _text,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          Text(
            '${item.count}',
            style: const TextStyle(
              color: _green,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(width: 5),

          const Text(
            'coupons',
            style: TextStyle(
              color: _muted,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _verticalDivider() {
    return Container(
      width: 1,
      height: 62,
      color: _border,
    );
  }

  // ===========================================================================
  // ERROR
  // ===========================================================================

  Widget _buildError({
    String? message,
  }) {
    return RefreshIndicator(
      color: _accentGreen,
      onRefresh: () =>
          _loadAttendance(showLoading: false),
      child: ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding:
            const EdgeInsets.symmetric(
          horizontal: 24,
        ),
        children: [
          const SizedBox(height: 100),

          const Icon(
            Icons.error_outline_rounded,
            color: _orange,
            size: 48,
          ),

          const SizedBox(height: 14),

          Text(
            message ??
                _errorMessage ??
                'Could not load attendance.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _muted,
              fontSize: 14,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 18),

          Center(
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _accentGreen,
                foregroundColor: Colors.white,
              ),
              onPressed: () =>
                  _loadAttendance(),
              child: const Text('Retry'),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// SECTION CARD
// =============================================================================

class _SectionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;

  const _SectionCard({
    required this.title,
    this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        16,
        17,
        16,
        18,
      ),
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
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color:
                        _AdminAttendanceScreenState
                            ._green,
                    fontSize: 11,
                    fontWeight:
                        FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),

              if (subtitle != null)
                Text(
                  subtitle!,
                  style: const TextStyle(
                    color:
                        _AdminAttendanceScreenState
                            ._muted,
                    fontSize: 11,
                    fontWeight:
                        FontWeight.w500,
                  ),
                ),
            ],
          ),

          const SizedBox(height: 20),

          child,
        ],
      ),
    );
  }
}

// =============================================================================
// MEAL STAT
// =============================================================================

class _MealStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _MealStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: const BoxDecoration(
            color: Color(0xFFFFF1E8),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color:
                _AdminAttendanceScreenState
                    ._orange,
            size: 19,
          ),
        ),

        const SizedBox(height: 9),

        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color:
                _AdminAttendanceScreenState
                    ._muted,
            fontSize: 10.5,
            fontWeight: FontWeight.w500,
          ),
        ),

        const SizedBox(height: 5),

        Text(
          value,
          style: const TextStyle(
            color:
                _AdminAttendanceScreenState
                    ._text,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}