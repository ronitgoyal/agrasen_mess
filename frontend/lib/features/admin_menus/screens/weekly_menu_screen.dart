import 'package:flutter/material.dart';

import '../../admin_meal_slots/models/meal_slot_model.dart';
import '../../admin_meal_slots/services/meal_slot_service.dart';
import '../models/weekly_menu_model.dart';
import '../services/weekly_menu_service.dart';

class WeeklyMenuScreen extends StatefulWidget {
  const WeeklyMenuScreen({super.key});

  @override
  State<WeeklyMenuScreen> createState() => _WeeklyMenuScreenState();
}

class _WeeklyMenuScreenState extends State<WeeklyMenuScreen>
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

  // ===========================================================================
  // LOAD DATA
  // ===========================================================================

  Future<void> _loadWeeklyMenu({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

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
        _errorMessage = null;
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

  // ===========================================================================
  // FIND MENU
  // ===========================================================================

  WeeklyMenuModel? _menuFor(int mealSlotId) {
    for (final menu in _menus) {
      if (menu.dayOfWeek == _selectedDay && menu.mealSlotId == mealSlotId) {
        return menu;
      }
    }

    return null;
  }

  // ===========================================================================
  // WEEK DATE
  // ===========================================================================

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

  // ===========================================================================
  // MEAL STYLE
  // ===========================================================================

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

  // ===========================================================================
  // EDIT MENU
  // ===========================================================================

  Future<void> _openMenuEditor(
    MealSlotModel meal,
    WeeklyMenuModel? existingMenu,
  ) async {
    String menuText = existingMenu?.menuItems.join(', ') ?? '';

    bool isActive = existingMenu?.isActive ?? true;

    bool isSaving = false;
    String? dialogError;

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> saveMenu() async {
              if (isSaving) return;

              final items = menuText
                  .split(',')
                  .map((item) => item.trim())
                  .where((item) => item.isNotEmpty)
                  .toSet()
                  .toList();

              if (items.isEmpty) {
                setSheetState(() {
                  dialogError = 'Please enter at least one menu item.';
                });

                return;
              }

              setSheetState(() {
                isSaving = true;
                dialogError = null;
              });

              try {
                if (existingMenu == null) {
                  await _menuService.createMenu(
                    dayOfWeek: _selectedDay,
                    mealSlotId: meal.id,
                    menuItems: items,
                    isActive: isActive,
                  );
                } else {
                  await _menuService.updateMenu(
                    menuId: existingMenu.id,
                    dayOfWeek: _selectedDay,
                    mealSlotId: meal.id,
                    menuItems: items,
                    isActive: isActive,
                  );
                }

                if (!sheetContext.mounted) return;

                Navigator.of(sheetContext).pop(true);
              } catch (error) {
                setSheetState(() {
                  isSaving = false;

                  dialogError = error.toString().replaceFirst(
                    'Exception: ',
                    '',
                  );
                });
              }
            }

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  5,
                  20,
                  MediaQuery.viewInsetsOf(sheetContext).bottom + 24,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // -------------------------------------------------------
                      // TITLE
                      // -------------------------------------------------------

                      Text(
                        existingMenu == null ? 'Add Menu' : 'Edit Menu',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: _text,
                          fontSize: 21,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        '${_weekDays[_selectedDay]} • '
                        '${meal.displayMealType}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: _muted,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // -------------------------------------------------------
                      // ERROR
                      // -------------------------------------------------------
                      if (dialogError != null) ...[
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            dialogError!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],

                      // -------------------------------------------------------
                      // MENU FIELD
                      // -------------------------------------------------------
                      TextFormField(
                        initialValue: menuText,
                        enabled: !isSaving,
                        minLines: 3,
                        maxLines: 5,
                        textCapitalization: TextCapitalization.sentences,
                        onChanged: (value) {
                          menuText = value;
                        },
                        decoration: InputDecoration(
                          labelText: 'Menu items',
                          hintText: 'Poha, Tea, Banana',
                          helperText: 'Separate items with commas.',
                          alignLabelWithHint: true,
                          prefixIcon: const Icon(
                            Icons.restaurant_menu_rounded,
                            color: _accentGreen,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF8FBF9),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: _border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: _accentGreen,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // -------------------------------------------------------
                      // ACTIVE / INACTIVE
                      // -------------------------------------------------------
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FBF9),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: _border),
                        ),
                        child: SwitchListTile(
                          activeThumbColor: _accentGreen,
                          value: isActive,
                          onChanged: isSaving
                              ? null
                              : (value) {
                                  setSheetState(() {
                                    isActive = value;
                                  });
                                },
                          title: const Text(
                            'Active menu',
                            style: TextStyle(
                              color: _text,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            isActive
                                ? 'Students can see this menu'
                                : 'Students cannot see this menu',
                            style: const TextStyle(color: _muted, fontSize: 12),
                          ),
                        ),
                      ),

                      const SizedBox(height: 22),

                      // -------------------------------------------------------
                      // SAVE BUTTON
                      // -------------------------------------------------------
                      SizedBox(
                        height: 50,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: _accentGreen,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: isSaving ? null : saveMenu,
                          icon: isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.save_rounded),
                          label: Text(
                            isSaving ? 'Saving...' : 'Save Menu',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
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

    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: _accentGreen,
          content: Text('Weekly menu successfully saved.'),
        ),
      );

      // Reload silently so the entire page does not
      // switch to the loading screen.
      await _loadWeeklyMenu(showLoading: false);
    }
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

  // ===========================================================================
  // HEADER
  // ===========================================================================

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
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
        ],
      ),
    );
  }

  // ===========================================================================
  // DAY SELECTOR
  // ===========================================================================

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

  // ===========================================================================
  // BODY
  // ===========================================================================

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
              onEdit: () {
                _openMenuEditor(meal, menu);
              },
            ),
          );
        },
      ),
    );
  }

  // ===========================================================================
  // ERROR
  // ===========================================================================

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
      color: selected ? _WeeklyMenuScreenState._accentGreen : Colors.white,
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
                  ? _WeeklyMenuScreenState._accentGreen
                  : _WeeklyMenuScreenState._border,
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
                      : _WeeklyMenuScreenState._muted,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                '$date',
                style: TextStyle(
                  color: selected ? Colors.white : _WeeklyMenuScreenState._text,
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

  final VoidCallback onEdit;

  const _MealCard({
    required this.meal,
    required this.menu,
    required this.color,
    required this.circleBackground,
    required this.initial,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final bool menuAvailable = menu != null && menu!.menuItems.isNotEmpty;

    final bool isInactive = menu != null && !menu!.isActive;

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
                        color: _WeeklyMenuScreenState._muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // ---------------------------------------------------------------
              // ADMIN EDIT BUTTON
              // ---------------------------------------------------------------
              IconButton(
                tooltip: menu == null ? 'Add menu' : 'Edit menu',
                visualDensity: VisualDensity.compact,
                onPressed: onEdit,
                icon: Icon(
                  menu == null
                      ? Icons.add_circle_outline_rounded
                      : Icons.edit_outlined,
                  size: 20,
                  color: _WeeklyMenuScreenState._accentGreen,
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
                          color: _WeeklyMenuScreenState._accentGreen.withValues(
                            alpha: 0.08,
                          ),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _WeeklyMenuScreenState._accentGreen
                                .withValues(alpha: 0.18),
                          ),
                        ),
                        child: Text(
                          item,
                          style: const TextStyle(
                            color: _WeeklyMenuScreenState._green,
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
                      color: _WeeklyMenuScreenState._muted,
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
          ),

          // ---------------------------------------------------------------
          // INACTIVE STATUS - ADMIN ONLY
          // ---------------------------------------------------------------
          if (isInactive) ...[
            const SizedBox(height: 10),

            Padding(
              padding: const EdgeInsets.only(left: 15),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Inactive',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
