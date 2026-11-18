import 'package:flutter/material.dart';

import '../models/staff_attendance_model.dart';
import '../services/staff_attendance_service.dart';

class StaffAttendanceScreen extends StatefulWidget {
  const StaffAttendanceScreen({super.key});

  @override
  State<StaffAttendanceScreen> createState() => _StaffAttendanceScreenState();
}

class _StaffAttendanceScreenState extends State<StaffAttendanceScreen> {
  final StaffAttendanceService _service = const StaffAttendanceService();

  final TextEditingController _searchController = TextEditingController();

  List<StaffAttendanceModel> _allRecords = [];

  String _selectedMeal = 'all';
  String _searchText = '';
  DateTime? _selectedDate;

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAttendance();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<StaffAttendanceModel> get _filteredRecords {
    return _allRecords.where((record) {
      final matchesMeal =
          _selectedMeal == 'all' ||
          record.mealType.toLowerCase() == _selectedMeal;

      final query = _searchText.trim().toLowerCase();

      final matchesSearch =
          query.isEmpty ||
          record.studentName.toLowerCase().contains(query) ||
          record.roomNumber.toLowerCase().contains(query);

      final matchesDate =
          _selectedDate == null ||
          _isSameDate(record.attendedAt?.toLocal(), _selectedDate);

      return matchesMeal && matchesSearch && matchesDate;
    }).toList();
  }

  bool _isSameDate(DateTime? first, DateTime? second) {
    if (first == null || second == null) {
      return false;
    }

    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  Future<void> _loadAttendance() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final records = await _service.getAttendance();

      if (!mounted) return;

      records.sort((a, b) {
        final first = a.attendedAt ?? DateTime.fromMillisecondsSinceEpoch(0);

        final second = b.attendedAt ?? DateTime.fromMillisecondsSinceEpoch(0);

        return second.compareTo(first);
      });

      setState(() {
        _allRecords = records;
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

  Future<void> _selectDate() async {
    final now = DateTime.now();

    final selected = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
      helpText: 'Select attendance date',
    );

    if (selected == null || !mounted) return;

    setState(() {
      _selectedDate = selected;
    });
  }

  void _selectToday() {
    final now = DateTime.now();

    setState(() {
      _selectedDate = DateTime(now.year, now.month, now.day);
    });
  }

  void _clearFilters() {
    _searchController.clear();

    setState(() {
      _searchText = '';
      _selectedMeal = 'all';
      _selectedDate = null;
    });
  }

  String _formatSelectedDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String _formatDateTime(DateTime? date) {
    if (date == null) {
      return 'Time unavailable';
    }

    final value = date.toLocal();
    final hour = value.hour;
    final minute = value.minute.toString().padLeft(2, '0');

    final period = hour >= 12 ? 'PM' : 'AM';

    final displayHour = hour == 0
        ? 12
        : hour > 12
        ? hour - 12
        : hour;

    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/'
        '${value.year}  '
        '$displayHour:$minute $period';
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

  @override
  Widget build(BuildContext context) {
    final records = _filteredRecords;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Records'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loadAttendance,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSummary(records.length),
          _buildSearchBox(),
          _buildDateFilter(),
          _buildMealFilters(),
          Expanded(child: _buildRecords(records)),
        ],
      ),
    );
  }

  Widget _buildSummary(int filteredCount) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            Icons.fact_check,
            size: 38,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Attendance Records'),
                const SizedBox(height: 3),
                Text(
                  '$filteredCount shown out of '
                  '${_allRecords.length}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBox() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchText = value;
          });
        },
        decoration: InputDecoration(
          hintText: 'Search name or room number',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchText.isNotEmpty
              ? IconButton(
                  tooltip: 'Clear search',
                  onPressed: () {
                    _searchController.clear();

                    setState(() {
                      _searchText = '';
                    });
                  },
                  icon: const Icon(Icons.clear),
                )
              : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  Widget _buildDateFilter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _selectDate,
              icon: const Icon(Icons.calendar_month),
              label: Text(
                _selectedDate == null
                    ? 'Select Date'
                    : _formatSelectedDate(_selectedDate!),
              ),
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(onPressed: _selectToday, child: const Text('Today')),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Clear all filters',
            onPressed: _clearFilters,
            icon: const Icon(Icons.filter_alt_off),
          ),
        ],
      ),
    );
  }

  Widget _buildMealFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          _filterChip('all', 'All'),
          _filterChip('breakfast', 'Breakfast'),
          _filterChip('lunch', 'Lunch'),
          _filterChip('dinner', 'Dinner'),
        ],
      ),
    );
  }

  Widget _filterChip(String value, String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: _selectedMeal == value,
        onSelected: (_) {
          setState(() {
            _selectedMeal = value;
          });
        },
      ),
    );
  }

  Widget _buildRecords(List<StaffAttendanceModel> records) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 64),
              const SizedBox(height: 16),
              Text(_errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _loadAttendance,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (records.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 60),
          const Icon(Icons.search_off, color: Colors.grey, size: 70),
          const SizedBox(height: 16),
          const Text(
            'Selected filters ke liye koi '
            'attendance record nahi mila.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Center(
            child: OutlinedButton.icon(
              onPressed: _clearFilters,
              icon: const Icon(Icons.filter_alt_off),
              label: const Text('Clear Filters'),
            ),
          ),
        ],
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAttendance,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: records.length,
        itemBuilder: (context, index) {
          final record = records[index];

          final color = _mealColor(record.mealType);

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.15),
                child: Icon(Icons.person, color: color),
              ),
              title: Text(
                record.studentName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Room: ${record.roomNumber}\n'
                    '${record.displayMealType} • '
                      '${_formatDateTime(record.attendedAt)}',
                     ),
              ),
              trailing: const Icon(Icons.check_circle, color: Colors.green),
            ),
          );
        },
      ),
    );
  }
}
