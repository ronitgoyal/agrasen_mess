import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'dart:async';
import '../../../core/config/api_config.dart';

class PasswordResetService {
  // Android Emulator: 10.0.2.2
  // Physical phone: laptop ka local Wi-Fi IP use karo.
  static const _baseUrl = '${ApiConfig.baseUrl}/auth';
  Future<void> requestOtp(String email) async {
    final response = await _post(
      '$_baseUrl/forgot-password',
      {'email': email.trim().toLowerCase()},
    );
    _throwIfFailed(response);
    
  }

  Future<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    final response = await _post(
      '$_baseUrl/reset-password',
      {
        'email': email.trim().toLowerCase(),
        'otp': otp.trim(),
        'new_password': newPassword,
      },
    );
    _throwIfFailed(response);
  }

  Future<http.Response> _post(
    String url,
    Map<String, String> body,
  ) async {
    try {
      return await http
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 60));
    } 
    on SocketException {
      throw const PasswordResetException(
        'Cannot connect to the server. Check your connection and try again.',
      );
    } on HttpException {
      throw const PasswordResetException('Network request failed.');
    } catch (error) {
      if (error is PasswordResetException) rethrow;
      throw PasswordResetException('Network error: $error');
      
    }
  }

  void _throwIfFailed(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    String message = 'Request failed (${response.statusCode}).';

    try {
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic>) {
        final detail = data['detail'];
        if (detail is String) {
          message = detail;
        } else if (detail is List) {
          message = detail
              .map((item) =>
                  item is Map ? (item['msg'] ?? item).toString() : '$item')
              .join(', ');
        }
      }
    } on FormatException {
      // Server ne JSON return nahi kiya.
    }

    throw PasswordResetException(message);
  }
}

class PasswordResetException implements Exception {
  final String message;

  const PasswordResetException(this.message);

  @override
  String toString() => message;
}