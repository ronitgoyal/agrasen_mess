import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/responsive/responsive_layout.dart';
import '../../admin_attendance/models/admin_attendance_model.dart';
import '../../admin_attendance/services/admin_attendance_service.dart';
import '../../admin_attendance/screens/admin_attendance_screen.dart';
import '../../admin_menus/screens/weekly_menu_screen.dart';
import '../../auth/providers/auth_provider.dart';
import '../../profile/screens/profile_screen.dart';
import 'scanner_screen.dart';

class StaffHomeScreen extends StatefulWidget {
  const StaffHomeScreen({super.key});

  @override
  State<StaffHomeScreen> createState() => _StaffHomeScreenState();
}

class _StaffHomeScreenState extends State<StaffHomeScreen> {
  static const Color _background = Color(0xFFF8FBF9);
  static const Color _green = Color(0xFF298C4A);

  int _selectedIndex = 0;

  void _openScanner() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ScannerScreen()));
  }

  Widget _selectedPage() {
    switch (_selectedIndex) {
      case 1:
        return const WeeklyMenuScreen();

      case 2:
        return const AdminAttendanceScreen();

      case 3:
        return const ProfileScreen();

      default:
        return _StaffOverview(
          onScanner: _openScanner,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: _selectedPage(),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          height: 72,
          backgroundColor: Colors.white,
          indicatorColor: const Color(0xFFF0F9F2),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);

            return TextStyle(
              color: selected ? _green : const Color(0xFF637369),
              fontSize: 10.5,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            );
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            return IconThemeData(
              color: states.contains(WidgetState.selected)
                  ? _green
                  : const Color(0xFF637369),
              size: 20,
            );
          }),
        ),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Overview',
            ),
            NavigationDestination(
              icon: Icon(Icons.restaurant_menu_outlined),
              selectedIcon: Icon(Icons.restaurant_menu_rounded),
              label: 'Menu',
            ),
            NavigationDestination(
              icon: Icon(Icons.fact_check_outlined),
              selectedIcon: Icon(Icons.fact_check_rounded),
              label: 'Attendance',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

class _StaffOverview extends StatefulWidget {
  final VoidCallback onScanner;

  const _StaffOverview({
    required this.onScanner,
  });

  @override
  State<_StaffOverview> createState() => _StaffOverviewState();
}

class _StaffOverviewState extends State<_StaffOverview>
    with AutomaticKeepAliveClientMixin {
  static const Color _background = Color(0xFFF8FBF9);
  static const Color _green = Color(0xFF298C4A);
  static const Color _darkGreen = Color(0xFF1A6E3D);
  static const Color _orange = Color(0xFFFF7D33);
  static const Color _text = Color(0xFF18251E);
  static const Color _muted = Color(0xFF637369);
  static const Color _border = Color(0xFFEBE8DF);

  final AdminAttendanceService _attendanceService =
      const AdminAttendanceService();

  AdminAttendanceModel? _attendance;

  bool _isLoading = true;
  String? _errorMessage;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadAttendance();
  }

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
      final now = DateTime.now();

      final report = await _attendanceService.getMonthlySummary(
        year: now.year,
        month: now.month,
      );

      if (!mounted) return;

      setState(() {
        _attendance = report;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage =
            error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  String _greeting() {
    final hour = DateTime.now().hour;

    if (hour < 12) {
      return 'Good morning';
    }

    if (hour < 17) {
      return 'Good afternoon';
    }

    return 'Good evening';
  }

  String _formattedDate() {
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

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

    final now = DateTime.now();

    return '${weekdays[now.weekday - 1]}, '
        '${now.day} ${months[now.month - 1]}';
  }

  String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) {
      return 'S';
    }

    if (parts.length == 1) {
      return parts.first[0].toUpperCase();
    }

    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final user = context.watch<AuthProvider>().user;
    final name = user?.name ?? 'Mess Staff';

    return ColoredBox(
      color: _background,
      child: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: _green,
          onRefresh: () => _loadAttendance(
            showLoading: false,
          ),
          child: ResponsiveContent(
            maxWidth: 760,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                18,
                22,
                18,
                28,
              ),
              children: [
                _buildHeader(name),

                const SizedBox(height: 28),

                const Text(
                  "Today's Attendance",
                  style: TextStyle(
                    color: _text,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 4),

                const Text(
                  'Live meal attendance for today',
                  style: TextStyle(
                    color: _muted,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 14),

                _buildAttendanceSection(),

                const SizedBox(height: 28),

                const Text(
                  'Quick Actions',
                  style: TextStyle(
                    color: _text,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 14),

                _ScanQrCard(
                  onTap: widget.onScanner,
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String name) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              Text(
                '${_greeting()},',
                style: const TextStyle(
                  color: _muted,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 3),

              Text(
                name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _text,
                  fontSize: 28,
                  height: 1.1,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 7),

              Text(
                _formattedDate(),
                style: const TextStyle(
                  color: _muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 12),

        CircleAvatar(
          radius: 25,
          backgroundColor: _orange,
          child: Text(
            _initials(name),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceSection() {
    if (_isLoading && _attendance == null) {
      return const _AttendanceLoadingCard();
    }

    if (_attendance == null) {
      return _AttendanceErrorCard(
        message: _errorMessage ?? 'Could not load attendance.',
        onRetry: _loadAttendance,
      );
    }

    final report = _attendance!;
    final daily = report.dailySummary;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        12,
        18,
        12,
        18,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _border,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D0A1A12),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _AttendanceProgress(
              title: 'Breakfast',
              shortTitle: 'BF',
              count: daily.breakfast,
              total: daily.totalStudents,
              icon: Icons.free_breakfast_rounded,
              color: _orange,
            ),
          ),

          _verticalDivider(),

          Expanded(
            child: _AttendanceProgress(
              title: 'Lunch',
              shortTitle: 'Lunch',
              count: daily.lunch,
              total: daily.totalStudents,
              icon: Icons.lunch_dining_rounded,
              color: _green,
            ),
          ),

          _verticalDivider(),

          Expanded(
            child: _AttendanceProgress(
              title: 'Dinner',
              shortTitle: 'Dinner',
              count: daily.dinner,
              total: daily.totalStudents,
              icon: Icons.dinner_dining_rounded,
              color: _darkGreen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _verticalDivider() {
    return Container(
      width: 1,
      height: 112,
      margin: const EdgeInsets.symmetric(horizontal: 5),
      color: _border,
    );
  }
}

class _AttendanceProgress extends StatelessWidget {
  final String title;
  final String shortTitle;
  final int count;
  final int total;
  final IconData icon;
  final Color color;

  const _AttendanceProgress({
    required this.title,
    required this.shortTitle,
    required this.count,
    required this.total,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final progress = total <= 0
        ? 0.0
        : (count / total).clamp(0.0, 1.0).toDouble();

    return Column(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),

        const SizedBox(height: 9),

        LayoutBuilder(
          builder: (context, constraints) {
            return Text(
              constraints.maxWidth < 80 ? shortTitle : title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF637369),
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            );
          },
        ),

        const SizedBox(height: 5),

        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            '$count / $total',
            style: const TextStyle(
              color: Color(0xFF18251E),
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),

        const SizedBox(height: 10),

        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: const Color(0xFFF0F2EF),
            valueColor: AlwaysStoppedAnimation<Color>(
              color,
            ),
          ),
        ),
      ],
    );
  }
}

class _ScanQrCard extends StatelessWidget {
  final VoidCallback onTap;

  const _ScanQrCard({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFFEBE8DF),
            ),
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
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(
                    0xFF298C4A,
                  ).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(15),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.qr_code_scanner_rounded,
                  color: Color(0xFF298C4A),
                  size: 27,
                ),
              ),

              const SizedBox(width: 15),

              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Scan QR',
                      style: TextStyle(
                        color: Color(0xFF18251E),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Scan student QR to record meal attendance',
                      style: TextStyle(
                        color: Color(0xFF637369),
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F9F2),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: Color(0xFF298C4A),
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AttendanceLoadingCard extends StatelessWidget {
  const _AttendanceLoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFEBE8DF),
        ),
      ),
      alignment: Alignment.center,
      child: const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: Color(0xFF298C4A),
        ),
      ),
    );
  }
}

class _AttendanceErrorCard extends StatelessWidget {
  final String message;
  final Future<void> Function({
    bool showLoading,
  }) onRetry;

  const _AttendanceErrorCard({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFEBE8DF),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            color: Color(0xFF637369),
            size: 30,
          ),

          const SizedBox(height: 10),

          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF637369),
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 12),

          TextButton.icon(
            onPressed: () {
              onRetry(showLoading: true);
            },
            icon: const Icon(
              Icons.refresh_rounded,
              size: 18,
            ),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
}