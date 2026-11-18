import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/responsive/responsive_layout.dart';
import '../../admin_meal_slots/screens/meal_slot_management_screen.dart';
import '../../admin_menus/screens/weekly_menu_screen.dart';
import '../../admin_staff/screens/staff_management_screen.dart';
import '../../admin_students/screens/student_management_screen.dart';
import '../../auth/providers/auth_provider.dart';
import '../../profile/screens/profile_screen.dart';
import '../../qr_scanner/screens/scanner_screen.dart';
import '../../admin_attendance/screens/admin_attendance_screen.dart';
import '../widgets/admin_overview.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  static const Color _background = Color(0xFFF8FBF9);
  static const Color _green = Color(0xFF298C4A);

  final GlobalKey<AdminOverviewState> _overviewKey =
      GlobalKey<AdminOverviewState>();

  int _selectedIndex = 0;

  void _open(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
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
        return _AdminHome(
          overviewKey: _overviewKey,
          onStudents: () => _open(const StudentManagementScreen()),
          onStaff: () => _open(const StaffManagementScreen()),
          onMeals: () => _open(const MealSlotManagementScreen()),
          onScanner: () => _open(const ScannerScreen()),
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
            setState(() => _selectedIndex = index);
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
              label: 'Weekly Menu',
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

class _AdminHome extends StatelessWidget {
  static const Color _text = Color(0xFF18251E);
  static const Color _muted = Color(0xFF637369);
  static const Color _orange = Color(0xFFFF7D33);

  final GlobalKey<AdminOverviewState> overviewKey;
  final VoidCallback onStudents;
  final VoidCallback onStaff;
  final VoidCallback onMeals;
  final VoidCallback onScanner;

  const _AdminHome({
    required this.overviewKey,
    required this.onStudents,
    required this.onStaff,
    required this.onMeals,
    required this.onScanner,
  });

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
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
    return '${weekdays[now.weekday - 1]}, ${now.day} ${months[now.month - 1]}';
  }

  String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'A';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final name = context.watch<AuthProvider>().user?.name ?? 'Admin';

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: () async {
          await overviewKey.currentState?.refresh();
        },
        child: ResponsiveContent(
          maxWidth: 760,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 22, 18, 28),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                       
                        const SizedBox(height:16),
                        Text(
                          '${_greeting()}, $name',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _muted,
                            fontSize: 28,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _formattedDate(),
                          style: const TextStyle(color: _muted, fontSize: 12),
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
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              AdminOverview(
                key: overviewKey,
                onStudents: onStudents,
                onStaff: onStaff,
                onMeals: onMeals,
                onScanner: onScanner,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
