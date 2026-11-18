import 'package:flutter/material.dart';

import '../models/dashboard_model.dart';

class MealCard extends StatelessWidget {
  static const Color _green = Color(0xFF298C4A);
  static const Color _orange = Color(0xFFFF7D33);
  static const Color _text = Color(0xFF18251E);
  static const Color _muted = Color(0xFF637369);

  final DashboardMealModel meal;
  final VoidCallback? onGenerateQr;

  const MealCard({super.key, required this.meal, this.onGenerateQr});

  String get _effectiveStatus {
    if (meal.attendanceRecorded) return 'completed';
    return meal.status.toLowerCase();
  }

  Color get _statusColor {
    switch (_effectiveStatus) {
      case 'completed':
        return _green;
      case 'available':
        return _orange;
      case 'upcoming':
      case 'closed':
        return _muted;
      default:
        return _muted;
    }
  }

  Color get _statusBackground {
    switch (_effectiveStatus) {
      case 'completed':
        return const Color(0xFFF0F9F2);
      case 'available':
        return const Color(0xFFFFF6EC);
      default:
        return const Color(0xFFF6F7F9);
    }
  }

  String _title(String type) {
    final clean = type.trim().toLowerCase();
    if (clean.isEmpty) return 'Meal';
    return '${clean[0].toUpperCase()}${clean.substring(1)}';
  }

  String _letter(String type) {
    final clean = type.trim();
    return clean.isEmpty ? 'M' : clean[0].toUpperCase();
  }

  String _formatTime(String value) {
    try {
      final parts = value.split('.').first.split(':');
      if (parts.length < 2) return value;

      var hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);
      if (hour == null || minute == null) return value;

      final suffix = hour >= 12 ? 'PM' : 'AM';
      if (hour == 0) {
        hour = 12;
      } else if (hour > 12) {
        hour -= 12;
      }

      return '$hour:${minute.toString().padLeft(2, '0')} $suffix';
    } catch (_) {
      return value;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor;

    return Container(
      padding: const EdgeInsets.all(16),
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
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _statusBackground,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  _letter(meal.mealType),
                  style: TextStyle(
                    color: color,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _title(meal.mealType),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _text,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${_formatTime(meal.startTime)} – '
                      '${_formatTime(meal.endTime)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: _statusBackground,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  _effectiveStatus.replaceAll('_', ' ').toUpperCase(),
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 17),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  meal.menuItems.isEmpty
                      ? 'Menu not available'
                      : meal.menuItems.join(' • '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: meal.menuItems.isEmpty ? Colors.grey : _muted,
                    fontSize: 12,
                    fontStyle: meal.menuItems.isEmpty
                        ? FontStyle.italic
                        : FontStyle.normal,
                  ),
                ),
              ),
              if (meal.canGenerateQr) ...[
                const SizedBox(width: 12),
                SizedBox(
                  height: 38,
                  child: FilledButton(
                    onPressed: onGenerateQr,
                    style: FilledButton.styleFrom(
                      backgroundColor: _orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: const Text('Generate QR'),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
