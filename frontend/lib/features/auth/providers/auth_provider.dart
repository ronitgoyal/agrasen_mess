import 'package:flutter/foundation.dart';

import '../../../core/storage/secure_storage_service.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../../../core/network/api_client.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  UserModel? _user;
  bool _isInitializing = true;
  bool _isLoading = false;
  String? _errorMessage;

  AuthProvider() {
    ApiClient.initialize(onUnauthorized: handleUnauthorized);
  }

  UserModel? get user => _user;
  bool get isInitializing => _isInitializing;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _user != null;
  String? get errorMessage => _errorMessage;

  Future<void> handleUnauthorized() async {
    await SecureStorageService.clearAll();

    _user = null;
    _errorMessage =
        'Your session has expired. Please log in again.';

    notifyListeners();
  }

  Future<void> initialize() async {
    final token = await SecureStorageService.getToken();

    if (token == null || token.isEmpty) {
      _isInitializing = false;
      notifyListeners();
      return;
    }

    try {
      _user = await _authService.getCurrentUser();
    } catch (_) {
      await SecureStorageService.clearAll();
      _user = null;
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  Future<bool> login({required String email, required String password}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authService.login(email: email, password: password);

      _user = result.user;
      return true;
    } catch (error) {
      _errorMessage = error.toString().replaceFirst('Exception: ', '');

      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _authService.logout();

    _user = null;
    _errorMessage = null;

    notifyListeners();
  }
}
