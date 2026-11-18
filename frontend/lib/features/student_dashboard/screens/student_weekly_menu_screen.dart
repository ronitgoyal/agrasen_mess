import 'package:flutter/material.dart';

import '../../admin_meal_slots/models/meal_slot_model.dart';
import '../../admin_meal_slots/services/meal_slot_service.dart';
import '../../admin_menus/models/weekly_menu_model.dart';
import '../../admin_menus/services/weekly_menu_service.dart';

class StudentWeeklyMenuScreen extends StatefulWidget {
  /// Keep this false for students.
  ///
  /// Later:
  /// Admin  -> canEdit: true
  /// Staff  -> canEdit: true
  final bool canEdit;

  const StudentWeeklyMenuScreen({super.key, this.canEdit = false});

  @override
  State<StudentWeeklyMenuScreen> createState() =>
      _StudentWeeklyMenuScreenState();
}

class _StudentWeeklyMenuScreenState extends State<StudentWeeklyMenuScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  // ---------------------------------------------------------------------------
  // COLORS
  // ---------------------------------------------------------------------------

  static const Color _background = Color(0xFFF8FBF9);
  static const Color _green = Color(0xFF1A6E3D);
  static const Color _accentGreen = Color(0xFF298C4A);
  static const Color _orange = Color(0xFFFF7D33);
  static const Color _text = Color(0xFF18251E);
  static const Color _muted = Color(0xFF637369);
  static const Color _border = Color(0xFFEBE8DF);

  // ---------------------------------------------------------------------------
  // DATA
  // ---------------------------------------------------------------------------

  static const Map<int, String> _weekDays = {
    1: 'Monday',
    2: 'Tuesday',
    3: 'Wednesday',
    4: 'Thursday',
    5: 'Friday',
    6: 'Saturday',
    7: 'Sunday',
  };

  static const Map<int, String> _shortWeekDays = {
    1: 'MON',
    2: 'TUE',
    3: 'WED',
    4: 'THU',
    5: 'FRI',
    6: 'SAT',
    7: 'SUN',
  };

  final WeeklyMenuService _menuService = const WeeklyMenuService();
  final MealSlotService _mealService = const MealSlotService();

  List<WeeklyMenuModel> _menus = [];
  List<MealSlotModel> _mealSlots = [];

  int _selectedDay = DateTime.now().weekday;

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadWeeklyMenu();
  }

  // ---------------------------------------------------------------------------
  // API
  // ---------------------------------------------------------------------------

  Future<void> _loadWeeklyMenu() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _mealService.getMealSlots(),
        _menuService.getWeeklyMenus(),
      ]);

      final mealSlots = results[0] as List<MealSlotModel>;
      final menus = results[1] as List<WeeklyMenuModel>;

      mealSlots.sort(
        (a, b) => _mealOrder(a.mealType).compareTo(_mealOrder(b.mealType)),
      );

      if (!mounted) return;

      setState(() {
        _mealSlots = mealSlots;
        _menus = menus;
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

  int _mealOrder(String type) {
    switch (type.toLowerCase()) {
      case 'breakfast':
        return 1;

      case 'lunch':
        return 2;

      case 'dinner':
        return 3;

      default:
        return 4;
    }
  }

  WeeklyMenuModel? _menuFor(int mealSlotId) {
    for (final menu in _menus) {
      if (menu.dayOfWeek == _selectedDay &&
          menu.mealSlotId == mealSlotId &&
          menu.isActive) {
        return menu;
      }
    }

    return null;
  }

  // ---------------------------------------------------------------------------
  // WEEK DATE
  // ---------------------------------------------------------------------------

  DateTime get _monday {
    final now = DateTime.now();

    return DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
  }

  DateTime _dateForDay(int weekday) {
    return _monday.add(Duration(days: weekday - 1));
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

  String get _weekRange {
    final start = _monday;
    final end = start.add(const Duration(days: 6));

    if (start.month == end.month) {
      return '${start.day}–${end.day} ${_monthName(start.month)}';
    }

    return '${start.day} ${_monthName(start.month)}'
        ' – '
        '${end.day} ${_monthName(end.month)}';
  }

  // ---------------------------------------------------------------------------
  // MEAL STYLE
  // ---------------------------------------------------------------------------

  Color _mealColor(String type) {
    return _orange;
  }

  Color _mealCircleBackground(String type) {
    return const Color(0xFFFFF1E8);
  }

  String _mealInitial(String type) {
    final value = type.trim();

    if (value.isEmpty) {
      return 'M';
    }

    return value[0].toUpperCase();
  }

  // ---------------------------------------------------------------------------
  // EDIT
  // ---------------------------------------------------------------------------

  void _editMenu(MealSlotModel meal, WeeklyMenuModel? menu) {
    // We will connect the Admin/Staff edit screen in the next step.
    //
    // Keeping the callback here means this same Weekly Menu UI can later
    // be opened by Student, Staff and Admin without rebuilding the screen.

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Edit ${meal.displayMealType} menu')),
    );
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            /*
             * Figma reference width = 390px.
             *
             * On phones we use almost the complete width.
             * On tablets we limit the width so the cards do not become
             * excessively large.
             */

            final double contentWidth = constraints.maxWidth > 600
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

                    _buildDaySelector(),

                    const SizedBox(height: 20),

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

  // ---------------------------------------------------------------------------
  // HEADER
  // ---------------------------------------------------------------------------

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(30),
            onTap: () {
              Navigator.of(context).maybePop();
            },
            child: const SizedBox(),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Weekly Menu',
                  style: TextStyle(
                    color: _text,
                    fontSize: 22,
                    height: 1.1,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  _weekRange,
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),

          if (widget.canEdit)
            TextButton.icon(
              onPressed: () {
                if (_mealSlots.isNotEmpty) {
                  final meal = _mealSlots.first;
                  _editMenu(meal, _menuFor(meal.id));
                }
              },
              style: TextButton.styleFrom(
                foregroundColor: _accentGreen,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
              ),
              icon: const Icon(Icons.edit_rounded, size: 17),
              label: const Text(
                'Edit',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // DAY SELECTOR
  // ---------------------------------------------------------------------------

  Widget _buildDaySelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 17),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const double gap = 7;

          final double availableWidth = constraints.maxWidth - (gap * 6);

          final double itemWidth = availableWidth / 7;

          return Row(
            children: List.generate(7, (index) {
              final int day = index + 1;
              final bool selected = day == _selectedDay;

              final DateTime date = _dateForDay(day);

              return Padding(
                padding: EdgeInsets.only(right: index == 6 ? 0 : gap),
                child: _DayItem(
                  width: itemWidth,
                  day: _shortWeekDays[day]!,
                  date: date.day,
                  selected: selected,
                  onTap: () {
                    setState(() {
                      _selectedDay = day;
                    });
                  },
                ),
              );
            }),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // BODY
  // ---------------------------------------------------------------------------

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: _accentGreen),
      );
    }

    if (_errorMessage != null) {
      return _buildError();
    }

    if (_mealSlots.isEmpty) {
      return RefreshIndicator(
        color: _accentGreen,
        onRefresh: _loadWeeklyMenu,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 160),
            Center(
              child: Text(
                'Meal slots not available.',
                style: TextStyle(color: _muted, fontSize: 14),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: _accentGreen,
      onRefresh: _loadWeeklyMenu,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(17, 10, 17, 30),
        itemCount: _mealSlots.length,
        itemBuilder: (context, index) {
          final meal = _mealSlots[index];

          final menu = _menuFor(meal.id);

          return Padding(
            padding: EdgeInsets.only(
              bottom: index == _mealSlots.length - 1 ? 0 : 20,
            ),
            child: _MealCard(
              meal: meal,
              menu: menu,
              color: _mealColor(meal.mealType),
              circleBackground: _mealCircleBackground(meal.mealType),
              initial: _mealInitial(meal.mealType),
              canEdit: widget.canEdit,
              onEdit: () {
                _editMenu(meal, menu);
              },
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ERROR
  // ---------------------------------------------------------------------------

  Widget _buildError() {
    return RefreshIndicator(
      color: _accentGreen,
      onRefresh: _loadWeeklyMenu,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: [
          const SizedBox(height: 100),

          const Icon(Icons.error_outline_rounded, color: _orange, size: 48),

          const SizedBox(height: 14),

          Text(
            _errorMessage ?? 'Could not load weekly menu.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: _muted, fontSize: 14, height: 1.4),
          ),

          const SizedBox(height: 18),

          Center(
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _accentGreen,
                foregroundColor: Colors.white,
              ),
              onPressed: _loadWeeklyMenu,
              child: const Text('Retry'),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// DAY ITEM
// =============================================================================

class _DayItem extends StatelessWidget {
  final double width;
  final String day;
  final int date;
  final bool selected;
  final VoidCallback onTap;

  const _DayItem({
    required this.width,
    required this.day,
    required this.date,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? _StudentWeeklyMenuScreenState._accentGreen
          : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: width,
          height: 54,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? _StudentWeeklyMenuScreenState._accentGreen
                  : _StudentWeeklyMenuScreenState._border,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                day,
                maxLines: 1,
                style: TextStyle(
                  color: selected
                      ? Colors.white
                      : _StudentWeeklyMenuScreenState._muted,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                '$date',
                style: TextStyle(
                  color: selected
                      ? Colors.white
                      : _StudentWeeklyMenuScreenState._text,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// MEAL CARD
// =============================================================================

class _MealCard extends StatelessWidget {
  final MealSlotModel meal;
  final WeeklyMenuModel? menu;

  final Color color;
  final Color circleBackground;

  final String initial;

  final bool canEdit;
  final VoidCallback onEdit;

  const _MealCard({
    required this.meal,
    required this.menu,
    required this.color,
    required this.circleBackground,
    required this.initial,
    required this.canEdit,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final bool menuAvailable = menu != null && menu!.menuItems.isNotEmpty;

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 112),
      padding: const EdgeInsets.fromLTRB(13, 14, 13, 14),
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: circleBackground,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  initial,
                  style: TextStyle(
                    color: color,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meal.displayMealType.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.15,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      '${meal.displayStartTime} – '
                      '${meal.displayEndTime}',
                      style: const TextStyle(
                        color: _StudentWeeklyMenuScreenState._muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              if (canEdit)
                IconButton(
                  tooltip: 'Edit menu',
                  visualDensity: VisualDensity.compact,
                  onPressed: onEdit,
                  icon: const Icon(
                    Icons.edit_outlined,
                    size: 19,
                    color: _StudentWeeklyMenuScreenState._accentGreen,
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),

          Padding(
            padding: const EdgeInsets.only(left: 15),
            child: menuAvailable
                ? Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: menu!.menuItems.map((item) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: _StudentWeeklyMenuScreenState._accentGreen
                              .withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _StudentWeeklyMenuScreenState._accentGreen
                                .withValues(alpha: 0.18),
                          ),
                        ),
                        child: Text(
                          item,
                          style: const TextStyle(
                            color: _StudentWeeklyMenuScreenState._green,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList(),
                  )
                : const Text(
                    'Menu not available',
                    style: TextStyle(
                      color: _StudentWeeklyMenuScreenState._muted,
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
