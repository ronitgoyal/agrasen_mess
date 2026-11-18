import 'package:flutter/foundation.dart';

import '../models/dashboard_model.dart';
import '../services/dashboard_service.dart';

class DashboardProvider extends ChangeNotifier {
  final DashboardService _service = DashboardService();

  StudentDashboardModel? _dashboard;
  bool _isLoading = false;
  String? _errorMessage;

  StudentDashboardModel? get dashboard => _dashboard;

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  Future<void> loadDashboard() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _dashboard = await _service.getStudentDashboard();
    } catch (error) {
      _errorMessage = error.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
