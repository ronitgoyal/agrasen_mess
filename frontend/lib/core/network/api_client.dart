import 'package:dio/dio.dart';

import '../config/api_config.dart';
import '../storage/secure_storage_service.dart';
import 'package:flutter/foundation.dart';

class ApiClient {
  ApiClient._();

  static Future<void> Function()? _unauthorizedHandler;
  static bool _isHandlingUnauthorized = false;

  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: ApiConfig.timeout,
      receiveTimeout: ApiConfig.timeout,
      sendTimeout: ApiConfig.timeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  static bool _interceptorAdded = false;

  static void initialize({Future<void> Function()? onUnauthorized}) {
    _unauthorizedHandler = onUnauthorized;

    if (_interceptorAdded) return;

    dio.interceptors.add(
      QueuedInterceptorsWrapper(
        onRequest:
            (RequestOptions options, RequestInterceptorHandler handler) async {
              final token = await SecureStorageService.getToken();

              if (token != null && token.isNotEmpty) {
                options.headers['Authorization'] = 'Bearer $token';
              } else {
                options.headers.remove('Authorization');
              }

              handler.next(options);
            },

        onResponse:
            (Response<dynamic> response, ResponseInterceptorHandler handler) {
              handler.next(response);
            },

        onError: (DioException error, ErrorInterceptorHandler handler) async {
          final statusCode = error.response?.statusCode;

          final requestPath = error.requestOptions.path;

          final isLoginRequest = requestPath.contains('/auth/login');
          debugPrint(
  'API 401: ${error.requestOptions.method} '
  '${error.requestOptions.uri} '
  'detail=${error.response?.data}',
);

          if (statusCode == 401 &&
              !isLoginRequest &&
              !_isHandlingUnauthorized) {
            _isHandlingUnauthorized = true;

            try {
              await SecureStorageService.clearAll();

              final callback = _unauthorizedHandler;

              if (callback != null) {
                await callback();
              }
            } finally {
              _isHandlingUnauthorized = false;
            }
          }

          handler.next(error);
        },
      ),
    );

    _interceptorAdded = true;
  }
}
