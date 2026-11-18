import 'package:flutter/material.dart';

import '../models/admin_overview_model.dart';
import '../services/admin_overview_service.dart';

class AdminOverview extends StatefulWidget {
  final VoidCallback onStudents;
  final VoidCallback onStaff;
  final VoidCallback onMeals;
  final VoidCallback onScanner;

  const AdminOverview({
    super.key,
    required this.onStudents,
    required this.onStaff,
    required this.onMeals,
    required this.onScanner,
  });

  @override
  State<AdminOverview> createState() => AdminOverviewState();
}

class AdminOverviewState extends State<AdminOverview> {
  final AdminOverviewService _service = const AdminOverviewService();

  AdminOverviewModel? _overview;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    refresh();
  }

  Future<void> refresh() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final overview = await _service.getOverview();
      if (!mounted) return;
      setState(() {
        _overview = overview;
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _overview == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 80),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null && _overview == null) {
      return _ErrorCard(message: _errorMessage!, onRetry: refresh);
    }

    final overview = _overview;
    if (overview == null) return const SizedBox.shrink();

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TodayAttendanceCard(overview: overview),
            const SizedBox(height: 28),
            const _SectionTitle('Quick actions'),
            const SizedBox(height: 14),
            _QuickActionsGrid(
              overview: overview,
              onStudents: widget.onStudents,
              onStaff: widget.onStaff,
              onMeals: widget.onMeals,
              onScanner: widget.onScanner,
            ),
            const SizedBox(height: 30),
            const _SectionTitle('Meal performance'),
            const SizedBox(height: 14),
            _MealPerformanceCard(overview: overview),
            const SizedBox(height: 10),
          ],
        ),
        if (_isLoading)
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(),
          ),
      ],
    );
  }
}

class _TodayAttendanceCard extends StatelessWidget {
  static const Color _green = Color(0xFF1A6E3D);

  final AdminOverviewModel overview;

  const _TodayAttendanceCard({required this.overview});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
      decoration: BoxDecoration(
        color: _green,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Today’s attendance',
            style: TextStyle(
              color: Color(0xFFD1F0D9),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _AttendanceValue(
                  label: 'Breakfast',
                  value: overview.breakfastAttendance,
                  percentage: overview.breakfastPerformance,
                ),
              ),
              const _VerticalDivider(),
              Expanded(
                child: _AttendanceValue(
                  label: 'Lunch',
                  value: overview.lunchAttendance,
                  percentage: overview.lunchPerformance,
                ),
              ),
              const _VerticalDivider(),
              Expanded(
                child: _AttendanceValue(
                  label: 'Dinner',
                  value: overview.dinnerAttendance,
                  percentage: overview.dinnerPerformance,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Out of ${overview.activeStudents} active students',
            style: const TextStyle(
              color: Color(0xFFD1F0D9),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _AttendanceValue extends StatelessWidget {
  final String label;
  final int value;
  final int percentage;

  const _AttendanceValue({
    required this.label,
    required this.value,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 27,
            height: 1,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          maxLines: 1,
          style: const TextStyle(color: Colors.white, fontSize: 11),
        ),
        const SizedBox(height: 3),
        Text(
          '$percentage%',
          style: const TextStyle(
            color: Color(0xFFFFA26D),
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 54,
      color: Colors.white.withValues(alpha: 0.18),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF18251E),
        fontSize: 22,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  final AdminOverviewModel overview;
  final VoidCallback onStudents;
  final VoidCallback onStaff;
  final VoidCallback onMeals;
  final VoidCallback onScanner;

  const _QuickActionsGrid({
    required this.overview,
    required this.onStudents,
    required this.onStaff,
    required this.onMeals,
    required this.onScanner,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 12.0;
        final columns = constraints.maxWidth < 320 ? 1 : 2;
        final width =
            (constraints.maxWidth - gap * (columns - 1)) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            _QuickActionCard(
              width: width,
              title: 'Students',
              subtitle: '${overview.totalStudents}',
              letter: 'S',
              color: const Color(0xFF298C4A),
              onTap: onStudents,
            ),
            _QuickActionCard(
              width: width,
              title: 'Staff',
              subtitle: '${overview.totalStaff}',
              letter: 'T',
              color: const Color(0xFFFF7D33),
              onTap: onStaff,
            ),
            _QuickActionCard(
              width: width,
              title: 'Meals',
              subtitle: '${overview.activeMeals} active',
              letter: 'M',
              color: const Color(0xFF637369),
              onTap: onMeals,
            ),
            _QuickActionCard(
              width: width,
              title: 'Scanner',
              subtitle: 'Open',
              letter: 'Q',
              color: const Color(0xFF298C4A),
              onTap: onScanner,
            ),
          ],
        );
      },
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final double width;
  final String title;
  final String subtitle;
  final String letter;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.width,
    required this.title,
    required this.subtitle,
    required this.letter,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            height: 124,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0D0A1A12),
                  blurRadius: 10,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 50,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    letter,
                    style: TextStyle(
                      color: color,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF18251E),
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: color,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF637369),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MealPerformanceCard extends StatelessWidget {
  final AdminOverviewModel overview;

  const _MealPerformanceCard({required this.overview});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D0A1A12),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          _PerformanceRow(
            label: 'Breakfast',
            percentage: overview.breakfastPerformance,
            color: const Color(0xFF298C4A),
          ),
          const SizedBox(height: 22),
          _PerformanceRow(
            label: 'Lunch',
            percentage: overview.lunchPerformance,
            color: const Color(0xFFFF7D33),
          ),
          const SizedBox(height: 22),
          _PerformanceRow(
            label: 'Dinner',
            percentage: overview.dinnerPerformance,
            color: const Color(0xFF1A6E3D),
          ),
        ],
      ),
    );
  }
}

class _PerformanceRow extends StatelessWidget {
  final String label;
  final int percentage;
  final Color color;

  const _PerformanceRow({
    required this.label,
    required this.percentage,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 78,
          child: Text(
            label,
            style: const TextStyle(color: Color(0xFF637369), fontSize: 13),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: percentage / 100,
              minHeight: 9,
              backgroundColor: const Color(0xFFF2F4F3),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 38,
          child: Text(
            '$percentage%',
            textAlign: TextAlign.right,
            style: TextStyle(color: color, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 42),
          const SizedBox(height: 10),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
