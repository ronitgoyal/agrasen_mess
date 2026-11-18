import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../models/user_model.dart';

class LoginResult {
  final String accessToken;
  final UserModel user;

  const LoginResult({required this.accessToken, required this.user});
}

class AuthService {
  Future<LoginResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await ApiClient.dio.post(
        '/auth/login',
        data: {'email': email.trim().toLowerCase(), 'password': password},
      );

      final data = response.data as Map<String, dynamic>;

      final accessToken = data['access_token'] as String;

      final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);

      await SecureStorageService.saveToken(accessToken);

      return LoginResult(accessToken: accessToken, user: user);
    } on DioException catch (error) {
      throw Exception(extractErrorMessage(error));
    }
  }

  Future<UserModel> getCurrentUser() async {
    try {
      final response = await ApiClient.dio.get('/auth/me');

      return UserModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw Exception(extractErrorMessage(error));
    }
  }

  Future<void> logout() {
    return SecureStorageService.clearAll();
  }

  String extractErrorMessage(DioException error) {
    final responseData = error.response?.data;

    if (responseData is Map<String, dynamic>) {
      final detail = responseData['detail'];

      if (detail is String) {
        return detail;
      }

      if (detail is List && detail.isNotEmpty) {
        final firstError = detail.first;

        if (firstError is Map<String, dynamic>) {
          return firstError['msg']?.toString() ?? 'Invalid information';
        }
      }
    }

    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout) {
      return 'Unable to connect to the server';
    }

    return 'Login failed. Please try again.';
  }
}
