import 'package:flutter/material.dart';

import '../models/meal_slot_model.dart';
import '../services/meal_slot_service.dart';
import '../../../core/responsive/responsive_form_list.dart';

class MealFormScreen extends StatefulWidget {
  final MealSlotModel? meal;

  const MealFormScreen({super.key, this.meal});

  bool get isEditing => meal != null;

  @override
  State<MealFormScreen> createState() => _MealFormScreenState();
}

class _MealFormScreenState extends State<MealFormScreen> {
  final MealSlotService _service = const MealSlotService();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  static const List<String> _mealTypes = ['breakfast', 'lunch', 'dinner'];

  String _mealType = 'breakfast';
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _isActive = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    final meal = widget.meal;

    if (meal != null) {
      _mealType = _mealTypes.contains(meal.mealType.toLowerCase())
          ? meal.mealType.toLowerCase()
          : 'breakfast';

      _startTime = _parseTime(meal.startTime);

      _endTime = _parseTime(meal.endTime);

      _isActive = meal.isActive;
    }
  }

  TimeOfDay? _parseTime(String value) {
    try {
      final cleanValue = value.split('.').first;
      final parts = cleanValue.split(':');

      if (parts.length < 2) return null;

      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } catch (_) {
      return null;
    }
  }

  String _apiTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}:00';
  }

  String _displayTime(TimeOfDay? time) {
    if (time == null) {
      return 'Select time';
    }

    return time.format(context);
  }

  Future<void> _selectStartTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: _startTime ?? const TimeOfDay(hour: 7, minute: 0),
      helpText: 'Select meal start time',
    );

    if (selected == null || !mounted) return;

    setState(() {
      _startTime = selected;
    });
  }

  Future<void> _selectEndTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: _endTime ?? const TimeOfDay(hour: 9, minute: 0),
      helpText: 'Select meal end time',
    );

    if (selected == null || !mounted) return;

    setState(() {
      _endTime = selected;
    });
  }

  Future<void> _saveMeal() async {
    if (_isSaving) return;

    if (_startTime == null) {
      setState(() {
        _errorMessage = 'Please select start time.';
      });

      return;
    }

    if (_endTime == null) {
      setState(() {
        _errorMessage = 'Please select end time.';
      });

      return;
    }

    if (_startTime!.hour == _endTime!.hour &&
        _startTime!.minute == _endTime!.minute) {
      setState(() {
        _errorMessage = 'Start and end times cannot be the same.';
      });

      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      if (widget.isEditing) {
        await _service.updateMeal(
          mealId: widget.meal!.id,
          mealType: _mealType,
          startTime: _apiTime(_startTime!),
          endTime: _apiTime(_endTime!),
          isActive: _isActive,
        );
      } else {
        await _service.createMeal(
          mealType: _mealType,
          startTime: _apiTime(_startTime!),
          endTime: _apiTime(_endTime!),
          isActive: _isActive,
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green,
          content: Text(
            widget.isEditing
                ? 'Meal successfully updated.'
                : 'Meal successfully created.',
          ),
        ),
      );

      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  String _formatMealType(String value) {
    if (value.isEmpty) return value;

    return '${value[0].toUpperCase()}'
        '${value.substring(1).toLowerCase()}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.isEditing ? 'Edit Meal' : 'Add Meal')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ResponsiveFormList(
            children: [
              Icon(
                widget.isEditing
                    ? Icons.edit_calendar
                    : Icons.add_circle_outline,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 12),
              Text(
                widget.isEditing ? 'Update Meal Details' : 'Create New Meal',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 25),

              if (_errorMessage != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 18),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),

              DropdownButtonFormField<String>(
                initialValue: _mealType,
                decoration: const InputDecoration(
                  labelText: 'Meal type',
                  prefixIcon: Icon(Icons.restaurant),
                ),
                items: _mealTypes.map((mealType) {
                  return DropdownMenuItem<String>(
                    value: mealType,
                    child: Text(_formatMealType(mealType)),
                  );
                }).toList(),
                onChanged: _isSaving
                    ? null
                    : (value) {
                        if (value == null) return;

                        setState(() {
                          _mealType = value;
                        });
                      },
              ),

              const SizedBox(height: 18),

              _TimeSelector(
                title: 'Start time',
                value: _displayTime(_startTime),
                icon: Icons.access_time,
                onPressed: _isSaving ? null : _selectStartTime,
              ),

              const SizedBox(height: 16),

              _TimeSelector(
                title: 'End time',
                value: _displayTime(_endTime),
                icon: Icons.access_time_filled,
                onPressed: _isSaving ? null : _selectEndTime,
              ),

              const SizedBox(height: 18),

              Card(
                child: SwitchListTile(
                  value: _isActive,
                  onChanged: _isSaving
                      ? null
                      : (value) {
                          setState(() {
                            _isActive = value;
                          });
                        },
                  title: const Text(
                    'Active Meal',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    _isActive
                        ? 'Students can use this meal slot.'
                        : 'This meal slot is disabled.',
                  ),
                  secondary: Icon(
                    _isActive ? Icons.check_circle : Icons.cancel,
                    color: _isActive ? Colors.green : Colors.red,
                  ),
                ),
              ),

              const SizedBox(height: 28),

              FilledButton.icon(
                onPressed: _isSaving ? null : _saveMeal,
                icon: _isSaving
                    ? const SizedBox(
                        width: 21,
                        height: 21,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(widget.isEditing ? Icons.save : Icons.add),
                label: Text(
                  _isSaving
                      ? 'Saving...'
                      : widget.isEditing
                      ? 'Update Meal'
                      : 'Create Meal',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimeSelector extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final VoidCallback? onPressed;

  const _TimeSelector({
    required this.title,
    required this.value,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(14),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: title,
          prefixIcon: Icon(icon),
          suffixIcon: const Icon(Icons.arrow_drop_down),
        ),
        child: Text(value, style: const TextStyle(fontSize: 16)),
      ),
    );
  }
}
