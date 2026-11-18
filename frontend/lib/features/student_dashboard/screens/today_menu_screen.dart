import 'package:flutter/material.dart';

import '../../../core/responsive/responsive_layout.dart';
import '../../admin_meal_slots/models/meal_slot_model.dart';
import '../../admin_meal_slots/services/meal_slot_service.dart';
import '../../admin_menus/models/weekly_menu_model.dart';
import '../../admin_menus/services/weekly_menu_service.dart';

class TodayMenuScreen extends StatefulWidget {
  const TodayMenuScreen({super.key});

  @override
  State<TodayMenuScreen> createState() => _TodayMenuScreenState();
}

class _TodayMenuScreenState extends State<TodayMenuScreen> {
  final WeeklyMenuService _menuService = const WeeklyMenuService();

  final MealSlotService _mealService = const MealSlotService();

  List<WeeklyMenuModel> _menus = [];
  List<MealSlotModel> _mealSlots = [];

  bool _isLoading = true;
  String? _errorMessage;

  static const List<String> _weekDays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  @override
  void initState() {
    super.initState();
    _loadTodayMenu();
  }

  Future<void> _loadTodayMenu() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final mealSlots = await _mealService.getMealSlots();

      final menus = await _menuService.getTodayMenus();

      mealSlots.sort((first, second) {
        return _mealOrder(first.mealType)
            .compareTo(_mealOrder(second.mealType));
      });

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

  int _mealOrder(String mealType) {
    switch (mealType.toLowerCase()) {
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

  WeeklyMenuModel? _findMenu(int mealSlotId) {
    for (final menu in _menus) {
      if (menu.mealSlotId == mealSlotId && menu.isActive) {
        return menu;
      }
    }

    return null;
  }

  IconData _mealIcon(String mealType) {
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return Icons.free_breakfast;
      case 'lunch':
        return Icons.lunch_dining;
      case 'dinner':
        return Icons.dinner_dining;
      default:
        return Icons.restaurant;
    }
  }

  Color _mealColor(String mealType) {
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return Colors.orange;
      case 'lunch':
        return Colors.green;
      case 'dinner':
        return Colors.indigo;
      default:
        return Colors.blueGrey;
    }
  }

  String get _todayName {
    return _weekDays[DateTime.now().weekday - 1];
  }

  String get _formattedDate {
    final now = DateTime.now();

    return '${now.day.toString().padLeft(2, '0')}/'
        '${now.month.toString().padLeft(2, '0')}/'
        '${now.year}';
  }

  int get _availableMenuCount {
    return _mealSlots.where((meal) {
      return _findMenu(meal.id) != null;
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Today's Menu"),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _isLoading ? null : _loadTodayMenu,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ResponsiveContent(maxWidth: 1050, child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return _ErrorView(message: _errorMessage!, onRetry: _loadTodayMenu);
    }

    if (_mealSlots.isEmpty) {
      return const _EmptyView(
        icon: Icons.no_meals,
        message: 'Meal slots not available.',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTodayMenu,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          _DayHeader(
            dayName: _todayName,
            formattedDate: _formattedDate,
            availableMenus: _availableMenuCount,
            totalMeals: _mealSlots.length,
          ),

          const SizedBox(height: 22),

          Text(
            'Meals',
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 12),

          _buildResponsiveMeals(),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildResponsiveMeals() {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 14.0;

        final columns = constraints.maxWidth >= 900
            ? 3
            : constraints.maxWidth >= 650
            ? 2
            : 1;

        final cardWidth =
            ((constraints.maxWidth - (spacing * (columns - 1))) / columns)
                .toDouble();

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: _mealSlots.map((meal) {
            final menu = _findMenu(meal.id);

            return SizedBox(
              width: cardWidth,
              child: _TodayMealCard(
                meal: meal,
                menu: menu,
                icon: _mealIcon(meal.mealType),
                color: _mealColor(meal.mealType),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _DayHeader extends StatelessWidget {
  final String dayName;
  final String formattedDate;
  final int availableMenus;
  final int totalMeals;

  const _DayHeader({
    required this.dayName,
    required this.formattedDate,
    required this.availableMenus,
    required this.totalMeals,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(21),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colorScheme.primary, colorScheme.secondary],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.20),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.restaurant_menu,
              color: Colors.white,
              size: 35,
            ),
          ),

          const SizedBox(width: 15),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Today's Menu",
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 3),
                Text(
                  dayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  formattedDate,
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Column(
              children: [
                Text(
                  '$availableMenus/$totalMeals',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Menus',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TodayMealCard extends StatelessWidget {
  final MealSlotModel meal;
  final WeeklyMenuModel? menu;
  final IconData icon;
  final Color color;

  const _TodayMealCard({
    required this.meal,
    required this.menu,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final menuAvailable = menu != null && menu!.menuItems.isNotEmpty;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(icon, color: color, size: 29),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        meal.displayMealType,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${meal.displayStartTime} - '
                        '${meal.displayEndTime}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

                Icon(
                  menuAvailable ? Icons.check_circle : Icons.info_outline,
                  color: menuAvailable ? Colors.green : Colors.grey,
                ),
              ],
            ),

            const SizedBox(height: 17),

            const Divider(),

            const SizedBox(height: 12),

            if (!menuAvailable)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Menu not available',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              )
            else
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: menu!.menuItems.map((item) {
                  return Chip(
                    avatar: Icon(Icons.restaurant, size: 17, color: color),
                    label: Text(item),
                    visualDensity: VisualDensity.compact,
                    side: BorderSide.none,
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 68),
              const SizedBox(height: 16),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyView({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 75, color: Colors.grey),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
