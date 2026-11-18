import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../models/scan_result_model.dart';

class ScannerService {
  const ScannerService();

  Future<ScanResultModel> scanQr(String qrToken) async {
    try {
      final accessToken = await SecureStorageService.getToken();

      if (accessToken == null || accessToken.isEmpty) {
        throw Exception(
          'Your session has expired. Please log in again.',
        );
      }

      final response = await ApiClient.dio.post(
        '/attendance/scan',
        data: {'token': qrToken},
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );

      final responseData = response.data;

      if (responseData is! Map) {
        throw Exception('The server returned an invalid response.');
      }

      final data = Map<String, dynamic>.from(responseData);

      if (data['data'] is Map) {
        final nestedData = Map<String, dynamic>.from(data['data'] as Map);

        // Outer message ko nested response me include karna.
        nestedData['message'] ??= data['message'];

        return ScanResultModel.fromJson(nestedData);
      }

      return ScanResultModel.fromJson(data);
    } on DioException catch (error) {
      throw Exception(_getErrorMessage(error));
    } catch (error) {
      throw Exception(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  String _getErrorMessage(DioException error) {
    final responseData = error.response?.data;

    if (responseData is Map) {
      final detail =
          responseData['detail'] ??
          responseData['message'] ??
          responseData['error'];

      if (detail is String && detail.isNotEmpty) {
        return detail;
      }

      if (detail is List && detail.isNotEmpty) {
        final firstError = detail.first;

        if (firstError is Map && firstError['msg'] != null) {
          return firstError['msg'].toString();
        }

        return firstError.toString();
      }
    }

    if (error.response?.statusCode == 401) {
      return 'Your session has expired. Please log in again.';
}

if (error.response?.statusCode == 403) {
  return 'Only mess staff can scan QR codes.';
}

if (error.type == DioExceptionType.connectionError) {
  return 'Unable to connect to the server.';
}

return 'Could not process the QR scan.';
  }
}
