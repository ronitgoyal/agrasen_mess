import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../attendance/screens/attendance_history_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../qr_code/screens/qr_screen.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/meal_card.dart';
import 'student_weekly_menu_screen.dart';

class StudentDashboardPage extends StatelessWidget {
  const StudentDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DashboardProvider()..loadDashboard(),
      child: const StudentDashboardScreen(),
    );
  }
}

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  static const Color _background = Color(0xFFF8FBF9);
  static const Color _green = Color(0xFF298C4A);

  int _selectedIndex = 0;

  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    if (_selectedIndex == index) return;

    setState(() {
      _selectedIndex = index;
    });
  }

  void _onNavigationTap(int index) {
    if (_selectedIndex == index) return;

    final distance = (index - _selectedIndex).abs();

    if (distance > 1) {
      _pageController.jumpToPage(index);
      return;
    }

    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        physics: const PageScrollPhysics(),
        allowImplicitScrolling: true,
        children: const [
          _DashboardHome(),
          StudentWeeklyMenuScreen(),
          AttendanceHistoryScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          height: 62,
          backgroundColor: Colors.white,
          indicatorColor: const Color(0xFFF0F9F2),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            return TextStyle(
              color: states.contains(WidgetState.selected)
                  ? _green
                  : const Color(0xFF637369),
              fontSize: 11,
              fontWeight: states.contains(WidgetState.selected)
                  ? FontWeight.w700
                  : FontWeight.w500,
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
          onDestinationSelected: _onNavigationTap,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Home',
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
          ],
        ),
      ),
    );
  }
}

class _DashboardHome extends StatelessWidget {
  static const Color _background = Color(0xFFF8FBF9);
  static const Color _text = Color(0xFF18251E);

  const _DashboardHome();

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning,';
    if (hour < 17) return 'Good Afternoon,';
    return 'Good Evening,';
  }

  String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) return 'S';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  Future<void> _openProfile(BuildContext context, String roomNumber) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ProfileScreen(roomNumber: roomNumber)),
    );
  }

  Future<void> _openQr(BuildContext context, dynamic meal) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            QrScreen(mealSlotId: meal.mealSlotId, mealType: meal.mealType),
      ),
    );

    if (!context.mounted) return;
    await context.read<DashboardProvider>().loadDashboard();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DashboardProvider>();
    final dashboard = provider.dashboard;

    if (provider.isLoading && dashboard == null) {
      return const ColoredBox(
        color: _background,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (provider.errorMessage != null && dashboard == null) {
      return _DashboardError(
        message: provider.errorMessage!,
        onRetry: provider.loadDashboard,
      );
    }

    if (dashboard == null) {
      return const Center(child: Text('Dashboard data not available.'));
    }

    final completed = dashboard.completedMeals;
    final total = dashboard.totalActiveMeals;
    final progress = total == 0 ? 0.0 : (completed / total).clamp(0.0, 1.0);

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: provider.loadDashboard,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _HeaderAndProgress(
                  greeting: _greeting,
                  name: dashboard.student.name,
                  roomNumber: dashboard.student.roomNumber,
                  initials: _initials(dashboard.student.name),
                  completed: completed,
                  total: total,
                  progress: progress,
                  onProfileTap: () =>
                      _openProfile(context, dashboard.student.roomNumber),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 18, 18, 24),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const Text(
                      "Today's meals",
                      style: TextStyle(
                        color: _text,
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (dashboard.meals.isEmpty)
                      const _EmptyMeals()
                    else
                      ...dashboard.meals.map(
                        (meal) => Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: MealCard(
                            meal: meal,
                            onGenerateQr: () => _openQr(context, meal),
                          ),
                        ),
                      ),
                  ]),
                ),
              ),
            ],
          ),
        ),
        if (provider.isLoading)
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

class _HeaderAndProgress extends StatelessWidget {
  static const Color _headerGreen = Color(0xFF1A6E3D);
  static const Color _green = Color(0xFF298C4A);
  static const Color _orange = Color(0xFFFF7D33);
  static const Color _text = Color(0xFF18251E);
  static const Color _muted = Color(0xFF637369);

  final String greeting;
  final String name;
  final String roomNumber;
  final String initials;
  final int completed;
  final int total;
  final double progress;
  final VoidCallback onProfileTap;

  const _HeaderAndProgress({
    required this.greeting,
    required this.name,
    required this.roomNumber,
    required this.initials,
    required this.completed,
    required this.total,
    required this.progress,
    required this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = (progress * 100).round();
    final statusBarHeight = MediaQuery.paddingOf(context).top;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 205 + statusBarHeight,
          width: double.infinity,
          color: _headerGreen,
          padding: EdgeInsets.fromLTRB(25, statusBarHeight + 30, 22, 58),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      greeting,
                      style: const TextStyle(
                        color: Color(0xFFD1F0D9),
                        fontSize: 30,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 25,
                        height: 1,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.door_front_door_outlined,
                          color: Color(0xFFD1F0D9),
                          size: 10,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Room $roomNumber',
                          style: const TextStyle(
                            color: Color(0xFFD1F0D9),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Material(
                color: _orange,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onProfileTap,
                  child: SizedBox(
                    width: 65,
                    height: 65,
                    child: Center(
                      child: Text(
                        initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          margin: EdgeInsets.fromLTRB(20, statusBarHeight + 151, 20, 0),
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 17),
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
                "TODAY'S PROGRESS",
                style: TextStyle(
                  color: _muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                '$completed of $total meals completed',
                style: const TextStyle(
                  color: _text,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 9),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: const Color(0xFFF0F9F2),
                        valueColor: const AlwaysStoppedAnimation<Color>(_green),
                      ),
                    ),
                  ),
                  const SizedBox(width: 11),
                  Text(
                    '$percentage%',
                    style: const TextStyle(
                      color: _green,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DashboardError extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _DashboardError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 60),
            const SizedBox(height: 14),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyMeals extends StatelessWidget {
  const _EmptyMeals();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        children: [
          Icon(Icons.no_meals_outlined, size: 48, color: Color(0xFF637369)),
          SizedBox(height: 10),
          Text('No meals are available today.'),
        ],
      ),
    );
  }
}
